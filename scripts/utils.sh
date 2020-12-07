#!/bin/sh

if [ "$0" != "/bin/bash" -a "$0" != "/bin/sh" -a "$0" != "-bash" -a "$0" != "bash" ]; then
	_DIR="$(dirname "$(readlink -f "$0")")"
	_NAME="$(basename "$(readlink -f "$0")")"
	_CONF_FILE=$(readlink -f "${_DIR}/../etc/$(basename ${_NAME} .sh).conf")
	if [ -f "$_CONF_FILE" ];then
		source $_CONF_FILE
	else
		mkdir -p $(dirname "$_CONF_FILE")
		echo "# Config for $_NAME SCRIPT at $(date)" | tee -a $_CONF_FILE
	fi
else
	_DIR="$(readlink -f ".")"
	_NAME="INLINE SHELL"
fi
HA_SOCKET=/tmp/admin.sock

export PATH=$PATH:/opt/local/bin:/opt/local/MySQLTuner-perl:.

export my_private_ipv4=$(ip a | grep inet | grep '192.168'| cut -d/ -f1 | awk '{print $2}')
export my_public_ipv4=$(ip a | grep inet | grep '10.'| cut -d/ -f1 | awk '{print $2}')


is() {
    if [ "$1" == "--help" ]; then
        cat << EOF
Conditions:
  is equal VALUE_A VALUE_B
  is matching REGEXP VALUE
  is substring VALUE_A VALUE_B
  is empty VALUE
  is number VALUE
  is gt NUMBER_A NUMBER_B
  is lt NUMBER_A NUMBER_B
  is ge NUMBER_A NUMBER_B
  is le NUMBER_A NUMBER_B
  is file PATH
  is dir PATH
  is link PATH
  is existing PATH
  is readable PATH
  is writeable PATH
  is executable PATH
  is available COMMAND
  is older PATH_A PATH_B
  is newer PATH_A PATH_B
  is true VALUE
  is false VALUE
  is fowner PATH USER
  is fgroup  PATH GROUP
  is fmountpoint PATH MOUNTPOINT
  is fempty PATH
  is fsize PATH BYTE_SIZE
  is fsizelt PATH$path BYTE_SIZE
  is fsizegt PATH$path BYTE_SIZE
  is forights PATH OCTALRIGHTS
  is fuser USER
  is tcp_port PORTNUMBER

Negation:
  is not equal VALUE_A VALUE_B

Optional article:
  is not a number VALUE
  is an existing PATH
  is the file PATH
EOF
        exit
    fi

    if [ "$1" == "--version" ]; then
        echo "is.sh 1.1.0"
        exit
    fi

    local condition="$1"
    local value_a="$2"
    local value_b="$3"

    if [ "$condition" == "not" ]; then
        shift 1
        ! is "${@}"
        return $?
    fi

    if [ "$condition" == "a" ] || [ "$condition" == "an" ] || [ "$condition" == "the" ]; then
        shift 1
        is "${@}"
        return $?
    fi

    case "$condition" in
        file)
            [ -f "$value_a" ]; return $?;;
        dir|directory)
            [ -d "$value_a" ]; return $?;;
        link|symlink)
            [ -L "$value_a" ]; return $?;;
        existent|existing|exist|exists)
            [ -e "$value_a" ]; return $?;;
        readable)
            [ -r "$value_a" ]; return $?;;
        writeable)
            [ -w "$value_a" ]; return $?;;
        executable)
            [ -x "$value_a" ]; return $?;;
        available|installed)
            which "$value_a"; return $?;;
        tcp_port_open|tcp_port|tport)
            netstat -ltn | grep -E ":${value_a}\s" | grep -q 'LISTEN'; return $?;;
        fowner|fuser)
            [ "$(stat -c %U $value_a)" = "$value_b" ]; return $?;;
        fgroup)
            [ "$(stat -c %G $value_a)" = "$value_b" ]; return $?;;
        fmountpoint)
            [ "$(stat -c %m $value_a)" = "$value_b" ]; return $?;;
        fempty)
            [ "$(stat -c %s $value_a)" = "0" ]; return $?;;
        fsize)
            [ $(stat -c %s $value_a) -eq $value_b ]; return $?;;
        fsizelt)
            [ $(stat -c %s $value_a) -lt $value_b ]; return $?;;
        fsizegt)
            [ $(stat -c %s $value_a) -gt $value_b ]; return $?;;
        forights)
            [ "$(stat -c %a $value_a)" = "$value_b" ]; return $?;;
        fagegt)
			[ $(fileAge $value_a) -gt $value_b ]; return  $?;;
        fagelt)
			[ $(fileAge $value_a) -lt $value_b ]; return  $?;;
        fmagegt)
			[ $(fileMinAge $value_a) -gt $value_b ]; return  $?;;
        fmagelt)
			[ $(fileMinAge $value_a) -lt $value_b ]; return  $?;;
        fhagegt)
			[ $(fileHourAge $value_a) -gt $value_b ]; return  $?;;
        fhagelt)
			[ $(fileHourAge $value_a) -lt $value_b ]; return  $?;;
        fdagegt)
			[ $(fileDayAge $value_a) -gt $value_b ]; return  $?;;
        fdagelt)
			[ $(fileDayAge $value_a) -lt $value_b ]; return  $?;;
        fcontains)
			shift;
			grep -q "$*" $value_a
			return  $?
			;;
        user)
            is eq $(whoami) $value_a; return $?;;
        empty)
            [ -z "$value_a" ]; return $?;;
        number)
            echo "$value_a" | grep -E '^[0-9]+(\.[0-9]+)?$'; return $?;;
        older)
            [ "$value_a" -ot "$value_b" ]; return $?;;
        newer)
            [ "$value_a" -nt "$value_b" ]; return $?;;
        gt)
            is not a number "$value_a"      && return 1;
            is not a number "$value_b"      && return 1;
            awk "BEGIN {exit $value_a > $value_b ? 0 : 1}"; return $?;;
        lt)
            is not a number "$value_a"      && return 1;
            is not a number "$value_b"      && return 1;
            awk "BEGIN {exit $value_a < $value_b ? 0 : 1}"; return $?;;
        ge)
            is not a number "$value_a"      && return 1;
            is not a number "$value_b"      && return 1;
            awk "BEGIN {exit $value_a >= $value_b ? 0 : 1}"; return $?;;
        le)
            is not a number "$value_a"      && return 1;
            is not a number "$value_b"      && return 1;
            awk "BEGIN {exit $value_a <= $value_b ? 0 : 1}"; return $?;;
        eq|equal)
            [ "$value_a" = "$value_b" ]     && return 0;
            is not a number "$value_a"      && return 1;
            is not a number "$value_b"      && return 1;
            awk "BEGIN {exit $value_a == $value_b ? 0 : 1}"; return $?;;
        match|matching)
            echo "$value_b" | grep -xE "$value_a"; return $?;;
        substr|substring)
            echo "$value_b" | grep -F "$value_a"; return $?;;
        true)
            [ "$value_a" == true ] || [ "$value_a" == 0 ]; return $?;;
        false)
            [ "$value_a" != true ] && [ "$value_a" != 0 ]; return $?;;
    esac > /dev/null

    return 1
}

