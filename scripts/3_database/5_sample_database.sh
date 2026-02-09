#!/bin/bash

source /etc/os-release

# --- Minimal Utility Functions ---
now() { echo "$(date "+%F %T %Z")($(hostname -s))"; }
info() { echo "$(now) INFO: $*" 1>&2; }
error() { echo "$(now) ERROR: $*" 1>&2; return 1; }
ok() { info "[SUCCESS] $* [SUCCESS]"; }
sep1() { echo "$(now) -----------------------------------------------------------------------------"; }
title1() { sep1; echo "$(now) $*"; sep1; }
title2() { echo "$(now)  --- $* ---"; }
cmd() {
    local tcmd="$1"
    local descr=${2:-"$tcmd"}
    title1 "RUNNING: $descr"
    eval "$tcmd"
    local cRC=$?
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
db_tables() {
    local db="${1:-"mysql"}"
    mysql -Nrs -e "show tables" "$db"
}
db_count() {
    local db="${1:-"mysql"}"
    for tbl in $(db_tables "$db"); do
        echo -ne "$db\t$tbl\t"
        mysql -Nrs -e "select count(*) from $db.$tbl"
    done | sort -nr -k3 | column -t
}
# --- End of Utility Functions ---

_NAME="$(basename "$(readlink -f "$0")")"
NAME="${_NAME}"
lRC=0

#cmd "create_database.sh employees employees employees_rw employees_ro"
cmd "create_database.sh employees "


cd /opt/local
cmd "git clone https://github.com/datacharmer/test_db.git"

cd /opt/local/test_db

title2 "CREATE DATABASE employees"

bash /opt/local/bin/create_database.sh employees 

title2 "Inject DATABASE employees"
#mysql  < ./employees.sql

perl -ne '/DROP DATABASE/ or /CREATE DATABASE/ or /USE employees/ or print' ./employees.sql | mysql employees
cmd "db_tables employees"

cmd "db_count employees"

cmd "list_user.sh"

footer "END SCRIPT: ${_NAME}"

exit $lRC
