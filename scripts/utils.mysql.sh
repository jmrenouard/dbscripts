#!/bin/bash

tlog()
{
    tail_error_log
}

change_user_ssl()
{
    db_users | perl -pe 's/(.+)\s+(.+)/ALTER USER "$1"@"$2" REQUIRE SSL;/g; s/\s+/ /gs;s/ \"/"/g;s/;/;\n/g;s/^\s//g'
}
## Code MariaDB
my_status()
{
    local lRC=0
    $SSH_CMD mysqladmin ping 2>&1 | grep -qiE '(error|commande introuvable|command not found)'
    lRC=$(reverse_rc $?)
    if [ $lRC -eq 0 ]; then
        ok "mysql server is running ...."
        return 0
    fi
    error "mysql server is stopped ...."
    return 1
}

raw_mysql()
{
    local lDB=${DB:-"mysql"}
    if [ -z "$SSH_CMD" ];then
        mysql -Nrs -e "$*" $lDB
        return $?
    fi
    echo "$*" |$SSH_CMD mysql -Nrs $lDB
    return $?
}

db_list()
{
   raw_mysql 'show databases' | sort
}

db_user_list()
{
   db_list | grep -vE '(mysql|sys|information_schema|performance_schema)'
}

db_users()
{
    raw_mysql 'select user, host from mysql.user' mysql| sort -k${1:-"1"} | column -t
}

db_tables()
{
    DB="${1:-"mysql"}" raw_mysql 'show tables'
}

db_count()
{
    for tbl in $(db_tables ${1:-"mysql"}); do
        echo -ne "${1:-"mysql"}\t$tbl\t"
        raw_mysql "select count(*) from ${1:-"mysql"}.$tbl"
    done | sort -nr -k2 | column -t
}

db_countall()
{
    for db in $(db_list| sort); do
        db_count $db
    done
}
db_fast_count()
{
 	# BAsed on innodb stat
    #mysql -Nrs -e "select table_name, stat_value from mysql.innodb_index_stats where stat_name='n_diff_pfx02' and database_name='${1:-"mysql"}' order by 2 DESC;"
 	# based on information schema
 	raw_mysql "select table_name, table_rows from information_schema.tables where table_schema='${1:-"mysql"}' order by 2 DESC;" |column -t

}

dmysql()
{
    local DOCKER_ID=$1
    shift
    docker exec -it $DOCKER_ID mysql $*
}

drawmysql()
{
    local DOCKER_ID=$1
    shift
    docker exec -it $DOCKER_ID mysql -Nrs "$*"
}

dbash()
{
    docker exec -it ${DOCKER_ID:"$1"} /bin/bash
}

duserdbs()
{
    local DOCKER_ID=$1
    echo "SELECT DISTINCT(TABLE_SCHEMA)
    FROM information_schema.TABLES
    WHERE TABLE_SCHEMA NOT IN ('performance_schema', 'sys',
    'mysql', 'information_schema', 'innodb')" | \
    docker exec -i $DOCKER_ID mysql -Nrs | sort
}

dalltables()
{
    local DOCKER_ID=$1
    echo "SELECT CONCAT(TABLE_SCHEMA,';',TABLE_NAME)
    FROM information_schema.TABLES
    WHERE TABLE_SCHEMA NOT IN ('performance_schema', 'sys',
    'mysql', 'information_schema', 'innodb')
    AND TABLE_TYPE='BASE TABLE'" | \
    docker exec -i $DOCKER_ID mysql -Nrs | sort
}

dtables()
{
    local DOCKER_ID=$1
    local schema=$2
    echo "SELECT TABLE_NAME
    FROM information_schema.TABLES
    WHERE TABLE_SCHEMA = '${schema}'
    AND TABLE_TYPE='BASE TABLE'" | \
    docker exec -i $DOCKER_ID mysql -Nrs | sort
}

dallnottables()
{
    local DOCKER_ID=$1

    echo "SELECT CONCAT(TABLE_SCHEMA,';',TABLE_NAME)
    FROM information_schema.TABLES
    WHERE TABLE_SCHEMA NOT IN ('performance_schema', 'sys',
    'mysql', 'information_schema', 'innodb')
    AND TABLE_TYPE != 'BASE TABLE'" | \
    docker exec -i $DOCKER_ID mysql -Nrs | sort
}
dnottables()
{
    local DOCKER_ID=$1
    local schema=$2

    echo "SELECT CONCAT(TABLE_SCHEMA,';',TABLE_NAME,';',TABLE_TYPE)
    FROM information_schema.TABLES
    WHERE TABLE_SCHEMA = '${schema}'
    AND TABLE_TYPE != 'BASE TABLE'" | \
    docker exec -i $DOCKER_ID mysql -Nrs | sort
}

