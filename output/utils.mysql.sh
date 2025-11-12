# ##############################################################################
# Author:       jmrenouard/jean-Marie Renouard
# Email:        jmrenouard@lightpath.fr
#
# Description:
#   A comprehensive utility script for managing MySQL, MariaDB, and Galera Cluster.
#   It provides a wide range of functions for database inspection, administration,
#   Docker-based operations, Galera cluster management, and various checks.
#   This script is intended to be sourced to provide a powerful command-line
#   toolkit for DBAs.
#
# Usage:
#   source utils.mysql.sh
#
# Examples:
#   # Example 1: List all user databases.
#   db_list
#
#   # Example 2: Get a side-by-side status comparison of all Galera cluster members.
#   galera_member_status
#
#   # Example 3: Check for tables without a primary key.
#   tables_without_primary_key
# ##############################################################################
#!/bin/bash

# ------------------------------------------------------------------------------
# Description:
#   An alias to tail the MySQL error log.
#
# Arguments:
#   None
#
# Outputs:
#   - Follows the content of the MySQL error log to stdout.
# ------------------------------------------------------------------------------
tlog()
{
    tail_error_log
}

# ------------------------------------------------------------------------------
# Description:
#   Generates 'ALTER USER ... REQUIRE SSL' statements for all MySQL users.
#
# Arguments:
#   None
#
# Outputs:
#   - Writes the generated SQL statements to stdout.
# ------------------------------------------------------------------------------
change_user_ssl()
{
    db_users | perl -pe 's/(.+)\s+(.+)/ALTER USER "$1"@"$2" REQUIRE SSL;/g; s/\s+/ /gs;s/ \"/"/g;s/;/;\n/g;s/^\s//g'
}
# ------------------------------------------------------------------------------
# Description:
#   Checks if the MySQL/MariaDB server is running by pinging it.
#
# Arguments:
#   None
#
# Outputs:
#   - Writes a status message to stdout.
#   - Returns 0 on success, 1 on failure.
# ------------------------------------------------------------------------------
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

# ------------------------------------------------------------------------------
# Description:
#   Executes a raw SQL query against a specified database.
#   Can be run locally or remotely via SSH if $SSH_CMD is set.
#
# Arguments:
#   $* - The SQL query to execute.
#
# Outputs:
#   - Writes the query result to stdout.
#   - Returns the exit code of the mysql client.
# ------------------------------------------------------------------------------
raw_mysql()
{
    local lDB=${DB:-"mysql"}
    if [ -z "$SSH_CMD" ];then
        mysql -Nrs -e "$*" $lDB
        return $?
    fi
    echo "$*" |$SSH_CMD mysql -Nrs $lDB #${MYSQL_OPTION:-""}
    return $?
}

# ------------------------------------------------------------------------------
# Description:
#   Lists all databases on the server.
#
# Arguments:
#   None
#
# Outputs:
#   - Writes a sorted list of database names to stdout.
# ------------------------------------------------------------------------------
db_list()
{
   raw_mysql 'show databases' | sort
}

# ------------------------------------------------------------------------------
# Description:
#   Lists all non-system databases.
#
# Arguments:
#   None
#
# Outputs:
#   - Writes a list of user-created database names to stdout.
# ------------------------------------------------------------------------------
db_user_list()
{
   db_list | grep -vE '(mysql|sys|information_schema|performance_schema)'
}

# ------------------------------------------------------------------------------
# Description:
#   Lists all users and their hosts from the mysql.user table.
#
# Arguments:
#   $1 - (Optional) The column number to sort by. Defaults to 1.
#
# Outputs:
#   - Writes a formatted table of users and hosts to stdout.
# ------------------------------------------------------------------------------
db_users()
{
  raw_mysql 'select user, host from mysql.user' mysql| sort -k${1:-"1"} | column -t
}

# ------------------------------------------------------------------------------
# Description:
#   Lists all tables in a given database.
#
# Arguments:
#   $1 - (Optional) The database name. Defaults to "mysql".
#
# Outputs:
#   - Writes a list of table names to stdout.
# ------------------------------------------------------------------------------
db_tables()
{
    DB="${1:-"mysql"}" raw_mysql 'show tables'
}

# ------------------------------------------------------------------------------
# Description:
#   Counts the number of rows in each table of a given database.
#
# Arguments:
#   $1 - (Optional) The database name. Defaults to "mysql".
#
# Outputs:
#   - Writes a formatted table of database, table, and row count to stdout.
# ------------------------------------------------------------------------------
db_count()
{
    for tbl in $(db_tables ${1:-"mysql"}); do
        echo -ne "${1:-"mysql"}\t$tbl\t"
        raw_mysql "select count(*) from ${1:-"mysql"}.$tbl"
    done | sort -nr -k3 | column -t
}

