#!/bin/bash

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh

lRC=0
CONF_FILE="/etc/my.cnf.d/999_galera_settings.cnf"

[ -f "/etc/sysconfig/mariadbscript" ] && source /etc/sysconfig/mariadbscript

banner "BEGIN SCRIPT: $_NAME"

if [ -f "${CONF_FILE}.disabled" ]; then
	cmd "mv -f ${CONF_FILE}.disabled $CONF_FILE"
	cmd "systemctl restart mariadb"
else
	warn "${CONF_FILE}.disabled is MISSING"
fi

footer "END SCRIPT: $NAME"
exit $lRC