dcountlines()
{
    local DOCKER_ID=$1
    local schema=$2
    local table=$3
    echo "SELECT count(*) FROM $s.$t" | \
    docker exec -i $DOCKER_ID mysql -Nrs
}

dump_database_list()
{
    local DOCKER_ID=$1
    local outfile=${2}.dblist.csv
    [ -f "$outfile" ] && rm -f $outfile
    title1 "USER DATABASE LIST"
    duserdbs $DOCKER_ID | tee $outfile
}

dump_table_list()
{
    local DOCKER_ID=$1
    local outfile=${2}.tbl.csv
    [ -f "$outfile" ] && rm -f $outfile
    title1 "USER TABLE LIST"
  dalltables $DOCKER_ID | tee $outfile
}

dump_non_table_list()
{
    local DOCKER_ID=$1
    local outfile=${2}.nottbl.csv
    [ -f "$outfile" ] && rm -f $outfile
    title1 "USER NOT TABLE LIST"
    dallnottables $DOCKER_ID| sort | tee $outfile
}

dump_table_count()
{
    local DOCKER_ID=$1
    local outfile=${2}.count.csv
    [ -f "$outfile" ] && rm -f $outfile
     title1 "USER TABLE COUNT"
    for s in $(duserdbs $DOCKER_ID); do
        for t in $(dtables $DOCKER_ID $s); do
            count=$(dcountlines $DOCKER_ID $s $t)
            echo "$s;$t;$count"
        done | sort -nr -k3 -t';'
    done
}

galera_status()
{
    title1 "WSREP STATUS"
    $SSH_CMD mysql -e "select * from information_schema.wsrep_status\G"
    title1 "WSREP GLOBAL STATUS"
    $SSH_CMD mysql -e "select * from mysql.wsrep_cluster\G"
    title1 "WSREP MEMBER"
    $SSH_CMD mysql -e "select * from information_schema.wsrep_membership;"
    title1 "WSREP GLOBAL STATUS"
    $SSH_CMD mysql -e "select * from mysql.wsrep_cluster_members\G"
    title1 "WSREP STREAMING REPLICATION"
    $SSH_CMD mysql -e "select * from mysql.wsrep_streaming_log\G"

}

my_cluster_state() {
(
$SSH_CMD mysql -e "show status like '%wsrep%'"
$SSH_CMD mysql -e "show variables like 'auto%'"
$SSH_CMD mysql -e "show variables like 'wsrep_%'"
) |grep -v wsrep_provider_options| grep -E '(wsrep_last_committed|wsrep_node|wsrep_flow|wsresp_cluster_a|cluster_status|connected|ready|state_comment|cluster_size|state_uuid|conf|wsrep_cluster_name|auto_)'| \
sort | column -t
}

node_cluster_state()
{
    node=$1
    param=$2
    ssh -q $node "source /etc/profile.d/utils.sh;source /etc/profile.d/utils.mysql.sh;my_cluster_state" | grep $param | awk '{print $2}'
}

binlog_sql_xhours()
{
    start_date=$(date --date "$1 hour ago" +'%Y-%m-%d %T')
    echo "-- START DATE: $start_date"
#    exit 1
    mysqlbinlog --base64-output=decode-rows -vv --start-datetime "$start_date" /var/lib/mysql/mysqld-bin.0* 2>/dev/null| \
    perl -ne 's/^(#\d{6} \d{2}:\d{2}:\d{2}).*/$1/g and print; /^[#\/]/ or print' | perl -pe 's/^#/-- /g'
}

binlog_sql_type_xhours()
{
    binlog_sql_xhours ${1:-"1"}| grep -E '^(INSERT|DELETE|DROP|CREATE|UPDATE|COMMIT|ROLLBACK)' | awk '{print $1}' | cut -d/ -f 1 | sort | uniq -c | sort -nr
}

generate_sql_load()
{
    for i in $(seq 1 ${1:-"500"}); do
        mysqlslap --auto-generate-sql --verbose --concurrency=${2:-"50"} --iterations=${3:-"10"}
        sleep ${4:-"2"}s
    done
}

get_ssh_mariadb_root_password()
{
    node=$1
    ssh -q $node "source /etc/profile.d/utils.sh;get_mariadb_root_password"
}

