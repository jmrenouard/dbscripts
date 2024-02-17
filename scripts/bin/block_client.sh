#!/bin/bash


[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh

export PATH=/sbin:$PATH
iptables -A INPUT -p tcp --dport 3306 -j REJECT

iptables -L