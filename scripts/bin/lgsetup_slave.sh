#!/bin/sh

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh

lRC=$?
banner "SETUP SLAVE HOST WITH MYSQLDUMP"
master=$1
if [ -z "$master" ]; then
	error "Please give a master host"
	exit 127
fi

master_pivate_ipv4=$(ssh -q $master  'echo $my_private_ipv4')
ruser=${2:-"replication"}
pass=$3
[ -z "$pass" ] && pass=$(ssh -q $master_pivate_ipv4 "check_user_passwords.sh"|  grep $ruser| awk '{print $3}')

title2 "REMOVING GALERA MARIADB SERVER CONFIG"
if [ -f "/etc/my.cnf.d/999_galera_settings.cnf" ]; then
	mv /etc/my.cnf.d/999_galera_settings.cnf /etc/my.cnf.d/999_galera_settings.cnf.disabled
fi

title2 "ADDING REPLICATION CONFIG"
echo "[mariadb]
log_slave_updates=1
read_only=on" | tee /etc/my.cnf.d/100-replication_config.cnf

echo "-- stop slave;
STOP SLAVE;

-- RESET  slave
RESET SLAVE;

-- setup slave
CHANGE MASTER TO
MASTER_HOST='$master_pivate_ipv4',
MASTER_USER='$ruser',
MASTER_PASSWORD='$pass',
MASTER_PORT=3306;

STOP SLAVE;"  | mysql -v

title2 "SYNCHRONIZING LOGICAL DATA FROM $master"
cd $datadir
BACKUP_CMD="mysqldump --all-databases --master-data=1 --flush-logs --add-drop-database --routines --skip-opt --triggers --events --add-drop-table --add-locks --create-options --disable-keys --extended-insert --quick --set-charset --single-transaction"

if [ "$COMPRESS" = "1" ]; then
	ssh -q $master_pivate_ipv4 "$BACKUP_CMD | pigz" | pigz -cd | mysql -f
else
	ssh -q $master_pivate_ipv4 "$BACKUP_CMD" | mysql -f
fi

title2 "STARTING REPLICATION"
# ...
echo "-- Start slave
START SLAVE;
" |mysql -v

title2 "RESTARTING MARIADB SERVER"
systemctl restart mariadb

sleep 1s

get_replication_status

footer "SETUP SLAVE HOST WITH MYSQLDUMP"