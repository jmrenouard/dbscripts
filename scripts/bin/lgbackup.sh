#!/usr/bin/env bash
set -o pipefail
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
load_lib()
{
    libname="$1"
    if [ -z "$libname" -o "$libname" = "main" ];then 
        libname="utils.sh"
    else 
        libname="utils.$1.sh"
    fi
    _DIR="$(dirname "$(readlink -f "$0")")"
    if [ -f "$_DIR/$libname" ]; then
        source $_DIR/$libname
    else
        if [ -f "/etc/profile.d/$libname" ]; then
            source /etc/profile.d/$libname
        else 
            echo "No $libname found"
            exit 127
        fi
    fi
}
load_lib main
load_lib mysql

BCK_DIR=/data/backups/logical
GZIP_CMD=pigz
#GZIP_CMD=gzip
#GZIP_CMD=tee
GALERA_SUPPORT="0"
KEEP_LAST_N_BACKUPS=5
BCK_FILE=$BCK_DIR/backup_$(date +%Y%m%d-%H%M%S).sql.gz
TARGET_CONFIG=$(to_lower $1)
lRC=0

banner "LOGICAL BACKUP"

if [ -f "/etc/lgconfig.sh" ]; then
    info "LOADING CONFIG FROM /etc/lgconfig.sh"
    source /etc/lgconfig.sh
fi
if  [ -n "$1" -a -f "/etc/lgconfig_$TARGET_CONFIG.sh" ]; then
    info "LOADING CONFIG FROM /etc/lgconfig_$TARGET_CONFIG.sh"
    source /etc/lgconfig_$TARGET_CONFIG.sh
fi
if [ "$1" = "-l" -o "$1" = "--list" ]; then
    ls -lsht $BCK_DIR
    exit 0
fi


if [ "$1" = "-a" -o "$1" = "--addcrontab" ]; then
    [ -f "/etc/cron.d/lgbackup" ] && rm -f /etc/cron.d/lgbackup
    echo "${3:-"00"} ${2:-"02"} * * * root bash /opt/local/bin/lgbackup.sh" | tee /etc/cron.d/lgbackup
    chmod 644 /etc/cron.d/lgbackup
    #cat /etc/cron.d/lgbackup
    ls -lsh /etc/cron.d
    systemctl restart cron
    exit 0
fi

if [ "$1" = "-r" -o "$1" = "--removecrontab" ]; then
    [ -f "/etc/cron.d/lgbackup" ] && rm -f /etc/cron.d/lgbackup
    ls -lsh /etc/cron.d
    systemctl restart cron
    exit 0
fi

info "CHECKING MYSQL STATUS"
my_status
if [ $? -ne 0 ]; then
    error "LOGICAL BACKUP FAILED: Server must be running ...."
    lRC=2 footer "LOGICAL BACKUP"
	exit 2
fi
GALERA_SUPPORT=$(galera_is_enabled)

if [ "$GALERA_SUPPORT" = "1" ]; then
    info "Desynchronisation du noeud"
    # desync
    mysql -e 'set global wsrep_desync=on'

    info  "etat Desynchronisation"
    mysql -e 'select @@wsrep_desync'
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

info "Backup logique mysldump dans le fichier $(basename $BCK_FILE)"
title1 "Command: time mysqldump --all-databases $add_opt \
--add-drop-database \
--routines \
--skip-opt \
--triggers \
--add-drop-table --add-locks --create-options --disable-keys --extended-insert \
--quick --set-charset \
--single-transaction | $GZIP_CMD > $BCK_FILE"

time mysqldump --all-databases $add_opt \
--add-drop-database \
--routines \
--skip-opt \
--triggers \
--add-drop-table --add-locks --create-options --disable-keys --extended-insert \
--quick --set-charset \
--single-transaction | $GZIP_CMD > $BCK_FILE
lRC=$?

if [ $lRC -eq 0 ]; then
    info "BACKUP OK ..........."
else
    error "mysqldump BACKUP error"
fi

if [ "$LOCAL_BACKUP" = "1" ]; then
    if [ "$GALERA_SUPPORT" = "1" ]; then
        info desync off
        mysql -e 'set global wsrep_desync=off'

        info etat Desynchronisation
        mysql -e 'select @@wsrep_desync'
    fi
fi

info "Fin du fichier $(basename $BCK_FILE)"
zcat $BCK_FILE | tail -n 5 | grep "Dump completed"
lRC=$(($lRC + $?))
if [ $lRC -eq 0 ]; then
    info "BACKUP OK FIN FICHIER..........."
else
    error "mysqldump BACKUP error FIN FICHIER: Dump completed"
fi

if [ "$logbinopt" != "OFF" ]; then
    info "POSITION LOGBIN DANS $(basename $BCK_FILE)"
    zcat $BCK_FILE | head -n 40 | grep -E 'CHANGE MASTER'
    lRC=$(($lRC + $?))
fi

if [ $lRC -eq 0 -a -n "$KEEP_LAST_N_BACKUPS" ]; then
    info "KEEP LAST $KEEP_LAST_N_BACKUPS BACKUPS"
    (
    	ls -tp $BCK_DIR| grep -v '/$' | grep 'sha256sum' | tail -n +$(($KEEP_LAST_N_BACKUPS +1))
    	ls -tp $BCK_DIR| grep -v '/$' | grep -v 'sha256sum' | tail -n +$(($KEEP_LAST_N_BACKUPS +1))
    ) | while IFS= read -r f; do
        info "Removing $f BACKUP FILE";
        rm -f $BCK_DIR/$f
    done
fi

info "Adding signature file"
sha256sum $BCK_FILE > ${BCK_FILE}.sha256sum

info "Liste fichier backup"
ls -lsh $BCK_DIR

info "BACKUP DIRECTORY: $BCK_DIR"
info "BACKUP FILE NAME: $(basename $BCK_FILE)"
info "BACKUP FILE SUM : $(basename $BCK_FILE.sha256sum)"
info "BACKUP FILE SIZE: $(du -sh $BCK_FILE| awk '{print $1}')"
info "FINAL CODE RETOUR: $lRC"
footer "LOGICAL BACKUP"
exit $lRC