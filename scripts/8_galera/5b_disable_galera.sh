#!/bin/bash

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh
[ -f "$(pwd)/utils.sh" ] && source "$(pwd)/utils.sh"


lRC=0
CONF_FILE="/etc/my.cnf.d/999_galera_settings.cnf"
[ -d "/etc/my.cnf.d/" ] && CONF_FILE="/etc/my.cnf.d/999_galera_settings.cnf"
[ -d "/etc/mysql/conf.d/" ] && CONF_FILE="/etc/mysql/conf.d/999_galera_settings.cnf"
[ -d "/etc/mysql/mariadb.conf.d/" ] && CONF_FILE="/etc/mysql/mariadb.conf.d/999_galera_settings.cnf"

[ -f "/etc/sysconfig/mariadbscript" ] && source /etc/sysconfig/mariadbscript

banner "BEGIN SCRIPT: $_NAME"

if [ -f "$CONF_FILE" ]; then
	cmd "mv -f $CONF_FILE ${CONF_FILE}.disabled"
	cmd "systemctl restart mariadb"
else
	warn "$CONF_FILE is MISSING"
fi

footer "END SCRIPT: $NAME"
exit $lRC