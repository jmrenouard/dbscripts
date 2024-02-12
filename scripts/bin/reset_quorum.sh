#!/bin/bash


[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh

banner "RESET QUORUM"

systemctl stop mysql
perl –pe –i 's/(safe_to_bootstrap): 0/$1: 1/g' /var/lib/mysql/grastate.dat
galera_new_cluster
lRC=$?

footer "RESET QUORUM"
exit $lRC
