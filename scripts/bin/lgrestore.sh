#!/bin/sh

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh

banner "RESTORING DB"
BCK_DIR=/data/backups/logical
#GZIP_CMD="cat"
#GZIP_CMD="gzip -cd"
GZIP_CMD="pigz -cd"

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
	select DUMP_FILE in $BCK_DIR/*.sql.gz
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
		footer "RESTORING DB"
		die "CANCEL BY USER"
	fi
fi

# now we can use the selected file
info "$DUMP_FILE will be restored"

info "CMD: $GZIP_CMD $DUMP_FILE | time mysql -f -v"
$GZIP_CMD $DUMP_FILE | time mysql -f
lRC=$?
[ $lRC -eq 0 ] && ok "RESTORE OK"

cmd "db_list"
cmd "db_tables"

info "FINAL CODE RETOUR: $lRC"
footer "RESTORING DB"
exit $lRC