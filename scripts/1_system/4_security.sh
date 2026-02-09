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
MysqlOsUser=mysql
CONF_FILE=/etc/security/limits.d/99_mariadb.conf
banner "BEGIN SCRIPT: ${_NAME}"

title2 "CONFIGURATING SYSTEM LIMITS ..."

cmd "rm -f $CONF_FILE"

echo "# Nombre de fichiers
${MysqlOsUser} soft nofile 65536
${MysqlOsUser} hard nofile 65536
root soft nofile 65536
root hard nofile 65536

# Nombre de processus
${MysqlOsUser} soft nproc 65536
${MysqlOsUser} hard nproc 65536
root soft nproc 65536
root hard nproc 65536

# Taille des core dumps
* soft core 0
* hard core 0">>$CONF_FILE

cmd "cat $CONF_FILE"

footer "END SCRIPT: ${_NAME}"
exit $lRC