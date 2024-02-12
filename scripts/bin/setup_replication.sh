#!/bin/bash

target=${1:-"c4mysql3"}
muser=replication
morigin='%'

mpass=$(grep password $HOME/.my.cnf | cut -d= -f2)
ssh_cmd="ssh -q root@$target"
mhost=$(ping -c 1 $(hostname -s)| grep PING| perl -pe 's/.*?\((.*?)\).*/$1/g')
_title="$0 $@"
############################
# LOGGING FUNTIONS
############################
#exec 3>&2 # logging stream (file descriptor 3) defaults to STDERR
verbosity=5 # default to show warnings

case "$LEVEL" in
    silent|SILENT)
        verbosity=0
        ;;
    crit|CRIT|critical|CRITICAL)
        verbosity=1
        ;;
    err|ERR|error|ERROR)
        verbosity=2
        ;;
    warn|WARN|warning|WARNING)
        verbosity=3
        ;;
    info|INFO)
        verbosity=4
        ;;
    debug|DEBUG)
        verbosity=5
        ;;
    *)
        verbosity=5
        ;;
esac

    silent_lvl=0
crt_lvl=1
err_lvl=2
wrn_lvl=3
inf_lvl=4
dbg_lvl=5

silent_lvl=0
crt_lvl=1
err_lvl=2
wrn_lvl=3
inf_lvl=4
dbg_lvl=5

sep1()
{
    info '##########################################################'
}
sep2()
{
    info '----------------------------------------------------------'
}
title() {
    sep1
    info $@
    sep1
}
subtitle()
{
    sep2
    info $@
    sep2
}
banner()
{
    title "BEGIN OF $_title"
}
end()
{
    local lRC=$1
    title "END OF $_title - RC: $lRC"
    [ $lRC -eq 0 ] && ok "Script completed($lRC) at $(date +'%Y-%m-%d %H:%M:%S')"
    [ $lRC -eq 0 ] || fail "Script failed($lRC) at $(date +'%Y-%m-%d %H:%M:%S')"

    exit $lRC
}
notify()   { log $silent_lvl "NOTE : $@"; } # Always prints
critical() { log $crt_lvl    "CRIT : $@"; }
error()    { log $err_lvl    "ERROR: $@"; }
warn()     { log $wrn_lvl    "WARN : $@"; }
outwarn()  { log $wrn_lvl    "OUTWA: $@"; }
info()     { log $inf_lvl    "INFO : $@"; } # "info" is already a command
mcmd()     { log $inf_lvl    "CMD  : $@"; }
debug()    { log $dbg_lvl    "DEBUG: $@"; }
output()   { log $dbg_lvl    "OUT  : $@"; }
ok()       { log $inf_lvl    "OK   : $@"; }
fail()     { log $inf_lvl    "ERROR: $@"; }
log_err_log()
{
    l=$1
    t=${2:-"local"}
    grep -iE '(err|warn)' $l | while IFS= read -r line
    do
          outwarn "($t) $line"
    done
}

log_log()
{
    [ $verbosity -lt $dbg_lvl ] && return
    local l=$1
    local t=${2:-"local"}
    cat $l | while IFS= read -r line
    do
          output "($t) $line"
    done
}

log() {
    [ $verbosity -ge $1 ] ||return
    shift
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') $*" | sed '2~1s/^/  /'
}

cmd() {
    mcmd "(local) $@"
    l=$(mktemp)
    [ $verbosity -ge $dbg_lvl ] && set -x
    $@ &>$l
    lRC=$?
    set +x
    log_log $l
    log_err_log $l
    rm -f $l

    [ $lRC -eq 0 ] && ok "(local) Command completed: $@"
    [ $lRC -eq 0 ] || fail "(local) Command failed: $@"
    sep2
    return $lRC
}


cmd_die()
{
    cmd "$@"
    lRC=$?
    [ $lRC -ne 0 ] && end $lRC
}

scmd()
{
    mcmd "($target) $@"
    l=$(mktemp)
    $ssh_cmd "$@" &>$l
    lRC=$?
    log_log $l $target
    log_err_log $l $target
    rm -f $l
    [ $lRC -eq 0 ] && ok "($target) Command completed: $@"
    [ $lRC -eq 0 ] || fail "($target) Command failed: $@"
    sep2
    return $lRC
}


mysql_cmd()
{
    mcmd "(local) MYSQL EXEC: $(cat $1)"
    l=$(mktemp)
    cat $1 | mysql -f &>$l
    lRC=$?
    log_log $l
    [ -z "$NO_WARN" ] && log_err_log $l
    rm -f $l

    [ $lRC -eq 0 ] && ok "(local) SQL exec completed: $@"
    [ $lRC -eq 0 ] || fail "(local) SQL exec failed: $@"
    sep2
    return $lRC
}