get_mariadb_root_password()
{
    [ -f "/root/.my.cnf" ] || return 0
    grep -E "^password=" /root/.my.cnf | head -n1 | cut -d= -f2
}

perform_select()
{
    for i in $(seq 1 1000); do mysql -e 'select 1'; echo $i; sleep ${1:-"0.5"}s; done

}

perform_ms()
{
	echo "type: read / write / key /update / mixed"
	set -x
	mysqlslap --host=localhost --auto-generate-sql --verbose --iterations=${2:-"10"} --concurrency=${3:-"10"} --number-char-cols=10 --number-int_cols=10 --auto-generate-sql-load-type=${1:-"mixed"}
	set +x
}

global_variables()
{
    res=$(raw_mysql "show global variables like '$1'" | perl -pe 's/^.*?\s+(.*)$/$1/')

    [ -z "$res" -a -n "$2" ] && res="$2"
    echo -n $res
}

set_global_variables()
{
    raw_mysql "set global $1 = '$2'"

    global_variables $1
}

global_status()
{
    $SSH_CMD mysql -Nrs -e "show global status like '$1'"| perl -pe 's/^.*?\s+(.*)$/$1/'
}

provider_var()
{

    if [ -n "$1" ]; then
        $SSH_CMD mysql -Nrs -e "show global variables like 'wsrep_provider_options'" | \
        perl -pe 's/wsrep_provider_options//g;s/; /\n/g;s/ = /\t/g'| sort | column -t | grep -E "$1"
        return 0
    fi
    $SSH_CMD mysql -Nrs -e "show global variables like 'wsrep_provider_options'" | \
    perl -pe 's/wsrep_provider_options//g;s/; /\n/g;s/ = /\t/g'| sort | column -t 
}

set_geocluster_config()
{
    echo "wsrep_provider_options = 'evs.keepalive_period = PT3S';
    wsrep_provider_options = 'evs.inactive_check_period = PT10S';
    wsrep_provider_options = 'evs.suspect_timeout = PT30S';
    wsrep_provider_options = 'evs.inactive_timeout = PT1M';
    wsrep_provider_options = 'evs.install_timeout = PT1M';" | \
    $SSH_CMD mysql -f
}
set_localcluster_config()
{
    echo "wsrep_provider_options = 'evs.keepalive_period = PT1S';
    wsrep_provider_options = 'evs.inactive_check_period = PT0.5S';
    wsrep_provider_options = 'evs.suspect_timeout = PT5S';
    wsrep_provider_options = 'evs.inactive_timeout = PT15S';
    wsrep_provider_options = 'evs.install_timeout = PT7.5S';" | \
    $SSH_CMD mysql -f
}

galera_is_enabled()
{
    local var_wsrep_on=""
    var_wsrep_on="$(global_variables 'wsrep_on')"
    if [ "$var_wsrep_on" = "ON" ]; then
        echo "1"
        return 0
    fi
    echo "0"
}

get_cert_conflits()
{
    grep -a -A10 -E 'WSREP.*cluster confli' /var/log/mysql/mysqld.log | grep -a -E 'WSREP: cluster conflic|SQL'
}

galera_members()
{
    $SSH_CMD mysql -Nrs -e "SELECT NAME FROM information_schema.wsrep_membership WHERE NAME<>'garb';"
}

galera_member_status()
{
#    true
    parameters="auto_increment_increment
auto_increment_offset
wsrep_cluster_conf_id
wsrep_cluster_name
wsrep_cluster_size
wsrep_cluster_state_uuid
wsrep_cluster_status
wsrep_connected
wsrep_last_committed
wsrep_local_state_comment
wsrep_local_state_uuid
wsrep_node_address
wsrep_node_incoming_address
wsrep_node_name
wsrep_ready
wsrep_evs_delayed
wsrep_evs_evict_list
wsrep_evs_repl_latency
wsrep_evs_state"

(
echo -e "PARAMETER\t$(galera_members |xargs | perl -pe 's/\s+/\t/g')"
for param in $parameters; do
    echo -en "$param\t"
    for node in $(galera_members); do
        echo -en "$(node_cluster_state $node $param)\t"
    done
    echo
done
)|column -t
}

get_non_innodb_table_count()
{
    echo "select TABLE_SCHEMA, ENGINE , count(*)
    from information_schema.tables
    where TABLE_TYPE like 'Base table'
    AND ENGINE <> 'InnoDB'
    and TABLE_SCHEMA NOT IN ('mysql', 'performance_schema', 'sys', 'information_schema')
    GROUP BY TABLE_SCHEMA, ENGINE;
" |mysql -v
}

