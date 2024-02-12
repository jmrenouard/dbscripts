#!/usr/bin/env bash

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh

banner "RESTORING DB WITH MYLOADER"
BCK_DIR=/data/backups/mydumper
#GZIP_CMD="cat"
#GZIP_CMD="gzip -cd"
GZIP_CMD="pigz -cd"

[ -f "/etc/mdconfig.sh" ] && source /etc/mdconfig.sh

if [ "$1" = "-l" -o "$1" = "--list" ]; then
    ls -lsht $BCK_DIR
    exit 0
fi
if [ "$2" = "-l" -o "$2" = "--list" ]; then
    ls -lsht $BCK_DIR/$1/
    exit 0
fi
GALERA_SUPPORT=$(galera_is_enabled)

if [ "$GALERA_SUPPORT" = "1" ]; then
    info "GALERA IS ACTIVATED"
    echo -e "\t* Disable Galera with wsrep_on=off in configuration file"
    echo -e "\t* Drop Galera Cache /var/lib/mysql/galera.cache"
    echo -e "\t* Restart MariaDB or MySQL (systemctl restart mysql)"
    echo -e "\t* Restart restore script $0 $*"
    exit 1
fi

sourcedb=$1
dumpdir=$2
targetdb=$3

if [ -z "$sourcedb" ]; then
	title2 "SELECTING SOURCE DATABASE"
	select sourcedb in $(ls -1 $BCK_DIR)
	do
	# leave the loop if the user says 'stop'
    if [[ "$REPLY" == stop ]]; then
        break;
    fi

    # complain if no file was selected, and loop to ask again
    if [[ "$sourcedb" == "" ]]
    then
        echo "'$REPLY' is not a valid number"
        continue
    fi
    break
    done
fi
info "SOURCE DATABASE IS $sourcedb"

if [ -z "$dumpdir" ]; then
	title2 "SELECTING $sourcedb EXTRACTION"
	select dumpdir in $(ls -1 $BCK_DIR/$sourcedb| sort -nr)
	do
	# leave the loop if the user says 'stop'
    if [[ "$REPLY" == stop ]]; then
        break;
    fi

    # complain if no file was selected, and loop to ask again
    if [[ "$dumpdir" == "" ]]
    then
        echo "'$REPLY' is not a valid number"
        continue
    fi
    break
    done
fi
info "DATABASE EXTRACTION DIR IS $BCK_DIR/$sourcedb/$dumpdir"
if [ ! -d "$BCK_DIR/$sourcedb/$dumpdir" ]; then
    die "$BCK_DIR/$sourcedb/$dumpdir doesnt exist"
fi

if [ -z "$targetdb" ]; then
	ask_yes_or_no "Restore on $sourcedb database "
	[ $? -eq 0 ] && targetdb=$sourcedb
fi

if [ -z "$targetdb" ]; then
	echo -e
	read -p 'Target dabase name : ' targetdb
fi

info "TARGET DATABASE IS $sourcedb"


title1 "Command: time myloader \
--directory $BCK_DIR/$sourcedb/$dumpdir \
--verbose=3  \
--threads=$(nproc) \
--overwrite-tables \
--database $targetdb \
--source-db=$sourcedb \
--purge-mode DROP"

time myloader \
--directory $BCK_DIR/$sourcedb/$dumpdir \
--verbose=3  \
--threads=$(nproc) \
--overwrite-tables \
--database $targetdb \
--source-db=$sourcedb \
--purge-mode DROP
lRC=$?
[ $lRC -eq 0 ] && ok "RESTORE OK"
cmd "db_list"
cmd "db_tables"

info "FINAL CODE RETOUR: $lRC"
footer "RESTORING DB WITH MYLOADER"
exit $lRC