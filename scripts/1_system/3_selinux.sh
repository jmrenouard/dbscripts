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
banner "BEGIN SCRIPT: ${_NAME}"

PCKMANAGER="yum"
[ "$ID" = "ubuntu" -o "$ID" = "debian" ] && PCKMANAGER="apt"

cmd "$PCKMANAGER install -y policycoreutils selinux-utils selinux-basics" "INSTALL SELINUX for $ID"

cmd "setenforce 0" "SELINUX IN PERMISSIVE MODE"
#lRC=$(($lRC + $?))

if [ -f "/etc/sysconfig/selinux" ]; then
	cmd "cat /etc/sysconfig/selinux" "CONTENT OF /etc/sysconfig/selinux"
	title1 "REMOVING ENFORCING mode FROM /etc/sysconfig/selinux"
	perl -i -pe 's/(SELINUX=).*/$1PERMISSIVE/g' /etc/sysconfig/selinux
	grep -q "SELINUX=PERMISSIVE" /etc/sysconfig/selinux
	lRC=$(($lRC + $?))
fi
cmd "cat /etc/selinux/config" "CONTENT OF /etc/selinux/config"
title1 "REMOVING ENFORCING mode FROM /etc/selinux/config"
perl -i -pe 's/(SELINUX=).*/$1PERMISSIVE/g' /etc/selinux/config
grep -q "SELINUX=PERMISSIVE" /etc/selinux/config
lRC=$(($lRC + $?))

cmd "sestatus"

footer "END SCRIPT: ${_NAME}"
exit $lRC