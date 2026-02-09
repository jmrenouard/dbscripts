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

if [ "$ID" = "ubuntu" ]; then
	cmd "apt install -y policycoreutils selinux-utils selinux-basics" "INSTALL SELINUX for $ID"
else
	cmd "yum -y install policycoreutils-python  libsemanage-python" "INSTALL SELINUX UTILITIES for $ID"
fi
cmd "setenforce 1" "SELINUX IN ENFORCING MODE"
#lRC=$(($lRC + $?))

if [ -f "/etc/sysconfig/selinux" ]; then  
	cmd "cat /etc/sysconfig/selinux" "CONTENT OF /etc/sysconfig/selinux"
	title1 "REMOVING PERMISSIVE mode FROM /etc/sysconfig/selinux"
	perl -i -pe 's/(SELINUX=).*/$1ENFORCING/g' /etc/sysconfig/selinux
	grep -q "SELINUX=ENFORCING" /etc/sysconfig/selinux
	lRC=$(($lRC + $?))
fi

title1 "REMOVING PERMISSIVE mode FROM /etc/selinux/config"
perl -i -pe 's/(SELINUX=).*/$1ENFORCING/g' /etc/selinux/config
grep -q "SELINUX=ENFORCING" /etc/selinux/config
lRC=$(($lRC + $?))

cmd "sestatus"

info "CMD: semanage boolean -l| grep mysql"
semanage boolean -l| grep mysql

# PAsser en permissive uniquement les règles MYSQL
#cmd "semanage permissive -a mysqld_t"
cmd "semanage port -m -t mysqld_port_t -p tcp 4444"
cmd "semanage port -m -t mysqld_port_t -p tcp 4567"
cmd "semanage port -a -t mysqld_port_t -p tcp 4568"
semanage port -l| grep mysql

cmd 'semanage fcontext -a -t mysqld_db_t "/data(/.*)?"'
cmd "restorecon -Rv /data"
info "CMD: semanage boolean -l| grep mysql"
semanage fcontext -l| grep mysql

title2 "Trace SE Linux MariaDB"
grep -i mysql /var/log/audit/audit.log

footer "END SCRIPT: ${_NAME}"
exit $lRC