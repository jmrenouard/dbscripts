#!/bin/bash
[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh
[ -f '/etc/bootstrap.conf' ] && source /etc/bootstrap.conf

perl -i -pe 's/safe_to_bootstrap: 0/safe_to_bootstrap: 1/g' /var/lib/mysql/grastate.dat 
/usr/bin/galera_new_cluster

for srv in $(echo $node_addresses| tr ',' ' '); do
	[ "$my_private_ipv4" = "$srv" ] && continue
	echo "* RESTARTING $srv"
	ssh -q $srv "systemctl restart mysql"
done 


galera_member_status