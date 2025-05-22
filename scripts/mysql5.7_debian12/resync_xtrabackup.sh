#!/bin/bash

if [ -f "$1" ]; then
  [ -z "$SOURCE_HOST" ] && SOURCE_HOST=$(cat $1 | grep -E "^SOURCE_HOST=" | cut -d'=' -f2)
  [ -z "$SOURCE_USER" ] && $SOURCE_USER=$(cat $1 | grep -E "^SOURCE_USER=" | cut -d'=' -f2)
  [ -z "$RPL_USER" ] && REPL_USER=$(cat $1 | grep -E "^REPL_USER=" | cut -d'=' -f2)
  [ -z "$REPL_PASS" ] && REPL_PASS=$(cat $1 | grep -E "^REPL_PASS=" | cut -d'=' -f2)
  [ -z "$MYSQL_DATA_DIR" ] && MYSQL_DATA_DIR=$(cat $1 | grep -E "^MYSQL_DATA_DIR=" | cut -d'=' -f2)
fi

# Script de restauration d'un backup MySQL via xtrabackup
# Ce script doit être exécuté avec des privilèges root (par exemple, via sudo).
# Vérifier si le script est exécuté en tant que root
if [[ $EUID -ne 0 ]]; then
   echo "Ce script doit être exécuté en tant que root ou avec sudo."
   exit 1
fi
# Définir les variables



# Variables à personnaliser

if [ -z "$SOURCE_HOST" ]; then
  echo "SOURCE_HOST n'est pas défini. Veuillez le définir dans le fichier de configuration."
  exit 1
fi
if [ -z "$SOURCE_USER" ]; then
  echo "SOURCE_USER n'est pas défini. Veuillez le définir dans le fichier de configuration."
  exit 1
fi
if [ -z "$SOURCE_MYSQL_USER" ]; then
  echo "SOURCE_MYSQL_USER n'est pas défini. Veuillez le définir dans le fichier de configuration."
  exit 1
fi
if [ -z "$SOURCE_MYSQL_PASS" ]; then
  echo "SOURCE_MYSQL_PASS n'est pas défini. Veuillez le définir dans le fichier de configuration."
  exit 1
fi
if [ -z "$REPL_USER" ]; then
  echo "REPL_USER n'est pas défini. Veuillez le définir dans le fichier de configuration."
  exit 1
fi
if [ -z "$REPL_PASS" ]; then
  echo "REPL_PASS n'est pas défini. Veuillez le définir dans le fichier de configuration."
  exit 1
fi
if [ -z "$MYSQL_DATA_DIR" ]; then
  echo "MYSQL_DATA_DIR n'est pas défini. Veuillez le définir dans le fichier de configuration."
  exit 1
fi
if [ -z "$MYSQL_USER" ]; then
  echo
SOURCE_HOST="192.168.0.2"
SOURCE_USER="root"
SOURCE_MYSQL_USER="root"
SOURCE_MYSQL_PASS="xxxxx"
REPL_USER="rpl"
REPL_PASS="xxxxx"
MYSQL_DATA_DIR="/var/lib/mysql"
MYSQL_USER="mysql"
fi

# Vérification de la présence de xtrabackup
if ! command -v xtrabackup &> /dev/null; then
    echo "xtrabackup n'est pas installé. Veuillez l'installer avant de continuer."
    exit 1
fi
# Vérification de la présence de xbstream
if ! command -v xbstream &> /dev/null; then
    echo "xbstream n'est pas installé. Veuillez l'installer avant de continuer."
    exit 1
fi

echo "1. Arrêt et purge de MySQL local..."
systemctl stop mysql
systemctl disable mysql
rm -rf $MYSQL_DATA_DIR/*

echo "2. Restauration du backup streamé directement dans $MYSQL_DATA_DIR..."
ssh $SOURCE_USER@$SOURCE_HOST \
  "xtrabackup --backup --stream=xbstream --user=$SOURCE_MYSQL_USER --password=$SOURCE_MYSQL_PASS" \
| xbstream -x -C $MYSQL_DATA_DIR

echo "3. Application des logs dans $MYSQL_DATA_DIR..."
xtrabackup --prepare --target-dir=$MYSQL_DATA_DIR

echo "4. Suppression de auto.cnf (UUID unique pour le cluster)..."
rm -f $MYSQL_DATA_DIR/auto.cnf
rm -f $MYSQL_DATA_DIR/*.pem
rm -f  $MYSQL_DATA_DIR/*relay-bin*

echo "5. Droits sur le datadir..."
chown -R $MYSQL_USER:$MYSQL_USER $MYSQL_DATA_DIR
GTID_INFO=$(cat $MYSQL_DATA_DIR/xtrabackup_binlog_info | awk '{print $NF}'|xargs | sed -E 's/\s//')
echo "6. Redémarrage MySQL..."
systemctl start mysql
sleep 3s
echo "SET SQL_LOG_BIN=0;
RESET SLAVE ALL FOR CHANNEL 'group_replication_applier';
RESET SLAVE ALL FOR CHANNEL 'group_replication_recovery';
RESET MASTER;
delete from mysql.slave_master_info ;
delete from mysql.slave_relay_log_info;
delete from mysql.slave_worker_info;
SET GLOBAL GTID_PURGED='$GTID_INFO';
SET SQL_LOG_BIN=1;
CHANGE MASTER TO MASTER_USER='$REPL_USER', MASTER_PASSWORD='$REPL_PASS', MASTER_AUTO_POSITION=1;
START GROUP_REPLICATION' FOR CHANNEL 'group_replication_recovery';
START GROUP_REPLICATION;" | mysql -v

echo "==> Synchronisation terminée !"