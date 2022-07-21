#!/bin/bash

TYPE=$1
NAME=$2
STATE=$3
SRVNAME=${srv:-"proxysql"}
echo "$(date) $0 $*" >> /logs/scripts/ps_scripts.log

case $STATE in
        MASTER|BACKUP) 
		systemctl is-active $SRVNAME
		if [ $? -eq 0 ];then
			systemctl reload $SRVNAME
		else
			systemctl start $SRVNAME
		fi
                exit 0
                ;;
        FAULT|STOP) 
		#systemctl stop $SRVNAME
                  exit 0
                  ;;
        *)        echo "unknown state"
                  exit 1
                  ;;
esac
echo "Wrong STATE detected"
exit 127
