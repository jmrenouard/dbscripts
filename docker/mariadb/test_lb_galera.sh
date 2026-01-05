#!/bin/bash

# Configuration
LB_HOST="127.0.0.1"
LB_PORT="3306"
USER="root"
PASS="rootpass"
ITERATIONS=40

# Create reports directory if it doesn't exist
REPORT_DIR="reports"
mkdir -p "$REPORT_DIR"

# Report filename with timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
REPORT_MD="$REPORT_DIR/test_lb_galera_$TIMESTAMP.md"
REPORT_HTML="$REPORT_DIR/test_lb_galera_$TIMESTAMP.html"

echo "=========================================================="
echo "🚀 MariaDB Galera HAProxy Load Balancing Test"
echo "=========================================================="

# Function to write to report
write_report() {
    echo -e "$1" >> "$REPORT_MD"
}

# Initialize MD report
cat <<EOF > "$REPORT_MD"
# MariaDB Load Balancing Test Report
**Date:** $(date)
**Target:** $LB_HOST:$LB_PORT
**Iterations:** $ITERATIONS

EOF

# Data for reports
declare -A hosts_count
RAW_LOGS=""
TEST_RESULTS=""

echo "1. ⏳ Iterating through Load Balancer ($ITERATIONS connections)..."

for i in $(seq 1 $ITERATIONS); do
    # Use -sN for robust parsing of single values
    RESULT=$(mariadb -h "$LB_HOST" -P "$LB_PORT" -u "$USER" -p"$PASS" -sN -e "SELECT @@hostname, (SELECT VARIABLE_VALUE FROM information_schema.SESSION_STATUS WHERE VARIABLE_NAME='Ssl_cipher');" 2>/dev/null)
    if [ $? -eq 0 ]; then
        HOSTNAME=$(echo "$RESULT" | awk '{print $1}')
        SSL=$(echo "$RESULT" | awk '{print $2}')
        [ -z "$SSL" ] || [ "$SSL" == "NULL" ] && SSL="DISABLED"
        
        echo "   [Connection $i] -> $HOSTNAME (SSL: $SSL)"
        ((hosts_count["$HOSTNAME"]++))
        RAW_LOGS="$RAW_LOGS[Connection $i] -> $HOSTNAME (SSL: $SSL)\n"
    else
        echo "   [Connection $i] -> ❌ FAILED"
        RAW_LOGS="$RAW_LOGS[Connection $i] -> FAILED\n"
    fi
done

echo ""
echo "📊 Distribution Summary:"
echo "--------------------------------------------------------"
write_report "## Distribution Summary"
write_report "| Nom de l'hôte | Connexions | Pourcentage |"
write_report "| --- | --- | --- |"

DIST_DATA=""
for host in "${!hosts_count[@]}"; do
    count=${hosts_count[$host]}
    perc=$(echo "scale=2; $count*100/$ITERATIONS" | bc)
    printf "   %-15s : %d connections (%s%%)\n" "$host" "$count" "$perc"
    write_report "| $host | $count | $perc% |"
    DIST_DATA="$DIST_DATA{\"host\":\"$host\",\"count\":$count,\"perc\":$perc},"
done
echo "--------------------------------------------------------"

