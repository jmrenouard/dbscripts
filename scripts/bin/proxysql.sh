#!/bin/bash
set -euo pipefail

# --- Minimal Utility Functions ---
now() { echo "$(date "+%F %T %Z")($(hostname -s))"; }
info() { echo "$(now) INFO: $*" 1>&2; }
error() { echo "$(now) ERROR: $*" 1>&2; return 1; }
ok() { info "[SUCCESS] $* [SUCCESS]"; }
sep1() { echo "$(now) -----------------------------------------------------------------------------"; }
title1() { sep1; echo "$(now) $*"; sep1; }
cmd() {
    local tcmd="$1"
    local descr=${2:-"$tcmd"}
    title1 "RUNNING: $descr"
    set +e
    eval "$tcmd"
    local cRC=$?
    set -e
    if [ $cRC -eq 0 ]; then
        ok "$descr"
    else
        error "$descr (RC=$cRC)"
    fi
    return $cRC
}
banner() { title1 "START: $*"; info "run as $(whoami)@$(hostname -s)"; }
footer() {
    local lRC=${lRC:-"$?"}
    info "FINAL EXIT CODE: $lRC"
    [ $lRC -eq 0 ] && title1 "END: $* SUCCESSFUL" || title1 "END: $* FAILED"
    return $lRC
}
# --- End of Utility Functions ---

#https://github.com/sysown/proxysql/releases/download/v2.1.1/proxysql_2.1.1-ubuntu20_arm64.deb
#https://github.com/sysown/proxysql/releases/download/v2.1.1/proxysql-2.1.1-1-centos8.x86_64.rpm

PROXYSQL_MONITOR_USER=${1:-"proxy-monitor"}
PROXYSQL_MONITOR_PASS=${2:-"proxysql-monitor"}

 puser="admin"
 ppass="admin"
 phost="127.0.0.1"
 pport="6032"

pmysql()
{
    local puser=${1:-"$puser"}
    local ppass=${2:-"$ppass"}
    local phost=${3:-"$phost"}
    local pport=${4:-"$pport"}
    mysql -P$pport -u$puser -p$ppass -h$phost --prompt="proxysql://$puser@$phost>"
}

pmysqldump()
{
    local puser=${1:-"$puser"}
    local ppass=${2:-"$ppass"}
    local phost=${3:-"$phost"}
    local pport=${4:-"$pport"}

    mysqldump -P$pport -u$puser -p$ppass -h$phost \
    --skip-triggers --skip-add-drop-table --no-data main 2>/dev/null| grep -E 'CREATE TABLE' | perl -pe 's/CREATE /TRUNCATE /g;s/\(/;/g'

     mysqldump -P$pport -u$puser -p$ppass -h$phost \
     --no-tablespaces \
     --no-create-info \
     --no-create-db \
     --skip-triggers \
     --extended-insert
}

load_mysql_users()
{
	PROXYSQL_MONITOR_USER=${1:-"$PROXYSQL_MONITOR_USER"}
	PROXYSQL_MONITOR_PASS=${2:-"$PROXYSQL_MONITOR_PASS"}

    echo "create user '${PROXYSQL_MONITOR_USER}'@'192.168.%' IDENTIFIED BY '${PROXYSQL_MONITOR_PASS}';
    GRANT SELECT, USAGE ON *.* to '${PROXYSQL_MONITOR_USER}'@'192.168.%';
    "
}

load_cluster_config()
{
	local srv1=${1:-"192.168.33.181"}
	local srv2=${2:-"192.168.33.182"}
    echo "
update global_variables set variable_value='proxysql-monitor' where variable_name='$PROXYSQL_MONITOR_USER';
update global_variables set variable_value='proxysql-monitor' where variable_name='$PROXYSQL_MONITOR_PASS';
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

load_proxy_rwsplit_config()
{

echo "INSERT INTO mysql_servers VALUES 
('10','dbsrv4.local','3306','0','ONLINE','1','0','100','10','0','0','MariaDB cluster Node');
LOAD MYSQL SERVERS FROM MEMORY;
SAVE MYSQL SERVERS TO DISK;"

echo "DELETE FROM mysql_servers WHERE hostname ='dbsrv4.local';
LOAD MYSQL SERVERS FROM MEMORY;
SAVE MYSQL SERVERS TO DISK;"

    echo "DELETE FROM mysql_servers WHERE hostgroup_id = '10';
INSERT INTO mysql_servers VALUES 
('10','dbsrv1.local','3306','0','ONLINE','1','0','500','10','0','0','MariaDB cluster Node 1'),
('10','dbsrv2.local','3306','0','ONLINE','1','0','500','10','0','0','MariaDB cluster Node 2'),
('10','dbsrv3.local','3306','0','ONLINE','1','0','500','10','0','0','MariaDB cluster Node 3');

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

DELETE FROM mysql_users where  username ='${APPMYSQLUSER}';
INSERT INTO mysql_users(username,password,default_hostgroup,default_schema,transaction_persistent) VALUES ('${APPMYSQLUSER}','${APPMYSQLPASS}',10,'mysql', 0);
INSERT INTO mysql_users(username,password,default_hostgroup,default_schema,transaction_persistent) VALUES ('sbtest_user','password',10,'mysql', 0);

LOAD MYSQL USERS FROM MEMORY;
SAVE MYSQL USERS TO DISK;

SET admin-web_enabled='true';
SET mysql-monitor_username='${PROXYSQL_MONITOR_USER}';
SET mysql-monitor_password='${PROXYSQL_MONITOR_PASS}';
SET admin-admin_credentials='admin:admin;${PROXYSQL_MONITOR_USER}:${PROXYSQL_MONITOR_PASS}';

LOAD MYSQL VARIABLES FROM MEMORY;
SAVE MYSQL VARIABLES TO DISK;

LOAD ADMIN VARIABLES FROM MEMORY;
SAVE ADMIN VARIABLES TO DISK;

PROXYSQL RESTART;
"
}
