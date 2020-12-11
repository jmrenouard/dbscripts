#!/bin/sh

master=$1
ruser=${2:-"replication"}
pass=$3
[ -z "$pass" ] && pass=$(ssh -q $master "check_user_passwords.sh"|  grep $ruser| awk '{print $3}')

datadir=/var/lib/mysql

systemctl stop mariadb

rm -rf $datadir/*

cd $datadir
ssh -q $master "mariabackup --user=root --backup --stream=mbstream" | mbstream -v -x

ls -ls
rfile=$(awk '{print $1}' xtrabackup_binlog_info) 
posrfile=$(awk '{print $2}' xtrabackup_binlog_info) 
systemctl start mariadb
# ...
mysql -e  "CHANGE MASTER TO MASTER_HOST='$master', MASTER_USER='$ruser', MASTER_PORT=3306, MASTER_LOG_FILE='$rfile', MASTER_LOG_POS=$posrfile"

mysql -e 'start slave;'

sleep 1s

mysql -e 'SHOW SLAVE STATUS;' | grep -Ei '(_Running|Err|Behind)'
