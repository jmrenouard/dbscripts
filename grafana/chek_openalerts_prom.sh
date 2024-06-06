#!/bin/bash

# Répertoire où les fichiers texte seront stockés
OUTPUT_DIR="/var/lib/node_exporter/textfile_collector"
OUTPUT_FILE="$OUTPUT_DIR/alertmanager_alerts.prom"

# URL de l'API Alertmanager
ALERTMANAGER_URL="http://localhost:9093/api/v2/alerts"

# Récupérer les alertes en cours d'Alertmanager
alerts=$(curl -s $ALERTMANAGER_URL)

# Vérifier si la commande curl a réussi
if [ $? -ne 0 ]; then
    echo "Erreur: Impossible de récupérer les alertes d'Alertmanager" >&2
    exit 1
fi

# Créer un fichier texte pour les métriques
echo "# HELP alertmanager_active_alerts Count of active alerts in Alertmanager" > $OUTPUT_FILE
echo "# TYPE alertmanager_active_alerts gauge" >> $OUTPUT_FILE

# Compter le nombre d'alertes en cours
alert_count=$(echo $alerts | jq '. | length')
echo "alertmanager_active_alerts $alert_count" >> $OUTPUT_FILE

# Ajouter des métriques pour chaque alerte
for row in $(echo "${alerts}" | jq -r '.[] | @base64'); do
    _jq() {
        echo ${row} | base64 --decode | jq -r ${1}
    }

    alert_name=$(_jq '.labels.alertname')
    severity=$(_jq '.labels.severity')
    instance=$(_jq '.labels.instance')

    echo "# HELP alertmanager_alerts_info Information about active alerts in Alertmanager" >> $OUTPUT_FILE
    echo "# TYPE alertmanager_alerts_info gauge" >> $OUTPUT_FILE
    echo "alertmanager_alerts_info{alertname=\"$alert_name\",severity=\"$severity\",instance=\"$instance\"} 1" >> $OUTPUT_FILE
done
