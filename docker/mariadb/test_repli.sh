#!/bin/bash

# Configuration
MASTER_PORT=3411
SLAVE1_PORT=3412
SLAVE2_PORT=3413
USER="root"
PASS="rootpass"
DB="test_repli_db"

echo "=========================================================="
echo "🚀 MariaDB Replication Test Suite"
echo "=========================================================="

# Function to execute SQL
run_sql() {
    local port=$1
    local query=$2
    mariadb -h 127.0.0.1 -P $port -u$USER -p$PASS -e "$query" 2>/dev/null
}

echo "1. 🔍 Checking Connectivity and SSL..."
for port in $MASTER_PORT $SLAVE1_PORT $SLAVE2_PORT; do
    if run_sql $port "SELECT 1" > /dev/null; then
        CIPHER=$(mariadb -h 127.0.0.1 -P $port -u$USER -p$PASS -sN -e "SHOW STATUS LIKE 'Ssl_cipher';" | awk '{print $2}')
        if [ ! -z "$CIPHER" ] && [ "$CIPHER" != "NULL" ]; then
            echo "✅ Port $port is UP (SSL: $CIPHER)"
        else
            echo "⚠️  Port $port is UP (SSL: DISABLED)"
        fi
    else
        echo "❌ Port $port is DOWN"
        exit 1
    fi
done

echo -e "\n2. 👑 MASTER STATUS (Port $MASTER_PORT)"
run_sql $MASTER_PORT "SHOW MASTER STATUS\G"

echo -e "\n3. ⛓️ SLAVE 1 STATUS (Port $SLAVE1_PORT)"
run_sql $SLAVE1_PORT "SHOW SLAVE STATUS\G" | grep -E "Slave_IO_Running|Slave_SQL_Running|Master_Host|Seconds_Behind_Master"

echo -e "\n4. ⛓️ SLAVE 2 STATUS (Port $SLAVE2_PORT)"
run_sql $SLAVE2_PORT "SHOW SLAVE STATUS\G" | grep -E "Slave_IO_Running|Slave_SQL_Running|Master_Host|Seconds_Behind_Master"

echo -e "\n5. 🧪 Performing Data Replication Test..."
echo ">> Creating database '$DB' and table on Master..."
run_sql $MASTER_PORT "DROP DATABASE IF EXISTS $DB; CREATE DATABASE $DB; USE $DB; CREATE TABLE test_table (id INT AUTO_INCREMENT PRIMARY KEY, msg VARCHAR(255), ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP);"
run_sql $MASTER_PORT "INSERT INTO $DB.test_table (msg) VALUES ('Hello from Master at $(date)');"

echo ">> Waiting 2 seconds for replication..."
sleep 2

echo ">> Checking Slave 1..."
MSG1=$(run_sql $SLAVE1_PORT "SELECT msg FROM $DB.test_table LIMIT 1;")
if [ ! -z "$MSG1" ]; then
    echo "✅ Slave 1 received: $MSG1"
else
    echo "❌ Slave 1 failed to receive data"
fi

echo ">> Checking Slave 2..."
MSG2=$(run_sql $SLAVE2_PORT "SELECT msg FROM $DB.test_table LIMIT 1;")
if [ ! -z "$MSG2" ]; then
    echo "✅ Slave 2 received: $MSG2"
else
    echo "❌ Slave 2 failed to receive data"
fi

echo -e "\n=========================================================="
echo "🏁 Test Suite Finished"
echo "=========================================================="
