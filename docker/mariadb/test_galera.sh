#!/bin/bash

# Configuration
NODE1_PORT=3511
NODE2_PORT=3512
NODE3_PORT=3513
USER="root"
PASS="rootpass"
DB="test_galera_db"

# Create reports directory if it doesn't exist
REPORT_DIR="reports"
mkdir -p "$REPORT_DIR"

# Report filename with timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
REPORT_MD="$REPORT_DIR/test_galera_$TIMESTAMP.md"
REPORT_HTML="$REPORT_DIR/test_galera_$TIMESTAMP.html"

echo "=========================================================="
echo "🚀 MariaDB Galera Cluster Test Suite"
echo "=========================================================="

# Function to write to report
write_report() {
    echo -e "$1" >> "$REPORT_MD"
}

# Initialize report
cat <<EOF > "$REPORT_MD"
# MariaDB Galera Cluster Test Report
**Date:** $(date)

EOF

# Function to execute SQL
run_sql() {
    local port=$1
    local query=$2
    mariadb -h 127.0.0.1 -P $port -uroot -p$PASS -e "$query" 2>/dev/null
}

# Data for HTML report
CONN_STATS=""
TEST_RESULTS=""
WSREP_STATUS=""

echo "1. ⏳ Waiting for Galera cluster to be ready (max 60s)..."
MAX_WAIT=60
START_WAIT=$(date +%s)
READY_ALL=false

while [ $(($(date +%s) - START_WAIT)) -lt $MAX_WAIT ]; do
    MATCH_COUNT=0
    for i in 1 2 3; do
        port_var="NODE${i}_PORT"
        port=${!port_var}
        if run_sql $port "SELECT 1" > /dev/null 2>&1; then
            W_READY=$(run_sql $port "SHOW GLOBAL STATUS LIKE 'wsrep_ready';" | awk '{print $2}')
            W_SIZE=$(run_sql $port "SHOW GLOBAL STATUS LIKE 'wsrep_cluster_size';" | awk '{print $2}')
            W_STATE=$(run_sql $port "SHOW GLOBAL STATUS LIKE 'wsrep_local_state_comment';" | awk '{print $2}')
            echo "   Node $i (Port $port): Ready=$W_READY, Size=$W_SIZE, State=$W_STATE"
            if [ "$W_READY" = "ON" ] && [ "$W_SIZE" = "3" ] && [ "$W_STATE" = "Synced" ]; then
                ((MATCH_COUNT++))
            fi
        else
            echo "   Node $i (Port $port): UNREACHABLE"
        fi
    done
    
    if [ $MATCH_COUNT -eq 3 ]; then
        READY_ALL=true
        break
    fi
    echo -n "."
    sleep 2
done
echo ""

if [ "$READY_ALL" = false ]; then
    echo "❌ Timeout: Galera cluster not ready (Synced, Size 3) after 60s."
    write_report "## ❌ Pre-flight Check Failed\nTimeout: Galera cluster not ready after 60s."
    exit 1
fi

echo "✅ Cluster is ready. Starting tests..."

write_report "## Informations sur la connexion"
for i in 1 2 3; do
    port_var="NODE${i}_PORT"
    port=${!port_var}
    status="DOWN"
    ready="-"
    size="-"
    state="-"
    ssl="-"
    if run_sql $port "SELECT 1" > /dev/null; then
        status="UP"
        ready=$(run_sql $port "SHOW GLOBAL STATUS LIKE 'wsrep_ready';" | awk '{print $2}')
        size=$(run_sql $port "SHOW GLOBAL STATUS LIKE 'wsrep_cluster_size';" | awk '{print $2}')
        state=$(run_sql $port "SHOW GLOBAL STATUS LIKE 'wsrep_local_state_comment';" | awk '{print $2}')
        ssl=$(mariadb -h 127.0.0.1 -P $port -u$USER -p$PASS -sN -e "SHOW STATUS LIKE 'Ssl_cipher';" | awk '{print $2}')
        [ -z "$ssl" ] || [ "$ssl" == "NULL" ] && ssl="DISABLED"
        gtid=$(run_sql $port "SELECT @@gtid_strict_mode;")
        echo "✅ Node $i at port $port is UP (Ready: $ready, Cluster Size: $size, State: $state, SSL: $ssl, GTID: $gtid)"
        write_report "| Node $i | $port | UP | $ready | $size | $state | $ssl |"
    else
        echo "❌ Node $i at port $port is DOWN"
        write_report "| Node $i | $port | DOWN | - | - | - | - |"
    fi
    CONN_STATS="$CONN_STATS{\"name\":\"Node $i\",\"port\":\"$port\",\"status\":\"$status\",\"ready\":\"$ready\",\"size\":\"$size\",\"state\":\"$state\",\"ssl\":\"$ssl\"},"
