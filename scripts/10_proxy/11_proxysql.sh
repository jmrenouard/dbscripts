#!/bin/bash

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh
[ -f '/etc/os-release' ] && source /etc/os-release

lRC=0
myrootmy1
banner "BEGIN SCRIPT: $_NAME"

if [ "$ID" = "ubuntu" ]; then
        cmd "wget https://github.com/sysown/proxysql/releases/download/v2.6.0/proxysql_2.6.0-ubuntu22_amd64.deb"
				cmd "apt -y install proxysql_2.6.0-ubuntu22_amd64.deb"
else 
        cmd "yum -y install https://github.com/sysown/proxysql/releases/download/v2.6.0/proxysql-2.6.0-1-centos7.x86_64.rpm"
fi

cmd "systemctl enable haproxy"
cmd "systemctl restart haproxy"

which firewall-cmd &>/dev/null
if [ $? -eq 0 ]; then
	firewall-cmd --add-port=6033/tcp --permanent
	firewall-cmd --add-port=6032/tcp --permanent
	firewall-cmd --add-port=6080/tcp --permanent
	firewall-cmd --reload
fi

footer "END SCRIPT: $NAME"
exit $lRC