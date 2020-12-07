#!/bin/sh

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh

source /etc/os-release

lRC=0
TIMEZONE="GMT"
TIMEZONE="Europe/Paris"
banner "BEGIN SCRIPT: $_NAME"

if [ "$VERSION_ID" = "7" ]; then
	cmd "yum -y install ntpdate"
	cmd "ntpdate -vqd fr.pool.ntp.org"
else
	cmd "yum -y install ntpstat chrony"
	lRC=$(($lRC + $?))
	cmd "systemctl restart chronyd"
	lRC=$(($lRC + $?))
fi

cmd "timedatectl set-timezone $TIMEZONE"
lRC=$(($lRC + $?))

if [ "$VERSION_ID" = "8" ];then
		cmd "ntpstat"
		lRC=$(($lRC + $?))
fi

cmd "timedatectl"

cmd "date"

footer "END SCRIPT: $_NAME"
exit $lRC