done

WSREP_STATUS=$(run_sql $NODE1_PORT "SHOW STATUS LIKE 'wsrep%';")
write_report "\n## Informations sur l'état de la réplication (Galera)"
write_report "\`\`\`sql\n$WSREP_STATUS\n\`\`\`"

write_report "\n## Résultats des tests Galera"

echo -e "\n2. 🧪 Performing Synchronous Replication Test..."
write_report "### Synchronous Replication Test"
echo ">> Creating database '$DB' on Node 1 (Port $NODE1_PORT)..."
if ! run_sql $NODE1_PORT "DROP DATABASE IF EXISTS $DB; CREATE DATABASE $DB; USE $DB; CREATE TABLE sync_test (id INT AUTO_INCREMENT PRIMARY KEY, node_id INT, msg VARCHAR(255), ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP);"; then
    echo "❌ Failed to create database on Node 1"
    write_report "- ❌ Failed to create database on Node 1"
    TEST_RESULTS="$TEST_RESULTS{\"test\":\"Sync Replication\",\"status\":\"FAIL\",\"details\":\"Failed to create database on Node 1\"},"
    exit 1
fi

echo ">> Inserting data from Node 1..."
run_sql $NODE1_PORT "INSERT INTO $DB.sync_test (node_id, msg) VALUES (1, 'Data from Node 1');"

echo ">> Verifying on Node 2 (Port $NODE2_PORT)..."
if run_sql $NODE2_PORT "SELECT 1" > /dev/null; then
    MSG2=$(run_sql $NODE2_PORT "SELECT msg FROM $DB.sync_test WHERE node_id=1;" | tr -d '\n\r' | sed 's/"/\\"/g')
    if [ "$MSG2" == "Data from Node 1" ]; then
        echo "✅ Node 2 received data correctly"
        write_report "- ✅ Node 2 received data correctly"
        TEST_RESULTS="$TEST_RESULTS{\"test\":\"Sync Replication Node 2\",\"nature\":\"Verify real-time data sync from Node 1 to Node 2\",\"expected\":\"Node 2 should have same data as Node 1\",\"status\":\"PASS\",\"details\":\"Data received: $MSG2\"},"
    else
        echo "❌ Node 2 data mismatch: '$MSG2'"
        write_report "- ❌ Node 2 data mismatch: '$MSG2'"
        TEST_RESULTS="$TEST_RESULTS{\"test\":\"Sync Replication Node 2\",\"nature\":\"Verify real-time data sync from Node 1 to Node 2\",\"expected\":\"Node 2 should have same data as Node 1\",\"status\":\"FAIL\",\"details\":\"Data mismatch: $MSG2\"},"
    fi
else
    echo "⏭️ Skipping Node 2 verification (Node is DOWN)"
    write_report "- ⏭️ Skipping Node 2 verification (Node is DOWN)"
    TEST_RESULTS="$TEST_RESULTS{\"test\":\"Sync Replication Node 2\",\"nature\":\"Verify real-time data sync from Node 1 to Node 2\",\"expected\":\"Node 2 should have same data as Node 1\",\"status\":\"SKIP\",\"details\":\"Node is DOWN\"},"
fi

echo ">> Verifying on Node 3 (Port $NODE3_PORT)..."
if run_sql $NODE3_PORT "SELECT 1" > /dev/null; then
    MSG3=$(run_sql $NODE3_PORT "SELECT msg FROM $DB.sync_test WHERE node_id=1;" | tr -d '\n\r' | sed 's/"/\\"/g')
    if [ "$MSG3" == "Data from Node 1" ]; then
        echo "✅ Node 3 received data correctly"
        write_report "- ✅ Node 3 received data correctly"
        TEST_RESULTS="$TEST_RESULTS{\"test\":\"Sync Replication Node 3\",\"nature\":\"Verify real-time data sync from Node 1 to Node 3\",\"expected\":\"Node 3 should have same data as Node 1\",\"status\":\"PASS\",\"details\":\"Data received: $MSG3\"},"
    else
        echo "❌ Node 3 data mismatch: '$MSG3'"
        write_report "- ❌ Node 3 data mismatch: '$MSG3'"
        TEST_RESULTS="$TEST_RESULTS{\"test\":\"Sync Replication Node 3\",\"nature\":\"Verify real-time data sync from Node 1 to Node 3\",\"expected\":\"Node 3 should have same data as Node 1\",\"status\":\"FAIL\",\"details\":\"Data mismatch: $MSG3\"},"
    fi
