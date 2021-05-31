#!/bin/bash

#https://github.com/sysown/proxysql/releases/download/v2.1.1/proxysql_2.1.1-ubuntu20_arm64.deb
#https://github.com/sysown/proxysql/releases/download/v2.1.1/proxysql-2.1.1-1-centos8.x86_64.rpm

pmysql()
{
    local puser=${1:-"admin"}
    local ppass=${2:-"admin"}
    local phost=${3:-"127.0.0.1"}
    local pport=${4:-"6032"}
    mysql -P$pport -u$puser -p$ppass -h$phost --prompt="proxysql://$puser@$phost>"
}

pmysqldump()
{
    local puser=${1:-"admin"}
    local ppass=${2:-"admin"}
    local phost=${3:-"127.0.0.1"}
    local pport=${4:-"6032"}
    mysqldump -P$pport -u$puser -p$ppass -h$phost -h 127.0.0.1 \
    --skip-triggers --skip-add-drop-table --no-data main 2>/dev/null| grep -E 'CREATE TABLE' | perl -pe 's/CREATE /TRUNCATE /g;s/\(/;/g'


     mysqldump -P$pport -u$puser -p$ppass -h$phost -h 127.0.0.1 \
     --no-tablespaces \
     --no-create-info \
     --no-create-db \
     --skip-triggers \
     --extended-insert \
     main
}

load_mysql_users()
{
	PROXYSQL_MONITOR_USER=${1:-"proxy-monitor"}
	PROXYSQL_MONITOR_PASS=${2:-"proxysql-monitor"}

    echo "create user '${PROXYSQL_MONITOR_USER}'@'192.168.%' IDENTIFIED BY '${PROXYSQL_MONITOR_PASS}';
    GRANT SELECT, USAGE ON *.* to '${PROXYSQL_MONITOR_USER}'@'192.168.%';
    "
}

load_cluster_pp_config()
{
	local srv1=${1:-"192.168.33.181"}
	local srv2=${2:-"192.168.33.182"}
    echo "
update global_variables set variable_value='proxysql-monitor' where variable_name='admin-cluster_username';
update global_variables set variable_value='proxysql-monitor' where variable_name='admin-cluster_password';
update global_variables set variable_value=200 where variable_name='admin-cluster_check_interval_ms';
update global_variables set variable_value=100 where variable_name='admin-cluster_check_status_frequency';
update global_variables set variable_value='true' where variable_name='admin-cluster_mysql_query_rules_save_to_disk';
update global_variables set variable_value='true' where variable_name='admin-cluster_mysql_servers_save_to_disk';
update global_variables set variable_value='true' where variable_name='admin-cluster_mysql_users_save_to_disk';
update global_variables set variable_value='true' where variable_name='admin-cluster_proxysql_servers_save_to_disk';
update global_variables set variable_value=3 where variable_name='admin-cluster_mysql_query_rules_diffs_before_sync';
update global_variables set variable_value=3 where variable_name='admin-cluster_mysql_servers_diffs_before_sync';
update global_variables set variable_value=3 where variable_name='admin-cluster_mysql_users_diffs_before_sync';
update global_variables set variable_value=3 where variable_name='admin-cluster_proxysql_servers_diffs_before_sync';
load admin variables to RUNTIME;
save admin variables to disk;

INSERT INTO proxysql_servers (hostname,port,weight,comment) VALUES ('$srv1',6032,1000,'PRIMARY');
INSERT INTO proxysql_servers (hostname,port,weight,comment) VALUES ('$srv2',6032,99,'SECONDARY');

LOAD PROXYSQL SERVERS TO RUNTIME;
SAVE PROXYSQL SERVERS TO DISK;
"
}

