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

USER=$1
PASSWD="${2:-"$(pwgen -1 18)"}"

TMP_FILE=$(mktemp)

banner "CHANGING DB USER: $USER"

for hst in $(mysql -Nrs -e "SELECT host from mysql.user WHERE user='$USER'"); do
	mysql -v -e "SET PASSWORD FOR '$USER'@'$hst' = PASSWORD('$PASSWD');"
	[ $? -eq 0 ] && add_password_history $USER  $PASSWD
done
lRC=$?

rm -f $TMP_FILE

title2 "USER $USER PASSWORD: $PASSWD"
footer "CHANGING DB USER: $USER"
exit $lRC
