#!/bin/bash

#GLOBAL VAR
raw_mysql="$(which mysql) -Nrs"
mysql_force="$(which mysql) -f"


pauseenter()
{
    [ "$NOPAUSE" = "1" ] && return 0
    read -p "Press Enter to continue" </dev/tty
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
    info "$* [SUCCESS]"
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
}

footer()
{
    local lRC=${lRC:-"$?"}

    [ $lRC -eq 0 ] && title1 "END: $* ENDED SUCCESSFULLY"
    [ $lRC -eq 0 ] || title1 "END: $* ENDED WITH WARNING OR ERROR ($lRC)"
    return $lRC
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

db_list()
{
	$raw_mysql -e 'show databases;'
}
db_user_list()
{
    $raw_mysql -e 'show databases;' | grep -Ev '(mysql|information_schema|performance_schema|sys)'
}

db_tables()
{
    $raw_mysql -e 'show tables' $1
}

db_count()
{
    for tbl in $(db_tables ${1:-"mysql"}); do
        echo -ne "$tbl\t"
        $raw_mysql -e "select count(*) from $tbl" ${1:-"mysql"}
    done | sort -nr -k2 | column -t
}

db_truncate_tables()
{
    local TDB=$1
    [ -z "$TDB" ] && return 1
    db_list | grep -Eq "^$TDB$"
    [ $? -ne 0 ] && return 2

    title2 "AVANT VIDAGE DES TABLES $TDB"
    db_count $TDB
    sep2
    title2 "VIDAGE DES TABLES $TDB"
    for tbl in $(db_tables $TDB); do
        echo "DELETE FROM $TDB.$tbl;"
    done | $raw_mysql -v $TDB
    if [ $? -eq 0 ];then
        ok "VIDAGE DES TABLES $TDB OK"
    else 
        error "VIDAGE DES TABLES $TDB"
    fi
    title2 "APRES VIDAGE DES TABLES $TDB"
    db_count $TDB
    sep2
    return 0
}

db_inject_data()
{
    local TDB=$1
    local sqlfile=$2

    [ -z "$TDB" ] && return 1
    db_list | grep -Eq "^$TDB$"
    if [ $? -ne 0 ]; then
        echo "CREATE DATABASE $TDB;" | $raw_mysql
    fi

    [ -z "$sqlfile" ] && return 3
    [ -r "$sqlfile" ] ||return 4
    $raw_mysql $TDB < $sqlfile
    if [ $? -eq 0 ];then
        ok "INJECTION DATA $TDB FROM $(basename $sqlfile) OK"
    else 
        error "ERREUR INJECTION DATA $TDB FROM $(basename $sqlfile)"
        return 5
    fi

    db_count $TDB
    sep2
}

get_db_list_from_dir()
{
    for d in $*; do
    ls -1 $d
done  | cut -d_ -f1 | sort | uniq | grep -vE '(production|sys)'
}

get_database_names()
{
	ls -1 $1 |grep -vE '^sys_' | cut -d_ -f 1 | sort | uniq
}