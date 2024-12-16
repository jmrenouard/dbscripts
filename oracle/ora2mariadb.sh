#!/bin/bash

# Variables
INPUT_FILE="./bcr_ddl.sql"
OUTPUT_FILE="./bcr_ddl_mariadb.sql"

# Création d'un fichier temporaire pour le traitement
TEMP_FILE=$(mktemp)

# Conversion des types de données avec ajout de commentaires
while IFS= read -r line; do
  if echo "$line" | grep -q "VARCHAR2"; then
    echo -n "$line" | sed 's/VARCHAR2/VARCHAR/g' >> "$TEMP_FILE"
    echo "-- Original type: VARCHAR2" >> "$TEMP_FILE"
  elif echo "$line" | grep -q "NUMBER"; then
    echo -n "$line" | sed 's/NUMBER/INT/g' >> "$TEMP_FILE"
    echo " -- Original type: NUMBER" >> "$TEMP_FILE"
  elif echo "$line" | grep -q "DATE"; then
    echo -n "$line" | sed 's/DATE/DATETIME/g' >> "$TEMP_FILE"
    echo " -- Original type: DATE" >> "$TEMP_FILE"
  elif echo "$line" | grep -q "CLOB"; then
    echo -n "$line" | sed 's/CLOB/TEXT/g' >> "$TEMP_FILE"
    echo  " -- Original type: CLOB" >> "$TEMP_FILE"
  elif echo "$line" | grep -q "BLOB"; then
    echo -n "$line" | sed 's/BLOB/BINARY/g' >> "$TEMP_FILE"
    echo "-- Original type: BLOB" >> "$TEMP_FILE"
  else
    echo "$line" >> "$TEMP_FILE"
  fi
done < "$INPUT_FILE"

# Suppression des guillemets doubles autour des noms de tables et de colonnes
perl -i -pe 's/ (BYTE|CHAR)\)/)/g;s/CREATE TABLE ".+?"./CREATE TABLE /g;s/"//g;s/\) SEGMENT CREATION IMMEDIATE/);/g' "$TEMP_FILE"

# Remplacement de la séquence et du trigger pour les colonnes AUTO_INCREMENT
# Remplacer cette section par une analyse plus détaillée si besoin
sed -i 's/CREATE SEQUENCE.*;//g;s/CREATE OR REPLACE TRIGGER.*;//g;/^$/d;' "$TEMP_FILE"

sed -i '/PCTFREE .* PCTUSED/d;/NOCOMPRESS LOGGING/d;/PCTINCREASE/d;/BUFFER_POOL/d' "$TEMP_FILE"  

perl -i -pe '/\s*(TABLESPACE|STORAGE)\s*/d;s/\s*(COMMENT ON COLUMN .*)/-- $1/g;s/\s*(COMMENT ON TABLE .*)/-- $1/g' "$TEMP_FILE" 
# Sauvegarde du fichier converti
rm -f "$OUTPUT_FILE"
mv "$TEMP_FILE" "$OUTPUT_FILE"

echo "Conversion terminée. Le fichier converti est disponible sous : $OUTPUT_FILE"
