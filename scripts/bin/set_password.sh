#!/bin/sh

USER=$1
PASSWD="${2:-"$(pwgen -1 18)"}"

TMP_FILE=$(mktemp)

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh

banner "CHANGING DB USER: $USER"

for hst in $(mysql -Nrs -e "SELECT host from mysql.user WHERE user='$USER'"); do
	mysql -v -e "SET PASSWORD FOR '$USER'@'$hst' = PASSWORD('$PASSWD');"
done
lRC=$?

rm -f $TMP_FILE

title2 "USER $USER PASSWORD: $PASSWD"
footer "CHANGING DB USER: $USER"
exit $lRC
