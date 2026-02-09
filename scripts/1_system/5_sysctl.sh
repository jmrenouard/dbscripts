#!/bin/bash

source /etc/os-release

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
# --- End of Utility Functions ---

_NAME="$(basename "$(readlink -f "$0")")"
NAME="${_NAME}"
lRC=0
CONF_FILE=/etc/sysctl.d/99-mariadb.conf

banner "BEGIN SCRIPT: ${_NAME}"

info "RELOADING SYSCTL CONFIGURATION ..."

#sunrpc.tcp_slot_table_entries = 128
echo "fs.aio-max-nr=1048576
fs.nr_open=1048576
vm.swappiness=10
net.ipv4.tcp_keepalive_time=120
net.ipv4.tcp_keepalive_probes=4
net.ipv4.tcp_keepalive_intvl=20
" > $CONF_FILE

cmd "cat $CONF_FILE"

cmd "sysctl -q -p"

cmd "sysctl -p $CONF_FILE"

sysctl -a| grep -E '(swapi|aio-max-nr)'

footer "END SCRIPT: ${_NAME}"
exit $lRC