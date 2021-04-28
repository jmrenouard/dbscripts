#!/bin/sh

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh

lRC=0
banner "BEGIN SCRIPT: $_NAME"

cmd "setenforce 0" "SELINUX IN PERMISSIVE MODE"
lRC=$(($lRC + $?))

cmd "cat /etc/sysconfig/selinux" "CONTENT OF /etc/sysconfig/selinux"

title1 "REMOVING ENFORCING mode FROM /etc/sysconfig/selinux"
perl -i -pe 's/(SELINUX=).*/$1PERMISSIVE/g' /etc/sysconfig/selinux
grep -q "SELINUX=PERMISSIVE" /etc/sysconfig/selinux
lRC=$(($lRC + $?))

title1 "REMOVING ENFORCING mode FROM /etc/selinux/config"
perl -i -pe 's/(SELINUX=).*/$1PERMISSIVE/g' /etc/selinux/config
grep -q "SELINUX=PERMISSIVE" /etc/selinux/config
lRC=$(($lRC + $?))

cmd "sestatus"

footer "END SCRIPT: $_NAME"
exit $lRC