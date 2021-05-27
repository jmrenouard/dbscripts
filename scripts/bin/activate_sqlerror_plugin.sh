#!/bin/bash

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh

lRC=0
banner "BEGIN SCRIPT: $_NAME"

title2 "CREATE CONFIG FILE FOR SQL ERROR"
echo "[mariadb]
plugin_load_add = sql_errlog
sql_error_log=ON
sql_error_log_rotate=1
sql_error_log_rotations=5
sql_error_log_size_limit=$((5 * 1024 * 1024))

" | tee /etc/my.cnf.d/95_sql_error_plugin.cnf

title2 "RESTARTING MARIADB SERVER"
cmd "systemctl restart mariadb"
lRC=$(($lRC + $?))

title2 "INSTALLING SQL ERROR PLUGIN"
mysql  -v -e "INSTALL SONAME 'sql_errlog';"
lRC=$(($lRC + $?))

footer "END SCRIPT: $NAME"
exit $lRC