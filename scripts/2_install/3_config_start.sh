#!/bin/bash

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh

##title_en: MariaDB 10.6 server configuration based on  CPU/RAM
##title_fr: Configuration du serveur MariaDB 10.5 basée sur la RAM et CPU
##goals_en: Create configuration file / Setup systemctl service mariadb / Clean up log file / Starting service / Check service health
##goals_fr: Creation du fichier de configuration / Paramétrage du service mariadb / Nettoyage des fichiers de logs / Démarrage du service / vérification de l etat du service

lRC=0
DATADIR="/var/lib/mysql"
[ -d "/etc/my.cnf.d/" ] && CONF_FILE="/etc/my.cnf.d/99_minimal_config.cnf"
[ -d "/etc/mysql/conf.d/" ] && CONF_FILE="/etc/mysql/conf.d/99_minimal_config.cnf"
server_id=$(hostname -s| perl -pe 's/.+?(\d+)/$1/')
#server_id=$(ip a| grep '192' |grep inet|awk '{print $2}'| cut -d/ -f1 | cut -d. -f4)


mem_gb=$(free -g| grep Mem: | awk '{print $2}')
[ $mem_gb -eq 1 ] && mem_gb=2
[ $mem_gb -eq 0 ] && mem_gb=1


banner "BEGIN SCRIPT: $_NAME"

cmd "rm -f $CONF_FILE"

cmd "mkdir -p /var/log/mysql /run/mysqld"
cmd "chown -R mysql.mysql /var/log/mysql /run/mysqld"
#cmd "ln -sf /run/mysqld/mysqld.sock /var/lib/mysql/mysql.sock"


info "SETUP $(basename $CONF_FILE) FILE INTO $(dirname $CONF_FILE)"

(
echo "# Minimal configuration - created $(date)"
python3 /opt/local/bin/mygenconf.py server_id=$server_id mysql_ram_gb=$mem_gb
) | tee -a $CONF_FILE

cmd "chmod 644 $CONF_FILE"

[ -f "/usr/lib/systemd/system/mysqld.service" ] && perl -i -pe 's/LimitNOFILE=\d+/LimitNOFILE=infinity/g' /usr/lib/systemd/system/mysqld.service
[ -f "/usr/lib/systemd/system/mariadb.service" ]  && perl -i -pe 's/LimitNOFILE=\d+/LimitNOFILE=infinity/g' /usr/lib/systemd/system/mariadb.service

cmd "journalctl --rotate -u mariadb"
cmd "systemctl disable mariadb"
cmd "systemctl unmask mariadb"

if [ ! -d "/var/lib/mysql/mysql" ]; then
	cmd "rm -rf $DATADIR /var/log/mysql/*"
	cmd "journalctl --rotate -u mariadb"
	cmd "journalctl --vacuum-time=1s -u mariadb"
	cmd "mysql_install_db --user mysql --skip-name-resolve --datadir=$DATADIR"
fi

cmd "systemctl enable mariadb"
cmd "systemctl daemon-reload"
cmd "systemctl restart mariadb"

sleep 3s

cmd "netstat -ltnp"
cmd "netstat -lxnp"
cmd "ps -edf |grep [m]ysqld"
cmd "ps -edf |grep [m]ariadbd"

cmd "ls -ls /var/lib/mysql"

cmd "journalctl -xe -o cat -u mariadb"

[ -f "/var/lib/mysql/mysqld.log" ] && cmd "tail -n 15 /var/lib/mysql/mysqld.log"
[ -f "/var/log/mysql/mysqld.log" ] && cmd "tail -n 15 /var/log/mysql/mysqld.log"

sleep 3s
systemctl is-active mariadb
echo $?
cd /opt/local
if [ ! -d "./mariadb-sys" ]; then
	cmd "git clone https://github.com/FromDual/mariadb-sys.git"
	lRC=$(($lRC + $?))
fi
cd /opt/local/mariadb-sys
mysql -f < sys_10.sql

footer "END SCRIPT: $NAME"
exit $lRC