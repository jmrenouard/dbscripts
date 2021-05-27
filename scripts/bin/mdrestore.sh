#!/usr/bin/env bash

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh

banner "RESTORING DB"
BCK_DIR=/data/backups/logical
#GZIP_CMD="cat"
#GZIP_CMD="gzip -cd"
GZIP_CMD="pigz -cd"

[ -f "/etc/lgconfig.sh" ] && source /etc/lgconfig.sh

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
        footer "RESTORING DB"
        die "CANCEL BY USER"
    fi
fi

# now we can use the selected file
info "$DUMP_FILE will be restored"

info "Checking SHA256 SIGN file"
sha256sum -c ${DUMP_FILE}.sha256sum
lRC=$?

my_status
if [ $? -ne 0 ]; then
    error "LOGICAL RESTORE FAILED: Server must be running ...."
    info "FINAL CODE RETOUR: $lRC"
    footer "RESTORING DB"
    exit 2
fi

# check access root before inserting database
# adding time command

#mysql -u root -e 'show processlist'
#systemctl stop mysql
#rm -rf /var/lib/mysql/*
#mysql_install_db --user=mysql
#ls -lsah /var/lib/mysql
#systemctl start mysql
#watch "mysql -u root -e 'show processlist'"

if [ $lRC -eq 0 ]; then
	myloader --directory /data/backups/mydumper/employees/20210527-204553 --verbose=3 --threads=4 --overwrite-tables --database employees2  --source-db=employees --purge-mode DROP
    info "CMD: $GZIP_CMD $DUMP_FILE | mysql -uroot -f -v mysql"
    $GZIP_CMD $DUMP_FILE | time mysql -uroot -f mysql
    lRC=$?
    [ $lRC -eq 0 ] && ok "RESTORE OK"
    cmd "db_list"
    cmd "db_tables"
fi

info "FINAL CODE RETOUR: $lRC"
footer "RESTORING DB"
exit $lRC