tables_without_primary_key()
{
    echo "SELECT DISTINCT t.table_schema, t.table_name
       FROM information_schema.tables AS t
       LEFT JOIN information_schema.columns AS c ON t.table_schema = c.table_schema AND t.table_name = c.table_name
             AND c.column_key = 'PRI'
      WHERE t.table_schema NOT IN ('information_schema', 'mysql', 'performance_schema', 'sys')
        AND c.table_name IS NULL AND t.table_type != 'VIEW';" | mysql -v
}


force_primary_view()
{
    if [ "$(global_status wsrep_cluster_status)" != "Primary" ]; then
        ask_yes_or_no "Make this node a prim view for the whole cluster"
        [ $? -eq 0 ] && reset_quorum
    fi
}

change_users_ssl()
{
    
}
diff_schema()
{
    node1=$1
    node2=$2
    db=$3
    options=${4:-''}
    tables=$5
    lRC=0
    rm -f /tmp/db.diff
    [ -z "$tables" ] && tables=$(db_tables $db)
    tables=$(echo $tables | perl -pe 's/[,:;]/ /g')
    #echo $tables
    #return 0
    echo "<h1> Comparaison table ...</h1>"
    echo "<pre>"
for table in $tables; do
    echo -n "Comparing '$table'............" | tee -a /tmp/db.diff
    ssh -q $node1 "mysqldump $options --opt --compact --skip-extended-insert $db $table" > /tmp/file1.sql
    lRC=$(($lRC + $?))
    ssh -q $node2 "mysqldump $options --opt --compact --skip-extended-insert $db $table" > /tmp/file2.sql
    lRC=$(($lRC + $?))
    diff -up /tmp/file1.sql /tmp/file2.sql >> /tmp/db.diff
    if [ $? -eq 0 ]; then
      echo "[OK]" |tee -a /tmp/db.diff
    else
      echo "[FAIL]" |tee -a /tmp/db.diff
      lRC=1
    fi
done
echo "</pre>"
if [ $lRC -gt 0 ]; then
    echo "Some diff are presents"
    echo "All details in /tmp/db.diff"
    cat /tmp/db.diff
else
    echo "$db database is the same between $node1 and $node2 nodes (Specific options: $options)"
fi
rm -f /tmp/file1.sql /tmp/file2.sql
return $lRC
}

optimize_db()
{
    # For innoDB: alter table employees. engine=InnoDB;
	mysqlcheck -vvvos ${1:-"mysql"}
}

analyze_db()
{
	mysqlcheck -vvvas ${1:-"mysql"}
}

diff_checksum()
{
    node1=$1
    node2=$2
    db=$3
    tables=$5
    lRC=0
    rm -f /tmp/db.diff
    [ -z "$tables" ] && tables=$(db_tables $db)
    tables=$(echo $tables | perl -pe 's/[,:;]/ /g')
    #echo $tables
    #return 0
    echo "<h1> Comparaison checksum table ...</h1>"
    echo "<pre>"
for table in $tables; do
    echo -n "Comparing '$table'............" | tee -a /tmp/db.diff
    ssh -q $node1 "mysql -Nrs -e 'CHECKSUM TABLE $table' $db" > /tmp/file1.sql
    lRC=$(($lRC + $?))
    ssh -q $node2 "mysql -Nrs -e 'CHECKSUM TABLE $table' $db" > /tmp/file2.sql
    lRC=$(($lRC + $?))
    diff -up /tmp/file1.sql /tmp/file2.sql >> /tmp/db.diff
    if [ $? -eq 0 ]; then
      echo "[OK]" |tee -a /tmp/db.diff
    else
      echo "[FAIL]" |tee -a /tmp/db.diff
      lRC=1
    fi
done
echo "</pre>"
if [ $lRC -gt 0 ]; then
    echo "Some diff are presents"
    echo "All details in /tmp/db.diff"
    cat /tmp/db.diff
else
    echo "$db database table checksums are the same between $node1 and $node2 nodes (Specific options: $options)"
fi
rm -f /tmp/file1.sql /tmp/file2.sql
return $lRC
}

galera_member_count_tables()
{
    db=$1
(
echo -e "TABLE\t$(galera_members |xargs | perl -pe 's/\s+/\t/g')"
for tbl in $(db_tables $db); do
    echo -en "$tbl\t"
    for node in $(galera_members); do
        echo -en "$(ssh -q $node "mysql -Nrs -e 'SELECT count(*) from $db.$tbl'")\t"
    done
    echo
done
)|column -t
}

