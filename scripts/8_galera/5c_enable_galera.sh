#!/bin/bash

# --- Minimal Utility Functions ---
now() { echo "$(date "+%F %T %Z")($(hostname -s))"; }
info() { echo "$(now) INFO: $*" 1>&2; }
error() { echo "$(now) ERROR: $*" 1>&2; return 1; }
warn() {
    local lRC=$?
    echo "$(now) WARNING: $*" 1>&2
    return $lRC
}
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
my_private_ipv4=$(ip a | grep inet | grep 'brd' | grep -E '(192.168|172.2)'| cut -d/ -f1 | awk '{print $2}'|head -n1)


lRC=0
CONF_FILE="/etc/my.cnf.d/999_galera_settings.cnf"
[ -d "/etc/my.cnf.d/" ] && CONF_FILE="/etc/my.cnf.d/999_galera_settings.cnf"
[ -d "/etc/mysql/conf.d/" ] && CONF_FILE="/etc/mysql/conf.d/999_galera_settings.cnf"
[ -d "/etc/mysql/mariadb.conf.d/" ] && CONF_FILE="/etc/mysql/mariadb.conf.d/999_galera_settings.cnf"

[ -f "/etc/sysconfig/mariadbscript" ] && source /etc/sysconfig/mariadbscript

banner "BEGIN SCRIPT: ${_NAME}"

if [ -f "${CONF_FILE}.disabled" ]; then
	cmd "mv -f ${CONF_FILE}.disabled $CONF_FILE"
	cmd "systemctl restart mariadb"
else
	warn "${CONF_FILE}.disabled is MISSING"
fi

footer "END SCRIPT: ${_NAME}"
exit $lRC