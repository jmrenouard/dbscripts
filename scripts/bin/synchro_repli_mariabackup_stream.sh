#!/bin/bash
set -euo pipefail

# --- Minimal Utility Functions ---
now() { echo "$(date "+%F %T %Z")($(hostname -s))"; }
info() { echo "$(now) INFO: $*" 1>&2; }
error() { echo "$(now) ERROR: $*" 1>&2; return 1; }
ok() { info "[SUCCESS] $* [SUCCESS]"; }
sep1() { echo "$(now) -----------------------------------------------------------------------------"; }
title1() { sep1; echo "$(now) $*"; sep1; }
cmd() {
    local tcmd="$1"
    local descr=${2:-"$tcmd"}
    title1 "RUNNING: $descr"
    set +e
    eval "$tcmd"
    local cRC=$?
    set -e
    if [ $cRC -eq 0 ]; then
        ok "$descr"
    else
        error "$descr (RC=$cRC)"
    fi
    return $cRC
}
banner() { title1 "START: $*"; info "run as $(whoami)@$(hostname -s)"; }
footer() {
    local lRC=${lRC:-"$?"}
    info "FINAL EXIT CODE: $lRC"
    [ $lRC -eq 0 ] && title1 "END: $* SUCCESSFUL" || title1 "END: $* FAILED"
    return $lRC
}
# --- End of Utility Functions ---

# Load external configs if available
[ -f "/etc/bootstrap.conf" ] && source /etc/bootstrap.conf

# Defines a 'Usage' function that displays the script's help message.
Usage () {
# Uses a "here document" (cat << !FINHELP!) to display a multi-line text block.
cat << !FINHELP!

$(basename $0) -e pass-exploit -u user-maria -r pass-maria -p project
--------------------------------------------------------------------------------------------------
-e            : Password for the exploit account on the MariaDB Master server
-u            : Source account user
-r            : Password for the source MariaDB root account
-p            : Project name present in /data/mariadb (e.g., transmed)

!FINHELP!
}

# Checks if the number of arguments ($#) is 0.
if [ $# -eq 0 ]; then
       # If no arguments are passed, display help and exit.
       Usage
       exit 1
fi

# -- ------------------------------------------------------------------------------------
# -- Options
# -- -------------------------------------------------------------------------------------
# Loop as long as there are arguments to process.
while [ $# -gt 0 ]; do
       # Use a 'case' structure to process the current argument ($1).
       case $1 in
         # If the argument is -e, assign the next value ($2) to the SSHPASS variable.
         -e)           SSHPASS=$2
                       # Shift arguments by two positions to move to the next ones.
                       shift 2
                       ;;
         # Similar processing for -r, -p, -u options.
         -r)           ROOT_MARIADB_PASS=$2
                       shift 2
                       ;;
         -p)           project=$2
                       shift 2
                       ;;
         -u)           USER_MARIADB=$2
                       shift 2
                       ;;
         # If the argument is --help or -h, display help and exit.
         --help|-h)    Usage
                       exit;;
         # For any other unrecognized argument, shift by one position and ignore it.
         *) shift 1
       esac
done

# Check if mandatory variables are empty. If so, display help and exit with an error code.
[ -z "${SSHPASS}" ] && Usage && exit 1
[ -z "${USER_MARIADB}" ] && Usage && exit 1
[ -z "${ROOT_MARIADB_PASS}" ] && Usage && exit 1
[ -z "${project}" ] && Usage && exit 1

# Detect encryption by looking for the Hashicorp token in MariaDB configuration files.
TOKEN=$(cat /etc/mysql/mariadb.conf.d/5*.cnf | grep "hashicorp-key-management-token"  |cut -d'=' -f2| sed -e 's/"//g' |xargs -n1)
# If the TOKEN variable is not empty, encryption is detected.
[ ! -z ${TOKEN} ] && echo "Encrypted database detected"

# Build the path to the project's data directory.
DATADIR="/data/mariadb/${project}"
# Check if the data directory does not exist. If so, display an error and exit.
[ ! -d ${DATADIR} ] && echo "Directory ${DATADIR} does not exist" && exit 1

