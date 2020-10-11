#!/bin/bash

DATE_RESTORE=$(date +"%Y-%m-%d %H:%M:%S")
[ -n "$1" -a -n "$2" ] && DATE_RESTORE=$(date -d "$1 $2" +"%Y-%m-%d %H:%M:%S")

DIR_RESTORE="/backups/mariabackup/restore_$(echo $DATE_RESTORE | tr ' ' '_' | tr ':' '-')"
echo "RESTORE DIR: $DIR_RESTORE"

# Récupération de la dernière sauvegrade full
LAST_BASE_BACK=$(find /backups/mariabackup/base -mindepth 1 -maxdepth 1 -type d ! -newermt "$DATE_RESTORE" | sort -n | tail -1)

# Récupération des incrémentales correspondantes
LASTEST_INCR_BASK=$(find /backups/mariabackup/incr -mindepth 2 -maxdepth 2 -type d ! -newermt "$DATE_RESTORE" | sort -n | grep "$(basename $LAST_BASE_BACK)")

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
cat $LAST_BASE_BACK/backup.stream.gz | unpigz -c | mbstream -x -C $DIR_RESTORE/base
mariabackup --prepare --target-dir $DIR_RESTORE/base --user backup --password "6acd1f1cd53f4fec69713457a99d5e71" --apply-log-only
[ $? -eq 0 ] || exit 1
echo "OK"

# Décompression de toutes les incrémentales
for incr in $LASTEST_INCR_BASK; do
        DIR_INCR="$DIR_RESTORE/incr/$(basename $incr)"

        rm -rf $DIR_INCR
        mkdir -p $DIR_INCR

        echo "Decompression de la sauvegarde incr $incr dans $DIR_INCR"
        cat $incr/backup.stream.gz | unpigz -c | mbstream -x -C $DIR_INCR

        echo "Application incrémentale des modifications"
        mariabackup --prepare --target-dir $DIR_RESTORE/base --user backup --password "6acd1f1cd53f4fec69713457a99d5e71" --apply-log-only --incremental-dir $DIR_INCR
        [ $? -eq 0 ] || exit 1
        echo "OK"

        rm -rf $DIR_INCR
done

tree $DIR_RESTORE

echo "Arret du service"
systemctl stop mysqld

echo "Sauvegarde de la base"
DIR_BACKUP_DATA=/backups/backup_data/
rm -rf $DIR_BACKUP_DATA
mkdir -p $DIR_BACKUP_DATA
rsync -avz /data $DIR_BACKUP_DATA

rm -rf /data/*

echo "Restauration des fichiers"
mariabackup --copy-back --target-dir $DIR_RESTORE/base --user backup --password "6acd1f1cd53f4fec69713457a99d5e71" --datadir /data
[ $? -eq 0 ] || exit 1

chown mysql. /data -R

echo "Démarrage du service"
systemctl start mysqld
[ $? -eq 0 ] || exit 1

# Suppression des dossiers de restauration
rm -rf $DIR_RESTORE

exit 0
