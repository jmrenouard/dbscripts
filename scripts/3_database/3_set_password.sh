#!/bin/bash

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh
[ -f '/etc/profile.d/utils.mysql.sh' ] && source /etc/profile.d/utils.mysql.sh
[ -f "$(pwd)/utils.sh" ] && source "$(pwd)/utils.sh"

lRC=0
DATADIR="/var/lib/mysql"
PASSWD_ROOT="$(pwgen -1 32)"
PASSWD_REPLI="$(pwgen -1 32)"
PASSWD_GALERA="$(pwgen -1 32)"

NODE_IP_LIST="172.20.1.101,172.20.1.102,172.20.1.103"
NODE_IP_LIST="192.168.56.100,192.168.56.102,192.168.56.101,192.168.56.103"
NODE_IP_LIST="192.168.56.191,192.168.56.192,192.168.56.193"

MYSQL_IP_FILTERS="192.168.%,172.21.%,172.20.%"

banner "BEGIN SCRIPT: $_NAME"

for MYSQL_IP_FILTER in $(echo $MYSQL_IP_FILTERS| tr ',' ' '); do
echo "SET PASSWORD FOR 'root'@'localhost' = PASSWORD('${PASSWD_ROOT}');
GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' WITH GRANT OPTION;

CREATE OR REPLACE USER 'root'@'$MYSQL_IP_FILTER' IDENTIFIED BY '${PASSWD_ROOT}';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'$MYSQL_IP_FILTER';

CREATE OR REPLACE USER 'galera'@'$MYSQL_IP_FILTER' IDENTIFIED BY '${PASSWD_GALERA}';
GRANT RELOAD, PROCESS, LOCK TABLES, REPLICATION CLIENT ON *.* TO 'galera'@'$MYSQL_IP_FILTER';

CREATE OR REPLACE USER 'galera'@'localhost' IDENTIFIED BY '${PASSWD_GALERA}';
GRANT RELOAD, PROCESS, LOCK TABLES, REPLICATION CLIENT,SUPER ON *.* TO 'galera'@'localhost';

CREATE OR REPLACE USER 'replication'@'$MYSQL_IP_FILTER' IDENTIFIED BY '${PASSWD_REPLI}';
GRANT REPLICATION SLAVE ON *.* TO 'replication'@'$MYSQL_IP_FILTER';
"
done | mysql -uroot -v
lRC=$(($lRC + $?))
echo "[mysql]
user=root
password=${PASSWD_ROOT}
#socket=/run/mysqld/mysqld.sock
" > /root/.my.cnf

chmod 600 /root/.my.cnf

check_mariadb_password root "${PASSWD_ROOT}"
lRC=$(($lRC + $?))
check_mariadb_password replication "${PASSWD_REPLI}"
lRC=$(($lRC + $?))
check_mariadb_password galera "${PASSWD_GALERA}"
lRC=$(($lRC + $?))

footer "END SCRIPT: $NAME"

info "ROOT PASSWORD: $PASSWD_ROOT"
info "REPLICATION USER PASSWORD: $PASSWD_REPLI"
info "GALERA USER PASSWORD: $PASSWD_GALERA"
add_password_history root "$PASSWD_ROOT"
add_password_history replication "${PASSWD_REPLI}"
add_password_history galera "${PASSWD_GALERA}"

echo "node_addresses=$NODE_IP_LIST
sst_user=galera
sst_password=${PASSWD_GALERA}
cluster_name=generic
" > /etc/bootstrap.conf
chmod 700 /etc/bootstrap.conf

exit $lRC
