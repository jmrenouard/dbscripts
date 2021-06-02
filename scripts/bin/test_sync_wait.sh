#!/bin/bash

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh

remotesrv=${1:-"dbsrv2"}
wsrep_param=${2:-"wsrep_sync_wait"}
wsrep_value=${3:-"0"}

echo "
drop database sync_wait; 
create database sync_wait;
use sync_wait;
create table tsync ( i int not null );
" | mysql -v -f


for i in {1..5000}; do
	echo "Bouche $i"
	mysql sync_wait -e "INSERT INTO tsync values ($i)"

	ret=$(mysql -h $remotesrv --batch sync_wait -e "set ${wsrep_param}=${wsrep_value};select i from tsync where i=$i")
	if [ "$ret" = "" ]; then
		echo "ERROR $i IS MISSING"
		exit 127
	fi
done