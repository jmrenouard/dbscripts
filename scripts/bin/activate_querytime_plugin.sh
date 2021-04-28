#!/bin/bash

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh

lRC=0
banner "BEGIN SCRIPT: $_NAME"

title2 "CREATE CONFIG FILE FOR QUERY RESPONSE TIME AUDIT"
echo "[mariadb]
plugin_load_add = query_response_time
query_response_time_stats=ON;
query_response_time=ON;
" | tee /etc/my.cnf.d/94_query_response_time_plugin.cnf

title2 "RESTARTING MARIADB SERVER"
cmd "systemctl restart mariadb"
lRC=$(($lRC + $?))

title2 "INSTALLING QUERY RESPONSE TIME PLUGIN"
mysql  -v -e "INSTALL SONAME 'query_response_time';"
lRC=$(($lRC + $?))

mysql  -v -e 'SELECT * FROM INFORMATION_SCHEMA.QUERY_RESPONSE_TIME;'
lRC=$(($lRC + $?))

footer "END SCRIPT: $NAME"
exit $lRC