# If the master.info file exists, read replication information directly from this file.
if [ -f "${DATADIR}/master.info" ] ;then
   # Extract information (host, user, password, port) by reading specific lines from the file.
   MASTER_HOST="$(sed '4q;d' $DATADIR/master.info)"
   MASTER_USER="$(sed '5q;d' $DATADIR/master.info)"
   MASTER_PASS="$(sed '6q;d' $DATADIR/master.info)"
   MASTER_PORT="$(sed '7q;d' $DATADIR/master.info)"
else
   # If the file does not exist, interactively ask the user for replication information.
   echo "File ${DATADIR}/master.info does not exist. Please enter MariaDB replication info: repl/pwd@master:port"
   read -p "Primary server FQDN: " MASTER_HOST
   read -p "Port: " MASTER_PORT
   read -p "Replication user [repl]: " MASTER_USER
   # Use 'repl' as the default value for the replication user if nothing is entered.
   MASTER_USER=${MASTER_USER:-repl}
   read -p "Password: " MASTER_PASS
fi

# Request manual confirmation to ensure supervision actions have been performed.
echo "Have you disabled supervision + maintenance mode for the MariaDB server in MaxScale? Press Enter to continue..."
# Pause the script until the user presses "Enter".
read pause

banner "MARIADB REPLICATION SYNCHRONIZATION"

cmd "usermod -aG mysql exploit" "ADDING EXPLOIT TO MYSQL GROUP"
cmd "usermod -aG sudo exploit" "ADDING EXPLOIT TO SUDO GROUP"

cmd "systemctl stop mariadb" "STOPPING MARIADB SERVICE"

# Move into the data directory.
cd $DATADIR
# Recursively delete all files and folders in the data directory and project binlogs.
cmd "rm -rf $DATADIR/*" "CLEANING DATA DIRECTORY"
cmd "rm -f /data/binlog/${project}/*" "CLEANING BINLOGS"

cmd "chown -R exploit:exploit $DATADIR" "FIXING PERMISSIONS FOR EXPLOIT"
cmd "chmod -R 770 $DATADIR" "SETTING DIRECTORY MODES"

# Use a subshell to execute the following commands.
cmd "echo \"echo '\$SSHPASS' | sudo -S VAULT_TOKEN='${TOKEN}' mariadb-backup --user=\$USER_MARIADB --password='\$ROOT_MARIADB_PASS' --backup --stream=xbstream\" | sshpass -p \"\$SSHPASS\" ssh -o StrictHostKeyChecking=no \$MASTER_HOST \"bash -s\" | (cd \$DATADIR; mbstream -v -x)" "STARTING STREAMING BACKUP FROM MASTER"
lRC=$?

cmd "export VAULT_TOKEN=${TOKEN}; mariadb-backup --user=$USER_MARIADB --password=$ROOT_MARIADB_PASS --prepare --target-dir=$DATADIR" "PREPARING RESTORED BACKUP"
cmd "chown -R mysql:mysql $DATADIR" "REASSIGNING PERMISSIONS TO MYSQL USER"
cmd "systemctl start mariadb.service" "STARTING MARIADB SERVICE"
lRC=$?

# Extract replication information (binlog file name, position, GTID) from the file created by mariabackup.
rfile=$(awk '{print $1}' $DATADIR/mariadb_backup_binlog_info)
posrfile=$(awk '{print $2}' $DATADIR/mariadb_backup_binlog_info)
gtid=$(awk '{print $3}' $DATADIR/mariadb_backup_binlog_info)

cmd "mariadb -uroot -p\"$ROOT_MARIADB_PASS\" <<!FIN_SQL!
STOP SLAVE;
RESET SLAVE;
SET GLOBAL gtid_slave_pos='$gtid';
CHANGE MASTER TO
MASTER_HOST='$MASTER_HOST',
MASTER_USER='$MASTER_USER',
MASTER_PASSWORD='$MASTER_PASS',
MASTER_PORT=$MASTER_PORT,
MASTER_LOG_FILE='$rfile',
MASTER_LOG_POS=$posrfile,
MASTER_USE_GTID = slave_pos;
START SLAVE;
!FIN_SQL!" "RECONFIGURING REPLICATION"

sleep 2s

cmd "mariadb -uroot -p\"$ROOT_MARIADB_PASS\" -e \"show slave status\\G\" | grep -i Running" "CHECKING REPLICATION STATUS"
lRC=$?

footer "MARIADB REPLICATION SYNCHRONIZATION"
exit $lRC