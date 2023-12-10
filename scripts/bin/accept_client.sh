#!/bin/bash

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh

export PATH=/sbin:$PATH
for rule_id in $(iptables --list --line-numbers | grep -E 'REJECT.*(mysql|3306)' | awk '{print $1}'); do
	iptables -D INPUT $rule_id
done
iptables -L
