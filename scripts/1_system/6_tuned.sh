#!/bin/bash

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh

lRC=0
banner "BEGIN SCRIPT: $_NAME"

if [ "$ID" = "ubuntu" ];then
	cmd "apt install -y tuned tuned-utils" "INSTALL TUNED for $ID"

fi
cmd "timeout 30 systemctl start tuned"
lRC=$(($lRC + $?))

cmd "tuned-adm auto_profile"

cmd "tuned-adm active"

footer "END SCRIPT: $_NAME"
exit $lRC