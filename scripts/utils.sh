#!/bin/bash

if [ "$0" != "/bin/bash" -a "$0" != "/bin/sh" -a "$0" != "-bash" -a "$0" != "bash" -a "$0" != "-su" ]; then
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
[ -f '/etc/os-release' ] && source /etc/os-release

HA_SOCKET=/tmp/admin.sock

export PATH=$PATH:/opt/local/bin:/opt/local/MySQLTuner-perl:.

export my_private_ipv4=$(ip a | grep inet | grep '192.168'| cut -d/ -f1 | awk '{print $2}')
export my_public_ipv4=$(ip a | grep inet | grep '10.'| cut -d/ -f1 | awk '{print $2}')

export DEBIAN_FRONTEND=noninteractive

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
    read -p "$1 ([y]es or [n]o): "
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
my_status()
{
    local lRC=0
    mysqladmin ping &>/dev/null
    lRC=$?
    [ $lRC -eq 0 ] && ok "mysql server is running ...."
    [ $lRC -eq 0 ] || error "mysql server is stopped ...."
    return $lRC
}

db_list()
{
   mysql -Nrs -e 'show databases'
}

db_users()
{
    mysql -Nrs -e 'select user, host from mysql.user' mysql| sort -k${1:-"1"} | column -t
}

db_tables()
{
    mysql -Nrs -e 'show tables' ${1:-"mysql"}
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

global_variables()
{
    res=$(mysql -Nrs -e "show global variables like '$1'" | perl -pe 's/^.*?\s+(.*)$/$1/')

    [ -z "$res" -a -n "$2" ] && res="$2"
    echo -n $res
}

global_status()
{
    mysql -Nrs -e "show global status like '$1'"| perl -pe 's/^.*?\s+(.*)$/$1/'
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

rl()
{
    [ -f "/etc/profile.d/utils.sh" ] && source /etc/profile.d/utils.sh
    chsh -s /bin/bash root
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
    ssh_cmd $lsrv "mkdir -p /opt/local/bin"
    ssh_copy $lsrv $_DIR/scripts/bin /opt/local root 755
    ssh_cmd $lsrv "chmod -R 755 /opt/local/bin"
}

lUpdateScript()
{
    _DIR=/root/dbscripts
    rsync -av $_DIR/scripts/utils.sh /etc/profile.d/utils.sh
    chown root.root /etc/profile.d/utils.sh
    chmod 755 /etc/profile.d/utils.sh
    [ -d "/opt/local/bin" ] && mkdir -p /opt/local/bin
    rsync -av $_DIR/scripts/bin /opt/local/
    chown -R root.root /opt/local/bin
    chmod -R 755 /opt/local/bin
}

copy_rc()
{

	for srv in $(grep node_addresses= /etc/bootstrap.conf| cut -d= -f2 | tr ',' ' ' ) ;do
		[ "$my_private_ipv4" == "$srv" ] && continue
		info "COPYING /etc/bootstrap.conf TO $srv"
		rsync -avz /etc/bootstrap.conf root@$srv:/etc 2>/dev/null
		info "COPYING /root/.my.cnf TO $srv"
		rsync -avz /root/.my.cnf root@$srv:/root 2>/dev/null
	done
}
get_last_datadir_access()
{
	limit=${1:-"20"}
	datadir=$(global_variables datadir /var/lib/mysql)

	 sudo find $datadir -type f | xargs -n 1 sudo stat | grep "Modify: $(date +%Y-)" | perl -pe 's/Modify: //g;s/\.\d+ //g' | sort -n | uniq -c | tail -n $limit
}

tail_error_log()
{
	log_file="$(global_variables log_error)"

	[ -f "$log_file" ] && tail -f $log_file &
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


#----------------------------------------------------------------------------------------------------
# Create the logical volume and the file system
#----------------------------------------------------------------------------------------------------

createLogicalVolume() {
    vg=$1
    lv=$2
    lvsize=$3
    lvuser=$4
    lvhome=$5
    lvfstype=${6:-"ext4"}
    lvdisplay /dev/${vg}/${lv} &>/dev/null
    if [ $? -eq 0 ]; then
        echo "THE LOGICAL VOLUME /dev/${vg}/${lv} HAS BEEN ALREADY CREATED"
        return 1
    fi

    echo "CREATING LOGICAL VOLUME /dev/${vg}/${lv} (SIZE : ${lvsize}) ..."
    mkdir -p ${lvhome}

    if $(grep -q "%" <<< "${lvsize}")
    then
        lvcreate -L${lvsize} -n ${lv} ${vg}
    else
        lvcreate -l${lvsize} -n ${lv} ${vg}
    fi

    mkfs.${lvfstype} /dev/${vg}/${lv}
    mount /dev/${vg}/${lv} ${lvhome}
    chown ${lvuser}: ${lvhome}
    chmod 755 ${lvhome}

    # Options de montage
    if $(grep -q "/home\|/tmp\|/var/log/audit" <<< "${lvhome}")
    then
        option="${lvfstype}    nosuid,nodev,noexec        0       2"
    elif $(grep -q "/var" <<< "${lvhome}")
    then
        option="${lvfstype}    nosuid,nodev        0       2"
        if $(grep -q "/var/log" <<< "${lvhome}")
        then
            option="${lvfstype}    defaults        0       2"
        fi

    fi

    [ `grep -c "^/dev/${vg}/${lv}" /etc/fstab` = 0 ] && \
    echo "/dev/${vg}/${lv}        ${lvhome}       ${option}">>/etc/fstab

    lvdisplay /dev/${vg}/${lv} &>/dev/null
    if [ $? -ne 0 ]; then
        echo "[ERROR] CREATE LOGICAL VOLUME /dev/${vg}/${lv} : NOK"
        return 1
    fi

    echo "[INFO] CREATE LOGICAL VOLUME /dev/${vg}/${lv} : OK"
    return 0
}

# Some Alias
alias h=history
alias s=sudo
alias rsh='ssh -l root'
alias lh='ls -lsh'
alias ll='ls -ls'
alias la='ls -lsa'

alias gst='git status'
alias grm='git rm -f'
alias gadd='git add'
alias gcm='git commit -m'
alias gps='git push'
alias gpl='git pull'
alias glg='git log'
alias gmh='git log --follow -p --'
alias gbl='git blame'
alias grs='git reset --soft HEAD~1'
alias grh='git reset --hard HEAD~1'

which python &>/dev/null
if [ $? -eq 0 ]; then
    alias serve="python -m $(python -c 'import sys; print("http.server" if sys.version_info[:2] > (2,7) else "SimpleHTTPServer")')"
else
    alias serve="python3 -m $(python3 -c 'import sys; print("http.server" if sys.version_info[:2] > (2,7) else "SimpleHTTPServer")')"
fi

gunt() {
    git status | \
    grep -vE '(Changes to be committed:| to publish your local commits|git add|git restore|On branch|Your branch|Untracked files|nclude in what will b|but untracked files present|no changes added to commit|modified:|deleted:|Changes not staged for commit)' |\
    sort | uniq | \
    xargs -n 1 $*
}

gam() {
    git status | \
    grep 'modified:' | \
    cut -d: -f2- | \
    sort | uniq | \
    xargs -n 1 git add
}

gad() {
    git status | \
    grep 'deleted:' | \
    cut -d: -f2- | \
    sort | uniq | \
    xargs -n 1 git rm -f
}