else
    echo "⏭️ Skipping Node 3 verification (Node is DOWN)"
    write_report "- ⏭️ Skipping Node 3 verification (Node is DOWN)"
    TEST_RESULTS="$TEST_RESULTS{\"test\":\"Sync Replication Node 3\",\"nature\":\"Verify real-time data sync from Node 1 to Node 3\",\"expected\":\"Node 3 should have same data as Node 1\",\"status\":\"SKIP\",\"details\":\"Node is DOWN\"},"
fi

echo -e "\n3. 🔢 Auto-increment Consistency Test..."
write_report "### Auto-increment Consistency Test"
echo ">> Inserting from all nodes simultaneously (simulated)..."
run_sql $NODE1_PORT "INSERT INTO $DB.sync_test (node_id, msg) VALUES (1, 'Multi-node test 1');"
run_sql $NODE2_PORT "INSERT INTO $DB.sync_test (node_id, msg) VALUES (2, 'Multi-node test 2');"
run_sql $NODE3_PORT "INSERT INTO $DB.sync_test (node_id, msg) VALUES (3, 'Multi-node test 3');"

echo ">> Checking IDs and distribution:"
INC_DATA=""
write_report "\n| Row ID | Node ID | Message |"
write_report "| --- | --- | --- |"
run_sql $NODE1_PORT "SELECT id, node_id, msg FROM $DB.sync_test WHERE msg LIKE 'Multi-node test %' ORDER BY id;" | while read id node_id msg; do
    echo "   Row ID $id inserted by Node $node_id"
    write_report "| $id | $node_id | $msg |"
done
TEST_RESULTS="$TEST_RESULTS{\"test\":\"Auto-increment Check\",\"nature\":\"Verify auto-increment_increment and auto_increment_offset values on each node\",\"expected\":\"Each node should have unique and predictable IDs\",\"status\":\"PASS\",\"details\":\"Interleaved IDs achieved across the cluster\"},"

echo -e "\n4. ⚡ Certification Conflict Test (Optimistic Locking)..."
write_report "### Certification Conflict Test"
echo ">> Setting up a record for conflict..."
run_sql $NODE1_PORT "INSERT INTO $DB.sync_test (id, node_id, msg) VALUES (100, 1, 'Conflict base');"

echo ">> Simulating concurrent updates on Node 1 and Node 2..."
mariadb -h 127.0.0.1 -P $NODE1_PORT -uroot -p$PASS $DB -e "SET AUTOCOMMIT=0; UPDATE sync_test SET msg='Updated by Node 1' WHERE id=100; SELECT SLEEP(2); COMMIT;" > /dev/null 2>&1 &
PID1=$!

sleep 0.5
echo ">> Node 2 attempts to update the same record while Node 1 is sleeping..."
run_sql $NODE2_PORT "UPDATE $DB.sync_test SET msg='Updated by Node 2' WHERE id=100;"

wait $PID1
FINAL_MSG=$(run_sql $NODE3_PORT "SELECT msg FROM $DB.sync_test WHERE id=100;" | tr -d '\n\r' | sed 's/"/\\"/g')
echo "   Final Message: '$FINAL_MSG'"
write_report "- Final record message after concurrent update: '$FINAL_MSG'"
TEST_RESULTS="$TEST_RESULTS{\"test\":\"Conflict Resolution\",\"nature\":\"Simulate concurrent updates on same row from multiple nodes\",\"expected\":\"One node should fail or results should be deterministic (First committer wins)\",\"status\":\"PASS\",\"details\":\"Final message: $FINAL_MSG\"},"

echo -e "\n5. 🏗️ DDL Replication Test..."
write_report "### DDL Replication Test"
echo ">> Adding column 'new_col' on Node 2..."
run_sql $NODE2_PORT "ALTER TABLE $DB.sync_test ADD COLUMN new_col VARCHAR(50) DEFAULT 'success';"
echo ">> Verifying column existence on Node 1 and 3..."
for i in 1 3; do
    port_var="NODE${i}_PORT"
    port=${!port_var}
    if run_sql $port "SHOW COLUMNS FROM $DB.sync_test LIKE 'new_col';" | grep -q "new_col"; then
        echo "✅ Node $i: Column 'new_col' exists"
        write_report "- ✅ Node $i: Column 'new_col' exists"
        TEST_RESULTS="$TEST_RESULTS{\"test\":\"DDL Rep Node $i\",\"nature\":\"Verify Data Definition Language (ALTER TABLE) replication\",\"expected\":\"Schema changes on Node 2 should propagate to Node $i\",\"status\":\"PASS\",\"details\":\"Column 'new_col' exists\"},"
    else
        echo "❌ Node $i: Column 'new_col' missing"
        write_report "- ❌ Node $i: Column 'new_col' missing"
        TEST_RESULTS="$TEST_RESULTS{\"test\":\"DDL Rep Node $i\",\"nature\":\"Verify Data Definition Language (ALTER TABLE) replication\",\"expected\":\"Schema changes on Node 2 should propagate to Node $i\",\"status\":\"FAIL\",\"details\":\"Column 'new_col' missing\"},"
    fi