# ------------------------------------------------------------------------------
# Description:
#   Counts the rows for all tables in all databases.
#
# Arguments:
#   None
#
# Outputs:
#   - Writes row counts for all tables to stdout.
# ------------------------------------------------------------------------------
db_countall()
{
    for db in $(db_list| sort); do
        db_count $db
    done
}
# ------------------------------------------------------------------------------
# Description:
#   Provides a fast row count for tables in a database by querying the
#   information_schema, which is faster than `COUNT(*)`.
#
# Arguments:
#   $1 - (Optional) The database name. Defaults to "mysql".
#
# Outputs:
#   - Writes a formatted table of table names and their estimated row counts.
# ------------------------------------------------------------------------------
db_fast_count()
{
	# Based on information schema
	raw_mysql "select table_name, table_rows from information_schema.tables where table_schema='${1:-"mysql"}' order by 2 DESC;" |column -t

}

# ------------------------------------------------------------------------------
# Description:
#   Executes the `mysql` client inside a specified Docker container.
#
# Arguments:
#   $1 - The Docker container ID or name.
#   $* - Arguments to pass to the `mysql` client.
#
# Outputs:
#   - The output of the `mysql` command.
# ------------------------------------------------------------------------------
dmysql()
{
    local DOCKER_ID=$1
    shift
    docker exec -it $DOCKER_ID mysql $*
}

# ------------------------------------------------------------------------------
# Description:
#   Executes a raw SQL query inside a specified Docker container.
#
# Arguments:
#   $1 - The Docker container ID or name.
#   $* - The SQL query to execute.
#
# Outputs:
#   - The result of the SQL query.
# ------------------------------------------------------------------------------
drawmysql()
{
    local DOCKER_ID=$1
    shift
    docker exec -it $DOCKER_ID mysql -Nrs "$*"
}

# ------------------------------------------------------------------------------
# Description:
#   Opens an interactive bash shell inside a specified Docker container.
#
# Arguments:
#   $1 - The Docker container ID or name.
#
# Outputs:
#   - An interactive shell session.
# ------------------------------------------------------------------------------
dbash()
{
    docker exec -it ${DOCKER_ID:"$1"} /bin/bash
}

# ------------------------------------------------------------------------------
# Description:
#   Lists non-system databases within a Docker container.
#
# Arguments:
#   $1 - The Docker container ID or name.
#
# Outputs:
#   - A sorted list of database names.
# ------------------------------------------------------------------------------
duserdbs()
{
    local DOCKER_ID=$1
    echo "SELECT DISTINCT(TABLE_SCHEMA)
    FROM information_schema.TABLES
    WHERE TABLE_SCHEMA NOT IN ('performance_schema', 'sys',
    'mysql', 'information_schema', 'innodb')" | \
    docker exec -i $DOCKER_ID mysql -Nrs | sort
}

# ------------------------------------------------------------------------------
# Description:
#   Lists all user tables across all non-system databases in a Docker container.
#
# Arguments:
#   $1 - The Docker container ID or name.
#
# Outputs:
#   - A sorted list of 'schema;table_name'.
# ------------------------------------------------------------------------------
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

# ------------------------------------------------------------------------------
# Description:
#   Lists all tables for a specific schema within a Docker container.
#
# Arguments:
#   $1 - The Docker container ID or name.
#   $2 - The schema (database) name.
#
# Outputs:
#   - A sorted list of table names.
# ------------------------------------------------------------------------------
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

# ------------------------------------------------------------------------------
# Description:
#   Lists all non-table objects (like views) across all non-system databases
#   in a Docker container.
#
# Arguments:
#   $1 - The Docker container ID or name.
#
# Outputs:
#   - A sorted list of 'schema;object_name'.
# ------------------------------------------------------------------------------
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
# ------------------------------------------------------------------------------
# Description:
#   Lists all non-table objects (like views) for a specific schema in a Docker container.
#
# Arguments:
#   $1 - The Docker container ID or name.
#   $2 - The schema (database) name.
#
# Outputs:
#   - A sorted list of 'schema;object_name;object_type'.
# ------------------------------------------------------------------------------
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

# ------------------------------------------------------------------------------
# Description:
#   Counts the rows in a specific table within a Docker container.
#
# Arguments:
#   $1 - The Docker container ID or name.
#   $2 - The schema (database) name.
#   $3 - The table name.
#
# Outputs:
#   - The row count as a number.
# ------------------------------------------------------------------------------
dcountlines()
{
    local DOCKER_ID=$1
    local schema=$2
    local table=$3
    echo "SELECT count(*) FROM $s.$t" | \
    docker exec -i $DOCKER_ID mysql -Nrs
}

# ------------------------------------------------------------------------------
# Description:
#   Dumps the list of user databases from a Docker container to a CSV file.
#
# Arguments:
#   $1 - The Docker container ID or name.
#   $2 - The base name for the output file (e.g., "backup_prefix").
#
# Outputs:
#   - Creates a file named <outfile>.dblist.csv.
# ------------------------------------------------------------------------------
dump_database_list()
{
    local DOCKER_ID=$1
    local outfile=${2}.dblist.csv
    [ -f "$outfile" ] && rm -f $outfile
    title1 "USER DATABASE LIST"
    duserdbs $DOCKER_ID | tee $outfile
}

