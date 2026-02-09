#!/bin/bash
set -euo pipefail

# --- Minimal Utility Functions ---
now() { echo "$(date "+%F %T %Z")($(hostname -s))"; }
info() { echo "$(now) INFO: $*" 1>&2; }
error() { echo "$(now) ERROR: $*" 1>&2; return 1; }
ok() { info "[SUCCESS] $* [SUCCESS]"; }
sep1() { echo "$(now) -----------------------------------------------------------------------------"; }
title1() { sep1; echo "$(now) $*"; sep1; }
cmd() {
    local tcmd="$1"
    local descr=${2:-"$tcmd"}
    title1 "RUNNING: $descr"
    set +e
    eval "$tcmd"
    local cRC=$?
    set -e
    if [ $cRC -eq 0 ]; then
        ok "$descr"
    else
        error "$descr (RC=$cRC)"
    fi
    return $cRC
}
banner() { title1 "START: $*"; info "run as $(whoami)@$(hostname -s)"; }
footer() {
    local lRC=${lRC:-"$?"}
    info "FINAL EXIT CODE: $lRC"
    [ $lRC -eq 0 ] && title1 "END: $* SUCCESSFUL" || title1 "END: $* FAILED"
    return $lRC
}
# --- End of Utility Functions ---

# Load optional external config for secrets/overrides
[ -f "/etc/bootstrap.conf" ] && source /etc/bootstrap.conf

USER="${1:-""}"
DB="${2:-'*'}"
TYPE="${3:-"ro"}"
PASSWD="${4:-"$(pwgen -1 32 2>/dev/null || echo "SecretPassword123!")"}"

TMP_FILE=$(mktemp)

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

cmd "cat $TMP_FILE" "DUMPING SQL COMMANDS"
cmd "cat $TMP_FILE | mysql -v" "EXECUTING SQL IN MYSQL"
lRC=$?

rm -f $TMP_FILE

# Optional: only if tool is available or inlined
# add_password_history $USER "${PASSWD}"
[ "$lRC" = "0" -a -n "$PASSWD" ] && title2 "PASSWORD IS: $PASSWD"
footer "CREATING USER $USER - DB: $DB - PROFILE: $TYPE"
exit $lRC