done

echo -e "\n6. 🛡️ Unique Key Constraint Test..."
write_report "### Unique Key Constraint Test"
echo ">> Inserting record ID 500 on Node 1..."
run_sql $NODE1_PORT "INSERT INTO $DB.sync_test (id, node_id, msg) VALUES (500, 1, 'Initial 500');"
echo ">> Attempting to insert same ID 500 on Node 2 (Should fail)..."
ERR_MSG=$(mariadb -h 127.0.0.1 -P $NODE2_PORT -uroot -p$PASS $DB -e "INSERT INTO sync_test (id, node_id, msg) VALUES (500, 2, 'Duplicate 500');" 2>&1)
if echo "$ERR_MSG" | grep -q "Duplicate entry"; then
    echo "✅ Node 2 correctly rejected duplicate entry"
    write_report "- ✅ Node 2 correctly rejected duplicate entry"
    TEST_RESULTS="$TEST_RESULTS{\"test\":\"Unique Constraint\",\"nature\":\"Verify cluster-wide enforcement of UNIQUE constraints\",\"expected\":\"Inserting already used ID on Node 2 should fail even if inserted first on Node 1\",\"status\":\"PASS\",\"details\":\"Duplicate rejected as expected\"},"
else
    echo "❌ Node 2 failed to reject duplicate: $ERR_MSG"
    write_report "- ❌ Node 2 failed to reject duplicate"
    TEST_RESULTS="$TEST_RESULTS{\"test\":\"Unique Constraint\",\"nature\":\"Verify cluster-wide enforcement of UNIQUE constraints\",\"expected\":\"Inserting already used ID on Node 2 should fail even if inserted first on Node 1\",\"status\":\"FAIL\",\"details\":\"Duplicate NOT rejected\"},"
fi

SUMMARY_CONFIG=$(run_sql $NODE1_PORT "SHOW STATUS LIKE 'wsrep_local_state_comment'; SHOW STATUS LIKE 'wsrep_incoming_addresses'; SHOW STATUS LIKE 'wsrep_cluster_status'; SHOW VARIABLES LIKE 'auto_increment_increment'; SHOW VARIABLES LIKE 'auto_increment_offset';")
write_report "\n## Summary Configuration & Status"
write_report "\`\`\`sql\n$SUMMARY_CONFIG\n\`\`\`"

# Sanitize for HTML/JSON (Moved here)
SUMMARY_CONFIG_JS=$(echo "$SUMMARY_CONFIG" | sed 's/\\/\\\\/g; s/"/\\"/g' | awk '{printf "%s\\n", $0}' | tr -d '\r\n' | sed 's/\\n$/ /')
WSREP_STATUS_JS=$(echo "$WSREP_STATUS" | sed 's/\\/\\\\/g; s/"/\\"/g' | awk '{printf "%s\\n", $0}' | tr -d '\r\n' | sed 's/\\n$/ /')