# ------------------------------------------------------------------------------
# Description:
#   Dumps the list of user tables from a Docker container to a CSV file.
#
# Arguments:
#   $1 - The Docker container ID or name.
#   $2 - The base name for the output file.
#
# Outputs:
#   - Creates a file named <outfile>.tbl.csv.
# ------------------------------------------------------------------------------
dump_table_list()
{
    local DOCKER_ID=$1
    local outfile=${2}.tbl.csv
    [ -f "$outfile" ] && rm -f $outfile
    title1 "USER TABLE LIST"
  dalltables $DOCKER_ID | tee $outfile
}

# ------------------------------------------------------------------------------
# Description:
#   Dumps the list of non-table objects from a Docker container to a CSV file.
#
# Arguments:
#   $1 - The Docker container ID or name.
#   $2 - The base name for the output file.
#
# Outputs:
#   - Creates a file named <outfile>.nottbl.csv.
# ------------------------------------------------------------------------------
dump_non_table_list()
{
    local DOCKER_ID=$1
    local outfile=${2}.nottbl.csv
    [ -f "$outfile" ] && rm -f $outfile
    title1 "USER NOT TABLE LIST"
    dallnottables $DOCKER_ID| sort | tee $outfile
}

# ------------------------------------------------------------------------------
# Description:
#   Dumps the row counts for all user tables in a Docker container.
#
# Arguments:
#   $1 - The Docker container ID or name.
#   $2 - The base name for the output file (not currently used to create a file).
#
# Outputs:
#   - Writes a list of 'schema;table;count' to stdout.
# ------------------------------------------------------------------------------
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

# ------------------------------------------------------------------------------
# Description:
#   Displays a comprehensive status report for a Galera Cluster node.
#
# Arguments:
#   None
#
# Outputs:
#   - Writes several status sections to stdout.
# ------------------------------------------------------------------------------
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

# ------------------------------------------------------------------------------
# Description:
#   Displays a filtered and sorted summary of the Galera cluster state.
#
# Arguments:
#   None
#
# Outputs:
#   - Writes a formatted table of important wsrep status variables to stdout.
# ------------------------------------------------------------------------------
my_cluster_state() {
(
$SSH_CMD mysql -e "show status like '%wsrep%'"
$SSH_CMD mysql -e "show variables like 'auto%'"
$SSH_CMD mysql -e "show variables like 'wsrep_%'"
$SSH_CMD mysql -e "show variables like 'report_host'"
$SSH_CMD mysql -e "show variables like 'server_id'"
) |grep -v wsrep_provider_options| grep -E '(wsrep_last_committed|wsrep_node|wsrep_flow|wsresp_cluster_a|cluster_status|connected|ready|state_comment|cluster_size|state_uuid|conf|wsrep_cluster_name|auto_)'| \
sort | column -t
}

