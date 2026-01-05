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
echo "Connecting to $LB_HOST:$LB_PORT $ITERATIONS times..."
echo ""

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

for i in $(seq 1 $ITERATIONS); do
    RESULT=$(mariadb -h "$LB_HOST" -P "$LB_PORT" -u "$USER" -p"$PASS" -N -s -e "SELECT @@hostname, (SELECT VARIABLE_VALUE FROM information_schema.SESSION_STATUS WHERE VARIABLE_NAME='Ssl_cipher');" 2>/dev/null)
    if [ $? -eq 0 ]; then
        HOSTNAME=$(echo "$RESULT" | awk '{print $1}')
        SSL=$(echo "$RESULT" | awk '{print $2}')
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
echo -e "## Distribution Summary\n| Hostname | Connections | Percentage |\n| --- | --- | --- |" >> "$REPORT_MD"
DIST_DATA=""
for host in "${!hosts_count[@]}"; do
    count=${hosts_count[$host]}
    perc=$(echo "scale=2; $count*100/$ITERATIONS" | bc)
    printf "   %-15s : %d connections (%s%%)\n" "$host" "$count" "$perc"
    echo "| $host | $count | $perc% |" >> "$REPORT_MD"
    DIST_DATA="$DIST_DATA{\"host\":\"$host\",\"count\":$count,\"perc\":$perc},"
done
echo "--------------------------------------------------------"

# Basic check
UNIQUE_HOSTS=${#hosts_count[@]}
STATUS="FAIL"
if [ "$UNIQUE_HOSTS" -ge 3 ]; then
    echo "✅ SUCCESS: Connections were balanced across $UNIQUE_HOSTS nodes."
    STATUS="PASS"
else
    echo "⚠️  WARNING: Connections only hit $UNIQUE_HOSTS node(s). Check HAProxy status."
fi

echo -e "\n**Final Status:** $STATUS ($UNIQUE_HOSTS nodes hit)" >> "$REPORT_MD"

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
                <span class="px-4 py-1 rounded-full text-[10px] font-bold uppercase ${STATUS === 'PASS' ? 'bg-green-500/10 text-green-500 border border-green-500/20' : 'bg-red-500/10 text-red-500 border border-red-500/20'}">
                    ${STATUS}
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
            <h3 class="text-xl font-bold mb-6 text-blue-400">Connection Logs</h3>
            <pre class="p-4 bg-black/40 rounded text-[10px] font-mono whitespace-pre overflow-y-auto h-64 text-slate-400">$RAW_LOGS</pre>
        </div>
    </div>

    <script>
        const distData = [${DIST_DATA%?}];
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
    </script>
</body>
</html>
EOF

echo "=========================================================="
echo "🏁 Test Finished."
echo "Markdown Report: $REPORT_MD"
echo "HTML Report: $REPORT_HTML"
echo "=========================================================="
