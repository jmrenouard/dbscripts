#!/bin/bash

# Configuration
MASTER_PORT=3411
SLAVE1_PORT=3412
SLAVE2_PORT=3413
USER="root"
PASS="rootpass"
DB="test_repli_db"

# Create reports directory if it doesn't exist
REPORT_DIR="reports"
mkdir -p "$REPORT_DIR"

# Report filename with timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
REPORT_MD="$REPORT_DIR/test_repli_$TIMESTAMP.md"
REPORT_HTML="$REPORT_DIR/test_repli_$TIMESTAMP.html"

echo "=========================================================="
echo "🚀 MariaDB Replication Test Suite"
echo "=========================================================="

# Function to write to report
write_report() {
    echo -e "$1" >> "$REPORT_MD"
}

# Initialize report
cat <<EOF > "$REPORT_MD"
# MariaDB Replication Test Report
**Date:** $(date)

EOF

# Function to execute SQL
run_sql() {
    local port=$1
    local query=$2
    mariadb -h 127.0.0.1 -P $port -u$USER -p$PASS -e "$query" 2>/dev/null
}

# Data for HTML report
CONN_STATS=""
REPL_INFO=""
TEST_RESULTS=""

echo "1. ⏳ Waiting for containers and replication to be ready (max 60s)..."
MAX_WAIT=60
START_WAIT=$(date +%s)
READY=false

while [ $(($(date +%s) - START_WAIT)) -lt $MAX_WAIT ]; do
    ALL_UP=true
    REPL_OK=true
    
    # Check Master
    if ! run_sql $MASTER_PORT "SELECT 1" > /dev/null 2>&1; then ALL_UP=false; fi
    
    # Check Slaves and Replication Status
    for port in $SLAVE1_PORT $SLAVE2_PORT; do
        if ! run_sql $port "SELECT 1" > /dev/null 2>&1; then
            ALL_UP=false
        else
            IO=$(run_sql $port "SHOW SLAVE STATUS\G" | grep "Slave_IO_Running:" | awk '{print $2}')
            SQL=$(run_sql $port "SHOW SLAVE STATUS\G" | grep "Slave_SQL_Running:" | awk '{print $2}')
            if [ "$IO" != "Yes" ] || [ "$SQL" != "Yes" ]; then
                REPL_OK=false
            fi
        fi
    done
    
    if $ALL_UP && $REPL_OK; then
        READY=true
        break
    fi
    echo -n "."
    sleep 2
done
echo ""

if [ "$READY" = false ]; then
    echo "❌ Timeout: Containers or replication not ready after 60s."
    write_report "## ❌ Pre-flight Check Failed\nTimeout: Containers or replication not ready after 60s."
    exit 1
fi

echo "✅ Environment is ready. Starting tests..."

write_report "## Informations sur la connexion"
for role in "Master:$MASTER_PORT" "Slave1:$SLAVE1_PORT" "Slave2:$SLAVE2_PORT"; do
    IFS=":" read -r name port <<< "$role"
    status="DOWN"
    ssl="N/A"
    if run_sql $port "SELECT 1" > /dev/null; then
        status="UP"
        CIPHER=$(mariadb -h 127.0.0.1 -P $port -u$USER -p$PASS -sN -e "SHOW STATUS LIKE 'Ssl_cipher';" | awk '{print $2}')
        if [ ! -z "$CIPHER" ] && [ "$CIPHER" != "NULL" ]; then
            echo "✅ $name (Port $port) is UP (SSL: $CIPHER)"
            ssl="$CIPHER"
        else
            echo "⚠️  $name (Port $port) is UP (SSL: DISABLED)"
            ssl="DISABLED"
        fi
        write_report "| $name | $port | UP | $ssl |"
    else
        echo "❌ $name (Port $port) is DOWN"
        write_report "| $name | $port | DOWN | N/A |"
    fi
    CONN_STATS="$CONN_STATS{\"name\":\"$name\",\"port\":\"$port\",\"status\":\"$status\",\"ssl\":\"$ssl\"},"
done

