#!/bin/bash

lRC=0
CONF_FILE=/etc/sysctl.d/99-mariadb.conf

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh
[ -f "$(pwd)/utils.sh" ] && source "$(pwd)/utils.sh"

banner "BEGIN SCRIPT: $_NAME"

info "RELOADING SYSCTL CONFIGURATION ..."

#sunrpc.tcp_slot_table_entries = 128
echo "fs.aio-max-nr=1048576
fs.nr_open=1048576
vm.swappiness=10
net.ipv4.tcp_keepalive_time=120
net.ipv4.tcp_keepalive_probes=4
net.ipv4.tcp_keepalive_intvl=20
" > $CONF_FILE

cmd "cat $CONF_FILE"

cmd "sysctl -q -p"

cmd "sysctl -p $CONF_FILE"

sysctl -a| grep -E '(swapi|aio-max-nr)'

footer "END SCRIPT: $_NAME"
exit $lRC