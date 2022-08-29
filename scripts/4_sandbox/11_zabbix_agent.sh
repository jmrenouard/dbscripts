#!/bin/bash

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh

lRC=0

ZabbixServer=192.168.0.12
banner "Zabbix Agent"

cmd "rpm -Uvh https://repo.zabbix.com/zabbix/6.0/rhel/7/x86_64/zabbix-release-6.0-2.el7.noarch.rpm"
cmd "yum clean all"

cmd "yum -y install zabbix-agent"

perl -i -pe "s/^Server=(.+)$/Server=$ZabbixServer/;s/^ServerActive=/#ServerActive=/" /etc/zabbix/zabbix_agentd.conf
cmd "systemctl restart zabbix-agent"
cmd "systemctl enable zabbix-agent"

tail -n 30 /var/log/zabbix/zabbix_agentd.log

footer "Zabbix Agent"
exit $lRC