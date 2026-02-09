#!/bin/bash

source /etc/os-release

# --- Minimal Utility Functions ---
now() { echo "$(date "+%F %T %Z")($(hostname -s))"; }
info() { echo "$(now) INFO: $*" 1>&2; }
error() { echo "$(now) ERROR: $*" 1>&2; return 1; }
ok() { info "[SUCCESS] $* [SUCCESS]"; }
sep1() { echo "$(now) -----------------------------------------------------------------------------"; }
title1() { sep1; echo "$(now) $*"; sep1; }
cmd() {
    local tcmd="$1"
    local descr=${2:-"$tcmd"}
    title1 "RUNNING: $descr"
    eval "$tcmd"
    local cRC=$?
    if [ $cRC -eq 0 ]; then
        ok "$descr"
    else
        error "$descr (RC=$cRC)"
    fi
    return $cRC
}
banner() { title1 "START: $*"; info "run as $(whoami)@$(hostname -s)"; }
footer() {
    local lRC=${lRC:-"$?"}
    info "FINAL EXIT CODE: $lRC"
    [ $lRC -eq 0 ] && title1 "END: $* SUCCESSFUL" || title1 "END: $* FAILED"
    return $lRC
}
check_mariadb_password() {
    local user=$1
    local password=$2
    info "CHECKING PASSWORD FOR USER: $user"
    local ret=$(mysql -Nrs -h 127.0.0.1 -u "$user" -p"$password" -e "select 1" 2>&1)
    if [ "$ret" = "1" ]; then
        info "PASSWORD FROM '$user' USER IS CORRECT."
        return 0
    else
        error "PASSWORD FROM '$user' IS INCORRECT."
        return 1
    fi
}
add_password_history() {
    local user=$1
    local password=$2
    local history_file=$HOME/.pass_mariadb
    touch "$history_file"
    chmod 600 "$history_file"
    echo -e "$(date)\t$user\t$password" >> "$history_file"
}
# --- End of Utility Functions ---

_NAME="$(basename "$(readlink -f "$0")")"
NAME="${_NAME}"

lRC=0
DATADIR="/var/lib/mysql"
PASSWD_ROOT="$(pwgen -1 32)"
PASSWD_REPLI="$(pwgen -1 32)"
PASSWD_GALERA="$(pwgen -1 32)"

NODE_IP_LIST="172.20.1.101,172.20.1.102,172.20.1.103"
NODE_IP_LIST="192.168.56.100,192.168.56.102,192.168.56.101,192.168.56.103"
NODE_IP_LIST="192.168.56.191,192.168.56.192,192.168.56.193"

MYSQL_IP_FILTERS="192.168.%,172.21.%,172.20.%"

banner "BEGIN SCRIPT: ${_NAME}"

for MYSQL_IP_FILTER in $(echo $MYSQL_IP_FILTERS| tr ',' ' '); do
echo "SET PASSWORD FOR 'root'@'localhost' = PASSWORD('${PASSWD_ROOT}');
GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' WITH GRANT OPTION;

CREATE OR REPLACE USER 'root'@'$MYSQL_IP_FILTER' IDENTIFIED BY '${PASSWD_ROOT}';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'$MYSQL_IP_FILTER';

CREATE OR REPLACE USER 'galera'@'$MYSQL_IP_FILTER' IDENTIFIED BY '${PASSWD_GALERA}';
GRANT RELOAD, PROCESS, LOCK TABLES, REPLICATION CLIENT, SUPER, BINLOG MONITOR, REPLICA MONITOR ON *.* TO 'galera'@'$MYSQL_IP_FILTER';

CREATE OR REPLACE USER 'galera'@'localhost' IDENTIFIED BY '${PASSWD_GALERA}';
GRANT RELOAD, PROCESS, LOCK TABLES, REPLICATION CLIENT, SUPER, BINLOG MONITOR, REPLICA MONITOR ON *.* TO 'galera'@'localhost';

CREATE OR REPLACE USER 'replication'@'$MYSQL_IP_FILTER' IDENTIFIED BY '${PASSWD_REPLI}';
GRANT REPLICATION SLAVE ON *.* TO 'replication'@'$MYSQL_IP_FILTER';

CREATE OR REPLACE USER 'monitor'@'$MYSQL_IP_FILTER' IDENTIFIED BY 'monitor1234!';
GRANT USAGE, REPLICATION CLIENT ON *.* TO 'monitor'@'$MYSQL_IP_FILTER';
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

footer "END SCRIPT: ${_NAME}"

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
