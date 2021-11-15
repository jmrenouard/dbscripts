#!/bin/bash

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh

pass=ahgh3aliTeemaa3loo
srvProxy=192.168.33.180

for i in $(seq 1 500); do
	mysql -h$srvProxy -uroot -p$pass mysql -e 'show variables like "report_host%"' -Nrs 2>/dev/null
	sleep 1s
	echo "------"
done