now() {
    # echo "$(date "+%F %T %Z")"
    echo "$(date "+%F %T %Z")($(hostname -s))"
}

error() {
    local lRC=$?
    echo "$(now) ERROR: $*" 1>&2
    [ -n "$TEE_LOG_FILE" ] && echo "$(now) ERROR: $*">>$TEE_LOG_FILE
    return $lRC
}

die() {
    error $*
    exit 1
}

info() {
    [ "$quiet" != "yes" ] && echo "$(now) INFO: $*" 1>&2
    [ -n "$TEE_LOG_FILE" ] && echo "$(now) INFO: $*">>$TEE_LOG_FILE
    return 0
}

ok()
{
    info "[SUCCESS]  $*  [SUCCESS]"
    return $?
}

warn() {
	local lRC=$?
    echo "$(now) WARNING: $*" 1>&2
    [ -n "$TEE_LOG_FILE" ] && echo "$(now) WARNING: $*">>$TEE_LOG_FILE
    return $lRC
}

warning()
{
    warn "$*"
}
sep1()
{
    echo "$(now) -----------------------------------------------------------------------------" 1>&2
    [ -n "$TEE_LOG_FILE" ] && echo "$(now) -----------------------------------------------------------------------------" >>$TEE_LOG_FILE
}
sep2()
{
    echo "$(now) _____________________________________________________________________________" 1>&2
    [ -n "$TEE_LOG_FILE" ] && echo "$(now) _____________________________________________________________________________" >>$TEE_LOG_FILE
}
title1() {
    sep1
	echo "$(now) $*" 1>&2
	[ -n "$TEE_LOG_FILE" ] && echo "$(now) $*">>$TEE_LOG_FILE
	sep1
}

