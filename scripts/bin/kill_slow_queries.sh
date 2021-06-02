#!/bin/bash

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh

for req in $(mysql -Nrs -B -e "select id from information_schema.processlist where user <> 'system user' and TIME >= '0'"); do 
	infos=$(mysql -Nrs -e "select * from information_schema.processlist where id=$req")
	if [ -n "$infos"]; then
		ask_yes_no "KILLING $infos"
		[ $? -eq 0 ] && mysql -e "KILL $id"
	fi
done
