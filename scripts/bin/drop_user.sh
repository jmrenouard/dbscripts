#!/bin/sh

USER=${1:-""}
TMP_FILE=$(mktemp)

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh
banner "DROPPING USER $USER - DB: $DB - PROFILE: $TYPE"

echo "-- DELETE USER SQL COMMAND
DROP USER IF EXISTS '$USER'@'192.168.%';
DROP USER IF EXISTS '$USER'@'10.%';
DROP USER IF EXISTS '$USER'@'localhost';" > $TMP_FILE

cmd "cat $TMP_FILE"

cat $TMP_FILE | mysql -v
lRC=$?

rm -f $TMP_FILE

footer "DROP USER $USER - DB: $DB - PROFILE: $TYPE"
exit $lRC