# ------------------------------------------------------------------------------
# Description:
#   Gets the value of a global status or variable from a specific cluster node or locally.
#
# Arguments:
#   $1 - The parameter (variable/status name) to query. OR The node name.
#   $2 - (If $1 is a node) The parameter name to query.
#
# Outputs:
#   - Writes the value of the parameter to stdout.
# ------------------------------------------------------------------------------
global_variable_or_status()
{
    if [ $# -eq 2 ]; then
			node=$1
			param=$2
			mysql -Nrs -h $(galera_member_ip $node) -e "show global status like '$param';show global variables like '$param'" | grep -v wsrep_provider_options | awk '{print $2}'
		else
			param=$1
			mysql -Nrs -e "show global status like '$param';show global variables like '$param'" | grep -v wsrep_provider_options | awk '{print $2}'
		fi
}

# ------------------------------------------------------------------------------
# Description:
#   Extracts and formats SQL statements from the binary logs from the last X hours.
#
# Arguments:
#   $1 - The number of hours ago to start reading from.
#
# Outputs:
#   - Writes the formatted SQL statements to stdout.
# ------------------------------------------------------------------------------
binlog_sql_xhours()
{
    start_date=$(date --date "$1 hour ago" +'%Y-%m-%d %T')
    echo "-- START DATE: $start_date"
#    exit 1
    mysqlbinlog --base64-output=decode-rows -vv --start-datetime "$start_date" /var/lib/mysql/mysqld-bin.0* 2>/dev/null| \
    perl -ne 's/^(#\d{6} \d{2}:\d{2}:\d{2}).*/$1/g and print; /^[#\/]/ or print' | perl -pe 's/^#/-- /g'
}

# ------------------------------------------------------------------------------
# Description:
#   Provides a summary of DML/DDL statement types (INSERT, UPDATE, etc.) found
#   in the binary logs from the last X hours.
#
# Arguments:
#   $1 - (Optional) The number of hours ago to start reading. Defaults to "1".
#
# Outputs:
#   - Writes a sorted list of statement counts to stdout.
# ------------------------------------------------------------------------------
binlog_sql_type_xhours()
{
    binlog_sql_xhours ${1:-"1"}| grep -E '^(INSERT|DELETE|DROP|CREATE|UPDATE|COMMIT|ROLLBACK)' | awk '{print $1}' | cut -d/ -f 1 | sort | uniq -c | sort -nr
}

# ------------------------------------------------------------------------------
# Description:
#   Generates a test SQL load on the server using the `mysqlslap` utility.
#
# Arguments:
#   $1 - (Optional) Number of main loops. Defaults to 500.
#   $2 - (Optional) Number of concurrent clients. Defaults to 50.
#   $3 - (Optional) Number of iterations per client. Defaults to 10.
#   $4 - (Optional) Sleep time between main loops. Defaults to 2 seconds.
#
# Outputs:
#   - Runs `mysqlslap` in a loop.
# ------------------------------------------------------------------------------
generate_sql_load()
{
    for i in $(seq 1 ${1:-"500"}); do
        mysqlslap --auto-generate-sql --verbose --concurrency=${2:-"50"} --iterations=${3:-"10"}
        sleep ${4:-"2"}s
    done
}

# ------------------------------------------------------------------------------
# Description:
#   Retrieves the MariaDB root password from a remote node via SSH.
#
# Arguments:
#   $1 - The hostname or IP of the remote node.
#
# Outputs:
#   - Writes the password to stdout.
# ------------------------------------------------------------------------------
get_ssh_mariadb_root_password()
{
    node=$1
    ssh -q $node "source /etc/profile.d/utils.sh;get_mariadb_root_password"
}

# ------------------------------------------------------------------------------
# Description:
#   Retrieves the MariaDB root password from the local /root/.my.cnf file.
#
# Arguments:
#   None
#
# Outputs:
#   - Writes the password to stdout.
# ------------------------------------------------------------------------------
get_mariadb_root_password()
{
    [ -f "/root/.my.cnf" ] || return 0
    grep -E "^password=" /root/.my.cnf | head -n1 | cut -d= -f2
}

# ------------------------------------------------------------------------------
# Description:
#   Performs a simple 'SELECT 1' query in a loop to test connectivity.
#
# Arguments:
#   $1 - (Optional) Number of iterations. Defaults to 1000.
#   $2 - (Optional) Sleep time between queries. Defaults to 1 second.
#
# Outputs:
#   - Writes the iteration number to stdout.
# ------------------------------------------------------------------------------
perform_select()
{
    for i in $(seq 1 ${1:-"1000"}); do mysql -e 'select 1'; echo $i; sleep ${2:-"1"}s; done
}

# ------------------------------------------------------------------------------
# Description:
#   Performs a 'SELECT @@report_host' query in a loop.
#
# Arguments:
#   $1 - (Optional) Number of iterations. Defaults to 1000.
#   $2 - (Optional) Sleep time between queries. Defaults to 1 second.
#
# Outputs:
#   - Writes the iteration number to stdout.
# ------------------------------------------------------------------------------
perform_report_host()
{
    for i in $(seq 1 ${1:-"1000"}); do mysql -e 'select @report_host'; echo $i; sleep ${2:-"1"}s; done
}

# ------------------------------------------------------------------------------
# Description:
#   A wrapper for the `mysqlslap` utility to perform load testing.
#
# Arguments:
#   $1 - (Optional) Load type (e.g., read, write, mixed). Defaults to "mixed".
#   $2 - (Optional) Number of iterations. Defaults to 10.
#   $3 - (Optional) Number of concurrent clients. Defaults to 10.
#
# Outputs:
#   - The output of the `mysqlslap` command.
# ------------------------------------------------------------------------------
perform_ms()
{
	echo "type: read / write / key /update / mixed"
	set -x
	mysqlslap --host=localhost --auto-generate-sql --verbose --iterations=${2:-"10"} --concurrency=${3:-"10"} --number-char-cols=10 --number-int_cols=10 --auto-generate-sql-load-type=${1:-"mixed"}
	set +x
}

# ------------------------------------------------------------------------------
# Description:
#   Gets the value of a global variable.
#
# Arguments:
#   $1 - The name of the global variable.
#   $2 - (Optional) A default value to return if the variable is not set.
#
# Outputs:
#   - Writes the variable's value to stdout.
# ------------------------------------------------------------------------------
global_variables()
{
    res=$(raw_mysql "show global variables like '$1'" | perl -pe 's/^.*?\s+(.*)$/$1/')

    [ -z "$res" -a -n "$2" ] && res="$2"
    echo -n $res
}

# ------------------------------------------------------------------------------
# Description:
#   Sets the value of a global variable.
#
# Arguments:
#   $1 - The name of the global variable.
#   $2 - The value to set.
#
# Outputs:
#   - Writes the new value of the variable to stdout.
# ------------------------------------------------------------------------------
set_global_variables()
{
    raw_mysql "set global $1 = '$2'"

    global_variables $1
}

# ------------------------------------------------------------------------------
# Description:
#   Gets the value of a global status variable.
#
# Arguments:
#   $1 - The name of the status variable.
#
# Outputs:
#   - Writes the status value to stdout.
# ------------------------------------------------------------------------------
global_status()
{
    $SSH_CMD mysql -Nrs -e "show global status like '$1'"| perl -pe 's/^.*?\s+(.*)$/$1/'
}

# ------------------------------------------------------------------------------
# Description:
#   Displays Galera provider options in a formatted table. Can be filtered.
#
# Arguments:
#   $1 - (Optional) A regex pattern to filter the options.
#
# Outputs:
#   - A formatted table of provider options and their values.
# ------------------------------------------------------------------------------
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

# ------------------------------------------------------------------------------
# Description:
#   Applies a set of predefined Galera provider options suitable for a
#   geographically distributed cluster.
#
# Arguments:
#   None
#
# Outputs:
#   - Executes SET GLOBAL commands.
# ------------------------------------------------------------------------------
set_geocluster_config()
{
    echo "SET GLOBAL wsrep_provider_options = 'evs.keepalive_period = PT3S';
    SET GLOBAL wsrep_provider_options = 'evs.inactive_check_period = PT10S';
    SET GLOBAL wsrep_provider_options = 'evs.suspect_timeout = PT30S';
    SET GLOBAL wsrep_provider_options = 'evs.inactive_timeout = PT1M';
    SET GLOBAL wsrep_provider_options = 'evs.install_timeout = PT1M';" | \
    $SSH_CMD mysql -f
}
# ------------------------------------------------------------------------------
# Description:
#   Applies a set of predefined Galera provider options suitable for a
#   local-area network cluster.
#
# Arguments:
#   None
#
# Outputs:
#   - Executes SET GLOBAL commands.
# ------------------------------------------------------------------------------
set_localcluster_config()
{
    echo "SET GLOBAL wsrep_provider_options = 'evs.keepalive_period = PT1S';
    SET GLOBAL wsrep_provider_options = 'evs.inactive_check_period = PT0.5S';
    SET GLOBAL wsrep_provider_options = 'evs.suspect_timeout = PT5S';
    SET GLOBAL wsrep_provider_options = 'evs.inactive_timeout = PT15S';
    SET GLOBAL wsrep_provider_options = 'evs.install_timeout = PT7.5S';" | \
    $SSH_CMD mysql -f
}

# ------------------------------------------------------------------------------
# Description:
#   Checks if Galera Cluster replication is enabled (wsrep_on = ON).
#
# Arguments:
#   None
#
# Outputs:
#   - Writes "1" to stdout if enabled, "0" otherwise.
#   - Returns 0 if enabled, non-zero otherwise.
# ------------------------------------------------------------------------------
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

# ------------------------------------------------------------------------------
# Description:
#   Searches the MySQL error log for Galera certification conflict messages.
#
# Arguments:
#   None
#
# Outputs:
#   - Writes the relevant log lines to stdout.
# ------------------------------------------------------------------------------
get_cert_conflits()
{
    grep -a -A10 -E 'WSREP.*cluster confli' /var/log/mysql/mysqld.log | grep -a -E 'WSREP: cluster conflic|SQL'
}


# ------------------------------------------------------------------------------
# Description:
#   Finds and counts the number of tables that are not using the InnoDB storage engine.
#
# Arguments:
#   None
#
# Outputs:
#   - Writes a table of schema, engine, and count to stdout.
# ------------------------------------------------------------------------------
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

# ------------------------------------------------------------------------------
# Description:
#   Lists all tables across non-system databases that do not have a primary key.
#
# Arguments:
#   None
#
# Outputs:
#   - Writes a list of schema and table names to stdout.
# ------------------------------------------------------------------------------
tables_without_primary_key()
{
    echo "SELECT DISTINCT t.table_schema, t.table_name
       FROM information_schema.tables AS t
       LEFT JOIN information_schema.columns AS c ON t.table_schema = c.table_schema AND t.table_name = c.table_name
             AND c.column_key = 'PRI'
      WHERE t.table_schema NOT IN ('information_schema', 'mysql', 'performance_schema', 'sys')
        AND c.table_name IS NULL AND t.table_type != 'VIEW';" | mysql -v
}


# ------------------------------------------------------------------------------
# Description:
#   Checks if the current node is in a 'Primary' cluster state. If not, it
#   prompts the user to force this node to become a new primary component.
#
# Arguments:
#   None
#
# Outputs:
#   - Prompts the user for confirmation if needed.
# ------------------------------------------------------------------------------
force_primary_view()
{
    if [ "$(global_status wsrep_cluster_status)" != "Primary" ]; then
        ask_yes_or_no "Make this node a prim view for the whole cluster"
        [ $? -eq 0 ] && reset_quorum
    fi
}

# ------------------------------------------------------------------------------
# Description:
#   Finds and kills MySQL processes based on a keyword.
#
# Arguments:
#   $1 - (Optional) A keyword to filter the process list (e.g., "Sleep", "Query"). Defaults to "sleep".
#
# Outputs:
#   - Executes KILL commands.
# ------------------------------------------------------------------------------
kill_mprocess()
{
	mysql -Nrs -e 'show processlist' |grep -i ${1:-"sleep"}|cut -f1|xargs -n 1 -I {} mysql -e "kill {}"
}

# ------------------------------------------------------------------------------
# Description:
#   A duplicate function definition. See the first `change_user_ssl`.
#
# Arguments:
#   None
#
# Outputs:
#   - See `db_users`.
# ------------------------------------------------------------------------------
change_user_ssl() {
    db_users
}

# ------------------------------------------------------------------------------
# Description:
#   Compares the schema of a database between two nodes using `mysqldump` and `diff`.
#
# Arguments:
#   $1 - node1: The first node's hostname.
#   $2 - node2: The second node's hostname.
#   $3 - db: The database name to compare.
#   $4 - (Optional) options: Extra options for `mysqldump`.
#   $5 - (Optional) tables: A space-separated list of tables to compare. Defaults to all tables.
#
# Outputs:
#   - Writes comparison status to stdout and detailed diffs to /tmp/db.diff.
#   - Returns 1 if differences are found, 0 otherwise.
# ------------------------------------------------------------------------------
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

# ------------------------------------------------------------------------------
# Description:
#   Runs `OPTIMIZE TABLE` on all tables in a database using `mysqlcheck`.
#
# Arguments:
#   $1 - (Optional) The database name. Defaults to "mysql".
#
# Outputs:
#   - The output of the `mysqlcheck` command.
# ------------------------------------------------------------------------------
optimize_db()
{
    # For innoDB: alter table employees. engine=InnoDB;
	mysqlcheck -vvvos ${1:-"mysql"}
}

# ------------------------------------------------------------------------------
# Description:
#   Runs `ANALYZE TABLE` on all tables in a database using `mysqlcheck`.
#
# Arguments:
#   $1 - (Optional) The database name. Defaults to "mysql".
#
# Outputs:
#   - The output of the `mysqlcheck` command.
# ------------------------------------------------------------------------------
analyze_db()
{
	mysqlcheck -vvvas ${1:-"mysql"}
}

# ------------------------------------------------------------------------------
# Description:
#   Compares the checksums of tables in a database between two nodes.
#
# Arguments:
#   $1 - node1: The first node's hostname.
#   $2 - node2: The second node's hostname.
#   $3 - db: The database name.
#   $5 - (Optional) tables: A space-separated list of tables. Defaults to all.
#
# Outputs:
#   - Writes comparison status to stdout and details to /tmp/db.diff.
#   - Returns 1 if checksums differ, 0 otherwise.
# ------------------------------------------------------------------------------
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
    echo "$db database table checksums are the same between $node1 and $node2 nodes "
fi
rm -f /tmp/file1.sql /tmp/file2.sql
return $lRC
}

