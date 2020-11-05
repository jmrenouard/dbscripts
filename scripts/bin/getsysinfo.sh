#!/bin/sh


[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh

lRC=0

cmd "hostname -s"

cmd "ip a"

cmd "netstat -ltpn"

cmd "nproc"

cmd "free -m"

cmd "df -Ph"
