#!/bin/bash
[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh
[ -f '/etc/bootstrap.conf' ] && source /etc/bootstrap.conf

for srv in $(echo $node_addresses| tr ',' ' '); do
	echo -ne "$srv\t"
	ssh -q $srv "grep 'uuid:' /var/lib/mysql/grastate.dat"|cut -d: -f2
done | sort -nr -k2
