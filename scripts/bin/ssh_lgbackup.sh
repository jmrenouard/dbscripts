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

TARGET_CONFIG=$(to_lower $1)
lRC=0

GOOD_USER="service-sgbd"

if [ "$(whoami)" != "$GOOD_USER" ]; then
    echo "WRONG USER - THIS IS NOT $GOOD_USER RUNNING $0"
    gen_log_entry FAIL 127 "WRONG USER $(whoami) FAILED"
    exit 127
fi
LOG_STATE_FILE=/var/log/lgbackup/backup_status.log
gen_log_entry()
{
    local status=$1
    shift
    local rc=$1
    shift
    local nowtime=$(date "+%F-%T")
    echo -e "$nowtime\tMYSQLDUMP\t$TARGET_CONFIG\t$status\t$rc\t$TEE_LOG_FILE\t$*" >> $LOG_STATE_FILE
}

banner "SSH LOGICAL BACKUP"

if [ -f "/etc/mybackupbdd/ssh_lgconfig.conf" ]; then
    info "LOADING CONFIG FROM /etc/mybackupbdd/ssh_lgconfig.conf"
    source /etc/mybackupbdd/ssh_lgconfig.conf
fi
if  [ -n "$TARGET_CONFIG" -a -f "/etc/mybackupbdd/ssh_lgconfig_$TARGET_CONFIG.conf" ]; then
    info "LOADING CONFIG FROM /etc/mybackupbdd/ssh_lgconfig_$TARGET_CONFIG.conf"
    source /etc/mybackupbdd/ssh_lgconfig_$TARGET_CONFIG.conf
else
    error "NO CONFIG FILE /etc/mybackupbdd/ssh_lgconfig_$TARGET_CONFIG.conf"
    gen_log_entry FAIL 127 "NO CONFIG FILE /etc/mybackupbdd/ssh_lgconfig_$TARGET_CONFIG.conf"
    exit 127
fi
if [ ! -d "$BCK_DIR" ]; then
    info "CREATING DIRECTORY: $BCK_DIR"
    mkdir -p $BCK_DIR
else
    info "DIRECTORY $BCK_DIR ALREADY EXISTS"
fi
SSH_CMD="ssh -q -o ConnectTimeout=2 -o ConnectionAttempts=2 -i $SSH_PRIVATE_KEY $SSH_USER@$SSH_HOSTNAME sudo"
TEE_LOG_FILE=${BCK_FILE}.log

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

info "CONNEXION STRING $SSH_CMD"
$SSH_CMD true
if [ $? -ne 0 ];then
    lRC=2 footer "SSH LOGICAL BACKUP"
    gen_log_entry FAIL 1 "SERVER $TARGET_CONFIG SSH CONNEXION FAILED"
    exit 1
fi
info "CHECKING STATUS IN REMOTE SSH MODE"
my_status
if [ $? -ne 0 ]; then
    error "SSH LOGICAL BACKUP FAILED: Server must be running ...."
    lRC=2 footer "SSH LOGICAL BACKUP"
    gen_log_entry FAIL 2 "SERVER MYSQL NOT RUNNING"
       exit 2
fi
GALERA_SUPPORT=$(galera_is_enabled)
info "GALERA MODE: $GALERA_SUPPORT"
if [ "$GALERA_SUPPORT" = "1" ]; then
    info "GALERA IS ENABLED"
    info "Desynchronisation du noeud"
    # desync
    raw_mysql 'set global wsrep_desync=on'

    info  "Etat Desynchronisation: WSREP_DESYNC($(global_variables wsrep_desync))"
fi


if [ ! -d "$BCK_DIR" ]; then
    info "CREATING DIRECTORY: $BCK_DIR"
    mkdir -p $BCK_DIR
else
    info "DIRECTORY $BCK_DIR ALREADY EXISTS"
fi

add_opt=""
logbinopt="$(global_variables log_bin)"
[ "$logbinopt" = "OFF" ] || add_opt="--master-data=1 --flush-logs"

#exit 0
start_timer "BACKUP"
info "Backup logique mysldump dans le fichier $(basename $BCK_FILE)"
title1 "Command: mysqldump --all-databases $add_opt \
--add-drop-database \
--routines \
--skip-opt \
--triggers \
--events \
--add-drop-table --add-locks --create-options --disable-keys --extended-insert \
--quick --set-charset \
--single-transaction | $GZIP_CMD > $BCK_FILE"

$SSH_CMD "mysqldump --all-databases $add_opt \
--add-drop-database \
--routines \
--skip-opt \
--triggers \
--events \
--add-drop-table --add-locks --create-options --disable-keys --extended-insert \
--quick --set-charset \
--single-transaction | $GZIP_CMD" > $BCK_FILE
lRC=$?

chmod 750 $BCK_FILE
update_timer "BACKUP"
dump_timer "BACKUP"

if [ $lRC -eq 0 ]; then
    info "BACKUP OK ..........."
else
    gen_log_entry FAIL $lRC "MYSQLDUMP FAIL($lRC)"
    error "mysqldump BACKUP error"
    exit $lRC
