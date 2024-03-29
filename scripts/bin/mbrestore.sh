#!/bin/bash

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
TMP_DIR=/data/backups/tmp
DATADIR=/var/lib/mysql
#GZIP_CMD="cat"
#GZIP_CMD="gzip -cd"
GZIP_CMD="pigz -cd"
lRC=0

banner "MARIABACKUP RESTORING DB"
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

GALERA_SUPPORT=$(galera_is_enabled)

if [ "$GALERA_SUPPORT" = "1" ]; then
    info "GALERA IS ACTIVATED"
    echo -e "\t* Disable Galera with wsrep_on=off in configuration file"
    echo -e "\t* Drop Galera Cache /var/lib/mysql/galera.cache"
    echo -e "\t* Restart MariaDB or MySQL (systemctl restart mysql)"
    echo -e "\t* Restart restore script $0 $*"
    exit 1
fi

DUMP_FILE=$1
if [ -z "$DUMP_FILE" ]; then
	echo "The following archives were found; select one:"
	PS3="Use number to select a file or 'stop' to cancel: "

	# allow the user to choose a file
	select DUMP_FILE in $BCK_DIR/*.xbstream.gz
	do
	    # leave the loop if the user says 'stop'
	    if [[ "$REPLY" == stop ]]; then
	    	break;
	    fi

	    # complain if no file was selected, and loop to ask again
	    if [[ "$DUMP_FILE" == "" ]]
	    then
	        echo "'$REPLY' is not a valid number"
	        continue
	    fi
	    break
	done
fi

if [ ! -f "$DUMP_FILE" ]; then
	warn "$DUMP_FILE doesnt exist"
	lRC=127
fi

if [ "$2" != "-f" -a "$2" != "--force" ]; then
	title1 "FILE TO RESTORE"
	ls -lsht $DUMP_FILE
	info "Do you really want to restore $DUMP_FILE ?"
	ask_yes_or_no
	if [ $? -ne 0 ];then
		lRC=127
		footer "MARIABACKUP RESTORING DB"
		die "CANCEL BY USER"
	fi
fi

info "Checking SHA256 SIGN file"
sha256sum -c ${DUMP_FILE}.sha256sum
lRC=$?

# now we can use the selected file
info "$DUMP_FILE will be restored"

[ -d "$TMP_DIR" ] || mkdir -p $TMP_DIR
rm -rf "$TMP_DIR/*"

info "CMD: $GZIP_CMD $DUMP_FILE | mbstream -x"
cd $TMP_DIR
$GZIP_CMD $DUMP_FILE | mbstream -x
lRC=$?
info "PREPARING RESTORE"
mariabackup --prepare --target-dir=.

ls -lsh $TMP_DIR

if [ $lRC -eq 0 ]; then
	#chown -R mysql.mysql $TMP_DIR/*
	systemctl stop mariadb
	mv ${DATADIR} ${BCK_DIR}/sav_datadir_$(date +%Y%m%d-%H%M%S)
	rm -rf $DATADIR/*
	mkdir -p ${DATADIR}
	rsync -avz $TMP_DIR/* $DATADIR/
	chown -R mysql.mysql $DATADIR
	systemctl start mariadb
	[ $? -eq 0 ] && rm -rf $TMP_DIR
fi

lRC=$?
[ $lRC -eq 0 ] && ok "MARIABACKUP RESTORE OK"

cmd "db_list"

info "FINAL CODE RETOUR: $lRC"
footer "MARIABACKUP RESTORING DB"
exit $lRC