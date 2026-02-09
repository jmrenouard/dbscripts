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

banner "GALERA BOOTSTRAP POST-REBOOT"

cmd "systemctl stop mariadb" "STOPPING MARIADB"
cmd "perl -i -pe 's/(safe_to_bootstrap): 0/\$1: 1/g' /var/lib/mysql/grastate.dat" "SETTING SAFE_TO_BOOTSTRAP=1"

info "Identifying recovery position..."
GPOS=$(galera_recovery 2>/dev/null | tail -n 1 || echo "")

if [ -z "$GPOS" ]; then
    info "Could not determine recovery position, starting base cluster."
    cmd "systemctl set-environment _WSREP_NEW_CLUSTER='--wsrep-new-cluster'" "SETTING CLUSTER ENVIRONMENT"
else
    cmd "systemctl set-environment _WSREP_NEW_CLUSTER=\"--wsrep-new-cluster --wsrep-start-position='$GPOS'\"" "SETTING CLUSTER ENVIRONMENT WITH POSITION"
fi

cmd "systemctl restart mariadb" "RESTARTING MARIADB"

footer "BOOTSTRAP AFTER REBOOT COMPLETE"