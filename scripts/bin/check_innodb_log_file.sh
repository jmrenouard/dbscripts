#!/usr/bin/env bash

# ==============================================================================
# Script: check_innodb_log_usage.sh
# Description: Monitors the InnoDB redo log usage rate by parsing the output
#              of 'SHOW ENGINE INNODB STATUS;'.
# Author: Jean-Marie Renouard
# Date: 12/06/2025
# Prerequisites:
#   - The 'mysql' client must be installed.
#   - The 'bc' utility for floating-point arithmetic.
#   - A ~/.my.cnf configuration file for credentials (recommended).
# ==============================================================================

# --- Configuration ---
# The script uses the standard ~/.my.cnf configuration file to connect.
# Ensure it contains at least:
# [client]
# user=your_user
# password=your_password
# host=your_host
MYSQL_CMD="mysql"

# Define colors for the output
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[0;33m'
COLOR_RED='\033[0;31m'
COLOR_NC='\033[0m' # No Color

# --- Functions ---

# Function to check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Function to display an error message and exit
die() {
    echo -e "${COLOR_RED}ERROR: $1${COLOR_NC}" >&2
    exit 1
}

# --- Prerequisites Check ---
if ! command_exists mysql; then
    die "The 'mysql' client is not found. Please install it."
fi

if ! command_exists bc; then
    die "The 'bc' command is not found. Please install it (e.g., sudo apt-get install bc)."
fi


# --- Data Fetching ---
echo "⚙️  Connecting to the database and fetching status..."

# Fetch the output of SHOW ENGINE INNODB STATUS
# The \G option is crucial for an easy-to-parse output format
STATUS_OUTPUT=$($MYSQL_CMD -e "SHOW ENGINE INNODB STATUS\G" 2>/dev/null)
if [ $? -ne 0 ]; then
    die "Could not connect to the database or execute the command. Check your credentials in ~/.my.cnf."
fi

# Extract LSN (Log Sequence Number) values
# We use 'grep' to find the line, and 'awk' to extract the last column (the number)
lsn=$(echo "$STATUS_OUTPUT" | grep 'Log sequence number' | awk '{print $NF}')
checkpoint_lsn=$(echo "$STATUS_OUTPUT" | grep 'Last checkpoint at' | awk '{print $NF}')

# Fetch the total log size from global variables
# The -sN option (silent, no-headers) is perfect for getting a raw value
log_file_size=$($MYSQL_CMD -sN -e "SELECT @@innodb_log_file_size;")
log_files_in_group=$($MYSQL_CMD -sN -e "SELECT @@innodb_log_files_in_group;" 2>/dev/null)

# Fallback for log_files_in_group if it's not set
if [ -z "$log_files_in_group" ]; then
    log_files_in_group=1  # Default value if not defined
fi

# --- Validation and Calculations ---
echo "🧮  Calculating usage rate..."

# Check that all necessary values have been fetched
if [ -z "$lsn" ] || [ -z "$checkpoint_lsn" ] || [ -z "$log_file_size" ]; then
    die "Could not retrieve one or more necessary values. Is InnoDB active and in use?"
fi

# Calculation in bytes (Bash handles integers)
active_log_bytes=$((lsn - checkpoint_lsn))
total_log_bytes=$((log_file_size * log_files_in_group))

# Safety check to prevent division by zero
if [ "$total_log_bytes" -eq 0 ]; then
    die "Total log size is 0. Cannot calculate percentage."
fi

# Calculate percentages and sizes in MB using 'bc'
active_log_mb=$(echo "scale=2; $active_log_bytes / 1024 / 1024" | bc)
total_log_mb=$(echo "scale=2; $total_log_bytes / 1024 / 1024" | bc)
percentage=$(echo "scale=2; ($active_log_bytes / $total_log_bytes) * 100" | bc)

# Convert percentage to an integer for the progress bar and color logic
percentage_int=$(echo "$percentage" | cut -d. -f1)


# --- Report Display ---

# Determine the status color based on thresholds
if [ "$percentage_int" -ge 90 ]; then
    STATUS_COLOR=$COLOR_RED
    STATUS_MSG="Critical"
elif [ "$percentage_int" -ge 75 ]; then
    STATUS_COLOR=$COLOR_YELLOW
    STATUS_MSG="Warning"
else
    STATUS_COLOR=$COLOR_GREEN
    STATUS_MSG="Healthy"
fi

# Create the progress bar
BAR_WIDTH=50
filled_len=$((percentage_int * BAR_WIDTH / 100))
bar=$(printf "%-${filled_len}s" "" | sed 's/ /#/g')
empty_bar=$(printf "%-$((BAR_WIDTH - filled_len))s" "")

echo ""
echo "--- InnoDB Redo Log Usage Report ---"
printf "Active size  : %.2f MB\n" "$active_log_mb"
printf "Total size   : %.2f MB\n" "$total_log_mb"
printf "Usage rate   : ${STATUS_COLOR}%.2f %%${COLOR_NC}\n" "$percentage"
printf "Status       : ${STATUS_COLOR}%s${COLOR_NC}\n" "$STATUS_MSG"
printf "Visualization: [${STATUS_COLOR}%s${COLOR_NC}%s] %.0f%%\n" "$bar" "$empty_bar" "$percentage"
echo "------------------------------------"
# --- End of Script ---
echo "✅  Report generated successfully."
# Exit with success status
exit 0
# --- End of Script ---
# Note: This script is designed to be run in a bash shell and requires the MySQL client
# and bc utility to be installed. It assumes that the user has access to the MySQL
# server and that the InnoDB storage engine is in use.
# It is recommended to run this script periodically to monitor the InnoDB log usage.
# Adjust the script as necessary for your environment and requirements.
# Ensure the script is executable
chmod +x check_innodb_log_usage.sh
# You can run the script using:
# ./check_innodb_log_usage.sh
# Note: If you encounter issues with the script, check your MySQL server version and ensure
# that the InnoDB storage engine is enabled. The script may need adjustments for different MySQL versions.
