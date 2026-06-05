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
my_private_ipv4=$(ip a | grep inet | grep 'brd' | grep -E '(192.168|172.2)'| cut -d/ -f1 | awk '{print $2}'|head -n1)

lRC=0
galera_user=galera
galera_password=ohGh7boh7eeg6shuph

[ -f '/etc/bootstrap.conf' ] && source /etc/bootstrap.conf
[ -n "$sst_password" ] && galera_password="$sst_password"

banner "BEGIN SCRIPT: ${_NAME}"

PCKMANAGER="yum"
[ "$ID" = "ubuntu" -o "$ID" = "debian" ] && PCKMANAGER="apt"

cmd "$PCKMANAGER -y --fix-broken install"
cmd "$PCKMANAGER -y install xinetd"

[ -d "/etc/sysconfig" ] && echo "MYSQL_USERNAME='${galera_user}'
MYSQL_PASSWORD='${galera_password}'
AVAILABLE_WHEN_DONOR=1" > /etc/sysconfig/clustercheck

[ -d "/etc/default" ] && echo "MYSQL_USERNAME='${galera_user}'
MYSQL_PASSWORD='${galera_password}'
AVAILABLE_WHEN_DONOR=1" > /etc/default/clustercheck

sed -i  "/mysqlchk/d" /etc/services
echo "mysqlchk 9200/tcp" >> /etc/services


echo "
# default: on
# description: mysqlchk
service mysqlchk
{
	disable = no
	flags = REUSE
	socket_type = stream
	port = 9200
	wait = no
	instances = 10
	user = mysql
	server = /opt/local/bin/clustercheck
	log_on_failure += USERID
	only_from = 0.0.0.0/0
	bind = 0.0.0.0
	per_source = UNLIMITED
}" > /etc/xinetd.d/mysqlchk


cmd "systemctl enable xinetd"
cmd "systemctl restart xinetd"


firewall-cmd --add-port=9200/tcp --permanent
firewall-cmd --reload

cmd "netstat -ltpn | grep 9200"
lRC=$(($lRC + $?))

cmd "curl -v http://127.0.0.1:9200/"
lRC=$(($lRC + $?))

cmd "curl -v http://${my_private_ipv4}:9200/"
lRC=$(($lRC + $?))


footer "END SCRIPT: ${_NAME}"
exit $lRC
