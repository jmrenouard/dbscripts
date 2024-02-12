#!/bin/bash

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh

lRC=0
banner "BEGIN SCRIPT: $_NAME"

title2 "CREATE CONFIG FILE FOR CRACKLIB PASSOWRD"
cmd "yum -y install MariaDB-cracklib-password-check cracklib cracklib-dicts"

echo "[mariadb]
plugin-load-add=cracklib_password_check
[mariadb]
plugin_load_add = server_audit
cracklib_password_check=FORCE_PLUS_PERMANENT

" | tee /etc/my.cnf.d/93_cracklib_password_plugin.cnf

title2 "RESTARTING MARIADB SERVER"
cmd "systemctl restart mariadb"
lRC=$(($lRC + $?))

title2 "INSTALLING CRACKLIB PASSWORD PLUGIN"
mysql  -v -e "INSTALL SONAME 'cracklib_password_check';"
lRC=$(($lRC + $?))

footer "END SCRIPT: $NAME"
exit $lRC