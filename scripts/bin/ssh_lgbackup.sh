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

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh

BCK_DIR=/data/backups/logical
GZIP_CMD=pigz
#GZIP_CMD=gzip
#GZIP_CMD=tee
GALERA_SUPPORT="0"
KEEP_LAST_N_BACKUPS=5
BCK_FILE=$BCK_DIR/backup_$(date +%Y%m%d-%H%M%S).sql.gz
SSH_PRIVATE_KEY=/root/.ssh/id_rsa
SSH_USER=root
SSH_HOSTNAME=targetbdd.infra

TARGET_CONFIG=$(to_lower $1)
lRC=0

banner "SSH LOGICAL BACKUP"

if [ -f "/etc/mybackupbdd/ssh_lgconfig.conf" ]; then
    info "LOADING CONFIG FROM /etc/mybackupbdd/ssh_lgconfig.conf"
    source /etc/mybackupbdd/ssh_lgconfig.conf
fi
if  [ -n "$TARGET_CONFIG" -a -f "/etc/mybackupbdd/ssh_lgconfig_$TARGET_CONFIG.conf" ]; then
    info "LOADING CONFIG FROM /etc/mybackupbdd/ssh_lgconfig_$TARGET_CONFIG.conf"
    source /etc/mybackupbdd/ssh_lgconfig_$TARGET_CONFIG.conf
fi

SSH_CMD="ssh -q -i $SSH_PRIVATE_KEY $SSH_USER@$SSH_HOSTNAME"

info "CHECKING STATUS IN REMOTE SSH MODE"
my_status
if [ $? -ne 0 ]; then
    error "SSH LOGICAL BACKUP FAILED: Server must be running ...."
    lRC=2 footer "SSH LOGICAL BACKUP"
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

if [ $lRC -eq 0 ]; then
    info "BACKUP OK ..........."
else
    error "mysqldump BACKUP error"
fi
dump_timer "BACKUP"
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

if [ $lRC -eq 0 -a -n "$KEEP_LAST_N_BACKUPS" ]; then
    info "KEEP LAST $KEEP_LAST_N_BACKUPS BACKUPS"
    (
    	ls -tp $BCK_DIR| grep -v '/$' | grep 'sha256sum' | tail -n +$(($KEEP_LAST_N_BACKUPS +1))
    	ls -tp $BCK_DIR| grep -v '/$' | grep -v 'sha256sum' | tail -n +$(($KEEP_LAST_N_BACKUPS +1))
    ) | while IFS= read -r f; do
        info "Removing $f";
        rm -f $BCK_DIR/$f
    done
fi

info "Adding signature file"
sha256sum $BCK_FILE > ${BCK_FILE}.sha256sum

info "Liste fichier backup"
ls -lsh $BCK_DIR

footer "SSH LOGICAL BACKUP"
exit $lRC