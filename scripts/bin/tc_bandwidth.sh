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

inter=${1:-"eth1"}
bw=${2:-"1kbps"}
durs=${3:-"200"}

if [ "$1" = "install" ]; then
	yum -y install iproute-tc kernel-modules-extra
	exit $?
fi

( 
	set -x
	tc qdisc add dev ${inter} handle 1: root htb default 11
    tc class add dev ${inter} parent 1: classid 1:1 htb rate ${bw}
	tc class add dev ${inter} parent 1:1 classid 1:11 htb rate ${bw}

	sleep ${durs}s; 
	tc qdisc del dev ${inter} root
) &
