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
REPORT_FILE="$REPORT_DIR/test_repli_$TIMESTAMP.md"

echo "=========================================================="
echo "🚀 MariaDB Replication Test Suite"
echo "=========================================================="

# Function to write to report
write_report() {
    echo -e "$1" >> "$REPORT_FILE"
}

# Initialize report
cat <<EOF > "$REPORT_FILE"
# MariaDB Replication Test Report
**Date:** $(date)

EOF

# Function to execute SQL
run_sql() {
    local port=$1
    local query=$2
    mariadb -h 127.0.0.1 -P $port -u$USER -p$PASS -e "$query" 2>/dev/null
}

# Function to run SQL and format for Markdown table
run_sql_md() {
    local port=$1
    local query=$2
    local output=$(mariadb -h 127.0.0.1 -P $port -u$USER -p$PASS -e "$query" 2>/dev/null)
    if [ ! -z "$output" ]; then
        echo "$output" | sed 's/\t/ | /g' | sed '1s/^/| /; 1s/$/ |/' | sed '1a | --- | --- |' | sed 's/^/| /; s/$/ |/'
    else
        echo "No data returned"
    fi
}

write_report "## Informations sur la connexion"
write_report "| Component | Port | Status | SSL Status |"
write_report "| --- | --- | --- | --- |"

echo "1. 🔍 Checking Connectivity and SSL..."
for role in "Master:$MASTER_PORT" "Slave1:$SLAVE1_PORT" "Slave2:$SLAVE2_PORT"; do
    IFS=":" read -r name port <<< "$role"
    if run_sql $port "SELECT 1" > /dev/null; then
        CIPHER=$(mariadb -h 127.0.0.1 -P $port -u$USER -p$PASS -sN -e "SHOW STATUS LIKE 'Ssl_cipher';" | awk '{print $2}')
        if [ ! -z "$CIPHER" ] && [ "$CIPHER" != "NULL" ]; then
            echo "✅ $name (Port $port) is UP (SSL: $CIPHER)"
            write_report "| $name | $port | UP | $CIPHER |"
        else
            echo "⚠️  $name (Port $port) is UP (SSL: DISABLED)"
            write_report "| $name | $port | UP | DISABLED |"
        fi
    else
        echo "❌ $name (Port $port) is DOWN"
        write_report "| $name | $port | DOWN | N/A |"
        exit 1
    fi
done

write_report "\n## Config replication (status)"
write_report "### Master Variables"
write_report "\`\`\`sql\n$(run_sql $MASTER_PORT "SHOW VARIABLES LIKE '%binlog%'; SHOW VARIABLES LIKE '%gtid%';")\n\`\`\`"

write_report "\n## Status replication (variables)"
write_report "### Master Status"
write_report "\`\`\`sql\n$(run_sql $MASTER_PORT "SHOW MASTER STATUS\G")\n\`\`\`"

write_report "\n## Informations sur l'état de la réplication"
for port in $SLAVE1_PORT $SLAVE2_PORT; do
    REPL_STATUS=$(run_sql $port "SHOW SLAVE STATUS\G" | grep -E "Slave_IO_Running|Slave_SQL_Running|Master_Host|Seconds_Behind_Master")
    write_report "### Slave (Port $port) Status Summary\n\`\`\`\n$REPL_STATUS\n\`\`\`"
done

write_report "\n## Sections pour la réplication (master & slave)"

echo -e "\n2. 👑 MASTER STATUS (Port $MASTER_PORT)"
run_sql $MASTER_PORT "SHOW MASTER STATUS\G"
write_report "### Detailed Master Status\n\`\`\`sql\n$(run_sql $MASTER_PORT "SHOW MASTER STATUS\G")\n\`\`\`"

echo -e "\n3. ⛓️ SLAVE 1 STATUS (Port $SLAVE1_PORT)"
run_sql $SLAVE1_PORT "SHOW SLAVE STATUS\G" | grep -E "Slave_IO_Running|Slave_SQL_Running|Master_Host|Seconds_Behind_Master"
write_report "### Detailed Slave 1 Status\n\`\`\`sql\n$(run_sql $SLAVE1_PORT "SHOW SLAVE STATUS\G")\n\`\`\`"

echo -e "\n4. ⛓️ SLAVE 2 STATUS (Port $SLAVE2_PORT)"
run_sql $SLAVE2_PORT "SHOW SLAVE STATUS\G" | grep -E "Slave_IO_Running|Slave_SQL_Running|Master_Host|Seconds_Behind_Master"
write_report "### Detailed Slave 2 Status\n\`\`\`sql\n$(run_sql $SLAVE2_PORT "SHOW SLAVE STATUS\G")\n\`\`\`"

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
else
    echo "❌ Slave 1 failed to receive data"
    write_report "- ❌ Slave 1 (Port $SLAVE1_PORT): Data replication FAILED."
fi

echo ">> Checking Slave 2..."
MSG2=$(run_sql $SLAVE2_PORT "SELECT msg FROM $DB.test_table LIMIT 1;")
if [ ! -z "$MSG2" ]; then
    echo "✅ Slave 2 received: $MSG2"
    write_report "- ✅ Slave 2 (Port $SLAVE2_PORT): Data received correctly."
else
    echo "❌ Slave 2 failed to receive data"
    write_report "- ❌ Slave 2 (Port $SLAVE2_PORT): Data replication FAILED."
fi

echo -e "\n=========================================================="
echo "🏁 Test Suite Finished. Report: $REPORT_FILE"
echo "=========================================================="
