#!/bin/sh

set -x
nodename=$(hostname -s)
nodeip=$(ip a | grep 192.168.33 | awk '{print $2}' | cut -d/ -f1)
perl -i -pe "s/<NodeName>/$nodename/g;s/<NodeIp>/$nodeip/g" /etc/my.cnf.d/61_galera.cnf

cat /etc/my.cnf.d/61_galera.cnf