mysql_scmd()
{
    mcmd "($target) MYSQL EXEC: $(cat $1)"
    l=$(mktemp)
    cat $1 | $ssh_cmd "mysql -f" &>$l
    lRC=$?
    log_log $l $target
    [ -z "$NO_WARN" ] && log_err_log $l $target
    rm -f $l
    [ $lRC -eq 0 ] && ok "($target) SQL exec completed: $@"
    [ $lRC -eq 0 ] || fail "($target) SQL exec failed: $@"
    sep2
    return $lRC
}

scmd_die()
{
    scmd "$@"
    lRC=$?
    [ $lRC -ne 0 ] && end $lRC
}


# Check some parameters

check_params()
{

    mparams="server_id report_host logbin log_basename relaylog log_slave_updates read_only gtid_mode"


    checkMysqlTarget
    if [ $? -eq 0 ]; then
        subtitle "PARAMETERS MYSQL ON $target"
        (
        for param in $mparams; do
            echo "show global variables like '$param'" |$ssh_cmd mysql -Nrs
        done
        ) | column -t
    fi

    subtitle "LOCAL PARAMETERS MYSQL"

    (
    for param in $mparams; do
        echo "show global variables like '$param'" |mysql -Nrs
    done
    ) | column -t
    sep2
}

preRepli()
{
subtitle "INSTALLING LOCAL PACKAGES"
cmd "sudo yum -y remove percona-xtrabackup percona-release"
cmd "rm -f percona-release-latest.noarch.rpm"
cmd "curl -k -O https://repo.percona.com/yum/percona-release-latest.noarch.rpm"
cmd "rpm -qpi percona-release-latest.noarch.rpm"
cmd "sudo yum -y install percona-release-latest.noarch.rpm"
cmd "sudo yum -y install percona-xtrabackup-80 qpress rsync policycoreutils-python percona-toolkit"
cmd "sudo setenforce 0"

subtitle "INSTALLING REMOTE $target PACKAGES"
scmd "yum -y remove percona-xtrabackup  percona-release"
scmd "rm -f percona-release-latest.noarch.rpm"
scmd "curl -k -O https://repo.percona.com/yum/percona-release-latest.noarch.rpm"
scmd "rpm -qpi percona-release-latest.noarch.rpm"
scmd "sudo yum -y install percona-release-latest.noarch.rpm"
scmd "rm -f percona-release-latest.noarch.rpm"
scmd "sudo yum -y install percona-xtrabackup-80 qpress rsync policycoreutils-python percona-toolkit"
scmd "sudo setenforce 0"

subtitle "SYNCHRONIZING CREDENTIALS ON $target"
cmd_die "rsync -av $HOME/.my.cnf root@$target:"


subtitle "UNLOCK LOCAL LINUX FIREWALL"
cmd "sudo /sbin/iptables --flush"
cmd "sudo /usr/sbin/iptables-save"

subtitle "UNLOCK $target LINUX FIREWALL"
scmd "/sbin/iptables --flush"
scmd "/usr/sbin/iptables-save"
}

createRepliUser()
{
subtitle "CREATING LOCAL REPLICATION MYSQL USER"
tsql=$(mktemp)
echo "DROP USER IF EXISTS '$muser'@'$morigin';
CREATE USER '$muser'@'$morigin' IDENTIFIED WITH mysql_native_password BY '$mpass';
GRANT REPLICATION SLAVE ON *.* TO '$muser'@'$morigin';" > $tsql
log_log $tsql
mysql_cmd $tsql
}

createAdminUser()
{
subtitle "CREATING LOCAL MYSQL USER $1"
tsql=$(mktemp)
echo "DROP USER IF EXISTS '$1'@'$2';
CREATE USER '$1'@'$2' IDENTIFIED WITH mysql_native_password BY '$3';
GRANT ALL ON *.* TO '$1'@'$2';" > $tsql
log_log $tsql
mysql_cmd $tsql
}


setupRepli()
{
    case "$1" in
        xtrabackup|xtra)
            cloneXtrabackup
            setGtid
            setupRepliXtra
            ;;
        mysqldump|dump)
            setupRepliDump
            ;;
        *)
            error "Error unknown replication method: $1"
            end 128
            ;;
    esac
}

execTargetSql()
{
    tsql=$(mktemp)
    echo "$@" > $tsql
    log_log $tsql
    rsync -av $tsql root@$target:$tsql &>/dev/null
    mysql_scmd $tsql
    lRC=$?
    rm -f $tsql
    scmd "rm -f $tsql"
    return $lRC
}
execLocalSql()
{
    tsql=$(mktemp)
    echo "$@" > $tsql
    mysql_cmd  $tsql
    lRC=$?
    rm -f $tsql
    return $lRC
}

