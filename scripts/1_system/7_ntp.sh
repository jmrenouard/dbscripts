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
TIMEZONE="GMT"
TIMEZONE="Europe/Paris"
banner "BEGIN SCRIPT: ${_NAME}"

if [ "$ID" != "ubuntu" ];then
	if [ "$VERSION_ID" = "7" ]; then
		# Centos 7 / Red Hat 7
		cmd "yum -y install ntpdate"
		cmd "ntpdate -vqd fr.pool.ntp.org"
	else
		# Centos 8 / Red Hat 8
		cmd "yum -y install ntpstat chrony"
		lRC=$(($lRC + $?))
		
	fi
	cmd "systemctl restart chronyd"
	lRC=$(($lRC + $?))
	sleep 3s
else
		# Ubuntu / Debian
		cmd "apt -y install ntpstat ntp"
		lRC=$(($lRC + $?))
		
		cmd "systemctl enable ntp"
		lRC=$(($lRC + $?))
		
		cmd "systemctl restart ntp"
		lRC=$(($lRC + $?))
		sleep 3s	
fi
cmd "timedatectl set-timezone $TIMEZONE"
lRC=$(($lRC + $?))

cmd "timedatectl status"

cmd "date"

if [ "$VERSION_ID" = "8" ]; then
	cmd "chronyc sources"
else 
	cmd "ntpq -p"
fi

sleep 3s
cmd "ntpstat"
# Attente de résolution :)
# sleep 3s
#ntpstat
#lRC=$(($lRC + $?))

footer "END SCRIPT: ${_NAME}"
exit $lRC