title2()
{
    echo "$(now) $*" 1>&2
    [ -n "$TEE_LOG_FILE" ] && echo "$(now) $*">>$TEE_LOG_FILE
    sep2
}
banner()
{
	title1 "START: $*"
	info " run as $(whoami)@$(hostname -s)"
}

footer()
{
    local lRC=${lRC:-"$?"}

    [ $lRC -eq 0 ] && title1 "END: $* ENDED SUCCESSFULLY"
    [ $lRC -eq 0 ] || title1 "END: $* ENDED WITH WARNING OR ERROR"
    return $lRC
}

cmd()
{
	local cRC=0
	local tcmd="$1"
	local descr=${2:-"$tcmd"}
	if [ -z "$2" ]; then
		title1 "RUNNING COMMAND: $tcmd"
	else
		title1 "$descr"
		info "RUNNING COMMAND: $tcmd"
		sep1
	fi
	$tcmd
	cRC=$?
	info "RETURN CODE: $cRC"
	if [ $cRC -eq 0 ]; then
		ok "$descr"
	else
		error "$descr"
	fi
	sep1
	return $cRC
}

function ask_yes_or_no() {
    read -p "$1 ([y]es or [N]o): "
    case $(echo $REPLY | tr '[A-Z]' '[a-z]') in
        y|Y|yes) echo "yes";return 0 ;;
        *)     echo "no"; return 1;;
    esac
    return 1
}

pgGetVal()
{
	local value=$1
	echo $(eval "echo \$${value}")
}

pgSetVal()
{
	local var=$1
	shift
	eval "${var}='$*'"
}

tlog()
{
    tail  -f /var/lib/mysql/mysqld.log &
}


## Code MariaDB

db_list()
{
   mysql -Nrs -e 'show databases'
}

db_tables()
{
    mysql -Nrs -e 'show tables' ${1:-"mysql"}
}

db_users()
{
	mysql -Nrs -e 'select user, host from mysql.user' mysql| sort -k${1:-"1"} | column -t
}

db_count()
{
    for tbl in $(db_tables ${1:-"mysql"}); do
        echo -ne "$tbl\t"
        mysql -Nrs -e "select count(*) from $tbl" ${1:-"mysql"}
    done | sort -nr -k2 | column -t
}

galera_status()
{
    title1 "WSREP STATUS"
    mysql -e "select * from information_schema.wsrep_status\G"
    title1 "WSREP MEMBER"
    mysql -e "select * from information_schema.wsrep_membership;"
    title1 "WSREP GLOBAL STATUS"
}

my_cluster_state() {
(
mysql -e "show status like '%wsrep%'"
mysql -e "show variables like 'auto%'"
mysql -e "show variables like 'wsrep_%'"
) |grep -v wsrep_provider_options|| grep -E '(wsrep_last_committed|wsrep_node|wsrep_flow|wsresp_cluster_a|cluster_status|connected|ready|state_comment|cluster_size|state_uuid|conf|wsrep_cluster_name|auto_)'| \
sort | column -t
}

node_cluster_state()
{
    node=$1
    param=$2
    ssh -q $node "source /etc/profile.d/utils.sh;my_cluster_state" | grep $param | awk '{print $2}'
}

sql_1hour()
{
    mysqlbinlog --start-datetime "$(date --date '1 hour ago' +'%Y-%m-%d %T')" mysqld-bin.0000*
}

