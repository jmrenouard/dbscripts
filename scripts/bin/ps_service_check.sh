#!/bin/bash


echo "$(date) $0 $*" >> /logs/scripts/ps_scripts.log
SRVNAME=${srv:-"proxysql"}

FAULT_FLAG="/admin/flags/ps_fault_proxysql.flag"
if [ -f "$FAULT_FLAG" ]; then
	echo "ENTERING FAULT MODE"
	exit 2
fi
sta=$(systemctl is-active $SRVNAME)

[ "active" = "$sta" ] || exit 1

systemctl is-active $SRVNAME
exit $?

