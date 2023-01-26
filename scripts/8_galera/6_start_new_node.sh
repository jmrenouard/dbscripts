#!/bin/bash

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh
lRC=0
CONF_FILE="/etc/my.cnf.d/999_galera_settings.cnf"
[ -d "/etc/my.cnf.d/" ] && CONF_FILE="/etc/my.cnf.d/999_galera_settings.cnf"
[ -d "/etc/mysql/conf.d/" ] && CONF_FILE="/etc/mysql/conf.d/999_galera_settings.cnf"
[ -d "/etc/mysql/mariadb.conf.d/" ] && CONF_FILE="/etc/mysql/mariadb.conf.d/999_galera_settings.cnf"

DATADIR=/var/lib/mysql/
cluster_name="generic"
server_id=$(hostname -s| perl -pe 's/.+?(\d+)/$1/')
node_name=$(hostname -s)
private_ip=$(ip a| grep '192.168' |grep inet|awk '{print $2}'| cut -d/ -f1| head -n 1)
[ -z "$private_ip" ] && private_ip=$my_private_ipv4
node_addresses=192.168.56.191,192.168.56.192,192.168.56.193
sst_user=galera
sst_password=kee2iesh1Ohk1puph8

[ -f "/etc/bootstrap.conf" ] && source /etc/bootstrap.conf

##title_en: Adding a new member into a galera Cluster
##title_fr: Initialisation d un nouveau membre dasn le cluster Galera
##goals_en: Start a other operationnal node /  Start a consistent new node / Adding Galera Cluster member
##goals_fr: Démarrer un nouveau noeud Galera operationnel / Démarrer un autre noeud dans un état consistant  / Ajouter un nouveau membre au cluster Galera

banner "BEGIN SCRIPT: $_NAME"

cmd "rm -f $CONF_FILE"


[ -f "/usr/lib/galera/libgalera_smm.so" ] && GALERA_LIB=/usr/lib/galera/libgalera_smm.so
[ -f "/usr/lib64/galera-4/libgalera_smm.so" ] && GALERA_LIB=/usr/lib64/galera-4/libgalera_smm.so

info "SETUP $(basename $CONF_FILE) FILE INTO $(dirname $CONF_FILE)"

(
echo "# Minimal Galera configuration - created $(date)
[server]
binlog-format=ROW
default-storage-engine=innodb
innodb-autoinc-lock-mode=2
innodb-flush-log-at-trx-commit = 0

sync-binlog=0
innodb-force-primary-key=1

wsrep-on=on
wsrep-provider=$GALERA_LIB
wsrep-slave-threads=$(( $(nproc) * 4 ))

wsrep_log_conflicts=ON

wsrep-cluster-name=${cluster_name}
wsrep-node-name=${node_name}
wsrep-node-address=${private_ip}
wsrep-cluster-address=gcomm://${node_addresses}
#wsrep-cluster-address=gcomm://

wsrep-sst-method=mariabackup

wsrep_sst_receive_address=${private_ip}
wsrep-sst-auth=${sst_user}:${sst_password}
#wsrep-notify-cmd=/opt/local/bin/table_wsrep_notif.sh
wsrep-notify-cmd=/opt/local/bin/file_wsrep_notif.sh

# Provider options
wsrep-provider-options='gcache.size=512M'
wsrep_provider_options='cert.log_conflicts=yes';
wsrep_provider_options='gcs.fc_factor=0.8'
wsrep_provider_options='gcs.fc_limit=254'
wsrep_provider_options='socket.ssl_cert=/etc/mysql/ssl/server-cert.pem;socket.ssl_ca=/etc/mysql/ssl/ca-cert.pem;socket.ssl_key=/etc/mysql/ssl/server-key.pem'
wsrep_provider_options='socket.ssl_cipher=AES128-SHA'
wsrep_debug=1

[sst]
#streamfmt=mbstream
compressor='pigz'
decompressor='pigz -dc'

[mariabackup]
parallel=$(nproc)
"
) | tee -a $CONF_FILE

cmd "chmod 644 $CONF_FILE"

cmd "rm -f ${DATADIR}/galera.cache ${DATADIR}/grastate.dat ${DATADIR}/gvwstate.dat"
cmd "systemctl restart mariadb"

echo "install soname 'wsrep_info';"| mysql -v
echo "select * from information_schema.wsrep_status\G" |mysql
title2 "MEMBERS IN GALERA"
echo "select * from information_schema.wsrep_membership;" | mysql

cmd "tail -n 30 /var/log/mysql/mysqld.log"
footer "END SCRIPT: $NAME"
exit $lRC