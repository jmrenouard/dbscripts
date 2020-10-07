#!/bin/sh

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh

lRC=0
banner "BEGIN SCRIPT: $_NAME"

cmd "yum -y install ntpstat"

cmd "timedatectl set-timezone Europe/Paris"
lRC=$(($lRC + $?))

cmd "ntpstat"

cmd "timedatectl"

footer "END SCRIPT: $_NAME"
exit $lRC