cleanSlaveRepli()
{
    execTargetSql 'STOP SLAVE; RESET SLAVE;'
    return $?
}

setupRepliDump()
{
    checkMysqlTarget
    [ $? -ne 0 ] && end 127
    mysqldump --master-data --single-transaction --opt --all-databases \
--triggers --routines --events --set-gtid-purged=OFF --add-drop-database | \
perl -pe "s/CHANGE MASTER TO /CHANGE MASTER TO MASTER_HOST='$mhost', MASTER_USER='$muser', MASTER_PASSWORD='$mpass', /g" \
| $ssh_cmd mysql -uroot -f


execTargetSql "START SLAVE"
}

setGtid()
{
NO_WARN=1 execLocalSql "SET @@GLOBAL.ENFORCE_GTID_CONSISTENCY = WARN; \
SET @@GLOBAL.ENFORCE_GTID_CONSISTENCY = ON; \
SET @@GLOBAL.GTID_MODE = OFF_PERMISSIVE; \
SET @@GLOBAL.GTID_MODE = ON_PERMISSIVE; \
SHOW STATUS LIKE 'ONGOING_ANONYMOUS_TRANSACTION_COUNT'; \
SET @@GLOBAL.GTID_MODE = ON;"

subtitle "GTID MODE LOCAL"
echo "SHOW GLOBAL VARIABLES LIKE 'gtid%'" | mysql | column -t


NO_WARN=1 execTargetSql "SET @@GLOBAL.ENFORCE_GTID_CONSISTENCY = WARN; \
SET @@GLOBAL.ENFORCE_GTID_CONSISTENCY = ON; \
SET @@GLOBAL.GTID_MODE = OFF_PERMISSIVE; \
SET @@GLOBAL.GTID_MODE = ON_PERMISSIVE; \
SHOW STATUS LIKE 'ONGOING_ANONYMOUS_TRANSACTION_COUNT'; \
SET @@GLOBAL.GTID_MODE = ON;"

subtitle "GTID MODE ON $target"
echo "SHOW GLOBAL VARIABLES LIKE 'gtid%'" | $ssh_cmd mysql | column -t

}
cloneXtrabackup()
{
    scmd "systemctl stop mysqld"
    scmd "rm -Rf /var/lib/mysql;mkdir /var/lib/mysql"
    [ $? -eq 0 ] || end 1
    sep2
    mcmd "(local -> $target) STREAMING BACKUP ..."
    tres=$(mktemp)
    (sudo xtrabackup --backup --compress --compress-threads=$(nproc) --user=$muser --password=$mpass --stream=xbstream --target-dir=./ | $ssh_cmd "cd /var/lib/mysql;xbstream -x") &>$tres
    [ $? -eq 0 ] || end 2

    log_log $tres
    log_err_log $tres

    grep -q "completed OK!" $tres
    if [ $? -eq 0 ]; then
        ok "Message completed OK!"
    else
        fail "Message completed OK! IS MISSING"
        end 2
    fi
    rm -f $tres
    mcmd "(local -> $target) command completed: STREAMING BACKUP ..."
    sep2

    scmd "xtrabackup --decompress --compress-threads=$(nproc) --remove-original --target-dir=/var/lib/mysql"
    [ $? -eq 0 ] || exit 3
    scmd "xtrabackup --prepare --target-dir=/var/lib/mysql"
    [ $? -eq 0 ] || exit 4

    scmd "chown -R mysql.mysql /var/lib/mysql"
    [ $? -eq 0 ] || exit 5
    scmd "systemctl daemon-reload"
    [ $? -eq 0 ] || exit 6
    scmd "systemctl start mysqld"
}

setupRepliXtra()
{
    scmd "cat /var/lib/mysql/xtrabackup_binlog_info"
    execTargetSql "CHANGE MASTER TO MASTER_HOST='$mhost', MASTER_USER='$muser', MASTER_PASSWORD='$mpass';"
    scmd "cat /var/lib/mysql/xtrabackup_binlog_info"
    mfile=$($ssh_cmd "awk '{ print \$1 }' /var/lib/mysql/xtrabackup_binlog_info")
    mpos=$($ssh_cmd "awk '{ print \$2 }' /var/lib/mysql/xtrabackup_binlog_info")
    info "REPLICATION FILE    : $mfile"
    info "REPLICATION POSITION: $mpos"
    #echo "CHANGE MASTER TO MASTER_LOG_FILE='$mfile', MASTER_LOG_POS=$mpos" | $ssh_cmd mysql -v -f
    info "USING AUTO POSITION WITH GTID_MODE=ON"
    execTargetSql "CHANGE MASTER TO MASTER_AUTO_POSITION = 1"
    execTargetSql "START SLAVE"
}

