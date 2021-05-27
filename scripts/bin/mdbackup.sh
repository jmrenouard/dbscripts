#!/usr/bin/env bash

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh

DBNAME="$1"
[ -z "$DBNAME" ] && die "NO DATABASE NAME AS PARAMETER"

BCK_DIR=/data/backups/mydumper/$DBNAME
GZIP_CMD=pigz
#GZIP_CMD=gzip
#GZIP_CMD=tee
GALERA_SUPPORT=$(galera_is_enabled)
KEEP_LAST_N_BACKUPS=5
BCK_TARGET=$BCK_DIR/$(date +%Y%m%d-%H%M%S)

[ -f "/etc/mdconfig.sh" ] && source /etc/mdconfig.sh

lRC=0

banner "LOGICAL BACKUP WITH MYDUMPER"
my_status
if [ $? -ne 0 ]; then
    error "LOGICAL BACKUP FAILED: Server must be running ...."
    lRC=2 footer "LOGICAL BACKUP"
	exit 2
fi

db_list | grep -qE "^${DBNAME}$"
[  $? -ne 0 ] && die "NO DATABASE CALLED $DBNAME EXISTS"

if [ "$GALERA_SUPPORT" = "1" ]; then
    info "Desynchronisation du noeud"
    # desync
    mysql -e 'set global wsrep_desync=on'

    info  "etat Desynchronisation"
    mysql -e 'select @@wsrep_desync'
fi
[ -d "$BCK_TARGET" ] || mkdir -p $BCK_TARGET

info "Backup logique mydumper dans le repertoire $BCK_TARGET"
title1 "Command: time mydumper \
  --database=$DBNAME \
  --outputdir=$BCK_TARGET \
  --chunk-filesize=100 \
  --insert-ignore \
  --events \
  --triggers \
  --routines \
  --verbose 3 \
  --compress \
  --build-empty-files \
  --threads=${nbproc:-"$(nproc)"} \
  --compress-protocol"

time mydumper \
  --database=$DBNAME \
  --outputdir=$BCK_TARGET \
  --chunk-filesize=100 \
  --insert-ignore \
  --events \
  --triggers \
  --routines \
  --verbose 3 \
  --compress \
  --build-empty-files \
  --threads=${nbproc:-"$(nproc)"} \
  --compress-protocol
 lRC=$?

if [ $lRC -eq 0 ]; then
    echo "MYDUMPER BACKUP OK ..........."
else
    echo "PROBLEME MYDUMPER BACKUP"
fi

if [ "$GALERA_SUPPORT" = "1" ]; then
    info desync off
    mysql -e 'set global wsrep_desync=off'

    info etat Desynchronisation
    mysql -e 'select @@wsrep_desync'
fi

if [ $lRC -eq 0 -a -n "$KEEP_LAST_N_BACKUPS" ]; then
    info "KEEP LAST $KEEP_LAST_N_BACKUPS BACKUPS"
    ls -tp $BCK_DIR/ | grep '/$'| sort -nr | tail -n +$(($KEEP_LAST_N_BACKUPS +1)) | while IFS= read -r f; do
        echo "Removing $f";
        rm -fr $BCK_DIR/$f
    done
fi

info "Liste fichier backup"
ls -lsh $BCK_TARGET

info "FINAL CODE RETOUR: $lRC"
footer "LOGICAL BACKUP"
exit $lRC