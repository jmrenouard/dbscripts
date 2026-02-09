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

TYPE=$1
NAME=$2
STATE=$3
SRVNAME=${srv:-"proxysql"}
echo "$(date) $0 $*" >> /logs/scripts/ps_scripts.log

case $STATE in
        MASTER|BACKUP) 
		systemctl is-active $SRVNAME
		if [ $? -eq 0 ];then
			systemctl reload $SRVNAME
		else
			systemctl start $SRVNAME
		fi
                exit 0
                ;;
        FAULT|STOP) 
		#systemctl stop $SRVNAME
                  exit 0
                  ;;
        *)        echo "unknown state"
                  exit 1
                  ;;
esac
echo "Wrong STATE detected"
exit 127
