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

ZabbixServer=10.0.135.43
banner "BEGIN SCRIPT: ${_NAME}"

cmd "rpm -Uvh https://repo.zabbix.com/zabbix/6.0/rhel/7/x86_64/zabbix-release-6.0-2.el7.noarch.rpm"
cmd "yum clean all"

cmd "yum -y install zabbix-agent2"

#perl -i -pe "s/^Server=(.+)$/Server=$ZabbixServer/;s/^ServerActive=/#ServerActive=/" /etc/zabbix/zabbix_agentd.conf
cmd "systemctl stop zabbix-agent"
cmd "systemctl disable zabbix-agent"

perl -i -pe "s/^Server=(.+)$/Server=$ZabbixServer/;s/^ServerActive=/#ServerActive=/" /etc/zabbix/zabbix_agent2.conf
cmd "systemctl restart zabbix-agent"
cmd "systemctl enable zabbix-agent"

cmd "systemctl restart zabbix-agent2"
cmd "systemctl enable zabbix-agent2"

#tail -n 30 /var/log/zabbix/zabbix_agentd.log

footer "END SCRIPT: ${_NAME}"
exit $lRC