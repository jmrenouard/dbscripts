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

banner "BEGIN SCRIPT: $_NAME"

title2 "CREATE CONFIG FILE FOR SQL ERROR"
echo "[mariadb]
plugin_load_add = sql_errlog
sql_error_log_filename=/var/log/mariadb/sql_error.log
#sql_error_log=ON
sql_error_log_rotate=1
sql_error_log_rotations=5
sql_error_log_size_limit=$((5 * 1024 * 1024))

" | tee /etc/my.cnf.d/95_sql_error_plugin.cnf

title2 "RESTARTING MARIADB SERVER"
cmd "systemctl restart mariadb"
lRC=$(($lRC + $?))

title2 "INSTALLING SQL ERROR PLUGIN"
mysql  -v -e "INSTALL SONAME 'sql_errlog';"
lRC=$(($lRC + $?))

footer "END SCRIPT: $NAME"
exit $lRC