# ------------------------------------------------------------------------------
# Description:
#   Lists the names of all members in the Galera cluster (excluding garbd).
#
# Arguments:
#   None
#
# Outputs:
#   - Writes a list of member names to stdout.
# ------------------------------------------------------------------------------
galera_members()
{
    $SSH_CMD mysql -Nrs -e "SELECT NAME FROM information_schema.wsrep_membership WHERE NAME<>'garb';" information_schema
}

# ------------------------------------------------------------------------------
# Description:
#   Gets the IP address of a specific Galera cluster member.
#
# Arguments:
#   $1 - The name of the cluster member.
#
# Outputs:
#   - Writes the IP address to stdout.
# ------------------------------------------------------------------------------
galera_member_ip()
{
		node=$1
		$SSH_CMD mysql -Nrs -e "SELECT ADDRESS FROM information_schema.wsrep_membership WHERE NAME='$node';" information_schema | cut -d: -f1
}
# ------------------------------------------------------------------------------
# Description:
#   Displays a side-by-side comparison of key status variables for all
#   members of the Galera cluster.
#
# Arguments:
#   None
#
# Outputs:
#   - Writes a formatted table of parameters and their values across all nodes.
# ------------------------------------------------------------------------------
galera_member_status()
{
#    true
    parameters="server_id
report_host
auto_increment_increment
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
wsrep_ready"

(
echo -e "PARAMETER\t$(galera_members |xargs | perl -pe 's/\s+/\t/g')"
for param in $parameters; do
    echo -en "$param\t"
    for node in $(galera_members); do
        echo -en "$(global_variable_or_status $node $param)\t"
    done
    echo
done
)|column -t
}

