#!/bin/bash

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh
[ -f '/etc/os-release' ] && source /etc/os-release

lRC=0
myrootmy1
banner "BEGIN SCRIPT: $_NAME"

if [ "$ID" = "ubuntu" ]; then
        cmd "rm -f proxysql_2.6.0-ubuntu22_amd64.deb*"
				cmd "wget https://github.com/sysown/proxysql/releases/download/v2.6.0/proxysql_2.6.0-ubuntu22_amd64.deb"
				cmd "dpkg -i proxysql_2.6.0-ubuntu22_amd64.deb"
else 
        cmd "yum -y install https://github.com/sysown/proxysql/releases/download/v2.6.0/proxysql-2.6.0-1-centos7.x86_64.rpm"
fi

cmd "systemctl disable haproxy"
cmd "systemctl stop haproxy"
cmd "systemctl enable proxysql"
cmd "systemctl start proxysql"

cmd "apt -y install mariadb-client-core-10.6" 
which firewall-cmd &>/dev/null
if [ $? -eq 0 ]; then
	firewall-cmd --add-port=6033/tcp --permanent
	firewall-cmd --add-port=6032/tcp --permanent
	firewall-cmd --add-port=6080/tcp --permanent
	firewall-cmd --reload
fi

title2 "CONFIG PROXY SQL"
	echo "DELETE FROM mysql_servers;

INSERT INTO mysql_servers(hostgroup_id,hostname,port, use_ssl) VALUES (0,'192.168.56.191',3306, 1);
INSERT INTO mysql_servers(hostgroup_id,hostname,port, use_ssl) VALUES (0,'192.168.56.192',3306, 1);
INSERT INTO mysql_servers(hostgroup_id,hostname,port, use_ssl) VALUES (1,'192.168.56.193',3306, 1);

LOAD MYSQL SERVERS TO RUNTIME;
DELETE FROM mysql_galera_hostgroups;

INSERT INTO mysql_galera_hostgroups (writer_hostgroup, backup_writer_hostgroup, 
reader_hostgroup, offline_hostgroup, active, max_writers, writer_is_also_reader, 
max_transactions_behind, comment) 
VALUES (0, 2, 1, 4, 1, 1, 1, 100, NULL);

update mysql_galera_hostgroups set max_writers=2;
LOAD MYSQL SERVERS TO RUNTIME;

UPDATE global_variables SET variable_value='monitor' 
WHERE variable_name='mysql-monitor_username';

UPDATE global_variables SET variable_value='monitor1234!' 
WHERE variable_name='mysql-monitor_password';

UPDATE global_variables SET variable_value='2000' 
WHERE variable_name IN ('mysql-monitor_connect_interval','mysql-monitor_ping_interval',
'mysql-monitor_read_only_interval');

SELECT * FROM global_variables WHERE variable_name LIKE 'mysql-monitor_%';

LOAD MYSQL VARIABLES TO RUNTIME;
SAVE MYSQL VARIABLES TO DISK;

-- SELECT * FROM monitor.mysql_server_connect_log ORDER BY time_start_us DESC LIMIT 3;
-- SELECT * FROM monitor.mysql_server_ping_log ORDER BY time_start_us DESC LIMIT 3;

select * from mysql_servers\G
select * from mysql_galera_hostgroups\G
LOAD MYSQL SERVERS TO RUNTIME;
SAVE MYSQL SERVERS TO DISK;
select hostgroup_id, hostname, port, gtid_port, status, weight from runtime_mysql_servers;

DROP USER  'stnduser'@'%' ;
CREATE USER 'stnduser'@'%' IDENTIFIED BY 'stnduser1234!';
GRANT ALL PRIVILEGES ON *.* TO 'stnduser'@'%';

SHOW CREATE TABLE mysql_users\G

INSERT INTO mysql_users(username,password,default_hostgroup) 
VALUES ('stnduser','stnduser',0);

LOAD MYSQL USERS TO RUNTIME;
SAVE MYSQL USERS TO DISK;
" | mysql -vf -P6032 -uadmin -padmin -h127.0.0.1

footer "END SCRIPT: $NAME"
exit $lRC