#!/bin/bash

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh

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
		cmd "systemctl restart chronyd"
		lRC=$(($lRC + $?))
		sleep 3s
	fi
else
		# Ubuntu / Debian
		cmd "apt -y install ntpstat chrony"
		lRC=$(($lRC + $?))
		cmd "systemctl restart chronyd"
		lRC=$(($lRC + $?))
		sleep 3s	
fi
cmd "timedatectl set-timezone $TIMEZONE"
lRC=$(($lRC + $?))

cmd "timedatectl"

cmd "date"

# Attente de résolution :)
# sleep 3s
#ntpstat
#lRC=$(($lRC + $?))

footer "END SCRIPT: $_NAME"
exit $lRC