write_report "\n## Config replication (status)"
MASTER_VARS=$(run_sql $MASTER_PORT "SHOW VARIABLES LIKE '%binlog%'; SHOW VARIABLES LIKE '%gtid%';")
write_report "### Master Variables"
write_report "\`\`\`sql\n$MASTER_VARS\n\`\`\`"

write_report "\n## Status replication (variables)"
MASTER_STATUS=$(run_sql $MASTER_PORT "SHOW MASTER STATUS\G")
write_report "### Master Status"
write_report "\`\`\`sql\n$MASTER_STATUS\n\`\`\`"

write_report "\n## Informations sur l'état de la réplication"
for port in $SLAVE1_PORT $SLAVE2_PORT; do
    REPL_STATUS=$(run_sql $port "SHOW SLAVE STATUS\G" | grep -E "Slave_IO_Running|Slave_SQL_Running|Master_Host|Seconds_Behind_Master")
    write_report "### Slave (Port $port) Status Summary\n\`\`\`\n$REPL_STATUS\n\`\`\`"
    REPL_INFO="$REPL_INFO{\"port\":\"$port\",\"status\":\"$(echo "$REPL_STATUS" | tr '\n' ' ')\"},"
done

write_report "\n## Sections pour la réplication (master & slave)"

echo -e "\n2. 👑 MASTER STATUS (Port $MASTER_PORT)"
run_sql $MASTER_PORT "SHOW MASTER STATUS\G"
write_report "### Detailed Master Status\n\`\`\`sql\n$MASTER_STATUS\n\`\`\`"

echo -e "\n3. ⛓️ SLAVE 1 STATUS (Port $SLAVE1_PORT)"
run_sql $SLAVE1_PORT "SHOW SLAVE STATUS\G" | grep -E "Slave_IO_Running|Slave_SQL_Running|Master_Host|Seconds_Behind_Master"
SLAVE1_FULL=$(run_sql $SLAVE1_PORT "SHOW SLAVE STATUS\G")
write_report "### Detailed Slave 1 Status\n\`\`\`sql\n$SLAVE1_FULL\n\`\`\`"

echo -e "\n4. ⛓️ SLAVE 2 STATUS (Port $SLAVE2_PORT)"
run_sql $SLAVE2_PORT "SHOW SLAVE STATUS\G" | grep -E "Slave_IO_Running|Slave_SQL_Running|Master_Host|Seconds_Behind_Master"
SLAVE2_FULL=$(run_sql $SLAVE2_PORT "SHOW SLAVE STATUS\G")
write_report "### Detailed Slave 2 Status\n\`\`\`sql\n$SLAVE2_FULL\n\`\`\`"

echo -e "\n5. 🧪 Performing Data Replication Test..."
write_report "\n## Résultats des tests de réplication"
echo ">> Creating database '$DB' and table on Master..."
run_sql $MASTER_PORT "DROP DATABASE IF EXISTS $DB; CREATE DATABASE $DB; USE $DB; CREATE TABLE test_table (id INT AUTO_INCREMENT PRIMARY KEY, msg VARCHAR(255), ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP);"
run_sql $MASTER_PORT "INSERT INTO $DB.test_table (msg) VALUES ('Hello from Master at $(date)');"

echo ">> Waiting 2 seconds for replication..."
sleep 2

echo ">> Checking Slave 1..."
MSG1=$(run_sql $SLAVE1_PORT "SELECT msg FROM $DB.test_table LIMIT 1;")
if [ ! -z "$MSG1" ]; then
    echo "✅ Slave 1 received: $MSG1"
    write_report "- ✅ Slave 1 (Port $SLAVE1_PORT): Data received correctly."
    TEST_RESULTS="$TEST_RESULTS{\"test\":\"Replication Slave 1\",\"status\":\"PASS\",\"details\":\"Data received: $MSG1\"},"
else
    echo "❌ Slave 1 failed to receive data"
    write_report "- ❌ Slave 1 (Port $SLAVE1_PORT): Data replication FAILED."
    TEST_RESULTS="$TEST_RESULTS{\"test\":\"Replication Slave 1\",\"status\":\"FAIL\",\"details\":\"No data received\"},"
fi

