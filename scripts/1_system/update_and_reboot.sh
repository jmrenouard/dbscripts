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

banner "BEGIN SCRIPT: ${_NAME}"
lRC=0


SRV=$1
CYCLE=${2:-"10"}
SSH_CMD="ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${SRV}"

rm -f /tmp/save_my.cnf
cp -p /etc/mysql/my.cnf /tmp/save_my.cnf
$SSH_CMD "apt -y update"
$SSH_CMD "apt -y upgrade"

diff /etc/mysql/my.cnf /tmp/save_my.cnf
if [ $? -ne 0 ];then
	mv /etc/mysql/my.cnf /etc/mysql/my.cnf.sav
	cp -p /tmp/save_my.cnf /etc/mysql/my.cnf
fi

$SSH_CMD "reboot" & 

sleep 5s
i=0

while [ $i -lt $CYCLE ]; do
	$SSH_CMD -q exit 
	if [ $? -eq 0 ]; then
footer "END SCRIPT: ${_NAME}"
exit $lRC



#SRV_LST="galera1
#galera1
#galera1"

#for srv in $SRV_LST; do
#	bash -x update_and_reboot.sh $srv 
#	sleep 20s
#done