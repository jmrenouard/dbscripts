#!/bin/bash
set -euo pipefail

# --- Minimal Utility Functions ---
now() { echo "$(date "+%F %T %Z")($(hostname -s))"; }
info() { echo "$(now) INFO: $*" 1>&2; }
error() { echo "$(now) ERROR: $*" 1>&2; return 1; }
ok() { info "[SUCCESS] $* [SUCCESS]"; }
sep1() { echo "$(now) -----------------------------------------------------------------------------"; }
title1() { sep1; echo "$(now) $*"; sep1; }
cmd() {
    local tcmd="$1"
    local descr=${2:-"$tcmd"}
    title1 "RUNNING: $descr"
    set +e
    eval "$tcmd"
    local cRC=$?
    set -e
    if [ $cRC -eq 0 ]; then
        ok "$descr"
    else
        error "$descr (RC=$cRC)"
    fi
    return $cRC
}
banner() { title1 "START: $*"; info "run as $(whoami)@$(hostname -s)"; }
footer() {
    local lRC=${lRC:-"$?"}
    info "FINAL EXIT CODE: $lRC"
    [ $lRC -eq 0 ] && title1 "END: $* SUCCESSFUL" || title1 "END: $* FAILED"
    return $lRC
}
# --- End of Utility Functions ---

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
