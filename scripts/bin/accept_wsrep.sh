#!/bin/bash

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh

for rule_id in $(/sbin/iptables --list INPUT --line-numbers | grep -E 'REJECT.*(tram|4567)' | awk '{print $1}'); do
	/sbin/iptables -D INPUT $rule_id 
done


for rule_id in $(/sbin/iptables --list OUTPUT --line-numbers | grep -E 'REJECT.*(tram|4567)' | awk '{print $1}'); do
	/sbin/iptables -D OUTPUT $rule_id 
done
/sbin/iptables -L
