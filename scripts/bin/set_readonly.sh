#!/bin/bash

val=${1:-"on"}
lRC=0

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh
banner "RESTARTING DATABASE WITH READ MODE TO $val"

echo "[mysqld]
read_only=$val
" | sudo tee /etc/my.cnf.d/100-readonly.cnf

# Rechargement
systemctl restart mariadb
lRC=$(($lRC + $?))

mysql -e "SHOW global variables like 'read_only';"
lRC=$(($lRC + $?))

mysql -e "SHOW global variables like 'read_only';" | grep -iq $val
lRC=$(($lRC + $?))

footer "RESTARTING DATABASE WITH READ MODE TO $val"
exit $lRC