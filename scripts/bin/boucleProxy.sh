#!/bin/sh

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh

pass=$(get_ssh_mariadb_root_password dbsrv1)
srvProxy=proxy1

for i in $(seq 1 500); do 
	mysql -h$srvProxy -uroot -p$pass mysql -e 'show variables like "report_host%"' -Nrs
	sleep 1s
	echo "------"
done

