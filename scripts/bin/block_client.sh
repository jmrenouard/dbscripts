#!/bin/sh


[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh

/sbin/iptables -A INPUT -p tcp -dport 3306 -j REJECT

/sbin/iptables -L