load_cluster_prod_config()
{
    echo "
update global_variables set variable_value='proxysql-monitor' where variable_name='admin-cluster_username';
update global_variables set variable_value='proxysql-monitor' where variable_name='admin-cluster_password';
update global_variables set variable_value=200 where variable_name='admin-cluster_check_interval_ms';
update global_variables set variable_value=100 where variable_name='admin-cluster_check_status_frequency';
update global_variables set variable_value='true' where variable_name='admin-cluster_mysql_query_rules_save_to_disk';
update global_variables set variable_value='true' where variable_name='admin-cluster_mysql_servers_save_to_disk';
update global_variables set variable_value='true' where variable_name='admin-cluster_mysql_users_save_to_disk';
update global_variables set variable_value='true' where variable_name='admin-cluster_proxysql_servers_save_to_disk';
update global_variables set variable_value=3 where variable_name='admin-cluster_mysql_query_rules_diffs_before_sync';
update global_variables set variable_value=3 where variable_name='admin-cluster_mysql_servers_diffs_before_sync';
update global_variables set variable_value=3 where variable_name='admin-cluster_mysql_users_diffs_before_sync';
update global_variables set variable_value=3 where variable_name='admin-cluster_proxysql_servers_diffs_before_sync';
load admin variables to RUNTIME;
save admin variables to disk;

INSERT INTO proxysql_servers (hostname,port,weight,comment) VALUES ('ix1-pv-u18-DriveProxySQL-01.renater.fr',6032,1000,'PRIMARY');
INSERT INTO proxysql_servers (hostname,port,weight,comment) VALUES ('ix1-pv-u18-DriveProxySQL-02.renater.fr',6032,99,'SECONDARY');

LOAD PROXYSQL SERVERS TO RUNTIME;
SAVE PROXYSQL SERVERS TO DISK;
"
}

load_proxy_rwsplit_config()
{

echo "INSERT INTO mysql_servers VALUES 
('10','ix1-bv-u18-DrivePPdriveBD-04.renater.fr','3306','0','ONLINE','1','0','100','10','0','0','Drive PP MariaDB cluster Node xxxxxx');
LOAD MYSQL SERVERS FROM MEMORY;
SAVE MYSQL SERVERS TO DISK;"

echo "DELETE FROM mysql_servers WHERE hostname ='ix1-bv-u18-DrivePPdriveBD-04.renater.fr';
LOAD MYSQL SERVERS FROM MEMORY;
SAVE MYSQL SERVERS TO DISK;"

    echo "DELETE FROM mysql_servers WHERE hostgroup_id = '10';
INSERT INTO mysql_servers VALUES 
('10','ix1-bv-u18-DrivePPdriveBD-01.renater.fr','3306','0','ONLINE','1','0','500','10','0','0','Drive PP MariaDB cluster Node 1'),
('10','ix1-bv-u18-DrivePPdriveBD-02.renater.fr','3306','0','ONLINE','1','0','500','10','0','0','Drive PP MariaDB cluster Node 2'),
('10','ix1-bv-u18-DrivePPdriveBD-03.renater.fr','3306','0','ONLINE','1','0','500','10','0','0','Drive PP MariaDB cluster Node 3');

DELETE FROM mysql_galera_hostgroups  WHERE writer_hostgroup = '10';  
INSERT INTO mysql_galera_hostgroups VALUES 
( 10, 20, 30, 9999, 1, 1, 2, 30, 'Hostgroup Drive PP');

LOAD MYSQL SERVERS FROM MEMORY;
SAVE MYSQL SERVERS TO DISK;

delete from  mysql_query_rules where rule_id in (100, 200, 300);
INSERT INTO mysql_query_rules VALUES 
('100','1',NULL,NULL,'0',NULL,NULL,NULL,NULL,NULL,'^SELECT .* FOR UPDATE','0','CASELESS',NULL,NULL,'10',NULL,NULL,NULL,NULL,NULL,'0',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'1','',NULL),
('200','1',NULL,NULL,'0',NULL,NULL,NULL,NULL,NULL,'^SELECT .*','0','CASELESS',NULL,NULL,'30',NULL,NULL,NULL,NULL,NULL,'0',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'1','',NULL),
('300','1',NULL,NULL,'0',NULL,NULL,NULL,NULL,NULL,'.*','0','CASELESS',NULL,NULL,'10',NULL,NULL,NULL,NULL,NULL,'0',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'1','',NULL)
;
LOAD MYSQL QUERY RULES FROM MEMORY;
SAVE MYSQL QUERY RULES TO DISK;

DELETE FROM mysql_users where  username ='${APPNEXTCLOUDUSER_PP}';
INSERT INTO mysql_users(username,password,default_hostgroup,default_schema,transaction_persistent) VALUES ('${APPNEXTCLOUDUSER_PP}','${APPNEXTCLOUDPASS_PP}',10,'mysql', 0);
INSERT INTO mysql_users(username,password,default_hostgroup,default_schema,transaction_persistent) VALUES ('sbtest_user','password',10,'mysql', 0);

LOAD MYSQL USERS FROM MEMORY;
SAVE MYSQL USERS TO DISK;

SET admin-web_enabled='true';
SET mysql-monitor_username='${PROXYSQL_MONITOR_USER}';
SET mysql-monitor_password='${PROXYSQL_MONITOR_PASS}';
SET admin-admin_credentials='admin:admin;proxysql-monitor:proxysql-monitor';

LOAD MYSQL VARIABLES FROM MEMORY;
SAVE MYSQL VARIABLES TO DISK;

LOAD ADMIN VARIABLES FROM MEMORY;
SAVE ADMIN VARIABLES TO DISK;

PROXYSQL RESTART;
"
}

