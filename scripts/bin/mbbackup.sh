#!/bin/bash
#set -x

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

BCK_DIR=/data/backups/mariabackup
KEEP_LAST_N_BACKUPS=5
GZIP_CMD=pigz
#GZIP_CMD=gzip
#GZIP_CMD=tee

if [ -f "/root/.my.cnf" ]; then
	BACK_USER=$(grep -E '^user' $HOME/.my.cnf|head -n1| cut -d= -f2| xargs -n1)
	BACK_PASSWORD=$(grep -E '^password' $HOME/.my.cnf|head -n1| cut -d= -f2| xargs -n1)
fi
BCK_FILE=$BCK_DIR/backup_$(date +%Y%m%d-%H%M%S).xbstream.gz
LOG_FILE=$(echo $BCK_FILE|perl -pe 's/(.+).xbstream.gz/$1.log/g')



lRC=0

banner "MARIABACKUP BACKUP DB"
if [ -f "/etc/mbconfig.sh" ]; then
    info "LOADING CONFIG FROM /etc/mbconfig.sh"
    source /etc/mbconfig.sh
fi
if  [ -n "$1" -a -f "/etc/mbconfig_$TARGET_CONFIG.sh" ]; then
    info "LOADING CONFIG FROM /etc/mbconfig_$TARGET_CONFIG.sh"
    source /etc/mbconfig_$TARGET_CONFIG.sh
fi

if [ "$1" = "-l" -o "$1" = "--list" ]; then
    ls -lsht $BCK_DIR
    exit 0
fi

if [ "$1" = "-a" -o "$1" = "--addcrontab" ]; then
    [ -f "/etc/cron.d/mbbackup" ] && rm -f /etc/cron.d/mbbackup
    echo "${3:-"00"} ${2:-"02"} * * * root bash /opt/local/bin/mbbackup.sh" | tee /etc/cron.d/mbbackup
    chmod 644 /etc/cron.d/mbbackup
    #cat /etc/cron.d/mbbackup
    ls -lsh /etc/cron.d
    systemctl restart cron
    exit 0
fi

if [ "$1" = "-r" -o "$1" = "--removecrontab" ]; then
    [-f "/etc/cron.d/mbbackup" ] && rm -f /etc/cron.d/mbbackup
    ls -lsh /etc/cron.d
    systemctl restart cron
    exit 0
fi

[ -d "$BCK_DIR" ] || mkdir -p $BCK_DIR

info "Backup mariabackup dans le fichier $(basename $BCK_FILE)"
info "CMD: mariabackup --backup --user=${BACK_USER} --password=XXXXXXX --stream=xbstream | $GZIP_CMD"
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

info "Adding signature file"
sha256sum $BCK_FILE > ${BCK_FILE}.sha256sum

info Liste fichier backup
ls -lsh $BCK_DIR

info "BACKUP DIRECTORY: $BCK_DIR"
info "BACKUP FILE NAME: $(basename $BCK_FILE)"
info "BACKUP FILE SUM : $(basename $BCK_FILE.sha256sum)"
info "BACKUP FILE LOG : $(basename $LOG_FILE)"
info "BACKUP FILE SIZE: $(du -sh $BCK_FILE| awk '{print $1}')"
info "FINAL CODE RETOUR: $lRC"
footer "MARIABACKUP BACKUP DB"
exit $lRC
