#!/bin/bash

# Configuration
NODE1_PORT=3511
NODE2_PORT=3512
NODE3_PORT=3513
USER="root"
PASS="rootpass"
DB="test_galera_db"

echo "=========================================================="
echo "🚀 MariaDB Galera Cluster Test Suite"
echo "=========================================================="

# Function to execute SQL
run_sql() {
    local port=$1
    local query=$2
    mariadb -h 127.0.0.1 -P $port -u$USER -p$PASS -e "$query" 2>/dev/null
}

echo "1. 🔍 Checking Connectivity & Cluster Status..."
ALL_UP=true
for port in $NODE1_PORT $NODE2_PORT $NODE3_PORT; do
    if run_sql $port "SELECT 1" > /dev/null; then
        READY=$(run_sql $port "SHOW GLOBAL STATUS LIKE 'wsrep_ready';" | grep "ON" | awk '{print $2}')
        SIZE=$(run_sql $port "SHOW GLOBAL STATUS LIKE 'wsrep_cluster_size';" | grep "wsrep_cluster_size" | awk '{print $2}')
        STATE=$(run_sql $port "SHOW GLOBAL STATUS LIKE 'wsrep_local_state_comment';" | awk '{print $2}')
        echo "✅ Node at port $port is UP (Ready: $READY, Cluster Size: $SIZE, State: $STATE)"
    else
        echo "❌ Node at port $port is DOWN"
        ALL_UP=false
    fi
done

echo -e "\n2. 🧪 Performing Synchronous Replication Test..."
echo ">> Creating database '$DB' on Node 1 (Port $NODE1_PORT)..."
if ! run_sql $NODE1_PORT "DROP DATABASE IF EXISTS $DB; CREATE DATABASE $DB; USE $DB; CREATE TABLE sync_test (id INT AUTO_INCREMENT PRIMARY KEY, node_id INT, msg VARCHAR(255), ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP);"; then
    echo "❌ Failed to create database on Node 1"
    exit 1
fi

echo ">> Inserting data from Node 1..."
run_sql $NODE1_PORT "INSERT INTO $DB.sync_test (node_id, msg) VALUES (1, 'Data from Node 1');"

echo ">> Verifying on Node 2 (Port $NODE2_PORT)..."
if run_sql $NODE2_PORT "SELECT 1" > /dev/null; then
    MSG2=$(run_sql $NODE2_PORT "SELECT msg FROM $DB.sync_test WHERE node_id=1;")
    if [ "$MSG2" == "Data from Node 1" ]; then
        echo "✅ Node 2 received data correctly"
    else
        echo "❌ Node 2 data mismatch: '$MSG2'"
    fi
else
    echo "⏭️ Skipping Node 2 verification (Node is DOWN)"
fi

echo ">> Verifying on Node 3 (Port $NODE3_PORT)..."
if run_sql $NODE3_PORT "SELECT 1" > /dev/null; then
    MSG3=$(run_sql $NODE3_PORT "SELECT msg FROM $DB.sync_test WHERE node_id=1;")
    if [ "$MSG3" == "Data from Node 1" ]; then
        echo "✅ Node 3 received data correctly"
    else
        echo "❌ Node 3 data mismatch: '$MSG3'"
    fi
else
    echo "⏭️ Skipping Node 3 verification (Node is DOWN)"
fi

echo ">> Inserting data from Node 3 (Port $NODE3_PORT)..."
run_sql $NODE3_PORT "INSERT INTO $DB.sync_test (node_id, msg) VALUES (3, 'Data from Node 3');"

echo ">> Verifying on Node 1 (Port $NODE1_PORT)..."
MSG1=$(run_sql $NODE1_PORT "SELECT msg FROM $DB.sync_test WHERE node_id=3;")
if [ "$MSG1" == "Data from Node 3" ]; then
    echo "✅ Node 1 received data correctly"
else
    echo "❌ Node 1 data mismatch: '$MSG1'"
fi

echo -e "\n3. 📊 Cluster Info Summary"
run_sql $NODE1_PORT "SHOW STATUS LIKE 'wsrep_local_state_comment'; SHOW STATUS LIKE 'wsrep_incoming_addresses';"

echo -e "\n=========================================================="
echo "🏁 Galera Test Suite Finished"
echo "=========================================================="
