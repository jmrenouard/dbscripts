#!/bin/bash

# Configuration
LB_HOST="127.0.0.1"
LB_PORT="3306"
USER="root"
PASS="rootpass"
ITERATIONS=40

echo "=========================================================="
echo "🚀 MariaDB Galera HAProxy Load Balancing Test"
echo "=========================================================="
echo "Connecting to $LB_HOST:$LB_PORT $ITERATIONS times..."
echo ""

# Array to store hosts
declare -A hosts_count

for i in $(seq 1 $ITERATIONS); do
    HOSTNAME=$(mariadb -h "$LB_HOST" -P "$LB_PORT" -u "$USER" -p"$PASS" -N -e "SELECT @@hostname;" 2>/dev/null)
    if [ $? -eq 0 ]; then
        echo "   [Connection $i] -> $HOSTNAME"
        ((hosts_count["$HOSTNAME"]++))
    else
        echo "   [Connection $i] -> ❌ FAILED"
    fi
done

echo ""
echo "📊 Distribution Summary:"
echo "--------------------------------------------------------"
for host in "${!hosts_count[@]}"; do
    printf "   %-15s : %d connections\n" "$host" "${hosts_count[$host]}"
done
echo "--------------------------------------------------------"

# Basic check: were all 3 nodes hit? (assuming 3 nodes cluster)
UNIQUE_HOSTS=${#hosts_count[@]}
if [ "$UNIQUE_HOSTS" -ge 3 ]; then
    echo "✅ SUCCESS: Connections were balanced across $UNIQUE_HOSTS nodes."
else
    echo "⚠️  WARNING: Connections only hit $UNIQUE_HOSTS node(s). Check HAProxy status."
fi
echo "=========================================================="