generate_sql_load()
{
    mysqlslap --auto-generate-sql --verbose --concurrency=50 --iterations=10
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

provider_var()
{
    mysql -Nrs -e "show global variables like 'wsrep_provider_options'" | \
    perl -pe 's/wsrep_provider_options//g;s/; /\n/g;s/ = /\t/g'| sort | column -t
}

galera_is_enabled()
{
	local var_wsrep_on="$(mysql -Nrs -e "show global variables like 'wsrep_on';"|awk '{print $2}'| xargs -n1)"
	if [ "$var_wsrep_on" = "ON" ]; then
		echo "1"
		return 0
	fi
	echo "0"
	return 0
}

galera_members()
{
    mysql -Nrs -e "SELECT NAME FROM information_schema.wsrep_membership WHERE NAME<>'garb';"
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
wsrep_ready"

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
	ret="$(mysql -Nrs -h$my_private_ipv4 -u $1 -p$2 -e 'select 1' mysql 2>&1)"
	awa="1"

	if [ "$ret" = "$awa" ]; then
		[ "$3" != "silent" ] && info "PASSWORD FROM '$1' USER IS CORRECT."
		return 0
	fi
	[ "$3" != "silent" ] && error "PASSWORD FROM '$1' IS INCORRECT."
	return 1
}

rl()
{
    [ -f "/etc/profile.d/utils.sh" ] && source /etc/profile.d/utils.sh
}

last_state_changes()
{
    tac /tmp/galera.notif.txt |head -n 15
}

ha_status()
{
    local param=${1:-"info"}
    echo "show $param" |  socat unix-connect:$HA_SOCKET stdio
}
ha_states()
{
   (echo -e "NAME TYPE STATE"
    echo "show stat" |  socat unix-connect:$HA_SOCKET stdio| cut -d, -f1,2,18 | tr ',' '\t'| sort -k 3| grep -ve '^#'
    )|column -t
}
ha_disable()
{
    echo "disable server ${1:-"galera/node1"}" |  socat unix-connect:$HA_SOCKET stdio
}
ha_enable()
{
    echo "enable server ${1:-"galera/node1"}" |  socat unix-connect:$HA_SOCKET stdio
}

ssh_exec()
{
    local lsrv=$1
    local lRC=0
    shift


    for fcmd in $*; do
        if [ ! -f "$fcmd" ]; then
            error "$fcmd Not exists"
            return 127
        fi
        INTERPRETER=$(head -n 1 $fcmd | sed -e 's/#!//')

        for srv in $(echo $lsrv | perl -pe 's/[, :]/\n/g'); do
            title2 "RUNNING SCRIPT $(basename $fcmd) ON $srv SERVER"
            (echo "[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh";echo;cat $fcmd) | grep -v "#!" | ssh -T root@$srv -i ${DEFAULT_PRIVATE_KEY:-"/root/.ssh/id_rsa"} $INTERPRETER
            footer "RUNNING SCRIPT $(basename $fcmd) ON $srv SERVER"
            lRC=$(($lRC + $?))
        done
    done
    return $lRC
}

ssh_cmd()
{
    local lsrv=$1
    local lRC=0
    local fcmd=$2
    local silent=$3

    for srv in $(echo $lsrv | perl -pe 's/[, :]/\n/g'); do
        [ -z "$silent" ] && title2 "RUNNING SCRIPT $fcmd ON $srv($vip) SERVER"
        [ -n "$silent" ] && echo -ne "$srv\t$fcmd\t"
        ssh -T root@$srv -i ${DEFAULT_PRIVATE_KEY:-"/root/.ssh/id_rsa"} "$fcmd"
        lRC=$(($lRC + $?))
        [ -n "$silent" ] && echo
        [ -z "$silent" ] && footer "RUNNING SCRIPT $fcmd ON $srv($vip) SERVER"
    done
    return $lRC
}

ssh_copy()
{
    local lsrv=$1
    local fsource=$2
    local fdest=$3
    local own=$4
    local mode=$5
    local lRC=0

    if [ ! -f "$fsource" -a ! -d "$fsource" ]; then
        error "$fsource Not exists"
        return 127
    fi
    for srv in $(echo $lsrv | perl -pe 's/[, :]/\n/g'); do
        rsync -avz  -e "ssh -i ${DEFAULT_PRIVATE_KEY:-"/root/.ssh/id_rsa"}" $fsource root@$srv:$fdest
        lRC=$(($lRC + $?))

        [ -z "$own" ] || ssh_cmd $srv "chown -R $own:$own $fdest" silent
        lRC=$(($lRC + $?))
        [ -z "$mode" ] || ssh_cmd $srv "chmod -R $mode $fdest" silent
        lRC=$(($lRC + $?))

        [ -z "$silent" ] && footer "RUNNING SCRIPT $fcmd ON $srv SERVER"
        lRC=$(($lRC + $?))
    done
    return $lRC
}

updateScript()
{
	local lsrv=${1}
	_DIR=/root/dbscripts
	ssh_copy $lsrv $_DIR/scripts/utils.sh /etc/profile.d/utils.sh root 644
	ssh_copy $lsrv $_DIR/scripts/bin /opt/local root 755
    ssh_cmd $lsrv "chmod -R 755 /opt/local/bin"
}
