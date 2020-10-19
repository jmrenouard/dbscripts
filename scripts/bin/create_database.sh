#!/bin/sh

DB=$1
PASSWD_OWNER="${2:-"$(pwgen -1 18)"}"
PASSWD_RW="${3:-"$(pwgen -1 18)"}"
PASSWD_RO="${4:-"$(pwgen -1 18)"}"

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh

banner "CREATING DATABASE: $DB"
mysql -v -e "CREATE DATABASE IF NOT EXISTS $DB;"
lRC=$?

if [ "$lRC" = "0" ]; then
	create_user.sh ${DB} ${DB} owner ${PASSWD_OWNER}
	lRC=$(($lRC + $?))
	create_user.sh ${DB}_rw ${DB} rw ${PASSWD_RW}
	lRC=$(($lRC + $?))
	create_user.sh ${DB}_ro ${DB} ro ${PASSWD_RO}
	lRC=$(($lRC + $?))
fi

title2 "USER ${DB} PASSWORD: $PASSWD_OWNER"
title2 "USER ${DB}_rw PASSWORD: $PASSWD_RW"
title2 "USER ${DB}_ro PASSWORD: $PASSWD_RO"
footer "CREATING DATABASE: $DB"
exit $lRC
