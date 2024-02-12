#!/bin/bash


echo "$(date) $0 $*" >> /logs/scripts/ka_scripts.log
SRVNAME=${srv:-"haproxy"}

FAULT_FLAG="/tmp/ka_fault_haproxy.flag"
if [ -f "$FAULT_FLAG" ]; then
	echo "ENTERING FAULT MODE"
	exit 2
fi
sta=$(systemctl is-active $SRVNAME)

[ "active" = "$sta" ] || exit 1

systemctl is-active $SRVNAME
exit $?
