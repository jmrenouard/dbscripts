#!/bin/bash

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh
[ -f '/etc/profile.d/utils.mysql.sh' ] && source /etc/profile.d/utils.mysql.sh
[ -f "$(pwd)/utils.sh" ] && source "$(pwd)/utils.sh"

lRC=0
TMP_SCRIPT=$(mktemp)
DATADIR="/var/lib/mysql"

banner "BEGIN SCRIPT: $_NAME"

echo "DROP DATABASE IF EXISTS test;
DELETE FROM mysql.user where user ='';
FLUSH PRIVILEGES;"| mysql -uroot
rm -f $TMP_SCRIPT

title1 "DATABASE LIST"
echo "show databases;"| mysql -uroot -Nrs| column -t

title1 "USER LIST"
echo "select user, host from mysql.user;"| mysql -uroot -Nrs| column -t

footer "END SCRIPT: $NAME"
exit $lRC