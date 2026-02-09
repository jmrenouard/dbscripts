#!/bin/bash

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
my_private_ipv4=$(ip a | grep inet | grep 'brd' | grep -E '(192.168|172.2)'| cut -d/ -f1 | awk '{print $2}'|head -n1)
source /etc/os-release

lRC=0
VERSION=${1:-"13"}

##title_en: Centos MariaDB 10.5 server installation
##title_fr: Installation du serveur MariaDB 10.5 sur OS Centos  
##goals_en: Package software installation for MariaDB / Related tools installation / Last security packages installation
##goals_fr: Installation des packages logiciels pour MariaDB / Installation des logiciels tiers relatif aux bases de données / Installation des dernières versions logicielles
force=0
banner "BEGIN SCRIPT: ${_NAME}"


cmd  "dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-${VERSION_ID}.noarch.rpm"
lRC=$(($lRC + $?))

# Install the repository RPM:
cmd  "dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-${VERSION_ID}-x86_64/pgdg-redhat-repo-latest.noarch.rpm"
lRC=$(($lRC + $?))

# Disable the built-in PostgreSQL module:
cmd "dnf -qy module disable postgresql"
lRC=$(($lRC + $?))
# Install PostgreSQL:
cmd  "dnf install -y postgresql${VERSION} postgresql${VERSION}-server postgresql${VERSION}-contrib"
lRC=$(($lRC + $?))


cmd "dnf -y install python3 pgbackrest pgbadger htop nrpe nagios-plugins-nrpe nagios-plugins-all telnet"
lRC=$(($lRC + $?))

cmd "dnf -y install cracklib cracklib-dicts tree socat sysbench jemalloc rsync nmap lsof perl-DBI nc  pigz perl-DBD-MySQL git pwgen"
lRC=$(($lRC + $?))


footer "END SCRIPT: ${_NAME}"
exit $lRC