add_password_history()
{
    local history_file=$HOME/.pass_mariadb
    touch $history_file
    chmod 600 $history_file

    echo -e "$(date)\t$1\t$2" >> $history_file
}
check_mariadb_password()
{
    [ "$3" != "silent" ] && info "check cmd: mysql -Nrs -h$my_private_ipv4 -u $1 -p$2 -e 'select 1'"
    ret="$(mysql -Nrs -h$my_private_ipv4 -u $1 -p$2 -e 'select 1' 2>&1)"
    awa="1"

    if [ "$ret" = "$awa" ]; then
        [ "$3" != "silent" ] && info "PASSWORD FROM '$1' USER IS CORRECT."
        return 0
    fi
    [ "$3" != "silent" ] && error "PASSWORD FROM '$1' IS INCORRECT."
    return 1
}

last_state_changes()
{
    tac /tmp/galera.notif.txt |head -n 15
}

copy_rc()
{

	for srv in $(grep node_addresses= /etc/bootstrap.conf| cut -d= -f2 | tr ',' ' ' ) ;do
		[ "$my_private_ipv4" == "$srv" ] && continue
		info "COPYING /etc/bootstrap.conf TO $srv"
		rsync -avz /etc/bootstrap.conf root@$srv:/etc 2>/dev/null
		info "COPYING /root/.my.cnf TO $srv"
		rsync -avz /root/.my.cnf /root/.pass_mariadb root@$srv:/root 2>/dev/null
	done
}
get_last_datadir_access()
{
	limit=${1:-"20"}
	datadir=$(global_variables datadir /var/lib/mysql)

	 sudo find $datadir -type f | xargs -n 1 sudo stat | grep "Modify: $(date +%Y-)" | perl -pe 's/Modify: //g;s/\.\d+ //g' | sort -n | uniq -c | tail -n $limit
}

grep_error_log()
{
    grep -Ei '(err|warn|fat)' /var/log/mysql/mysqld.log
}

tail_error_log()
{
	log_file="$(global_variables log_error)"

	[ -f "$log_file" ] && tail -f $log_file &
}

less_error_log()
{
	log_file="$(global_variables log_error)"

	[ -f "$log_file" ] && less $log_file
}

generate_multi_instance_example()
{

    mysqld_multi --example | tee /etc/my.cnf.d/90_multi_config.cnf

    for datadir in $(grep datadir /etc/my.cnf.d/90_multi_config.cnf| cut -d= -f2 | xargs -n 1); do
        #mysqld_multi stop
        echo $datadir;
        rm -rf $datadir;
        mysql_install_db --user=mysql --datadir=$datadir;
        ls -ls $datadir;
        echo "--------------------------------------------";
    done

    mysqld_multi report
}

killall_mariadbd()
{
    ps -edf | grep [m]ysqld_safe | awk '{print $2}' | xargs -n1 kill -9
    ps -edf | grep [m]ariadbd | awk '{print $2}' | xargs -n1 kill -9
}

reset_quorum()
{
 systemctl stop mysql
 perl –pe –i 's/safe_to_bootstrap: 0/ safe_to_bootstrap: 1/g' /var/lib/mysql/grastate.dat
 galera_new_cluster
}
open_mariadb_root_from()
{
    local remoteIPv4=$1
    local pass=$(get_mariadb_root_password)
     echo "
 CREATE OR REPLACE USER 'root'@'$remoteIPv4' IDENTIFIED BY '$pass';
 GRANT ALL PRIVILEGES ON *.* TO 'root'@'$remoteIPv4';
     " | mysql -v
}

revoke_mariadb_root_from()
{
    local remoteIPv4=$1
     echo "DROP USER 'root'@'$remoteIPv4' ;" | mysql -v
}

binlog_sql()
{
    mysqlbinlog -j 387 --stop-position=890 --base64-output=decode-rows -vv mysqld-bin.000011 | perl -ne '/^[#\/]/ or print'
}

get_replication_status()
{
    title2 "REPLICATION STATUS:"
    mysql -e 'SHOW SLAVE STATUS\G' | grep -Ei '(_Running|Err|Behind|_State|Master_Host)'
    sep1
    (
    mysql -rs -e "select @@report_host\G"
    mysql -rs -e "select @@server_id\G"
    mysql -rs -e "select @@read_only\G"
    mysql -rs -e "select @@log_slave_updates\G"
    ) | grep -v '\*\*\*' | column -t
}

alias use='mysql'

UTILS_MYSQL_IS_LOADED="1"