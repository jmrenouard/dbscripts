#!/bin/sh

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh

banner "MARIABACKUP RESTORING DB"
BCK_DIR=/data/backups/mariabackup
TMP_DIR=/data/backups/tmp
#GZIP_CMD="cat"
#GZIP_CMD="gzip -cd"
GZIP_CMD="pigz -cd"

if [ "$1" = "-l" -o "$1" = "--list" ]; then
	ls -lsht $BCK_DIR
	exit 0
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
	warn "$DUMP_FILE doeasnt exist"
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

# now we can use the selected file
info "$DUMP_FILE will be restored"

[ -d "$TMP_DIR" ] || mkdir -p $TMP_DIR
rm -rf "$TMP_DIR/*"

info "CMD: $GZIP_CMD $DUMP_FILE | mbstream -x"

cd $TMP_DIR
$GZIP_CMD $DUMP_FILE | mbstream -x
lRC=$?

ls -lsh $TMP_DIR

if [ $lRC -ne 0 ]; then
	chown -R mysql.mysql $TMP_DIR/*
	systemctl stop mariadb
	rm -rf /var/lib/mysql/*
	rsync -avz $TMP_DIR/* /var/lib/mysql/
	systemctl start mariadb
	[ $? -eq 0 ] && rm -rf $TMP_DIR
fi

lRC=$?
[ $lRC -eq 0 ] && ok "MARAIBACKUP RESTORE OK"

cmd "db_list"

info "FINAL CODE RETOUR: $lRC"
footer "MARIABACKUP RESTORING DB"
exit $lRC