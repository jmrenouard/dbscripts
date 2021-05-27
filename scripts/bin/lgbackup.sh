#!/usr/bin/env bash

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh

BCK_DIR=/data/backups/logical
GZIP_CMD=pigz
#GZIP_CMD=gzip
#GZIP_CMD=tee
GALERA_SUPPORT=$(galera_is_enabled)
KEEP_LAST_N_BACKUPS=5
BCK_FILE=$BCK_DIR/backup_$(date +%Y%m%d-%H%M%S).sql.gz

[ -f "/etc/lgconfig.sh" ] && source /etc/lgconfig.sh

lRC=0

banner "LOGICAL BACKUP"
my_status
if [ $? -ne 0 ]; then
    error "LOGICAL BACKUP FAILED: Server must be running ...."
    lRC=2 footer "LOGICAL BACKUP"
	exit 2
fi

if [ "$GALERA_SUPPORT" = "1" ]; then
    info "Desynchronisation du noeud"
    # desync
    mysql -e 'set global wsrep_desync=on'

    info  "etat Desynchronisation"
    mysql -e 'select @@wsrep_desync'
fi
[ -d "$BCK_DIR" ] || mkdir -p $BCK_DIR

add_opt=""
logbinopt="$(global_variables log_bin)"
[ "$logbinopt" = "OFF" ] || add_opt="--master-data=1 --flush-logs"

info "Backup logique mysldump dans le fichier $(basename $BCK_FILE)"
title1 "Command: time mysqldump --all-databases $add_opt \
--add-drop-database \
--routines \
--skip-opt \
--triggers \
--events \
--add-drop-table --add-locks --create-options --disable-keys --extended-insert \
--quick --set-charset \
--single-transaction | $GZIP_CMD > $BCK_FILE"

time mysqldump --all-databases $add_opt \
--add-drop-database \
--routines \
--skip-opt \
--triggers \
--events \
--add-drop-table --add-locks --create-options --disable-keys --extended-insert \
--quick --set-charset \
--single-transaction | $GZIP_CMD > $BCK_FILE
lRC=$?

if [ $lRC -eq 0 ]; then
    echo "BACKUP OK ..........."
else
    echo "PROBLEME BACKUP"
fi

info "Fin du fichier $(basename $BCK_FILE)"
zcat $BCK_FILE | tail -n 5 | grep "Dump completed"
lRC=$(($lRC + $?))

if [ "$GALERA_SUPPORT" = "1" ]; then
    info desync off
    mysql -e 'set global wsrep_desync=off'

    info etat Desynchronisation
    mysql -e 'select @@wsrep_desync'
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
        echo "Removing $f";
        rm -f $BCK_DIR/$f
    done
fi

info "Adding signature file"
sha256sum $BCK_FILE > ${BCK_FILE}.sha256sum

info "Liste fichier backup"
ls -lsh $BCK_DIR

info "FINAL CODE RETOUR: $lRC"
footer "LOGICAL BACKUP"
exit $lRC