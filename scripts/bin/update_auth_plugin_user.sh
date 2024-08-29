#!/bin/bash

# Paramètres
USER="$1"
HOST="$2"
PASSWORD="$3"
PLUGIN="$4"

# Validation du plugin
if [[ "$PLUGIN" != "caching_sha2_password" && "$PLUGIN" != "ed25519" ]]; then
  echo "Plugin d'authentification non supporté. Utilisez 'caching_sha2_password' ou 'ed25519'."
  exit 1
fi

# Connexion initiale et exécution de ALTER USER
mysql -u"$USER" -p"$PASSWORD" -h"$HOST" -e "ALTER USER '$USER'@'$HOST' IDENTIFIED WITH '$PLUGIN' BY '$PASSWORD';"
if [ $? -ne 0 ]; then
  echo "Erreur lors de la mise à jour du plugin d'authentification."
  exit 1
fi

echo "Plugin d'authentification mis à jour vers $PLUGIN."

# Test de connexion avec le nouveau plugin
mysql -u"$USER" -p"$PASSWORD" -h"$HOST" -e "SELECT 'Connexion réussie avec le nouveau plugin.' AS message;"
if [ $? -ne 0 ]; then
  echo "Échec de la connexion avec le nouveau plugin."
  exit 1
fi

echo "Test de connexion réussi avec le nouveau plugin."