# Results Table logic
UNIQUE_HOSTS=${#hosts_count[@]}
LB_STATUS="FAIL"
LB_NATURE="Load Balancing Check"
LB_EXPECTED="Connections should be spread across 3 nodes"
LB_DETAILS="Connections hit $UNIQUE_HOSTS distinct hosts."

if [ "$UNIQUE_HOSTS" -ge 3 ]; then
    echo "✅ SUCCESS: Connections were balanced across $UNIQUE_HOSTS nodes."
    LB_STATUS="PASS"
else
    echo "⚠️  WARNING: Connections only hit $UNIQUE_HOSTS node(s). Check HAProxy status."
fi

write_report "\n## Résultats du Test"
write_report "| Nature du Test | Attendu | Statut | Résultat Réel / Détails |"
write_report "| --- | --- | --- | --- |"
write_report "| $LB_NATURE | $LB_EXPECTED | $LB_STATUS | $LB_DETAILS |"

TEST_RESULTS="{\"test\":\"$LB_NATURE\",\"nature\":\"$LB_NATURE\",\"expected\":\"$LB_EXPECTED\",\"status\":\"$LB_STATUS\",\"details\":\"$LB_DETAILS\"},"

# Generate HTML Report
cat <<EOF > "$REPORT_HTML"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>Rapport de Test de Charge HAProxy</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;600;700&display=swap');
        body { font-family: 'Outfit', sans-serif; background-color: #0f172a; color: #f1f5f9; }
        .glass { background: rgba(30, 41, 59, 0.7); backdrop-filter: blur(12px); border: 1px solid rgba(255, 255, 255, 0.1); }
    </style>
</head>
<body class="p-8">
    <div class="max-w-4xl mx-auto space-y-8">
        <header class="glass p-8 rounded-3xl flex justify-between items-center">
            <div>
                <h1 class="text-3xl font-bold bg-gradient-to-r from-emerald-400 to-cyan-500 bg-clip-text text-transparent italic">
                    <i class="fa-solid fa-balancer-scale mr-3"></i>Load Balancing Test
                </h1>
                <p class="text-slate-400 mt-2 font-light italic">Vérification de la distribution HAProxy</p>
            </div>
            <div class="text-right">
                <span class="px-4 py-1 rounded-full text-[10px] font-bold uppercase ${LB_STATUS === 'PASS' ? 'bg-green-500/10 text-green-500 border border-green-500/20' : 'bg-red-500/10 text-red-500 border border-red-500/20'}">
                    ${LB_STATUS}
                </span>
            </div>
        </header>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div class="glass p-8 rounded-3xl">
                <h3 class="text-xl font-bold mb-6 text-emerald-400">Distribution</h3>
                <canvas id="distChart"></canvas>
            </div>
            <div class="glass p-8 rounded-3xl flex flex-col justify-center text-center">
                <div class="text-slate-500 text-xs uppercase font-bold mb-2">Total Iterations</div>
                <div class="text-5xl font-bold text-cyan-400">$ITERATIONS</div>
                <div class="mt-4 text-slate-400 text-sm italic">$UNIQUE_HOSTS distinct hosts hit</div>
            </div>
        </div>

        <div class="glass p-8 rounded-3xl">
            <h3 class="text-xl font-bold mb-6 text-blue-400 italic">
                <i class="fa-solid fa-list-check mr-3"></i>Résultats des Tests
            </h3>
            <div class="overflow-x-auto">
                <table class="w-full text-left text-sm">
                    <thead>
                        <tr class="text-slate-500 uppercase text-[10px] font-bold border-b border-slate-700/50">
                            <th class="pb-4">Nature du Test</th>
                            <th class="pb-4">Attendu</th>
                            <th class="pb-4">Statut</th>
                            <th class="pb-4">Résultat Réel / Détails</th>
                        </tr>
                    </thead>
                    <tbody id="test-results"></tbody>
                </table>
            </div>
        </div>

        <div class="glass p-8 rounded-3xl">
            <h3 class="text-xl font-bold mb-6 text-blue-400">Connection Logs</h3>
            <pre class="p-4 bg-black/40 rounded text-[10px] font-mono whitespace-pre overflow-y-auto h-64 text-slate-400">$RAW_LOGS</pre>
        </div>
    </div>

    <script>
        const distData = [${DIST_DATA%?}];
        const testResults = [${TEST_RESULTS%?}];

        new Chart(document.getElementById('distChart'), {
            type: 'doughnut',
            data: {
                labels: distData.map(d => d.host),
                datasets: [{
                    data: distData.map(d => d.count),
                    backgroundColor: ['#34d399', '#22d3ee', '#818cf8', '#fbbf24', '#f87171'],
                    borderWidth: 0
                }]
            },
            options: {
                responsive: true,
                plugins: {
                    legend: { position: 'bottom', labels: { color: '#94a3b8', font: { size: 10 } } }
                }
            }
        });

        const resContainer = document.getElementById('test-results');
        testResults.forEach(item => {
            const row = document.createElement('tr');
            row.className = 'border-b border-slate-800/50 hover:bg-slate-800/30 transition-colors';
            row.innerHTML = \`
                <td class="py-4 font-semibold text-slate-300">\${item.nature}</td>
                <td class="py-4 text-slate-400">\${item.expected}</td>
                <td class="py-4">
                    <span class="px-2 py-1 rounded text-[10px] font-bold uppercase \${item.status === 'PASS' ? 'bg-green-500/10 text-green-500 border border-green-500/20' : 'bg-red-500/10 text-red-500 border border-red-500/20'}">
                        \${item.status}
                    </span>
                </td>
                <td class="py-4 text-slate-400 text-xs font-mono">\${item.details}</td>
            \`;
            resContainer.appendChild(row);
        });
    </script>
</body>
</html>
EOF

echo "=========================================================="
echo "🏁 Test Finished."
echo "Markdown Report: $REPORT_MD"
echo "HTML Report: $REPORT_HTML"
echo "=========================================================="
