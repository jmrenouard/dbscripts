#!/bin/bash

# Configuration
MASTER_IP="10.5.0.11"
MASTER_PORT=3411
SLAVE1_PORT=3412
SLAVE2_PORT=3413
USER="root"
PASS="rootpass"
REPLI_USER="repli_user"
REPLI_PASS="replipass"

echo "=========================================================="
echo "⚙️  MariaDB Replication Setup"
echo "=========================================================="

# Function to execute SQL on host ports
run_sql() {
    local port=$1
    local query=$2
    mariadb -h 127.0.0.1 -P $port -u$USER -p$PASS -e "$query" -sN 2>/dev/null
}

echo "1. 🔍 Getting Master Status from Port $MASTER_PORT..."
MASTER_LOG=$(run_sql $MASTER_PORT "SHOW MASTER STATUS" | awk '{print $1}')
MASTER_POS=$(run_sql $MASTER_PORT "SHOW MASTER STATUS" | awk '{print $2}')

if [ -z "$MASTER_LOG" ] || [ -z "$MASTER_POS" ]; then
    echo "❌ Failed to get Master status. Is MariaDB running on port $MASTER_PORT?"
    exit 1
fi

echo "✅ Master is at $MASTER_LOG:$MASTER_POS"

for port in $SLAVE1_PORT $SLAVE2_PORT; do
    echo -e "\n2. ⛓️ Configuring Slave on Port $port..."
    
    echo ">> Stopping Slave..."
    run_sql $port "STOP SLAVE;"
    
    echo ">> Resetting Slave..."
    run_sql $port "RESET SLAVE ALL;"
    
    echo ">> Setting Master to $MASTER_IP..."
    run_sql $port "CHANGE MASTER TO MASTER_HOST='$MASTER_IP', MASTER_USER='$REPLI_USER', MASTER_PASSWORD='$REPLI_PASS', MASTER_LOG_FILE='$MASTER_LOG', MASTER_LOG_POS=$MASTER_POS;"
    
    echo ">> Starting Slave..."
    run_sql $port "START SLAVE;"
    
    echo ">> Checking Slave Status..."
    IO_RUNNING=$(run_sql $port "SHOW SLAVE STATUS\G" | grep "Slave_IO_Running:" | awk '{print $2}')
    SQL_RUNNING=$(run_sql $port "SHOW SLAVE STATUS\G" | grep "Slave_SQL_Running:" | awk '{print $2}')
    
    if [ "$IO_RUNNING" == "Yes" ] && [ "$SQL_RUNNING" == "Yes" ]; then
        echo "✅ Slave on Port $port is UP and RUNNING"
    else
        echo "❌ Slave on Port $port has issues (IO: $IO_RUNNING, SQL: $SQL_RUNNING)"
        run_sql $port "SHOW SLAVE STATUS\G" | grep "Last_IO_Error"
    fi
done

echo -e "\n=========================================================="
echo "🏁 Replication Setup Finished"
echo "=========================================================="
