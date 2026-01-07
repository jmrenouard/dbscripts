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

echo "=========================================================="
echo "🎯 HAProxy Galera Load Balancer Validation"
echo "=========================================================="

# 1. Test de l'interface de statistiques (Admin Web)
echo "1. 📊 Vérification de l'interface de stats (Port $STATS_PORT)..."
if curl -s "http://$LB_IP:$STATS_PORT/stats" > /dev/null; then
    echo "✅ Interface stats accessible sur http://$LB_IP:$STATS_PORT/stats"
    
    # Vérification du statut des nœuds dans les stats (CSV format)
    echo ">> État des nœuds dans le backend 'galera_nodes' :"
    curl -s "http://$LB_IP:$STATS_PORT/stats;csv" | grep "galera_nodes," | grep -v "BACKEND" | awk -F',' '{printf "   - %-10s: %-10s (Sessions: %s)\n", $2, $18, $5}'
else
    echo "❌ Erreur: Interface stats inaccessible."
    exit 1
fi

echo ""

# 2. Test de répartition de charge (Select @@hostname)
echo "2. 🔄 Test de Round-Robin via le Port $LB_PORT ($ITERATIONS itérations)..."
declare -A HOSTS_COUNT

for ((i=1; i<=ITERATIONS; i++)); do
    HOSTNAME=$(mariadb -h $LB_IP -P $LB_PORT -u$USER -p$PASS -sN -e "SELECT @@hostname;" 2>/dev/null || echo "FAILED")
    if [ "$HOSTNAME" != "FAILED" ]; then
        ((HOSTS_COUNT[$HOSTNAME]++))
        echo "   [$i] Requête dirigée vers : $HOSTNAME"
    else
        echo "   [$i] ❌ Échec de connexion au Load Balancer"
    fi
done

echo ""
echo "📊 Résumé de la répartition :"
for host in "${!HOSTS_COUNT[@]}"; do
    echo "   - $host : ${HOSTS_COUNT[$host]} requêtes"
done

# Vérification finale
if [ ${#HOSTS_COUNT[@]} -gt 1 ]; then
    echo ""
    echo "✅ RÉSULTAT : Le Load Balancer répartit correctement la charge sur ${#HOSTS_COUNT[@]} nœuds."
else
    echo ""
    echo "⚠️ ATTENTION : Un seul nœud répond. Vérifiez l'état de synchronisation du cluster ou la config HAProxy."
fi

echo "=========================================================="