# ------------------------------------------------------------------------------
# Description:
#   Displays a side-by-side comparison of table row counts for a given
#   database across all Galera cluster members.
#
# Arguments:
#   $1 - The database name.
#
# Outputs:
#   - Writes a formatted table of row counts for each table on each node.
# ------------------------------------------------------------------------------
galera_member_count_tables()
{
    db=$1
(
echo -e "TABLE\t$(galera_members |xargs | perl -pe 's/\s+/\t/g')"
for tbl in $(db_tables $db); do
    echo -en "$tbl\t"
    for node in $(galera_members); do
        echo -en "$(mysql -Nrs -h $(galera_member_ip $node) -e "SELECT count(*) from $db.$tbl" $db)\t"
    done
    echo
done | sort -nr -k2
)|column -t
}

# ------------------------------------------------------------------------------
# Description:
#   A faster version of `galera_member_count_tables` that uses the
#   `information_schema.tables` for estimated row counts.
#
# Arguments:
#   $1 - The database name.
#
# Outputs:
#   - Writes a formatted table of estimated row counts for each table on each node.
# ------------------------------------------------------------------------------
galera_member_fast_count_tables()
{
    db=$1
(
echo -e "TABLE\t$(galera_members |xargs | perl -pe 's/\s+/\t/g')"
for tbl in $(db_tables $db); do
    echo -en "$tbl\t"
    for node in $(galera_members); do
        echo -en "$(mysql -Nrs -h $(galera_member_ip $node) -e "SELECT table_rows FROM information_schema.tables WHERE TABLE_TYPE='BASE TABLE' AND table_schema='$db' AND table_name='$tbl'" $db)\t"
    done
    echo
done | sort -nr -k2
)|column -t
}

