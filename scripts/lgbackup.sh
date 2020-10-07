#!/bin/sh

#set -x

BCK_DIR=/data/backups/logical
GZIP_CMD=gzip
#GZIP_CMD=pigz

BCK_FILE=$BCK_DIR/backup_$(date +%Y%m%d-%H%M).sql.gz
lRC=0

msg()
{
echo "--------------------------------------"
echo "-- $*"
echo "--------------------------------------"
}

msg "Desynchronisation du noeud"
# desync
mysql -e 'set global wsrep_desync=on'

msg  "etat Desynchronisation"
mysql -e 'select @@wsrep_desync'

msg "Backup logique mysldump dans le fichier $(basename $BCK_FILE)"
time mysqldump --all-databases --master-data=1 --flush-logs --add-drop-database --routines --opt --triggers --events --single-transaction | $GZIP_CMD > $BCK_FILE
lRC=$?

if [ $lRC -eq 0 ]; then
	echo "BACKUP OK SUPER RAS"
else
	echo "PROBLEME BACKUP"
fi

msg Liste fichier
ls -lsh $BCK_FILE

msg "Fin du fichier"
zcat $BCK_FILE | tail -n 5 | grep "Dump completed"

msg desync off
mysql -e 'set global wsrep_desync=off'

msg etat Desynchronisation
mysql -e 'select @@wsrep_desync'

msg "POSITION LOGBIN"
zcat $BCK_FILE | head -n 40 | grep -E 'CHANGE MASTER'

msg  "FINAL CODE RETOUR: $lRC"
exit $lRC
