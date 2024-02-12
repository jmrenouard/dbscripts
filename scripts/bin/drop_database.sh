#!/bin/bash

DB=$1

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh

banner "DROP DATABASE: $DB"
mysql -v -e "DROP DATABASE IF EXISTS $DB;"
lRC=$?

if [ "$lRC" = "0" ]; then
	drop_user.sh ${DB}
	lRC=$(($lRC + $?))
	drop_user.sh ${DB}_rw
	lRC=$(($lRC + $?))
	drop_user.sh ${DB}_ro
	lRC=$(($lRC + $?))
fi

footer "DROP DATABASE: $DB"
exit $lRC
