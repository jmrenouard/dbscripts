#!/bin/bash

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh

lRC=0

banner "Zabbix Agent"

cmd "rpm -Uvh https://repo.zabbix.com/zabbix/6.0/rhel/7/x86_64/zabbix-release-6.0-2.el7.noarch.rpm"
cmd "yum clean all"

cmd "yum -y install zabbix-agent"

cmd "systemctl restart zabbix-agent"
cmd "systemctl enable zabbix-agent"

footer "Zabbix Agent"
exit $lRC