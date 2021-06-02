#!/bin/bash

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh

for rule_id in $(/sbin/iptables --list --line-numbers | grep -E 'REJECT.*(mysql|3306)' | awk '{print $1}'); do
	/sbin/iptables -D INPUT $rule_id 
done
/sbin/iptables -L
