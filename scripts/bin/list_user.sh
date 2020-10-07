#!/bin/sh

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh
banner "LISTING DB USERS"

title2 "LIST DISTINCT USER/HOST"
mysql -e "SELECT user, host from mysql.user"
lRC=$?

title2 "LIST DISTINCT USER"
 mysql -e 'select distinct(user) from mysql.user'
lRC=$(($lRC + $?))

title2 "LIST DATABASE"
mysql -e 'show databases'
lRC=$(($lRC + $?))

footer "LISTING DB USERS"
exit $lRC
