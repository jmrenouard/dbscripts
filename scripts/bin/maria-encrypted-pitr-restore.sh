#!/bin/bash

# ==========================================================
# Script : Restore Encrypted Binlog GTID
# Date    : 12 Mars 2025
# Version : 1.4
#
# Description :
# Ce script permet de restaurer et de déchiffrer les événements des binlogs MariaDB,
# qui sont chiffrés et ne peuvent être lus directement. Le serveur MariaDB doit être utilisé
# pour décoder ces binlogs avant de pouvoir les appliquer.
#
# Il effectue les étapes suivantes :
# 1. Récupération du répertoire des binlogs MariaDB et du fichier index.
# 2. Récupération de la position courante du GTID.
# 3. Arrêt du service MariaDB.
# 4. Suppression des anciens binlogs dans le répertoire MariaDB.
# 5. Copie des binlogs restaurés vers le répertoire MariaDB.
# 6. Mise à jour du fichier index des binlogs.
# 7. Redémarrage de MariaDB.
# 8. Recherche du fichier binlog contenant le GTID exécuté (les binlogs étant chiffrés, seule MariaDB peut les lire).
# 9. Sélection des fichiers binlog suivants pour restauration.
# 10. Utilisation de `mariadb-binlog` pour rejouer les transactions après déchiffrement par le serveur.
#
# Paramètres :
# $1 - Chemin du répertoire contenant les fichiers binlog restaurés
# $2 - Date de fin pour la restauration (format YYYY-MM-DD)
# $3 - Heure de fin pour la restauration (format HH:MM:SS)
# ==========================================================

# Définir les chemins vers les utilitaires
MARIADBBINLOG="/usr/bin/mariadb-binlog"  # Modifier si nécessaire
MARIADB="/usr/bin/mariadb"              # Modifier si nécessaire

# Vérifier que les paramètres requis sont passés
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
    echo "[ERROR] Usage: $0 <chemin_binlogs> <stop_date (YYYY-MM-DD)> <stop_time (HH:MM:SS)>"
    exit 1
fi

RESTORED_BINLOG_PATH="$1"   # Stocke le chemin des fichiers binlogs restaurés
STOP_DATE="$2"      # Stocke la date limite
STOP_TIME="$3"      # Stocke l'heure limite
STOP_DATETIME="$STOP_DATE $STOP_TIME" # Construit la date complète pour la restauration

echo "[INFO] Début de l'exécution du script"
echo "[INFO] Chemin des binlogs restaurés : $RESTORED_BINLOG_PATH"
echo "[INFO] Stop datetime : $STOP_DATETIME"

# Étape 1 : Récupération du répertoire des binlogs et du fichier index depuis MariaDB
BINLOG_PATH=$($MARIADB -Nrs -e "SHOW VARIABLES LIKE 'log_bin_basename'" | awk '{print $2}'|xargs -n 1 dirname)
BINLOG_INDEX_PATH=$($MARIADB -Nrs -e "SHOW VARIABLES LIKE 'log_bin_index'" | awk '{print $2}')

LST_BINLOGS_TO_COPY=$(ls -1 $RESTORED_BINLOG_PATH | grep log_bin | xargs -n1 basename | sort -n)

# Étape 2 : Récupération de la position courante du GTID
GTID_EXECUTED=$($MARIADB -Nrs -e "SHOW VARIABLES LIKE 'gtid_current_pos'" | awk '{print $2}')

echo "[INFO] GTID exécuté : $GTID_EXECUTED"

# Étape 3 : Arrêt de MariaDB
systemctl stop mariadb

# Étape 4 : Suppression des anciens binlogs
rm -f $BINLOG_PATH/*

# Étape 5 : Copie des binlogs restaurés vers le répertoire MariaDB
(cd $RESTORED_BINLOG_PATH
cp $LST_BINLOGS_TO_COPY $BINLOG_PATH
)

# Étape 6 : Mise à jour du fichier index des binlogs
(
cd $BINLOG_PATH
echo $LST_BINLOGS_TO_COPY | xargs -n1 | xargs -I{} echo $BINLOG_PATH/{} 
) > $BINLOG_INDEX_PATH

chown -R mysql:mysql $BINLOG_PATH

# Étape 7 : Redémarrage de MariaDB
systemctl start mariadb

# Étape 8 : Recherche du fichier binlog contenant le GTID exécuté
echo "[INFO] Recherche du fichier binlog contenant le GTID..."
BINLOG_GTID_FILE=$(for i in "$RESTORED_BINLOG_PATH"/log_bin*; do
    $MARIADBBINLOG -R --base64-output=DECODE-ROWS "$(basename $i)" | grep -aq "$GTID_EXECUTED"; # Vérifie si le GTID est présent dans le fichier chiffré
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

# Étape 9 : Trouver les fichiers binlog après le fichier contenant le GTID
echo "[INFO] Recherche des fichiers binlog après le GTID..."
BINLOG_FILES=$(ls -1 "$BINLOG_PATH"/log_bin* | sed "0,/$(basename $BINLOG_GTID_FILE)/d" )

echo "[INFO] Fichiers binlog après le GTID :"
echo "$BINLOG_FILES"

# Vérifier si des fichiers binlog ont été trouvés
if [ -z "$BINLOG_FILES" ]; then
    echo "[ERROR] Aucun fichier binlog trouvé après le GTID."
    exit 1
fi

# Étape 10 : Restaurer les événements après déchiffrement des binlogs
echo "[INFO] Démarrage de la restauration des événements..."
$MARIADBBINLOG -R $BINLOG_FILES --stop-datetime="$STOP_DATETIME" | $MARIADB -f --binary-mode=1 # MariaDB décrypte et rejoue les logs jusqu'à la date spécifiée
if [ $? -eq 0 ]; then
  echo "[INFO] Restauration terminée avec succès"
  exit 0
fi
echo "[WARN] Restauration terminée avec des erreurs"
exit 2
