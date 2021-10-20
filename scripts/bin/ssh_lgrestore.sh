#!/usr/bin/env bash

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh

BCK_DIR=/data/backups/logical
#GZIP_CMD="cat"
#GZIP_CMD="gzip -cd"
GZIP_CMD="pigz -cd"
TARGET_CONFIG=$(to_lower $1)
lRC=0

banner "SSH LOGICAL RESTORE"

if [ -f "/etc/backupbdd/ssh_lgconfig.sh" ]; then
    info "LOADING CONFIG FROM /etc/backupbdd/ssh_lgconfig.sh"
    source /etc/backupbdd/ssh_lgconfig.sh
fi
if  [ -n "$1" -a -f "/etc/backupbdd/ssh_lgconfig_$TARGET_CONFIG.sh" ]; then
    info "LOADING CONFIG FROM /etc/backupbdd/ssh_lgconfig_$TARGET_CONFIG.sh"
    source /etc/backupbdd/ssh_lgconfig_$TARGET_CONFIG.sh
fi

SSH_CMD="ssh -q -i $SSH_PRIVATE_KEY $SSH_USER@$SSH_HOSTNAME"

if [ -z "$SSH_HOSTNAME" ]; then
    error "SSH LOGICAL RESTORE FAILED: WRONG CONFIG FOR $TARGET_CONFIG...."
    lRC=2 footer "SSH LOGICAL RESTORE"
    exit 2
fi
if [ "$2" = "-l" -o "$2" = "--list" ]; then
    ls -lsht $BCK_DIR
    exit 0
fi
GALERA_SUPPORT=$(galera_is_enabled)

if [ "$GALERA_SUPPORT" = "1" ]; then
    warning "GALERA IS ACTIVATED"
    echo -e "\t* Disable Galera with wsrep_on=off in configuration file"
    echo -e "\t* Drop Galera Cache /var/lib/mysql/galera.cache"
    echo -e "\t* Restart MariaDB or MySQL (systemctl restart mysql)"
    echo -e "\t* Restart restore script $0 $*"

    error "Server must NOT be running Galera Configuration...."
    lRC=2 footer "SSH LOGICAL RESTORE"
    exit 2
fi

DUMP_FILE=$2
if [ -n "$DUMP_FILE" -a ! -f "$DUMP_FILE" ]; then
    DUMP_FILE="$BCK_DIR/$DUMP_FILE"
fi
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
    lRC=127 footer "SSH LOGICAL RESTORE"
fi

if [ "$3" != "-f" -a "$3" != "--force" ]; then
    title1 "FILE TO RESTORE: $(basename $DUMP_FILE)"
    ls -lsht $DUMP_FILE
    info "Do you really want to restore $DUMP_FILE ON $SSH_HOSTNAME ?"
    ask_yes_or_no
    if [ $? -ne 0 ];then
        lRC=127
        footer "SSH LOGICAL RESTORE"
        die "CANCEL BY USER"
    fi
fi

# now we can use the selected file
info "$DUMP_FILE will be restored"

if [ -f "${DUMP_FILE}.sha256sum" ];then
    info "Checking SHA256 SIGN file"
    sha256sum -c ${DUMP_FILE}.sha256sum
    lRC=$?
else
    error "MISSING ${DUMP_FILE}.sha256sum SIG FILE"
    lRC=$(($lRC +1))
fi

my_status
if [ $? -ne 0 ]; then
    error "LOGICAL RESTORE FAILED: Server must be running ...."
    info "FINAL CODE RETOUR: $lRC"
    footer "SSH LOGICAL RESTORE"
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
#exit 1
if [ $lRC -ne 0 ]; then
    lRC=2 footer "SSH LOGICAL RESTORE"
    exit $lRC
fi

start_timer "RESTORE"
title2 "SSH RESTORE TO $SSH_HOSTNAME"
info "CMD: $GZIP_CMD -cd $DUMP_FILE | $SSH_CMD mysql -f"
(   echo "set SESSION sql_log_bin=0;"
    $GZIP_CMD -cd $DUMP_FILE
) | $SSH_CMD mysql -f
lRC=$?
dump_timer "RESTORE"
[ $lRC -eq 0 ] && ok "RESTORE OK"
cmd "db_list"
cmd "db_tables"

lRC=$? footer "SSH LOGICAL RESTORE"
exit $lRC