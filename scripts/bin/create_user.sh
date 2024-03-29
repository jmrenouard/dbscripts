#!/bin/bash

USER=${1:-""}
DB=${2:-'*'}
TYPE=${3:-"ro"}
PASSWD="${4:-"$(pwgen -1 32)"}"

TMP_FILE=$(mktemp)

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh
[ -f '/etc/profile.d/utils.mysql.sh' ] && source /etc/profile.d/utils.mysql.sh

banner "CREATING USER $USER - DB: $DB - PROFILE: $TYPE"

echo "-- CREATE USER SQL COMMANDS
CREATE OR REPLACE USER '$USER'@'192.168.%' IDENTIFIED BY '$PASSWD';
-- CREATE OR REPLACE USER '$USER'@'10.%' IDENTIFIED BY '$PASSWD';
CREATE OR REPLACE USER '$USER'@'localhost' IDENTIFIED BY '$PASSWD';" >> $TMP_FILE

case $TYPE in
	ro|RO|READONLY|readonly)
		echo "-- GRANTS FOR READONLY PRIVILEGES
GRANT USAGE, SELECT, CREATE TEMPORARY TABLES ON $DB.* TO '$USER'@'192.168.%';
-- GRANT USAGE, SELECT, CREATE TEMPORARY TABLES ON $DB.* TO '$USER'@'10.%';
GRANT USAGE, SELECT, CREATE TEMPORARY TABLES ON $DB.* TO '$USER'@'localhost';"  >> $TMP_FILE
		;;
	rw|RW|WRITE|write|readwrite)
		echo "-- GRANTS FOR READ/WRITE PRIVILEGES
GRANT SELECT, USAGE, UPDATE, DELETE, INSERT, CREATE TEMPORARY TABLES ON $DB.* TO '$USER'@'192.168.%';
-- GRANT SELECT, USAGE, UPDATE, DELETE, INSERT, CREATE TEMPORARY TABLES ON $DB.* TO '$USER'@'10.%';
GRANT SELECT, USAGE, UPDATE, DELETE, INSERT, CREATE TEMPORARY TABLES ON $DB.* TO '$USER'@'localhost';" >> $TMP_FILE
		;;
	OWNER|owner)
		echo "-- GRANTS FOR ALL PRIVILEGES
GRANT ALL ON $DB.* TO '$USER'@'192.168.%';
-- GRANT ALL ON $DB.* TO '$USER'@'10.%';
GRANT ALL ON $DB.* TO '$USER'@'localhost';" >> $TMP_FILE
		;;
	DROP|drop|RM|rm|del|DEL)
		echo "-- DELETE USER SQL COMMAND
DROP USER IF EXISTS '$USER'@'192.168.%';
DROP USER IF EXISTS '$USER'@'10.%';
DROP USER IF EXISTS '$USER'@'localhost';" > $TMP_FILE
#PASSWD=""
		;;
	*)
		error "CREATING USER $USER - DB: $DB - PROFILE: $TYPE"
		exit 127
		;;
esac

cmd "cat $TMP_FILE"
cat $TMP_FILE | mysql -v
lRC=$?

rm -f $TMP_FILE

add_password_history $USER "${PASSWD}"
[ "$lRC" = "0" -a -n "$PASSWD" ] && title2 "PASSWORD IS: $PASSWD"
footer "CREATING USER $USER - DB: $DB - PROFILE: $TYPE"
exit $lRC
