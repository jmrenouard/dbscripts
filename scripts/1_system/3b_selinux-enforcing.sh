#!/bin/bash

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh

lRC=0
banner "BEGIN SCRIPT: $_NAME"

if [ "$ID" = "ubuntu" ]; then
	cmd "apt install -y policycoreutils selinux-utils selinux-basics" "INSTALL SELINUX for $ID"
else
	cmd "yum -y install policycoreutils-python-utils libsemanage-python" "INSTALL SELINUX UTILITIES for $ID"
fi
cmd "setenforce 1" "SELINUX IN ENFORCING MODE"
#lRC=$(($lRC + $?))

if [ -f "/etc/sysconfig/selinux" ]; then  
	cmd "cat /etc/sysconfig/selinux" "CONTENT OF /etc/sysconfig/selinux"
	title1 "REMOVING PERMISSIVE mode FROM /etc/sysconfig/selinux"
	perl -i -pe 's/(SELINUX=).*/$1ENFORCING/g' /etc/sysconfig/selinux
	grep -q "SELINUX=ENFORCING" /etc/sysconfig/selinux
	lRC=$(($lRC + $?))
fi

title1 "REMOVING PERMISSIVE mode FROM /etc/selinux/config"
perl -i -pe 's/(SELINUX=).*/$1ENFORCING/g' /etc/selinux/config
grep -q "SELINUX=ENFORCING" /etc/selinux/config
lRC=$(($lRC + $?))

cmd "sestatus"

info "CMD: semanage boolean -l| grep mysql"
semanage boolean -l| grep mysql

# PAsser en permissive uniquement les règles MYSQL
#cmd "semanage permissive -a mysqld_t"
cmd "semanage port -m -t mysqld_port_t -p tcp 4444"
cmd "semanage port -m -t mysqld_port_t -p tcp 4567"
cmd "semanage port -a -t mysqld_port_t -p tcp 4568"
semanage port -l| grep mysql

cmd 'semanage fcontext -a -t mysqld_db_t "/data(/.*)?"'
info "CMD: semanage boolean -l| grep mysql"
semanage fcontext -l| grep mysql

title2 "Trace SE Linux MariaDB"
grep -i mysql /var/log/audit/audit.log

footer "END SCRIPT: $_NAME"
exit $lRC