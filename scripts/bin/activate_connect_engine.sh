#!/bin/bash

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh

lRC=0
banner "BEGIN SCRIPT: $_NAME"

title2 "CREATE CONFIG FILE FOR CONNECT ENGINE"
echo "[mariadb]
plugin_load_add = ha_connect
" | tee /etc/my.cnf.d/98_connect_engine.cnf

title2 "RESTARTING MARIADB SERVER"
cmd "systemctl restart mariadb"
lRC=$(($lRC + $?))

title2 "INSTALLING CONNECT ENGINE"
mysql  -v -e "INSTALL SONAME 'ha_connect';"
lRC=$(($lRC + $?))

footer "END SCRIPT: $NAME"
exit $lRC