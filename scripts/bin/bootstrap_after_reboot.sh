#!/bin/bash

systemctl stop mariadb

perl  -i -pe 's/(safe_to_bootstrap): 0/$1: 1/g' /var/lib/mysql/grastate.dat

GPOS=$(galera_recovery 2>&1| tail -n 1)
systemctl set-environment _WSREP_NEW_CLUSTER="--wsrep-new-cluster --wsrep-start-position='$GPOS'" 
systemctl restart mariadb