# ------------------------------------------------------------------------------
# Description:
#   Displays a side-by-side comparison of table checksums for a given
#   database across all Galera cluster members.
#
# Arguments:
#   $1 - The database name.
#
# Outputs:
#   - Writes a formatted table of checksums for each table on each node.
# ------------------------------------------------------------------------------
galera_member_checksum_tables()
{
    db=$1
(
echo -e "TABLE\t$(galera_members |xargs | perl -pe 's/\s+/\t/g')"
for tbl in $(db_tables $db); do
    echo -en "$tbl\t"
    for node in $(galera_members); do
        echo -en "$(mysql -Nrs -h $(galera_member_ip $node) -e "CHECKSUM TABLE ${db}.${tbl}" $db| awk '{print $2}')\t"
    done
    echo
done
)|column -t
}

# ------------------------------------------------------------------------------
# Description:
#   Adds a record to the MariaDB password history file (~/.pass_mariadb).
#
# Arguments:
#   $1 - The username.
#   $2 - The password.
#
# Outputs:
#   - Appends a line to the history file.
# ------------------------------------------------------------------------------
add_password_history()
{
    local history_file=$HOME/.pass_mariadb
    touch $history_file
    chmod 600 $history_file

    echo -e "$(date)\t$1\t$2" >> $history_file
}

# ------------------------------------------------------------------------------
# Description:
#   Checks if a given username and password are valid for a local MariaDB connection.
#
# Arguments:
#   $1 - The username.
#   $2 - The password.
#   $3 - (Optional) If "silent", suppresses informational messages.
#
# Outputs:
#   - Writes status messages to stdout unless in silent mode.
#   - Returns 0 if the password is correct, 1 otherwise.
# ------------------------------------------------------------------------------
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

# ------------------------------------------------------------------------------
# Description:
#   Displays the last 15 Galera state change notifications from a log file.
#
# Arguments:
#   None
#
# Outputs:
#   - Writes the last 15 lines of /tmp/galera.notif.txt to stdout.
# ------------------------------------------------------------------------------
last_state_changes()
{
    tac /tmp/galera.notif.txt |head -n 15
}

