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
my_private_ipv4=$(ip a | grep inet | grep 'brd' | grep -E '(192.168|172.2)'| cut -d/ -f1 | awk '{print $2}'|head -n1)

lRC=0

banner "BEGIN SCRIPT: ${_NAME}"

https://github.com/sysown/proxysql/releases/download/v2.1.1/proxysql_2.1.1-ubuntu20_arm64.deb

if [ "$ID" = "ubuntu" ]; then
        cmd "apt -y install https://github.com/sysown/proxysql/releases/download/v2.1.1/proxysql_2.1.1-ubuntu20_arm64.deb"
else 
        cmd "yum -y install https://github.com/sysown/proxysql/releases/download/v2.1.1/proxysql-2.1.1-1-centos8.x86_64.rpm"
fi

cmd "systemctl enable haproxy"
cmd "systemctl restart haproxy"

firewall-cmd --add-port=6033/tcp --permanent
firewall-cmd --add-port=6032/tcp --permanent
firewall-cmd --add-port=6080/tcp --permanent
firewall-cmd --reload

footer "END SCRIPT: ${_NAME}"
exit $lRC