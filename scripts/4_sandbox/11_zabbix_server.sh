#!/bin/bash

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh

lRC=0

banner "Zabbix Server"

cmd "yum -y install git"

cmd "mkdir -p /container/zabbix"

cd /container/zabbix

[ -d "./.git" ] || cmd "git clone https://git.rdr-it.io/docker/zabbix.git ."

cmd "ls -ls"

cmd "docker-compose pull"

cmd "docker-compose up -d"


footer "Zabbix Server"
exit $lRC