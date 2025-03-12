#!/bin/bash

# ==========================================================
# Script : Restore Binlog GTID
# Date    : March 12, 2025
# Version : 1.3
#
# Description:
# This script restores MariaDB binlog events from
# a given GTID up to a specific date.
# It performs the following steps:
# 1. Retrieve the current GTID position.
# 2. Identify the binlog file containing this GTID.
# 3. Select subsequent binlog files for recovery.
# 4. Execute mariadb-binlog to replay transactions
#    up to the specified date.
#
# Parameters:
# $1 - Path to the directory containing binlog files
# $2 - End date for recovery (format: YYYY-MM-DD)
# $3 - End time for recovery (format: HH:MM:SS)
# ==========================================================

# Define paths to utilities
MARIADBBINLOG="/usr/bin/mariadb-binlog"  # Modify if necessary
MARIADB="/usr/bin/mariadb"              # Modify if necessary

# Define the pattern for binlog files
BINLOG_PATTERN="log_bin*"  # Modify if necessary

# Check if required parameters are provided
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
    echo "[ERROR] Usage: $0 <binlog_path> <stop_date (YYYY-MM-DD)> <stop_time (HH:MM:SS)>"
    exit 1
fi

BINLOG_PATH="$1"   # Store the binlog file directory path
STOP_DATE="$2"      # Store the recovery end date
STOP_TIME="$3"      # Store the recovery end time
STOP_DATETIME="$STOP_DATE $STOP_TIME" # Construct the complete recovery timestamp

echo "[INFO] Script execution started"
echo "[INFO] Binlog path: $BINLOG_PATH"
echo "[INFO] Stop datetime: $STOP_DATETIME"

# Retrieve the current GTID position
GTID_EXECUTED=$($MARIADB -Nrs -e "SHOW VARIABLES LIKE 'gtid_current_pos'" | awk '{print $2}')

echo "[INFO] Executed GTID: $GTID_EXECUTED"

# Find the binlog file containing the GTID reference
echo "[INFO] Searching for the binlog file containing the GTID..."
BINLOG_GTID_FILE=$(for i in "$BINLOG_PATH"/$BINLOG_PATTERN; do
    $MARIADBBINLOG --base64-output=DECODE-ROWS "$i" | grep -aq "$GTID_EXECUTED"; # Check if GTID is present in the file
    if [ $? -eq 0 ]; then
        echo "$i"
        break
    fi
done)

echo "[INFO] Binlog file containing GTID $GTID_EXECUTED: $BINLOG_GTID_FILE"

# Check if a binlog file was found
if [ -z "$BINLOG_GTID_FILE" ]; then
    echo "[ERROR] No binlog file containing the GTID was found."
    exit 1
fi

# Find binlog files after the one containing the GTID
echo "[INFO] Searching for binlog files after the GTID..."
BINLOG_FILES=$(ls -1 "$BINLOG_PATH"/$BINLOG_PATTERN | sed "0,/$(basename $BINLOG_GTID_FILE)/d" )

echo "[INFO] Binlog files after the GTID:"
echo "$BINLOG_FILES"

# Check if binlog files were found
if [ -z "$BINLOG_FILES" ]; then
    echo "[ERROR] No binlog files found after the GTID."
    exit 1
fi

# Restore events up to a specific date
echo "[INFO] Starting event restoration..."
$MARIADBBINLOG $BINLOG_FILES --stop-datetime="$STOP_DATETIME" | $MARIADB -f --binary-mode=1 # Replay logs up to the specified timestamp
if [ $? -eq 0 ]; then
  echo "[INFO] Restoration completed successfully"
  exit 0
fi
echo "[WARN] Restoration completed with errors"
exit 2
