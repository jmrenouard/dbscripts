#!/bin/bash


[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh

/sbin/iptables -A INPUT -p tcp --dport 4567 -j REJECT
/sbin/iptables -A OUTPUT -p tcp --dport 4567 -j REJECT

/sbin/iptables -L