# ------------------------------------------------------------------------------
# Description:
#   Copies key configuration files (.my.cnf, bootstrap.conf, SSL certs) from
#   the current node to all other nodes in the cluster.
#
# Arguments:
#   None
#
# Outputs:
#   - Writes status messages to stdout.
# ------------------------------------------------------------------------------
copy_rc()
{

	for srv in $(grep node_addresses= /etc/bootstrap.conf| cut -d= -f2 | tr ',' ' ' ) ;do
		[ "$my_private_ipv4" == "$srv" ] && continue
		info "COPYING /etc/bootstrap.conf TO $srv"
		rsync -avz /etc/bootstrap.conf root@$srv:/etc 2>/dev/null
		info "COPYING /root/.my.cnf TO $srv"
		rsync -avz /root/.my.cnf /root/.pass_mariadb root@$srv:/root 2>/dev/null
		rsync -avz /etc/mysql/ssl/* root@$srv:/etc/mysql/ssl/ 2>/dev/null
		rsync -av /etc/mysql/mariadb.conf.d/99_minimal_ssl_config.cnf root@$srv:/etc/mysql/mariadb.conf.d/ 2>/dev/null
	done
}
# ------------------------------------------------------------------------------
# Description:
#   Shows the most recently modified files in the MySQL data directory.
#
# Arguments:
#   $1 - (Optional) The number of lines to show. Defaults to 20.
#
# Outputs:
#   - A sorted list of file modification timestamps and counts.
# ------------------------------------------------------------------------------
get_last_datadir_access()
{
	limit=${1:-"20"}
	datadir=$(global_variables datadir /var/lib/mysql)

	 sudo find $datadir -type f | xargs -n 1 sudo stat | grep "Modify: $(date +%Y-)" | perl -pe 's/Modify: //g;s/\.\d+ //g' | sort -n | uniq -c | tail -n $limit
}

# ------------------------------------------------------------------------------
# Description:
#   Searches the MySQL error log for common error/warning keywords.
#
# Arguments:
#   None
#
# Outputs:
#   - Writes matching log lines to stdout.
# ------------------------------------------------------------------------------
grep_error_log()
{
    grep -Ei '(err|warn|fat)' /var/log/mysql/mysqld.log
}

# ------------------------------------------------------------------------------
# Description:
#   Tails the MySQL error log file in the background.
#
# Arguments:
#   None
#
# Outputs:
#   - Runs `tail -f` as a background job.
# ------------------------------------------------------------------------------
tail_error_log()
{
	log_file="$(global_variables log_error)"

	[ -f "$log_file" ] && tail -f $log_file &
}

# ------------------------------------------------------------------------------
# Description:
#   Opens the MySQL error log file using `less`.
#
# Arguments:
#   None
#
# Outputs:
#   - An interactive `less` session.
# ------------------------------------------------------------------------------
less_error_log()
{
	log_file="$(global_variables log_error)"

	[ -f "$log_file" ] && less $log_file
}

# ------------------------------------------------------------------------------
# Description:
#   Generates an example multi-instance configuration file and initializes
#   the necessary data directories.
#
# Arguments:
#   None
#
# Outputs:
#   - Creates /etc/my.cnf.d/90_multi_config.cnf.
#   - Initializes data directories.
# ------------------------------------------------------------------------------
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

# ------------------------------------------------------------------------------
# Description:
#   Forcefully kills all `mysqld_safe` and `mariadbd` processes.
#
# Arguments:
#   None
#
# Outputs:
#   - None.
# ------------------------------------------------------------------------------
killall_mariadbd()
{
    ps -edf | grep [m]ysqld_safe | awk '{print $2}' | xargs -n1 kill -9
    ps -edf | grep [m]ariadbd | awk '{print $2}' | xargs -n1 kill -9
}

# ------------------------------------------------------------------------------
# Description:
#   Recovers a Galera cluster by setting the current node as safe_to_bootstrap
#   and initiating a `galera_new_cluster` command.
#
# Arguments:
#   None
#
# Outputs:
#   - Stops mysql, modifies grastate.dat, and starts a new cluster.
# ------------------------------------------------------------------------------
reset_quorum()
{
 systemctl stop mysql
 [ -f "/var/lib/mysql/grastate.dat" ] && perl -i -pe 's/safe_to_bootstrap: 0/safe_to_bootstrap: 1/g' /var/lib/mysql/grastate.dat
 galera_new_cluster
}
# ------------------------------------------------------------------------------
# Description:
#   Grants full root privileges to a user connecting from a specific remote IP.
#
# Arguments:
#   $1 - The remote IP address.
#
# Outputs:
#   - Executes CREATE USER and GRANT statements.
# ------------------------------------------------------------------------------
open_mariadb_root_from()
{
    local remoteIPv4=$1
    local pass=$(get_mariadb_root_password)
     echo "
 CREATE OR REPLACE USER 'root'@'$remoteIPv4' IDENTIFIED BY '$pass';
 GRANT ALL PRIVILEGES ON *.* TO 'root'@'$remoteIPv4';
     " | mysql -v
}

# ------------------------------------------------------------------------------
# Description:
#   Revokes root privileges for a user from a specific remote IP.
#
# Arguments:
#   $1 - The remote IP address.
#
# Outputs:
#   - Executes a DROP USER statement.
# ------------------------------------------------------------------------------
revoke_mariadb_root_from()
{
    local remoteIPv4=$1
     echo "DROP USER 'root'@'$remoteIPv4' ;" | mysql -v
}

# ------------------------------------------------------------------------------
# Description:
#   Extracts and displays SQL statements from a binary log file between specific positions.
#
# Arguments:
#   None (hardcoded positions)
#
# Outputs:
#   - Writes SQL statements to stdout.
# ------------------------------------------------------------------------------
binlog_sql()
{
    mysqlbinlog -j 387 --stop-position=890 --base64-output=decode-rows -vv mysqld-bin.000011 | perl -ne '/^[#\/]/ or print'
}

# ------------------------------------------------------------------------------
# Description:
#   Displays the status of standard (asynchronous) MySQL replication.
#
# Arguments:
#   None
#
# Outputs:
#   - Writes a formatted summary of the slave status and relevant variables.
# ------------------------------------------------------------------------------
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