load_proxy_rwsplit_config()
{

echo "INSERT INTO mysql_servers VALUES 
('10','ix1-bv-u18-DrivePPdriveBD-04.renater.fr','3306','0','ONLINE','1','0','100','10','0','0','Drive PP MariaDB cluster Node xxxxxx');
LOAD MYSQL SERVERS FROM MEMORY;
SAVE MYSQL SERVERS TO DISK;"

echo "DELETE FROM mysql_servers WHERE hostname ='ix1-bv-u18-DrivePPdriveBD-04.renater.fr';
LOAD MYSQL SERVERS FROM MEMORY;
SAVE MYSQL SERVERS TO DISK;"

    echo "DELETE FROM mysql_servers WHERE hostgroup_id = '10';
INSERT INTO mysql_servers VALUES 
('10','ix1-bv-u18-DrivePPdriveBD-01.renater.fr','3306','0','ONLINE','1','0','500','10','0','0','Drive PP MariaDB cluster Node 1'),
('10','ix1-bv-u18-DrivePPdriveBD-02.renater.fr','3306','0','ONLINE','1','0','500','10','0','0','Drive PP MariaDB cluster Node 2'),
('10','ix1-bv-u18-DrivePPdriveBD-03.renater.fr','3306','0','ONLINE','1','0','500','10','0','0','Drive PP MariaDB cluster Node 3');

DELETE FROM mysql_galera_hostgroups  WHERE writer_hostgroup = '10';  
INSERT INTO mysql_galera_hostgroups VALUES 
( 10, 20, 30, 9999, 1, 1, 2, 30, 'Hostgroup Drive PP');

LOAD MYSQL SERVERS FROM MEMORY;
SAVE MYSQL SERVERS TO DISK;

delete from  mysql_query_rules where rule_id in (100, 200, 300);
INSERT INTO mysql_query_rules VALUES 
('100','1',NULL,NULL,'0',NULL,NULL,NULL,NULL,NULL,'^SELECT .* FOR UPDATE','0','CASELESS',NULL,NULL,'10',NULL,NULL,NULL,NULL,NULL,'0',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'1','',NULL),
('200','1',NULL,NULL,'0',NULL,NULL,NULL,NULL,NULL,'^SELECT .*','0','CASELESS',NULL,NULL,'30',NULL,NULL,NULL,NULL,NULL,'0',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'1','',NULL),
('300','1',NULL,NULL,'0',NULL,NULL,NULL,NULL,NULL,'.*','0','CASELESS',NULL,NULL,'10',NULL,NULL,NULL,NULL,NULL,'0',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'1','',NULL)
;
LOAD MYSQL QUERY RULES FROM MEMORY;
SAVE MYSQL QUERY RULES TO DISK;

DELETE FROM mysql_users where  username ='${APPNEXTCLOUDUSER_PP}';
INSERT INTO mysql_users(username,password,default_hostgroup,default_schema,transaction_persistent) VALUES ('${APPNEXTCLOUDUSER_PP}','${APPNEXTCLOUDPASS_PP}',10,'mysql', 0);
INSERT INTO mysql_users(username,password,default_hostgroup,default_schema,transaction_persistent) VALUES ('sbtest_user','password',10,'mysql', 0);

LOAD MYSQL USERS FROM MEMORY;
SAVE MYSQL USERS TO DISK;

SET admin-web_enabled='true';
SET mysql-monitor_username='${PROXYSQL_MONITOR_USER}';
SET mysql-monitor_password='${PROXYSQL_MONITOR_PASS}';
SET admin-admin_credentials='admin:admin;proxysql-monitor:proxysql-monitor';

LOAD MYSQL VARIABLES FROM MEMORY;
SAVE MYSQL VARIABLES TO DISK;

LOAD ADMIN VARIABLES FROM MEMORY;
SAVE ADMIN VARIABLES TO DISK;

PROXYSQL RESTART;
"
}


