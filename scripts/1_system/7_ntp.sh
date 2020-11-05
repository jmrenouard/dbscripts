#!/bin/sh

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh

source /etc/os-release

lRC=0
banner "BEGIN SCRIPT: $_NAME"

if [ "$VERSION_ID" = "7" ]; then
	cmd "yum -y install ntpdate"
	cmd "ntpdate -vqd fr.pool.ntp.org"
else
	cmd "yum -y install ntpstat"
fi


cmd "timedatectl set-timezone Europe/Paris"
lRC=$(($lRC + $?))

[ "$VERSION_ID" = "8" ] &&  cmd "ntpstat"

cmd "timedatectl"

cmd "date"
footer "END SCRIPT: $_NAME"
exit $lRC