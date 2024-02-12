#!/bin/bash

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh

lRC=0
banner "BEGIN SCRIPT: $_NAME"

title2 "CREATE CONFIG FILE FOR SIMPLE PASSWORD"
echo "[mariadb]
plugin_load_add = simple_password_check

simple_password_check_digits=1
simple_password_check_letters_same_case=1
simple_password_check_minimal_length   = 18
simple_password_check_other_characters  = 0
" | tee /etc/my.cnf.d/92_simple_password_check_plugin.cnf

title2 "RESTARTING MARIADB SERVER"
cmd "systemctl restart mariadb"
lRC=$(($lRC + $?))

title2 "INSTALLING SIMPLE PASSWORD PLUGIN"
mysql  -v -e "INSTALL SONAME 'simple_password_check';"
lRC=$(($lRC + $?))

footer "END SCRIPT: $NAME"
exit $lRC