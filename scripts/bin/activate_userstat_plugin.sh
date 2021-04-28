#!/bin/bash

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh

lRC=0
banner "BEGIN SCRIPT: $_NAME"

title2 "CREATE CONFIG FILE FOR USER STAT"
echo "[mariadb]
userstat = 1
" | tee /etc/my.cnf.d/96_userstat_plugin.cnf

title2 "INSTALLING USERSTAT PLUGIN"
mysql  -v -e "SET GLOBAL userstat=1;"
lRC=$(($lRC + $?))

mysql  -v -e "SHOW USER_STATISTICS\G"
mysql  -v -e "SHOW CLIENT_STATISTICS\G"
mysql  -v -e "SHOW INDEX_STATISTICS\G"
mysql  -v -e "SHOW TABLE_STATISTICS\G"

footer "END SCRIPT: $NAME"
exit $lRC