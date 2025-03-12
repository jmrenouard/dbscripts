#!/bin/bash

# ==========================================================
# Script : Restore Binlog GTID
# Date    : 12 Mars 2025
# Version : 1.3
#
# Description :
# Ce script permet de restaurer les événements MariaDB binlog à partir
# d'un GTID donné jusqu'à une date spécifique.
# Il effectue les étapes suivantes :
# 1. Récupération de la position courante du GTID.
# 2. Identification du fichier binlog contenant cette position.
# 3. Sélection des fichiers binlog suivants pour restauration.
# 4. Exécution de mariadb-binlog pour rejouer les transactions jusqu'à
#    la date spécifiée.
#
# Paramètres :
# $1 - Chemin du répertoire contenant les fichiers binlog
# $2 - Date de fin pour la restauration (format YYYY-MM-DD)
# $3 - Heure de fin pour la restauration (format HH:MM:SS)
# ==========================================================

# Définir les chemins vers les utilitaires
MARIADBBINLOG="/usr/bin/mariadb-binlog"  # Modifier si nécessaire
MARIADB="/usr/bin/mariadb"              # Modifier si nécessaire

# Définir le motif pour les fichiers binlogs
BINLOG_PATTERN="log_bin*"  # Modifier si nécessaire

# Vérifier que les paramètres requis sont passés
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
    echo "[ERROR] Usage: $0 <chemin_binlogs> <stop_date (YYYY-MM-DD)> <stop_time (HH:MM:SS)>"
    exit 1
fi

BINLOG_PATH="$1"   # Stocke le chemin des fichiers binlogs
STOP_DATE="$2"      # Stocke la date limite
STOP_TIME="$3"      # Stocke l'heure limite
STOP_DATETIME="$STOP_DATE $STOP_TIME" # Construit la date complète pour la restauration

echo "[INFO] Début de l'exécution du script"
echo "[INFO] Chemin des binlogs : $BINLOG_PATH"
echo "[INFO] Stop datetime : $STOP_DATETIME"

# Récupérer la position courante du GTID
GTID_EXECUTED=$($MARIADB -Nrs -e "SHOW VARIABLES LIKE 'gtid_current_pos'" | awk '{print $2}')

echo "[INFO] GTID exécuté : $GTID_EXECUTED"

# Trouver le fichier binlog contenant la référence du GTID
echo "[INFO] Recherche du fichier binlog contenant le GTID..."
BINLOG_GTID_FILE=$(for i in "$BINLOG_PATH"/$BINLOG_PATTERN; do
    $MARIADBBINLOG --base64-output=DECODE-ROWS "$i" | grep -aq "$GTID_EXECUTED"; # Vérifie si le GTID est présent dans le fichier
    if [ $? -eq 0 ]; then
        echo "$i"
        break
    fi
done)

echo "[INFO] Fichier binlog contenant le GTID $GTID_EXECUTED: $BINLOG_GTID_FILE"

# Vérifier si un fichier binlog a été trouvé
if [ -z "$BINLOG_GTID_FILE" ]; then
    echo "[ERROR] Aucun fichier binlog contenant le GTID trouvé."
    exit 1
fi

# Trouver les fichiers binlog après le fichier contenant le GTID
echo "[INFO] Recherche des fichiers binlog après le GTID..."
BINLOG_FILES=$(ls -1 "$BINLOG_PATH"/$BINLOG_PATTERN | sed "0,/$(basename $BINLOG_GTID_FILE)/d" )

echo "[INFO] Fichiers binlog après le GTID :"
echo "$BINLOG_FILES"

# Vérifier si des fichiers binlog ont été trouvés
if [ -z "$BINLOG_FILES" ]; then
    echo "[ERROR] Aucun fichier binlog trouvé après le GTID."
    exit 1
fi

# Restaurer les événements jusqu'à une date spécifique
echo "[INFO] Démarrage de la restauration des événements..."
$MARIADBBINLOG $BINLOG_FILES --stop-datetime="$STOP_DATETIME" | $MARIADB -f --binary-mode=1 # Rejoue les logs jusqu'à la date spécifiée
if [ $? -eq 0 ]; then
  echo "[INFO] Restauration terminée avec succès"
  exit 0
fi
echo "[WARN] Restauration terminée avec des erreurs"
exit 2
