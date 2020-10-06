#!/bin/bash

val=${1:-"on"}

echo "[mysqld]
read_only=$val
" | sudo tee /etc/mysql/mariadb.conf.d/11-readonly.cnf

# Rechargement
sudo systemctl restart mysqld

mysql -e "SHOW global variables like 'read_only';"

#mysql -e "SHOW global variables like 'read_only';" | grep -iq $val
