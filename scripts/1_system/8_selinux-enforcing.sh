#!/bin/sh

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh

lRC=0
banner "BEGIN SCRIPT: $_NAME"

cmd "setenforce 1" "SELINUX IN ENFORCING MODE"
lRC=$(($lRC + $?))

cmd "cat /etc/sysconfig/selinux" "CONTENT OF /etc/sysconfig/selinux"

title1 "REMOVING PERMISSIVE mode FROM /etc/sysconfig/selinux"
perl -i -pe 's/(SELINUX=).*/$1ENFORCING/g' /etc/sysconfig/selinux
grep -q "SELINUX=ENFORCING" /etc/sysconfig/selinux
lRC=$(($lRC + $?))

cmd "sestatus"

cmd "yum -y install policycoreutils-python-utils"

semanage boolean -l| grep mysql

# PAsser en permissive uniquement les règles MYSQL
#cmd "semanage permissive -a mysqld_t"

cmd "semanage port -m -t mysqld_port_t -p tcp 4444"
cmd "semanage port -m -t mysqld_port_t -p tcp 4567"
cmd "semanage port -a -t mysqld_port_t -p tcp 4568"
semanage port -l| grep mysql

cmd 'semanage fcontext -a -t mysqld_db_t "/data(/.*)?"'
semanage fcontext -l| grep mysql

title2 "Trace SE Linux MariaDB"
grep -i mysql /var/log/audit/audit.log

footer "END SCRIPT: $_NAME"
exit $lRC