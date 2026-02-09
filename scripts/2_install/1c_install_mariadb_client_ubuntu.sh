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
VERSION=${1:-"11.8"}

banner "BEGIN SCRIPT: ${_NAME}"


find /etc/apt/sources.list.d -type f -iname '*mariadb*.list' -exec rm -f {} \;

#if [ "$VERSION_CODENAME" = "groovy" ];then
cmd "apt-get install software-properties-common" "ADDING SOFTWARE PROPERTIES"
apt-key adv --fetch-keys 'https://mariadb.org/mariadb_release_signing_key.asc'
add-apt-repository -y "deb [arch=amd64,arm64,ppc64el] http://nyc2.mirrors.digitalocean.com/mariadb/repo/$VERSION/ubuntu $VERSION_CODENAME main"
##fi
cmd "apt -y update" "UPDATE PACKAGE LIST"
cmd "apt -y install python3 mariadb-client mylvmbackup sysbench mycli mariadb-backup socat telnet rsync tree nmap lsof netcat pigz git pwgen"
lRC=$(($lRC + $?))

footer "END SCRIPT: $NAME"
exit $lRC