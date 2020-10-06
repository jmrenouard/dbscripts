#!/bin/sh

lRC=0
CONF_FILE=/etc/sysctl.d/99-mariadb.conf

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh

banner "BEGIN SCRIPT: $_NAME"

info "RELOADING SYSCTL CONFIGURATION ..."

echo "sunrpc.tcp_slot_table_entries = 128
fs.aio-max-nr = 1048576
vm.swappiness = 10" > $CONF_FILE

cmd "cat $CONF_FILE"

cmd "sysctl -q -p"

cmd "sysctl -p $CONF_FILE"

footer "END SCRIPT: $_NAME"
exit $lRC