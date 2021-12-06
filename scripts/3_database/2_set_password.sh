#!/bin/bash

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh

lRC=0
DATADIR="/var/lib/mysql"
PASSWD_ROOT="$(pwgen -1 18)"
PASSWD_REPLI="$(pwgen -1 18)"
PASSWD_GALERA="$(pwgen -1 18)"

banner "BEGIN SCRIPT: $_NAME"

echo "SET PASSWORD FOR 'root'@'localhost' = PASSWORD('${PASSWD_ROOT}');GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost';

CREATE OR REPLACE USER 'root'@'192.168.%' IDENTIFIED BY '${PASSWD_ROOT}';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'192.168.%';

CREATE OR REPLACE USER 'galera'@'192.168.%' IDENTIFIED BY '${PASSWD_GALERA}';
GRANT RELOAD, PROCESS, LOCK TABLES, REPLICATION CLIENT ON *.* TO 'galera'@'192.168.%';

CREATE OR REPLACE USER 'galera'@'localhost' IDENTIFIED BY '${PASSWD_GALERA}';
GRANT RELOAD, PROCESS, LOCK TABLES, REPLICATION CLIENT,SUPER ON *.* TO 'galera'@'localhost';

CREATE OR REPLACE USER 'replication'@'192.168.%' IDENTIFIED BY '${PASSWD_REPLI}';
GRANT REPLICATION SLAVE ON *.* TO 'replication'@'192.168.%';
" | mysql -uroot -v
lRC=$(($lRC + $?))
echo "[mysql]
user=root
password=${PASSWD_ROOT}
#socket=/run/mysqld/mysqld.sock
" > /root/.my.cnf

chmod 600 /root/.my.cnf

check_mariadb_password root ${PASSWD_ROOT}
lRC=$(($lRC + $?))
check_mariadb_password replication ${PASSWD_REPLI}
lRC=$(($lRC + $?))
check_mariadb_password galera ${PASSWD_GALERA}
lRC=$(($lRC + $?))

footer "END SCRIPT: $NAME"

info "ROOT PASSWORD: $PASSWD_ROOT"
info "REPLICATION USER PASSWORD: $PASSWD_REPLI"
info "GALERA USER PASSWORD: $PASSWD_GALERA"
add_password_history root "$PASSWD_ROOT"
add_password_history replication "${PASSWD_REPLI}"
add_password_history galera "${PASSWD_GALERA}"

echo "node_addresses=192.168.33.191,192.168.33.192,192.168.33.193
sst_user=galera
sst_password=${PASSWD_GALERA}
cluster_name="gendarmerie"
" > /etc/bootstrap.conf
chmod 700 /etc/bootstrap.conf

exit $lRC