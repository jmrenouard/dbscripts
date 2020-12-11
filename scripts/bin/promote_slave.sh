#!/bin/sh

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh

lRC=$?
banner "PROMOTE SLAVE"

rm -f /etc/my.cnf.d/100-replication_config.cnf

title2 "STOPPING MARIADB SERVER"
systemctl restart mariadb

title2 "PROMOTING SLAVE"
echo "SET GLOBAL read_only=OFF;
SET GLOBAL log_slave_updates=OFF;
-- stop slave;
STOP SLAVE;
-- RESET  slave
RESET SLAVE;" |mysql -v

title2 "REPLICATION STATUS:"
mysql -e 'SHOW SLAVE STATUS\G' | grep -Ei '(_Running|Err|Behind)'
mysql -e "select @@read_only"
mysql -e "select @@log_slave_updates"

footer "PROMOTE SLAVE"