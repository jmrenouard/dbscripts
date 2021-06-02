#!/bin/bash

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh
mysql -e 'show processlist' | grep -v 'system user'

max_time=${1:-"0"}
for req in $(mysql -Nrs -B -e "select id from information_schema.processlist where user <> 'system user' and TIME >= '${max_time}'"); do 
	infos=$(mysql -Nrs -e "select * from information_schema.processlist where id=$req")
	if [ -n "$infos" ]; then
		ask_yes_or_no "KILLING $infos"
		[ $? -eq 0 ] && mysql -v -e "KILL $req"
	fi
done
