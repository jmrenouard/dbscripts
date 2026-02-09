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

setup_ubuntu_nfs_server()
{
    apt -y install nfs-kernel-server nfswatch nfstrace quota stunnel4
}

setup_ubuntu_nfs_client()
{
    apt -y install nfs-common stunnel4
}

setup_centos_nfs_client()
{
    yum -y install nfs-utils stunnel
}

push_cert_config()
{
    local target=$1
    rsync -avz /etc/stunnel/*.pem $target:/etc/stunnel
}

gen_stunnel_cert()
{
    cd /etc/stunnel/
     rm stunnel.crt stunnel.key stunnel.pem stunnel.csr

    openssl req -newkey rsa:4096 -x509 -days 3650 -nodes \
  -out stunnel.pem -keyout stunnel.pem
  chmod 400 stunnel.pem

}

gen_stunnel_server_conf()
{
    echo "verify  =       4
CAfile  =       /etc/stunnel/stunnel.pem
cert    =       /etc/stunnel/stunnel.pem
pid = /var/run/stunnel.pid
output = /var/log/stunnel4/stunnel.log

[nfs_over_stunnel]
accept = 0.0.0.0:2450
connect = 127.0.0.1:2049" > /etc/stunnel/stunnel.conf
chmod 644 /etc/stunnel/stunnel.conf
systemctl restart stunnel4
systemctl status stunnel4
systemctl enable stunnel4
}

gen_stunnel_client_conf()
{
    local srv=$1
    echo "verify  =       4
CAfile  =       /etc/stunnel/stunnel.pem
cert    =       /etc/stunnel/stunnel.pem
pid = /var/run/stunnel.pid
output = /var/log/stunnel4/stunnel.log
client = yes
[nfs_over_stunnel]
accept = 127.0.0.1:2049
connect = ${srv}:2450
" > /etc/stunnel/stunnel.conf
chmod 644 /etc/stunnel/stunnel.conf
systemctl restart stunnel4
systemctl status stunnel4
systemctl enable stunnel4
}