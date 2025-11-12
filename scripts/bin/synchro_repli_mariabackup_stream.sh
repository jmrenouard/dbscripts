#!/bin/bash

# ------------------------------------------------------------------------------------
# Script Name   : synchro_repli_mariabackup_stream.sh
# Author        : Jean-Marie Renouard (jmrenouard)
# Date          : 18/09/2025
# Version       : 1.2
#
# Description   :
# This script is designed to resynchronize a MariaDB 11+ secondary node (slave)
# from a primary node (master). It automates the backup and restore process
# using mariadb-backup.
#
# The script performs the following actions:
#   1. Stops the MariaDB service on the secondary node.
#   2. Cleans up the old data directory and binlogs.
#   3. Executes mariadb-backup in streaming mode via SSH from the primary server.
#   4. Prepares the restored backup (`--prepare`).
#   5. Restarts the MariaDB service.
#   6. Reconfigures GTID replication based on information from the backup.
#   7. Checks the replication status.
#
# Parameters    :
#   -e <pass>   : Password for the 'exploit' account on the primary server.
#   -u <user>   : MariaDB user for the backup (e.g., root).
#   -r <pass>   : Password for the MariaDB backup user.
#   -p <project> : Project name (corresponds to the directory in /data/mariadb/).
#
# Prerequisites :
#   - sshpass, mariadb-backup (client), and mbstream must be installed on the secondary node.
#   - The 'exploit' user must exist on the primary and have sudo rights
#     to run mariadb-backup.
#   - SSH access from the secondary to the primary for the 'exploit' user is required.
#
# Usage         :
#   ./resync_mariadb_slave.sh -e 'exploit-pass' -u 'maria-user' -r 'maria-pass' -p 'project'
# ------------------------------------------------------------------------------------

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

# Add the 'exploit' user to the 'mysql' group to give necessary permissions on MariaDB files.
usermod -G mysql exploit
# Add the 'exploit' user to the 'sudo' group to allow executing commands with elevated privileges.
usermod -G sudo exploit

echo "Stopping MariaDB service..."
systemctl stop mariadb

# Move into the data directory.
cd $DATADIR
# Recursively delete all files and folders in the data directory and project binlogs.
echo "Cleaning up data directory and binlogs..."
rm -rf $DATADIR/* && rm -f /data/binlog/${project}/*

# Change the owner and group of the current directory to 'exploit'.
chown -R exploit:exploit .
# Give read, write, and execute permissions to the owner and group, but none to others.
chmod -R 770 .

# Use a subshell to execute the following commands.
(
# Switch to the 'exploit' user and execute commands in the "here document" (<<EOF).
su - exploit <<EOF
# Execute mariadb-backup on the master server via SSH.
# sshpass provides the password for non-interactive SSH connection.
# -o StrictHostKeyChecking=no ignores SSH host key checking.
# On the remote server, 'echo '$SSHPASS' | sudo -S' passes the password to sudo to run mariadb-backup with root privileges.
# VAULT_TOKEN is passed as an environment variable for encryption.
# --stream=xbstream sends the backup as a continuous stream instead of saving it to a file on the master.
# The stream is then redirected ('|') to the 'mbstream -v -x' command, which extracts it directly into the $DATADIR directory.
echo "Starting streaming backup from the master..."
sshpass -p "$SSHPASS" ssh -o StrictHostKeyChecking=no $MASTER_HOST "echo '$SSHPASS' |\
sudo -S VAULT_TOKEN="${TOKEN}" mariadb-backup --user=$USER_MARIADB --password='$ROOT_MARIADB_PASS' \
--backup --stream=xbstream" | \
(cd $DATADIR; mbstream -v -x)
EOF
)

# Export the Vault token as an environment variable for the next command.
export VAULT_TOKEN=${TOKEN}
# Prepare the restored backup. This step is crucial as it applies logs and makes the data consistent.
echo "Preparing the restored backup..."
mariadb-backup --user=$USER_MARIADB --password=$ROOT_MARIADB_PASS --prepare --target-dir=$DATADIR

# Change the owner and group of the directory back to 'mysql', the user under which the MariaDB service runs.
echo "Reassigning permissions to the mysql user..."
chown -R mysql:mysql .

# Restart the MariaDB service.
echo "Starting MariaDB service..."
systemctl start mariadb.service
# Check the return code of the previous command. If not 0 (error), display a message and exit.
[[ $? -ne 0 ]] && {
       echo "Could not start MariaDB service"
       exit 1
}

# Extract replication information (binlog file name, position, GTID) from the file created by mariabackup.
rfile=$(awk '{print $1}' $DATADIR/mariadb_backup_binlog_info)
posrfile=$(awk '{print $2}' $DATADIR/mariadb_backup_binlog_info)
gtid=$(awk '{print $3}' $DATADIR/mariadb_backup_binlog_info)

# Execute a series of SQL commands to reconfigure replication.
echo "Reconfiguring replication..."
mariadb -uroot -p"$ROOT_MARIADB_PASS"<<!FIN_SQL!
stop slave;
reset slave;
SET GLOBAL gtid_slave_pos='$gtid';
CHANGE MASTER TO
MASTER_HOST='$MASTER_HOST',
MASTER_USER='$MASTER_USER',
MASTER_PASSWORD='$MASTER_PASS',
MASTER_PORT=$MASTER_PORT,
MASTER_LOG_FILE='$rfile',
MASTER_LOG_POS=$posrfile,
MASTER_USE_GTID = slave_pos;
start slave;
!FIN_SQL!

# Short pause to allow replication to initialize.
sleep 2s

# Check the replication status and filter for lines containing "Running" to confirm that both threads (IO and SQL) are active.
echo "Checking replication status..."
mariadb -uroot -p"$ROOT_MARIADB_PASS" -e "show slave status\G" | grep -i Running

# Check the return code of the 'grep' command. If it found nothing, it means there is a replication problem.
[[ $? -ne 0 ]] && {
       echo "Replication problem on the secondary node $HOSTNAME"
       exit 1
}

echo "Resynchronization completed successfully."

exit 0