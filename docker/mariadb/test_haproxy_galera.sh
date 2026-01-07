#!/bin/bash
# test_haproxy_galera.sh - Validation du Load Balancer HAProxy pour Galera

# set -e removed to allow capturing individual failure counts

# Configuration
LB_IP="127.0.0.1"
LB_PORT="3306"
STATS_PORT="8404"
USER="root"
PASS="rootpass"
ITERATIONS=10
NODE3_NAME="mariadb-galera_03-1" # Nom du conteneur selon docker-compose prefix

echo "=========================================================="
echo "🎯 HAProxy Galera Advanced Validation Suite"
echo "=========================================================="

# 1. 📊 Interface de Stats & Santé Initiale
echo "1. 🏥 État de santé initial du Backend..."
if ! curl -s "http://$LB_IP:$STATS_PORT/stats" > /dev/null; then
    echo "❌ Erreur: Interface stats inaccessible."
    exit 1
fi
curl -s "http://$LB_IP:$STATS_PORT/stats;csv" | grep "galera_nodes," | grep -v "BACKEND" | awk -F',' '{printf "   - %-10s: %-10s\n", $2, $18}'

echo ""

# 2. 🏎️ Benchmarking de Performance (LB vs Direct)
echo "2. 🏎️ Test de Performance (Latence Moyenne)..."
function get_latency() {
    local host=$1; local port=$2
    local total_time=0
    for ((i=1; i<=5; i++)); do
        local start=$(date +%s%N)
        mariadb -h $host -P $port -u$USER -p$PASS -e "SELECT 1;" >/dev/null 2>&1
        local end=$(date +%s%N)
        total_time=$((total_time + (end - start)/1000000))
    done
    echo $((total_time / 5))
}

LAT_LB=$(get_latency $LB_IP $LB_PORT)
LAT_DIRECT=$(get_latency $LB_IP 3511)
echo "   - Via HAProxy : ${LAT_LB}ms (moyenne)"
echo "   - Direct (N1) : ${LAT_DIRECT}ms (moyenne)"
echo "   - Overhead LB : $((LAT_LB - LAT_DIRECT))ms"

echo ""

# 3. 🧩 Vérification de la Persistance (Sticky Sessions)
echo "3. 🧩 Test de Persistance / Sticky Sessions..."
H1=$(mariadb -h $LB_IP -P $LB_PORT -u$USER -p$PASS -sN -e "SELECT @@hostname;")
H2=$(mariadb -h $LB_IP -P $LB_PORT -u$USER -p$PASS -sN -e "SELECT @@hostname;")
if [ "$H1" == "$H2" ]; then
    echo "   📍 Mode de connexion : PERSISTANT (Sticky)"
else
    echo "   🔄 Mode de connexion : ROUND-ROBIN (Distribué)"
fi

echo ""

# 4. 🧨 Simulation de Panne & Failover (Stress-failover)
echo "4. 🧨 Test de Failover (Simulation de panne sur Node 3)..."
echo ">> [ACTION] Arrêt du conteneur Node 3..."
docker stop $NODE3_NAME > /dev/null

echo ">> [WAIT] Attente de la détection HAProxy (5s)..."
sleep 5

echo ">> [TEST] Vérification de la continuité de service..."
declare -A FAILOVER_COUNT
for ((i=1; i<=10; i++)); do
    HOSTNAME=$(mariadb -h $LB_IP -P $LB_PORT -u$USER -p$PASS -sN -e "SELECT @@hostname;" 2>/dev/null || echo "DOWN")
    ((FAILOVER_COUNT[$HOSTNAME]++))
done

for host in "${!FAILOVER_COUNT[@]}"; do
    if [ "$host" == "DOWN" ]; then
        echo "   ❌ ÉCHEC : $host (${FAILOVER_COUNT[$host]} requêtes échouées)"
    else
        echo "   ✅ OK : $host (${FAILOVER_COUNT[$host]} requêtes)"
    fi
done

echo ">> [ACTION] Redémarrage du conteneur Node 3..."
docker start $NODE3_NAME > /dev/null

echo ""
echo "🏁 Fin de la suite de validation avancée."
echo "=========================================================="
