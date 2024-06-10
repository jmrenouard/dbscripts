#!/bin/bash

# Variables
PROMETHEUS_URL="http://localhost:9090"
BACKUP_DIR="/path/to/backup/directory"
TIMESTAMP=$(date +%Y%m%d%H%M%S)
SNAPSHOT_DIR="/tmp/prometheus_snapshots"
SNAPSHOT_NAME="snapshot-$TIMESTAMP"
ARCHIVE_NAME="$SNAPSHOT_NAME.tar.gz"
TEXTFILE_DIR="/var/lib/node_exporter/textfile_collector"
TEXTFILE="$TEXTFILE_DIR/prometheus_backup.prom"

# Créer les répertoires temporaires et textfile
mkdir -p $SNAPSHOT_DIR
mkdir -p $TEXTFILE_DIR

# Créer un snapshot de Prometheus
echo "Creating Prometheus snapshot..."
SNAPSHOT_URL=$(curl -s -X POST "$PROMETHEUS_URL/api/v1/admin/tsdb/snapshot" | jq -r .data.name)

if [ -z "$SNAPSHOT_URL" ]; then
  echo "Error: Failed to create snapshot."
  exit 1
fi

SNAPSHOT_PATH="$PROMETHEUS_URL/snapshots/$SNAPSHOT_URL"

# Copier le snapshot dans le répertoire temporaire
echo "Copying snapshot files..."
cp -r $SNAPSHOT_PATH $SNAPSHOT_DIR/$SNAPSHOT_NAME

# Archiver le snapshot
echo "Archiving snapshot..."
tar -czf $SNAPSHOT_DIR/$ARCHIVE_NAME -C $SNAPSHOT_DIR $SNAPSHOT_NAME

# Calculer l'empreinte SHA256
echo "Calculating SHA256 checksum..."
sha256sum $SNAPSHOT_DIR/$ARCHIVE_NAME > $SNAPSHOT_DIR/$ARCHIVE_NAME.sha256

# Copier l'archive et l'empreinte SHA256 vers le répertoire de sauvegarde
echo "Copying archive and checksum to backup directory..."
cp $SNAPSHOT_DIR/$ARCHIVE_NAME $BACKUP_DIR/
cp $SNAPSHOT_DIR/$ARCHIVE_NAME.sha256 $BACKUP_DIR/

# Récupérer la taille de l'archive
ARCHIVE_SIZE=$(stat -c%s "$SNAPSHOT_DIR/$ARCHIVE_NAME")

# Écrire les informations dans le fichier textfile pour node_exporter
echo "Writing backup status to textfile collector..."
echo "# HELP prometheus_backup_success Indicates if the Prometheus backup was successful (1 = success, 0 = failure)" > $TEXTFILE
echo "# TYPE prometheus_backup_success gauge" >> $TEXTFILE
echo "prometheus_backup_success{snapshot=\"$SNAPSHOT_NAME\"} 1" >> $TEXTFILE

echo "# HELP prometheus_backup_size_bytes Size of the Prometheus backup in bytes" >> $TEXTFILE
echo "# TYPE prometheus_backup_size_bytes gauge" >> $TEXTFILE
echo "prometheus_backup_size_bytes{snapshot=\"$SNAPSHOT_NAME\"} $ARCHIVE_SIZE" >> $TEXTFILE

echo "# HELP prometheus_backup_timestamp Timestamp of the Prometheus backup" >> $TEXTFILE
echo "# TYPE prometheus_backup_timestamp gauge" >> $TEXTFILE
echo "prometheus_backup_timestamp{snapshot=\"$SNAPSHOT_NAME\"} $(date +%s)" >> $TEXTFILE

# Nettoyer les fichiers temporaires
echo "Cleaning up temporary files..."
rm -rf $SNAPSHOT_DIR/$SNAPSHOT_NAME
rm $SNAPSHOT_DIR/$ARCHIVE_NAME
rm $SNAPSHOT_DIR/$ARCHIVE_NAME.sha256

echo "Backup completed successfully."