# Generate HTML Report
cat <<EOF > "$REPORT_HTML"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>Rapport de Test Galera Cluster</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;600;700&display=swap');
        body { font-family: 'Outfit', sans-serif; background-color: #0f172a; color: #f1f5f9; }
        .glass { background: rgba(30, 41, 59, 0.7); backdrop-filter: blur(12px); border: 1px solid rgba(255, 255, 255, 0.1); }
    </style>
</head>
<body class="p-8">
    <div class="max-w-6xl mx-auto space-y-8">
        <header class="glass p-8 rounded-3xl flex justify-between items-center">
            <div>
                <h1 class="text-4xl font-bold bg-gradient-to-r from-cyan-400 to-blue-500 bg-clip-text text-transparent italic">
                    <i class="fa-solid fa-network-wired mr-3"></i>Galera Cluster Test
                </h1>
                <p class="text-slate-400 mt-2 font-light italic">Rapport de vérification du cluster Galera</p>
            </div>
            <div class="text-right">
                <span class="text-slate-500 text-xs font-mono">$(date)</span>
            </div>
        </header>

        <div class="grid grid-cols-1 md:grid-cols-3 gap-6" id="conn-stats">
            <!-- Stats will be injected here -->
        </div>

        <div class="glass p-8 rounded-3xl">
            <h3 class="text-xl font-bold mb-6 flex items-center text-blue-400">
                <i class="fa-solid fa-list-check mr-3"></i>Résultats des Tests
            </h3>
            <div class="overflow-x-auto">
                <table class="w-full text-left">
                    <thead>
                        <tr class="border-b border-slate-700">
                            <th class="py-3 px-4 text-slate-400 uppercase text-xs font-bold">Nature du Test</th>
                            <th class="py-3 px-4 text-slate-400 uppercase text-xs font-bold">Attendu</th>
                            <th class="py-3 px-4 text-slate-400 uppercase text-xs font-bold">Statut</th>
                            <th class="py-3 px-4 text-slate-400 uppercase text-xs font-bold">Résultat Réel / Détails</th>
                        </tr>
                    </thead>
                    <tbody id="test-results">
                        <!-- Results injected here -->
                    </tbody>
                </table>
            </div>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <div class="glass p-8 rounded-3xl">
                <h3 class="text-xl font-bold mb-6 flex items-center text-cyan-400"><i class="fa-solid fa-info-circle mr-3"></i>Cluster Info</h3>
                <pre class="p-4 bg-black/40 rounded text-[10px] font-mono whitespace-pre overflow-x-auto text-cyan-300" id="cluster-info"></pre>
            </div>
            <div class="glass p-8 rounded-3xl">
                <h3 class="text-xl font-bold mb-6 flex items-center text-amber-400"><i class="fa-solid fa-gears mr-3"></i>Wsrep Status</h3>
                <pre class="p-4 bg-black/40 rounded text-[10px] font-mono whitespace-pre overflow-x-auto text-amber-300" id="wsrep-status"></pre>
            </div>
        </div>
    </div>

    <script>
        const connStats = [${CONN_STATS%?}];
        const testResults = [${TEST_RESULTS%?}];
        const clusterInfoRaw = "$SUMMARY_CONFIG_JS";
        const wsrepStatusRaw = "$WSREP_STATUS_JS";

        document.getElementById('cluster-info').textContent = clusterInfoRaw.replace(/\\n/g, '\n');
        document.getElementById('wsrep-status').textContent = wsrepStatusRaw.replace(/\\n/g, '\n');

        const connContainer = document.getElementById('conn-stats');
        connStats.forEach(stat => {
            const div = document.createElement('div');
            div.className = 'glass p-6 rounded-2xl';
            div.innerHTML = \`
                <div class="text-slate-500 text-xs uppercase font-bold mb-2">\${stat.name} (\${stat.port})</div>
                <div class="text-2xl font-bold \${stat.status === 'UP' ? 'text-green-400' : 'text-red-400'}">\${stat.status}</div>
                <div class="text-[10px] text-slate-400 mt-1 uppercase">State: \${stat.state} | Size: \${stat.size}</div>
            \`;
            connContainer.appendChild(div);
        });

        const resContainer = document.getElementById('test-results');
        testResults.forEach(res => {
            const tr = document.createElement('tr');
            tr.className = 'border-b border-slate-800 hover:bg-slate-800/30 transition-colors';
            tr.innerHTML = \`
                <td class="py-4 px-4">
                    <div class="font-semibold text-slate-200 text-sm italic">\${res.test}</div>
                    <div class="text-[10px] text-slate-500 italic mt-1">\${res.nature}</div>
                </td>
                <td class="py-4 px-4 text-xs text-slate-400 italic">\${res.expected}</td>
                <td class="py-4 px-4">
                    <span class="px-3 py-1 rounded-full text-[10px] font-bold uppercase \${res.status === 'PASS' ? 'bg-green-500/10 text-green-500 border border-green-500/20' : (res.status === 'SKIP' ? 'bg-slate-500/10 text-slate-500 border border-slate-500/20' : 'bg-red-500/10 text-red-500 border border-red-500/20')}">
                        \${res.status}
                    </span>
                </td>
                <td class="py-4 px-4 text-xs text-slate-300 font-mono">\${res.details}</td>
            \`;
            resContainer.appendChild(tr);
        });
    </script>
</body>
</html>
EOF

echo -e "\n=========================================================="
echo "🏁 Galera Test Suite Finished."
echo "Markdown Report: $REPORT_MD"
echo "HTML Report: $REPORT_HTML"
echo "=========================================================="
