#!/bin/sh

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh

lRC=0
CONF_FILE="/etc/my.cnf.d/999_galera_settings.cnf"

[ -f "/etc/bootstrap.conf" ] && source /etc/bootstrap.conf

banner "BEGIN SCRIPT: $_NAME"

cmd "mv $CONF_FILE ${CONF_FILE}.disabled"

cmd "systemctl restart mariadb"

footer "END SCRIPT: $NAME"
exit $lRC