#!/bin/sh
#set -x

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh

BCK_DIR=/data/backups/mariabackup
KEEP_LAST_N_BACKUPS=5
GZIP_CMD=pigz
#GZIP_CMD=gzip
#GZIP_CMD=tee

BACK_USER=$(grep -E '^user' $HOME/.my.cnf|head -n1| cut -d= -f2| xargs -n1)
BACK_PASSWORD=$(grep -E '^password' $HOME/.my.cnf|head -n1| cut -d= -f2| xargs -n1)
BCK_FILE=$BCK_DIR/backup_$(date +%Y%m%d-%H%M%S).xbstream.gz
LOG_FILE=$(echo $BCK_FILE|perl -pe 's/(.+).xbstream.gz/$1.log/g')
lRC=0

banner "MARIABACKUP BACKUP DB"
[ -d "$BCK_DIR" ] || mkdir -p $BCK_DIR

info "Backup mariabackup dans le fichier $(basename $BCK_FILE)"
info "CMD: mariabackup --backup --user=${BACK_USER} --password=${BACK_PASSWORD} --stream=xbstream | $GZIP_CMD"
info "DUMP_FILE: $BCK_FILE"
info "LOG_FILE : $LOG_FILE"
time mariabackup --backup --user=${BACK_USER} --password=${BACK_PASSWORD} --stream=xbstream 2> $LOG_FILE | $GZIP_CMD > $BCK_FILE
lRC=$?
echo "................."
tail -n 20 $LOG_FILE

if [ $lRC -eq 0 ]; then
	echo "BACKUP OK ..........."
else
	die "PROBLEME BACKUP"
	footer "MARIABACKUP BACKUP DB"
fi

info "Fin du fichier $(basename $LOG_FILE)"
tail -n 5 $LOG_FILE| grep "completed OK!"
lRC=$(($lRC + $?))

if [ $lRC -eq 0 -a -n "$KEEP_LAST_N_BACKUPS" ]; then
	info "KEEP LAST $KEEP_LAST_N_BACKUPS BACKUPS"
	ls -tp $BCK_DIR| grep -v '/$'| tail -n +$(($KEEP_LAST_N_BACKUPS*2 +1)) | while IFS= read -r f; do
		info "Removing $f";
		rm -f $BCK_DIR/$f
	done
fi
info Liste fichier backup
ls -lsh $BCK_DIR

info "FINAL CODE RETOUR: $lRC"
footer "MARIABACKUP BACKUP DB"
exit $lRC
