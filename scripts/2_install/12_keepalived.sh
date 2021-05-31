#!/bin/bash

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh
[ -f '/etc/os-release' ] && source /etc/os-release

lRC=0

banner "BEGIN SCRIPT: $_NAME"

https://github.com/sysown/proxysql/releases/download/v2.1.1/proxysql_2.1.1-ubuntu20_arm64.deb

if [ "$ID" = "ubuntu" ]; then
        cmd "apt -y install https://github.com/sysown/proxysql/releases/download/v2.1.1/proxysql_2.1.1-ubuntu20_arm64.deb"
else 
        cmd "yum -y install https://github.com/sysown/proxysql/releases/download/v2.1.1/proxysql-2.1.1-1-centos8.x86_64.rpm"
fi

cmd "systemctl enable haproxy"
cmd "systemctl restart haproxy"

firewall-cmd --add-port=6033/tcp --permanent
firewall-cmd --add-port=6032/tcp --permanent
firewall-cmd --add-port=6080/tcp --permanent
firewall-cmd --reload

footer "END SCRIPT: $NAME"
exit $lRC