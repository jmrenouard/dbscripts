#!/bin/sh

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh

lRC=0
banner "BEGIN SCRIPT: $_NAME"

title1 "RUNNING COMMAND: yum -y update"
yum -y update
lRC=$(($lRC + $?))

title1 "RUNNING COMMAND: yum -y upgrade"
yum -y upgrade
lRC=$(($lRC + $?))

footer "END SCRIPT: $NAME"
exit $lRC