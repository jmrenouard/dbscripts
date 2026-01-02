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
    mariadb -h 127.0.0.1 -P $port -uroot -p$PASS -N -s -e "$query" 2>/dev/null
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

echo -e "\n3. � Auto-increment Consistency Test..."
echo ">> Inserting from all nodes simultaneously (simulated)..."
run_sql $NODE1_PORT "INSERT INTO $DB.sync_test (node_id, msg) VALUES (1, 'Multi-node test 1');"
run_sql $NODE2_PORT "INSERT INTO $DB.sync_test (node_id, msg) VALUES (2, 'Multi-node test 2');"
run_sql $NODE3_PORT "INSERT INTO $DB.sync_test (node_id, msg) VALUES (3, 'Multi-node test 3');"

echo ">> Checking IDs and distribution:"
run_sql $NODE1_PORT "SELECT id, node_id, msg FROM $DB.sync_test WHERE msg LIKE 'Multi-node test %' ORDER BY id;" | while read id node_id msg; do
    echo "   Row ID $id inserted by Node $node_id"
done

echo -e "\n4. ⚡ Certification Conflict Test (Optimistic Locking)..."
echo ">> Setting up a record for conflict..."
run_sql $NODE1_PORT "INSERT INTO $DB.sync_test (id, node_id, msg) VALUES (100, 1, 'Conflict base');"

echo ">> Simulating concurrent updates on Node 1 and Node 2..."
# Node 1 starts a transaction
mariadb -h 127.0.0.1 -P $NODE1_PORT -uroot -p$PASS $DB -e "SET AUTOCOMMIT=0; UPDATE sync_test SET msg='Updated by Node 1' WHERE id=100; SELECT SLEEP(2); COMMIT;" > /dev/null 2>&1 &
PID1=$!

sleep 0.5
echo ">> Node 2 attempts to update the same record while Node 1 is sleeping..."
# Node 2 updates and commits immediately
run_sql $NODE2_PORT "UPDATE $DB.sync_test SET msg='Updated by Node 2' WHERE id=100;"

wait $PID1
# Node 1 should have failed or been overridden depending on timing, but in Galera, if Node 2 committed first, Node 1's commit will fail with a deadlock (certification failure) or just see Node 2's change.
# Actually, the background process above might not show the error easily. 

echo ">> Final state of record 100:"
FINAL_MSG=$(run_sql $NODE3_PORT "SELECT msg FROM $DB.sync_test WHERE id=100;")
echo "   Message: '$FINAL_MSG'"

echo -e "\n5. 🏗️ DDL Replication Test..."
echo ">> Adding column 'new_col' on Node 2..."
run_sql $NODE2_PORT "ALTER TABLE $DB.sync_test ADD COLUMN new_col VARCHAR(50) DEFAULT 'success';"
echo ">> Verifying column existence on Node 1 and 3..."
if run_sql $NODE1_PORT "SHOW COLUMNS FROM $DB.sync_test LIKE 'new_col';" | grep -q "new_col"; then
    echo "✅ Node 1: Column 'new_col' exists"
else
    echo "❌ Node 1: Column 'new_col' missing"
fi

if run_sql $NODE3_PORT "SHOW COLUMNS FROM $DB.sync_test LIKE 'new_col';" | grep -q "new_col"; then
    echo "✅ Node 3: Column 'new_col' exists"
else
    echo "❌ Node 3: Column 'new_col' missing"
fi

echo -e "\n6. 🛡️ Unique Key Constraint Test..."
echo ">> Inserting record ID 500 on Node 1..."
run_sql $NODE1_PORT "INSERT INTO $DB.sync_test (id, node_id, msg) VALUES (500, 1, 'Initial 500');"
echo ">> Attempting to insert same ID 500 on Node 2 (Should fail)..."
ERR_MSG=$(mariadb -h 127.0.0.1 -P $NODE2_PORT -uroot -p$PASS $DB -e "INSERT INTO sync_test (id, node_id, msg) VALUES (500, 2, 'Duplicate 500');" 2>&1)
if echo "$ERR_MSG" | grep -q "Duplicate entry"; then
    echo "✅ Node 2 correctly rejected duplicate entry"
else
    echo "❌ Node 2 failed to reject duplicate (or error was different): $ERR_MSG"
fi

echo -e "\n7. 📊 Cluster Info Summary"
run_sql $NODE1_PORT "SHOW STATUS LIKE 'wsrep_local_state_comment'; SHOW STATUS LIKE 'wsrep_incoming_addresses'; SHOW STATUS LIKE 'wsrep_cluster_status';"
run_sql $NODE1_PORT "SHOW VARIABLES LIKE 'auto_increment_increment'; SHOW VARIABLES LIKE 'auto_increment_offset';"

echo -e "\n=========================================================="
echo "🏁 Galera Test Suite Finished"
echo "=========================================================="
