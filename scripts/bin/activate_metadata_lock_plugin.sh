#!/bin/bash

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh

lRC=0
banner "BEGIN SCRIPT: $_NAME"

title2 "CREATE CONFIG FILE FOR LOCK INFO"
echo "[mariadb]
plugin_load_add = metadata_lock_info
metadata_lock_info=FORCE_PLUS_PERMANENT
" | tee /etc/my.cnf.d/97_metadata_lock_plugin.cnf

title2 "RESTARTING MARIADB SERVER"
cmd "systemctl restart mariadb"
lRC=$(($lRC + $?))

title2 "INSTALLING LOCK INFO PLUGIN"
mysql  -v -e "INSTALL SONAME 'metadata_lock_info';"
lRC=$(($lRC + $?))

mysql  -v -e "SELECT * FROM information_schema.metadata_lock_info;"

footer "END SCRIPT: $NAME"
exit $lRC