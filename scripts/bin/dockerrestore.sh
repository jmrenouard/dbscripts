#!/usr/bin/env bash

# Support Galera (desync node if needed)
# Support possition un logbin for PITR recovery with mysqlbinlog
# Parallel compression with pigz if installed
# Check Dump Completed at the end of dump
# Checksum generation
# purge old backups if dump is OK

# Missing
# Support stop / start Slave if replciation slave
# support SSH remote command
# Support Flag file for supervision
# Support NRPE generation
# Support general history file for ELK
# Support HTML report

[ -f "$(dirname $(readlink -f $0))/utils.sh" ] && \
    source $(dirname $(readlink -f $0))/utils.sh
[ -f "$(dirname $(readlink -f $0))/../utils.sh" ] && \
    source $(dirname $(readlink -f $0))/../utils.sh

BCK_DIR=/backups/logical
GZIP_CMD=pigz
#GZIP_CMD=gzip
#GZIP_CMD=tee
GALERA_SUPPORT="0"
KEEP_LAST_N_BACKUPS=5
BCK_TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BCK_FILE=$BCK_DIR/backup_${BCK_TIMESTAMP}.sql.gz
SSH_PRIVATE_KEY=/root/.ssh/id_rsa
SSH_USER=root
SSH_HOSTNAME=targetbdd.infra
DATADIR_TMP_DOCKER="/backups/docker/tmp"
TARGET_CONFIG=$(to_lower $1)
MAX_CHECKS=1
NO_LIMIT_RUN=1
DOCKER_CLEANUP=1
lRC=0

GOOD_USER="service-sgbd"

if [ "$(whoami)" != "$GOOD_USER" ]; then
    echo "WRONG USER - THIS IS NOT $GOOD_USER RUNNING $0"
    exit 127
fi

banner "DOCKER CHECK RESTORE MYSQLDUMP"

if [ -f "/etc/mybackupbdd/ssh_lgconfig.conf" ]; then
    info "LOADING CONFIG FROM /etc/mybackupbdd/ssh_lgconfig.conf"
    source /etc/mybackupbdd/ssh_lgconfig.conf
fi
if [ "${TARGET_CONFIG:0:1}" != '-' ]; then
    if  [ -n "$TARGET_CONFIG" -a -f "/etc/mybackupbdd/ssh_lgconfig_$TARGET_CONFIG.conf" ]; then
        info "LOADING CONFIG FROM /etc/mybackupbdd/ssh_lgconfig_$TARGET_CONFIG.conf"
        source /etc/mybackupbdd/ssh_lgconfig_$TARGET_CONFIG.conf
    else
        error "NO CONFIG FILE /etc/mybackupbdd/ssh_lgconfig_$TARGET_CONFIG.conf"
        gen_log_entry $2 FAIL 127 "NO CONFIG FILE /etc/mybackupbdd/ssh_lgconfig_$TARGET_CONFIG.conf"
        exit 127
    fi
fi

if [ ! -d "$BCK_DIR" ]; then
    error "MISSING DIRECTORY: $BCK_DIR"
    exit 128
fi

info "DIRECTORY $BCK_DIR  EXISTS"

LOG_STATE_FILE=/var/log/lgbackup/backup_status.log
TEE_LOG_FILE=${BCK_FILE}.log
gen_log_entry()
{
    local TARGET_CONFIG=$1
    shift
    local status=$1
    shift
    local rc=$1
    shift
    local RESULT_FILE=$1
    shift
    local nowtime=$(date "+%F-%T")
    echo -e "$nowtime\tMYSQLDUMPCHECK\t$TARGET_CONFIG\t$status\t$rc\t$RESULT_FILE\t$*" >> $LOG_STATE_FILE
}

gen_size_log_entry()
{
    local BCK_DIR=$1
    shift
    local nowtime=$(date "+%F-%T")
    echo -e "$nowtime\tMYSQLDUMP_SIZE\t$TARGET_CONFIG\tOK\t$(du -s $BCK_DIR| awk '{print $1}')\t$BCK_DIR\t$(du -sh $BCK_DIR| awk '{print $1}')\t$*" >> $LOG_STATE_FILE
}

