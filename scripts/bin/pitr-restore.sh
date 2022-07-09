#!/bin/bash

TMP_DIR=/data/backups/tmp
GZIP_CMD="pigz -cd"
#GZIP_CMD="gzip -cd"
#GZIP_CMD=tee
DATADIR=/var/lib/mysql
BACKDIR=/data/backups/pitr


MYSQL_USER=$(grep -E '^user' $HOME/.my.cnf|head -n1| cut -d= -f2| xargs -n1)
MYSQL_PASSWORD=$(grep -E '^password' $HOME/.my.cnf|head -n1| cut -d= -f2| xargs -n1)

DATE_RESTORE=$(date +"%Y-%m-%d %H:%M:%S")
[ -n "$1" -a -n "$2" ] && DATE_RESTORE=$(date -d "$1 $2" +"%Y-%m-%d %H:%M:%S")

DIR_RESTORE="${BACKDIR}/restore_$(echo $DATE_RESTORE | tr ' ' '_' | tr ':' '-')"
echo "RESTORE DIR: $DIR_RESTORE"

# Récupération de la dernière sauvegarde full
LAST_BASE_BACK=$(find ${BACKDIR}/base -mindepth 1 -maxdepth 1 -type d ! -newermt "$DATE_RESTORE" | sort -n | tail -1)

# Récupération des incrémentales correspondantes
LASTEST_INCR_BASK=$(find ${BACKDIR}/incr -mindepth 2 -maxdepth 2 -type d ! -newermt "$DATE_RESTORE" | sort -n | grep "$(basename $LAST_BASE_BACK)")

echo "Base backup : $LAST_BASE_BACK"
echo "Incr backups : $LASTEST_INCR_BASK"

# Si une variable $doit valant 1 existe alors on exécute réellement la restauration
[ "$doit" = "1" ] || exit 0

# Vérification que nous sommes pas à la racine
[ "$DIR_RESTORE" = '/' ] && exit 1

rm -rf $DIR_RESTORE
mkdir -p $DIR_RESTORE/base

# Décompression de la full
echo "Decompression et preparation de la sauvegarde full dans $DIR_RESTORE/base"
$GZIP_CMD $LAST_BASE_BACK/backup.stream.gz | mbstream -x -C $DIR_RESTORE/base
mariabackup --prepare --target-dir $DIR_RESTORE/base --user $MYSQL_USER --password "$MYSQL_PASSWORD"
#--apply-log-only
[ $? -eq 0 ] || exit 1
echo "OK"

# Décompression de toutes les incrémentales
for incr in $LASTEST_INCR_BASK; do
        DIR_INCR="$DIR_RESTORE/incr/$(basename $incr)"

        rm -rf $DIR_INCR
        mkdir -p $DIR_INCR

        echo "Decompression de la sauvegarde incr $incr dans $DIR_INCR"
        $GZIP_CMD $incr/backup.stream.gz | mbstream -x -C $DIR_INCR

        echo "Application incrémentale des modifications"
        #--apply-log-only
        mariabackup --prepare --target-dir $DIR_RESTORE/base --user $MYSQL_USER --password "$MYSQL_PASSWORD" --incremental-dir $DIR_INCR
        [ $? -eq 0 ] || exit 1
        echo "OK"

        rm -rf $DIR_INCR
done

tree $DIR_RESTORE

echo "Arret du service"
systemctl stop mariadb

echo "Sauvegarde de la base"
DIR_BACKUP_DATA=/backups/backup_data/
rm -rf $DIR_BACKUP_DATA
mkdir -p $DIR_BACKUP_DATA
rsync -avz $DATADIR/* $DIR_BACKUP_DATA

rm -rf $DATADIR/*

echo "Restauration des fichiers"
mariabackup --copy-back --target-dir $DIR_RESTORE/base --user $MYSQL_USER --password "$MYSQL_PASSWORD" --datadir $DATADIR
[ $? -eq 0 ] || exit 1

chown mysql. $DATADIR -R

echo "Démarrage du service"
systemctl start mariadb
[ $? -eq 0 ] || exit 1

# Suppression des dossiers de restauration
rm -rf $DIR_RESTORE

exit 0
