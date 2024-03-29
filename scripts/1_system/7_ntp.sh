#!/bin/bash

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh
[ -f "$(pwd)/utils.sh" ] && source "$(pwd)/utils.sh"

source /etc/os-release

lRC=0
TIMEZONE="GMT"
TIMEZONE="Europe/Paris"
banner "BEGIN SCRIPT: $_NAME"

if [ "$ID" != "ubuntu" ];then
	if [ "$VERSION_ID" = "7" ]; then
		# Centos 7 / Red Hat 7
		cmd "yum -y install ntpdate"
		cmd "ntpdate -vqd fr.pool.ntp.org"
	else
		# Centos 8 / Red Hat 8
		cmd "yum -y install ntpstat chrony"
		lRC=$(($lRC + $?))
		
	fi
	cmd "systemctl restart chronyd"
	lRC=$(($lRC + $?))
	sleep 3s
else
		# Ubuntu / Debian
		cmd "apt -y install ntpstat ntp"
		lRC=$(($lRC + $?))
		
		cmd "systemctl enable ntp"
		lRC=$(($lRC + $?))
		
		cmd "systemctl restart ntp"
		lRC=$(($lRC + $?))
		sleep 3s	
fi
cmd "timedatectl set-timezone $TIMEZONE"
lRC=$(($lRC + $?))

cmd "timedatectl status"

cmd "date"

if [ "$VERSION_ID" = "8" ]; then
	cmd "chronyc sources"
else 
	cmd "ntpq -p"
fi

sleep 3s
cmd "ntpstat"
# Attente de résolution :)
# sleep 3s
#ntpstat
#lRC=$(($lRC + $?))

footer "END SCRIPT: $_NAME"
exit $lRC