testRepli()
{

execLocalSql "DROP DATABASE IF EXISTS replitest"

subtitle "TEST CREATION ET REPLICATION DE LA BASE replitest"
execLocalSql "CREATE DATABASE replitest"
sleep 1s
checkRepli

echo "show databases" | $ssh_cmd mysql -Nrs | grep -q "replitest"
if [ $? -eq 0 ]; then
    ok "Test repli create ok"
    sep2
else
    fail "Test repli create fail"
    sep2
    return 1
fi

subtitle "TEST CREATION ET REPLICATION DE LA BASE replitest"
execLocalSql "DROP DATABASE replitest"
sleep 1s
checkRepli

echo "show databases" | $ssh_cmd mysql -Nrs -f| grep -q "replitest"
if [ $? -ne 0 ]; then
    ok "Test repli drop ok"
    sep2
else
    fail "Test repli drop fail"
    sep2
    return 2
fi
}

checkRepli()
{
    echo "SHOW SLAVE STATUS\G" | $ssh_cmd mysql -v | grep -iE '(running|err)'
}

checkTarget()
{
    subtitle "TEST ACCESS TO $target"
    scmd true
    if [ $? -ne 0 ]; then
        fail "Error on access to $target"
        return 127
    fi
    ok "Connexion to $target OK"
    return 0
}

checkMysqlTarget()
{
    subtitle "TEST ACCESS TO $target"
    scmd "mysql -e 'select 1'"
    if [ $? -ne 0 ]; then
        fail "Error on MySQL access to $target"
        return 127
    fi
    ok "MySQL Connexion to $target OK"
    return 0
}

checkTableChecksum()
{
    subtitle "CALCULATE DIFF CHECKSUMS"
    pt-table-checksum --ignore-databases mysql,sys,mysql_innodb_cluster_metadata h=$(hostname -s),u=percona,p="$mpass" --recursion-method=processlist
    if [ $? -ne 0 ]; then
        fail "SOME SLAVES ARE NOT SYNCED"
        pt-table-checksum --replicate-check-only  --ignore-databases mysql,sys,mysql_innodb_cluster_metadata h=$(hostname -s),u=percona,p="$mpass" --recursion-method=processlist
        return $?
    fi
    ok "ALL SLAVES ARE SYNCED"
    return 0
}
syncSlave()
{
    subtitle "SYNCING SLAVES"
     pt-table-sync --execute --no-check-child-tables --algorithms="Stream" --ignore-databases mysql,sys,mysql_innodb_cluster_metadata --verbose --sync-to-master h=$target,u=percona,p="$mpass"
    if [ $? -ne 0 ]; then
        fail "SOME SLAVES ARE NOT SYNCED"
        return 127
    fi
    ok "ALL SLAVES ARE SYNCED"
    return 0
}

diffSlave()
{
    subtitle "SYNCING SLAVES"
     pt-table-sync --print --no-check-child-tables --algorithms="Stream" --ignore-databases mysql,sys,mysql_innodb_cluster_metadata --verbose --sync-to-master h=$target,u=percona,p="$mpass"
    if [ $? -ne 0 ]; then
        fail "SOME SLAVES ARE NOT SYNCED"
        return 127
    fi
    ok "ALL SLAVES ARE SYNCED"
    return 0
}
[ -z "$METHOD" ] && METHOD="xtra"

banner
debug "TARGET HOST FOR SLAVE: $target"
case "$2" in
    install|INSTALL)
        checkTarget
        checkMysqlTarget
        preRepli
        createRepliUser
        ;;
    full|FULL)
        checkTarget
        checkMysqlTarget
        preRepli
        cleanSlaveRepli
        setupRepli ${3:-"xtra"}
        testRepli
        ;;
    setup|SETUP)
        cleanSlaveRepli
        setupRepli ${3:-"xtra"}
        testRepli
    ;;
    setupRepli)
        cleanSlaveRepli
        [ "$3" = "dump" ] && setupRepliDump
        [ "$3" = "xtra" ] && setupRepliXtra
        [ "$3" = "xtrabackup" ] && setupRepliXtra
        [ -z "$3" ] && setupRepliXtra
        ;;
    clone|CLONE)
        cloneXtrabackup
        ;;
    test|TEST)
        lRC=0
        checkTarget
        lRC=$(($lRC + $?))
        checkMysqlTarget
        lRC=$(($lRC + $?))
        check_params
        lRC=$(($lRC + $?))
        testRepli
        lRC=$(($lRC + $?))
        checkTableChecksum
        lRC=$(($lRC + $?))
        end $lRC
        ;;
    *)
        true
        shift
        subtitle "RUNNING $*"
        $@
        lRC=$?
        subtitle "END OF RUNNING $* - STATUS: $lRC"

        end $lRC
esac
end $?