gen_version_log_entry()
{
    local VENDOR=$1
    shift
    local MAJ_VERS=$1
    shift
    local MIN_VERS=$1
    shift
    local nowtime=$(date "+%F-%T")
    echo -e "$nowtime\tMYSQL_VERSION\t$TARGET_CONFIG\tOK\t0\t$VENDOR\t$MAJ_VERS\t$MIN_VERS" >> $LOG_STATE_FILE
}

getinfo_bck()
{
    title1 "DUMPING INFO FOR $1"
    if [ -f "${1}.info" ]; then
        echo "----------"
        echo "$(basename $1)"
        echo "----------"
        cat ${1}.info
    else
        echo "* Missing $1.info"
    fi
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


# SELECT BACKUP FILE
if [ "${TARGET_CONFIG:0:2}" == '-l' ];then
    [ -d "$BCK_DIR/$2" ] && ls -lshsa $BCK_DIR/$2
    [ -d "$BCK_DIR/$2" ] || tree -Nugar $BCK_DIR/*

    exit 0
fi
# Find information into info file
if [ "${TARGET_CONFIG:0:2}" == '-i' ];then
    if [ ! -d "$BCK_DIR/$2" ]; then
        echo "MISSING DIR: $BCK_DIR/$2"
        exit 127
    fi
    bck_files="$BCK_DIR/$2/$3"
    [ -f "$bck_files" ] || bck_files="$(find $BCK_DIR/$2 -type f -iname '*.gz')"
    for bck in $bck_files; do
        getinfo_bck $bck
    done
    exit 0
fi
# Start appropriated docker image
# Find information into info file
if [ "${TARGET_CONFIG:0:2}" == '-t' ];then
    if [ -z "$3" ]; then
        title1 "Test BACKUPS INTO in $BCK_DIR/$2"
        lRC=0
        for gzfile in $( ls -1 $BCK_DIR/$2 | grep -E '.gz$'); do
            sep1
            sep1
            title1 "RUNNING: bash $0 -t $2 $gzfile"
            sep1
            sep1
            bash $0 -t $2 $gzfile
            lRC=$(($lRC + $?))
        done
        exit $lRC
    fi
    bck_file="$BCK_DIR/$2/$3"
    if [ ! -f "$bck_file" ]; then
        echo "MISSING backup: $bck_file"
        exit 127
    fi
    getinfo_bck $bck_file

    title1 "EXPORT VARIABLE"
    eval "$(sed 's/: /:/g;s/ /_/g;s/:/=/g' ${bck_file}.info)"
    info "VENDOR: $VENDOR"
    info "MAJOR_VERSION: $MAJOR_VERSION"
    info "FULL_VERSION: $FULL_VERSION"
    #set -x
    if [ -n "$CHECK_COUNT" -a "$NO_LIMIT_RUN" != "1" ]; then
        if [ $MAX_CHECKS -gt $CHECK_COUNT -o "$CHECK_RESULT" = "0" ]; then
            title1 "ALREADY CHECK BACKUP AND ALL IS OK"
            exit $CHECK_RESULT
        fi
        CHECK_COUNT=$(($CHECK_COUNT + 1))
    else
        CHECK_COUNT=1
    fi
    #set +x
    title1 "TEST SHA255SUM"
    sha256sum -c ${bck_file}.sha256sum
    [ $? -ne 0 ] && exit 128

    title2 "TEST LOG FILE"
    grep -Ei '(err|warn|excep)' ${bck_file}.log
    [ $? -eq 0 ] && exit 129
    ok "* No suspicious log pattern detected"

    title1 "CHECKING DOCKER IMAGE $(to_lower $VENDOR) $(to_lower $MAJOR_VERSION)"
    docker images | grep -E "$(to_lower $VENDOR)\s+$(to_lower $MAJOR_VERSION)"
    if is not equal $? 0;then
        docker pull $(to_lower $VENDOR):$(to_lower $MAJOR_VERSION)
        is equals 0 $? && bash $0 $*
        exit 27
    fi
    ok "GET THE RIGTH IMAGE $(to_lower $VENDOR) - $(to_lower $MAJOR_VERSION)"

    title1 "CLEANUP ALL OLD CONTAINERS"
    for did in $(docker ps -a | grep "$2" | awk '{print $1}'); do
         info "CLEAN UP $did CONTAINER"
         docker rm -f $did
    done

    title1 "Create mount point for data: $DATADIR_TMP_DOCKER"
    sudo rm -rf $DATADIR_TMP_DOCKER/$2
    sudo mkdir -p $DATADIR_TMP_DOCKER/$2

    title1 "CREATING DOCKER CONTAINER  $(to_lower $VENDOR):$(to_lower $MAJOR_VERSION)"
    docker run -d --name $2 -v $bck_file:/$3 -v $DATADIR_TMP_DOCKER/$2:/var/lib/mysql -e MYSQL_ALLOW_EMPTY_PASSWORD=yes $(to_lower $VENDOR):$(to_lower $MAJOR_VERSION)

#    nc -w1 -vz localhost 9999 &>/dev/null
#    while is false $?;do
#        sleep 1s
#        echo -n .
#        nc -w1 -vz localhost 9999 &>/dev/null
#        echo $?
#    done
#    nc -w1 -vz localhost 9999
    docker ps
    # inject backup
    DOCKER_ID=$(docker ps | grep $2 | awk '{print $1}')

    title2 "DOCKER ID: $DOCKER_ID"
    if is equals "" $DOCKER_ID; then
        die "NO DOCKER ID FOUND"
    fi
    start_timer INJECT
    title1 "Inject Dump"
    sed -iE '/^CHECK_.*:/d' ${bck_file}.info
    [ -f "${bck_file}.checkoutput" ] && rm -f ${bck_file}.checkoutput
    [ -f "${bck_file}.info" ] && sed -i '/CHECK_/d' ${bck_file}.info
    set -o pipefail
    (
        docker exec -i $DOCKER_ID bash <<EOF
            set -o pipefail
            mysql -e 'status' &>/dev/null
            while [ \$? -ne 0 ]; do
                sleep 1s
                #echo -n .
                mysql -e 'status' &>/dev/null
            done
            sleep 10s

            (
                echo "SET @@global.innodb_file_format = BARRACUDA;
                SET @@global.innodb_large_prefix = 1;"
                zcat /$3
            ) | grep -Ev '(WARNING.+--master-data is deprecated and will be removed in a future version)' | \
            mysql -f 2>&1
EOF
        lRC=$?
    )| tee -a ${bck_file}.checkoutput
dump_timer INJECT
update_timer INJECT

    echo "CHECK_NB_WARN: $(grep -c 'WARN' ${bck_file}.checkoutput)
CHECK_NB_ERROR: $(grep -c 'ERROR' ${bck_file}.checkoutput)
CHECK_DATE: $BCK_TIMESTAMP
CHECK_OUTPUT: ${bck_file}.checkoutput
CHECK_COUNT: $CHECK_COUNT
CHECK_START_DATE: $(get_timer_start_date INJECT)
CHECK_STOP_DATE: $(get_timer_stop_date INJECT)
CHECK_DURATION: $(get_timer_duration INJECT)">> ${bck_file}.info
    lRC=$(( $lRC + $(grep -c 'ERROR' ${bck_file}.checkoutput) ))
    echo "CHECK_RESULT: $lRC">> ${bck_file}.info

    title1 "File: ${bck_file}.info"
    cat ${bck_file}.info
    echo "---------------------------"
    title1 "File: ${bck_file}.checkoutput"
    cat ${bck_file}.checkoutput
    echo "---------------------------"
    
    #info "docker exec -it $DOCKER_ID /bin/bash"

    info "INJECTION RESULT: $lRC"
    if [ $lRC -eq 0 ];then
        start_timer COUNTS
        dump_database_list $DOCKER_ID ${bck_file}
        dump_table_list $DOCKER_ID ${bck_file}
        dump_non_table_list $DOCKER_ID ${bck_file}
        dump_table_count $DOCKER_ID ${bck_file}
        dump_timer COUNTS
        sep1
        sep1
        gen_log_entry $2 OK $lRC ${bck_file}.checkoutput
    else
        gen_log_entry $2 FAIL $lRC ${bck_file}.checkoutput
    fi
    if [ "DOCKER_CLEANUP" = "1" ]; then
        title1 "SHUTDOWN MySQL CONTAINER"
        docker rm -f $DOCKER_ID
    fi
fi
footer "DOCKER CHECK RESTORE MYSQLDUMP"
exit $lRC