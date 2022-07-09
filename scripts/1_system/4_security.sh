#!/bin/bash

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh

lRC=0
MysqlOsUser=mysql
CONF_FILE=/etc/security/limits.d/99_mariadb.conf
banner "BEGIN SCRIPT: $_NAME"

title2 "CONFIGURATING SYSTEM LIMITS ..."

cmd "rm -f $CONF_FILE"

echo "# Nombre de fichiers
${MysqlOsUser} soft nofile 65536
${MysqlOsUser} hard nofile 65536
root soft nofile 65536
root hard nofile 65536

# Nombre de processus
${MysqlOsUser} soft nproc 65536
${MysqlOsUser} hard nproc 65536
root soft nproc 65536
root hard nproc 65536

# Taille des core dumps
* soft core 0
* hard core 0">>$CONF_FILE

cmd "cat $CONF_FILE"

footer "END SCRIPT: $_NAME"
exit $lRC