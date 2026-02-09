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

if [ "$ID" != "centos" -a "$VERSION_ID" = "7" ]; then
	cmd "iptables -L"
	cmd "/sbin/iptables --flush OUTPUT"
	cmd "/sbin/iptables --flush INPUT"

	info "Autoriser les clients MySQL/MariaDB"
	cmd "/sbin/iptables -A INPUT -p tcp --dport 3306 -j ACCEPT"
	cmd "/sbin/iptables -A OUTPUT -p tcp --dport 3306 -j ACCEPT"

	info "Autoriser la réplication Group replication"
	cmd "/sbin/iptables -A INPUT -p tcp --dport 33061 -j ACCEPT"
	cmd "/sbin/iptables -A OUTPUT -p tcp --dport 33061 -j ACCEPT"
  
	info "Autoriser la réplication WSREP"
	cmd "/sbin/iptables -A INPUT -p tcp --dport 4567 -j ACCEPT"
	cmd "/sbin/iptables -A INPUT -p udp --dport 4567 -j ACCEPT"
	cmd "/sbin/iptables -A OUTPUT -p tcp --dport 4567 -j ACCEPT"
	cmd "/sbin/iptables -A OUTPUT -p udp --dport 4567 -j ACCEPT"

	info"Autoriser la synchro. WSREP IST"
	cmd "/sbin/iptables -A INPUT -p tcp --dport 4568 -j ACCEPT"
	cmd "/sbin/iptables -A OUTPUT -p udp --dport 4568 -j ACCEPT"

	info"Autoriser la synchro. WSREP SST"
	cmd "/sbin/iptables -A INPUT -p tcp --dport 4444 -j ACCEPT"
	#cmd "/sbin/iptables -A OUTPUT -p udp --dport 4444 -j ACCEPT"

	info"Autoriser l'agent Zabbix"
	cmd "/sbin/iptables -A INPUT -p tcp --dport 10050 -j ACCEPT"
	cmd "/sbin/iptables -A OUTPUT -p udp --dport 10050 -j ACCEPT"

	info"Autoriser l'agent NRPE"
	cmd "/sbin/iptables -A INPUT -p tcp --dport 5666 -j ACCEPT"
	cmd "/sbin/iptables -A OUTPUT -p udp --dport 5666 -j ACCEPT"

	#
	cmd "/sbin/iptables -A INPUT -p tcp --dport 9200 -j ACCEPT"
	cmd "/sbin/iptables -A OUTPUT -p udp --dport 9200 -j ACCEPT"

	cmd "iptables -L"
else
	cmd "apt install -y firewalld python3-firewall"
	cmd "timeout 10 systemctl restart firewalld"
	cmd "timeout 10 systemctl enable firewalld"
	lRC=$(($lRC + $?))
	cmd "firewall-cmd --add-port=3306/tcp --permanent"
	lRC=$(($lRC + $?))
	cmd "firewall-cmd --add-port=4444/tcp --permanent"
	lRC=$(($lRC + $?))
	cmd "firewall-cmd --add-port=4567/tcp --permanent"
	lRC=$(($lRC + $?))
	cmd "firewall-cmd --add-port=4568/tcp --permanent"
	lRC=$(($lRC + $?))
	cmd "firewall-cmd --add-port=10050/tcp --permanent"
	lRC=$(($lRC + $?))
	cmd "firewall-cmd --add-port=5666/tcp --permanent"
	lRC=$(($lRC + $?))
	cmd "firewall-cmd --add-port=9200/tcp --permanent"
	lRC=$(($lRC + $?))
	cmd "firewall-cmd --reload"
	cmd "firewall-cmd --list-all"
fi

footer "END SCRIPT: ${_NAME}"
exit $lRC