echo ">> Checking Slave 2..."
MSG2=$(run_sql $SLAVE2_PORT "SELECT msg FROM $DB.test_table LIMIT 1;")
if [ ! -z "$MSG2" ]; then
    echo "✅ Slave 2 received: $MSG2"
    write_report "- ✅ Slave 2 (Port $SLAVE2_PORT): Data received correctly."
    TEST_RESULTS="$TEST_RESULTS{\"test\":\"Replication Slave 2\",\"status\":\"PASS\",\"details\":\"Data received: $MSG2\"},"
else
    echo "❌ Slave 2 failed to receive data"
    write_report "- ❌ Slave 2 (Port $SLAVE2_PORT): Data replication FAILED."
    TEST_RESULTS="$TEST_RESULTS{\"test\":\"Replication Slave 2\",\"status\":\"FAIL\",\"details\":\"No data received\"},"
fi

# Generate HTML Report
cat <<EOF > "$REPORT_HTML"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>Rapport de Test de Réplication MariaDB</title>
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
                    <i class="fa-solid fa-sync mr-3"></i>Replication Test
                </h1>
                <p class="text-slate-400 mt-2 font-light italic">Rapport de vérification du cluster de réplication</p>
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
                <i class="fa-solid fa-flask mr-3"></i>Résultats des Tests
            </h3>
            <div class="overflow-x-auto">
                <table class="w-full text-left">
                    <thead>
                        <tr class="border-b border-slate-700">
                            <th class="py-3 px-4 text-slate-400 uppercase text-xs font-bold">Test</th>
                            <th class="py-3 px-4 text-slate-400 uppercase text-xs font-bold">Statut</th>
                            <th class="py-3 px-4 text-slate-400 uppercase text-xs font-bold">Détails</th>
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
                <h3 class="text-xl font-bold mb-6 flex items-center text-cyan-400"><i class="fa-solid fa-server mr-3"></i>Master Status</h3>
                <pre class="p-4 bg-black/40 rounded text-[10px] font-mono whitespace-pre overflow-x-auto text-cyan-300">$MASTER_STATUS</pre>
            </div>
            <div class="glass p-8 rounded-3xl">
                <h3 class="text-xl font-bold mb-6 flex items-center text-purple-400"><i class="fa-solid fa-microchip mr-3"></i>Master Variables</h3>
                <pre class="p-4 bg-black/40 rounded text-[10px] font-mono whitespace-pre overflow-x-auto text-purple-300">$MASTER_VARS</pre>
            </div>
        </div>
    </div>

    <script>
        const connStats = [${CONN_STATS%?}];
        const testResults = [${TEST_RESULTS%?}];

        const connContainer = document.getElementById('conn-stats');
        connStats.forEach(stat => {
            const div = document.createElement('div');
            div.className = 'glass p-6 rounded-2xl';
            div.innerHTML = \`
                <div class="text-slate-500 text-xs uppercase font-bold mb-2">\${stat.name} (Port \${stat.port})</div>
                <div class="text-2xl font-bold \${stat.status === 'UP' ? 'text-green-400' : 'text-red-400'}">\${stat.status}</div>
                <div class="text-xs text-slate-400 mt-1">SSL: \${stat.ssl}</div>
            \`;
            connContainer.appendChild(div);
        });

        const resContainer = document.getElementById('test-results');
        testResults.forEach(res => {
            const tr = document.createElement('tr');
            tr.className = 'border-b border-slate-800 hover:bg-slate-800/30 transition-colors';
            tr.innerHTML = \`
                <td class="py-4 px-4 font-semibold text-slate-200">\${res.test}</td>
                <td class="py-4 px-4">
                    <span class="px-3 py-1 rounded-full text-[10px] font-bold uppercase \${res.status === 'PASS' ? 'bg-green-500/10 text-green-500 border border-green-500/20' : 'bg-red-500/10 text-red-500 border border-red-500/20'}">
                        \${res.status}
                    </span>
                </td>
                <td class="py-4 px-4 text-xs text-slate-400">\${res.details}</td>
            \`;
            resContainer.appendChild(tr);
        });
    </script>
</body>
</html>
EOF

echo -e "\n=========================================================="
echo "🏁 Test Suite Finished."
echo "Markdown Report: $REPORT_MD"
echo "HTML Report: $REPORT_HTML"
echo "=========================================================="
