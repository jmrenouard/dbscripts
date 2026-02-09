#!/bin/bash
set -euo pipefail

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
    set +e
    eval "$tcmd"
    local cRC=$?
    set -e
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
# --- End of Utility Functions ---

lRC=$?
banner "SETUP SLAVE HOST WITH MARIABACKUP"
master=$1
if [ -z "$master" ]; then
	error "Please give a master host"
	exit 127
fi

master_pivate_ipv4=$(ssh -q $master  'echo $my_private_ipv4')
ruser=${2:-"replication"}
pass=$3
[ -z "$pass" ] && pass=$(ssh -q $master_pivate_ipv4 "check_user_passwords.sh"|  grep $ruser| awk '{print $3}')

title2 "STOPPING MARIADB SERVER"
systemctl stop mariadb
datadir=/var/lib/mysql

title2 "REMOVING GALERA MARIADB SERVER CONFIG"
if [ -f "/etc/my.cnf.d/999_galera_settings.cnf" ]; then
	mv /etc/my.cnf.d/999_galera_settings.cnf /etc/my.cnf.d/999_galera_settings.cnf.disabled
fi

title2 "REMOVING DATADIR"
rm -rf $datadir/*

title2 "SYNCHRONIZING DATADIR FROM $master"
cd $datadir
if [ "$COMPRESS" = "1" ]; then
	ssh -q $master_pivate_ipv4 "mariabackup --user=root --backup --stream=mbstream | pigz" | pigz -cd | mbstream -v -x
else
	ssh -q $master_pivate_ipv4 "mariabackup --user=root --backup --stream=mbstream" | mbstream -v -x
fi

chown -R mysql.mysql $datadir
ls -ls

rfile=$(awk '{print $1}' xtrabackup_binlog_info)
posrfile=$(awk '{print $2}' xtrabackup_binlog_info)
rgtid=$(awk '{print $3}' xtrabackup_binlog_info)
title2 "RETRIEVING REPLICATION POSITION $rfile($posrfile)"
title2 "ADDING REPLICATION CONFIG"

echo "[mariadb]
log_slave_updates=1
read_only=on" | tee /etc/my.cnf.d/100-replication_config.cnf

title2 "STARTING MARIADB SERVER"
systemctl start mariadb

title2 "SETUP SQL REPLICATION WITH START SLAVE AND CHANGE MASTER TO"

# ...
echo "-- stop slave;
STOP SLAVE;

-- RESET  slave
RESET SLAVE;

SET GLOBAL gtid_slave_pos='$rgtid'; 
-- setup slave
CHANGE MASTER TO
MASTER_HOST='$master_pivate_ipv4',
MASTER_USER='$ruser',
MASTER_PASSWORD='$pass',
MASTER_PORT=3306,
MASTER_LOG_FILE='$rfile',
MASTER_LOG_POS=$posrfile,
MASTER_USE_GTID = slave_pos;

-- Start slave
START SLAVE;
" |mysql -v

sleep 1s

get_replication_status

footer "SETUP SLAVE HOST WITH MARIABACKUP"