fi
if [ "$GALERA_SUPPORT" = "1" ]; then
    info "GALERA IS ENABLED"
    set_global_variables wsrep_desync OFF

    info  "Etat Desynchronisation: WSREP_DESYNC( $(global_variables wsrep_desync) )"
fi

info "Fin du fichier $(basename $BCK_FILE)"
info_cmd "zcat $BCK_FILE | tail -n 5 | grep 'Dump completed'"
lRC=$(($lRC + $?))

if [ "$logbinopt" != "OFF" ]; then
    info "POSITION LOGBIN DANS $(basename $BCK_FILE)"
    info_cmd "zcat $BCK_FILE | head -n 40 | grep -E 'CHANGE MASTER'"
    lRC=$(($lRC + $?))
fi

info "Adding signature file"
sha256sum $BCK_FILE > ${BCK_FILE}.sha256sum
lRC=$(($lRC + $?))

title2 "COLLECTING MYSQL VERSION INFORMATION"
MY_FULL_VERSION=$($SSH_CMD "mysql -Nrs -e 'status'"| grep -i "server version" | cut -d: -f2 | cut -d- -f1|xargs -n 1)
IS_MY_SLAVE=$($SSH_CMD "mysql -Nrs -e 'select @@read_only'")

VENDOR=$($SSH_CMD "mysql -Nrs -e 'status'"| grep -i 'server:'|cut -d: -f2| xargs -n 1)
[ -z "$VENDOR" ] && VENDOR="MYSQL"

VENDOR="${VENDOR^^}"

echo $MY_FULL_VERSION| grep -E '^8'
if [ $? -eq 0 ]; then
    MY_MAJOR_VERSION=$(echo "$MY_FULL_VERSION" | perl -pe 's/(\d+)\..*/$1/')
else
    MY_MAJOR_VERSION=$(echo "$MY_FULL_VERSION" | perl -pe 's/(\d+)\.(\d+)\..*/$1.$2/')
fi
update_timer GENERIC
echo "TIMESTAMP:$BCK_TIMESTAMP
VENDOR: $VENDOR
FULL VERSION: $MY_FULL_VERSION
MAJOR VERSION: $MY_MAJOR_VERSION
READ ONLY: $IS_MY_SLAVE
BACKUP DATA FILE: $(basename $BCK_FILE)
BACKUP DATA SIGN FILE: $(basename ${BCK_FILE}.sha256sum)
BACKUP LOG FILE: $(basename ${BCK_FILE}.log)
BACKUP START: $(get_timer_start_date GENERIC)
BACKUP END: $(get_timer_stop_date GENERIC)
BACKUP DURATION: $(get_timer_duration GENERIC)" > ${BCK_FILE}.info
gen_version_log_entry $VENDOR $MY_MAJOR_VERSION $MY_FULL_VERSION

chmod -R 740 $BCK_DIR

if [ $lRC -eq 0 -a -n "$KEEP_LAST_N_BACKUPS" ]; then
    info "KEEP LAST $KEEP_LAST_N_BACKUPS BACKUPS"
    info "Last GZ files found:"
    ls -tp $BCK_DIR| grep -v '/$' | grep -E '.gz$'
    (
       ls -tp $BCK_DIR| grep -v '/$' | grep -E '.gz$' | tail -n +$(($KEEP_LAST_N_BACKUPS +1))
    ) | while IFS= read -r f; do
        info "Removing $f";
        rm -f $BCK_DIR/$f*
    done
    info "PURGE ORPHANED INFO FILES"
    for metafile in $(ls -tp $BCK_DIR| grep -v '/$' | grep -E '\.gz\.'); do
        gzfile=$(echo $metafile | perl -pe 's/(.+)\.[^.]+$/$1/')
        info "LOOKUP FOR CONSISTENCY BETWEEN $metafile / $gzfile exists"
        if [ ! -f "$BCK_DIR/$gzfile" ]; then
            info "REMOVING ORPHAN INFO FILE: $metafile"
            rm -fv $BCK_DIR/$metafile
        fi
    done
fi

info "Liste fichier backup"
ls -lsh $BCK_DIR | tee -a $TEE_LOG_FILE

info "VENDOR                   : $VENDOR"
info "MAJOR VERSION            : $MY_MAJOR_VERSION"
info "FULL VERSION             : $MY_FULL_VERSION"
info "READ ONLY                : $IS_MY_SLAVE"
info "BACKUP DIRECTORY         : $(dirname $BCK_FILE)"
info "BACKUP INFO FILE         : $(basename ${BCK_FILE}.info)"
info "BACKUP DATA FILE         : $(basename $BCK_FILE)"
info "BACKUP DATA SIGN FILE    : $(basename ${BCK_FILE}.sha256sum)"
info "BACKUP LOG FILE          : $(basename ${BCK_FILE}.log)"
footer "SSH LOGICAL BACKUP"
if [ $lRC -ne 0 ]; then
    gen_log_entry FAIL $lRC "MYSQLDUMP POST OPERATION FAILED"
else
    gen_log_entry OK $lRC "MYSQLDUMP COMPLETED FOR $TARGET_CONFIG"
fi

gen_size_log_entry $BCK_DIR
exit $lRC