#!/bin/sh

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh

lRC=0
banner "BEGIN SCRIPT: $_NAME"

cmd "iptables -L"

cmd "firewall-cmd --list-all"

cmd "timeout 10 systemctl stop firewalld"
lRC=$(($lRC + $?))

cmd "timeout 10 systemctl status firewalld"

cmd "timeout 10 systemctl disable firewalld"
lRC=$(($lRC + $?))

cmd "timeout 10 systemctl status firewalld"

cmd "iptables -L"

footer "END SCRIPT: $_NAME"
exit $lRC