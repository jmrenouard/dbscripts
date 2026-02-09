#!/bin/bash

#-------------------------------------------------------------------------------
# METADATA
#-------------------------------------------------------------------------------
##title_en: Ubuntu MongoDB server uninstallation
##title_fr: Désinstallation du serveur MongoDB sur OS Ubuntu
##goals_en: Stop MongoDB service / Purge all MongoDB packages / Remove data and log directories / Clean up APT repository files
##goals_fr: Arrêt du service MongoDB / Purge des paquets MongoDB / Suppression des répertoires de données et de logs / Nettoyage des fichiers de dépôt APT

#-------------------------------------------------------------------------------
# CONFIGURATION
#-------------------------------------------------------------------------------
# Variable pour suivre les erreurs. Si une commande échoue, sa valeur augmente.
lRC=0

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
    eval "$tcmd"
    local cRC=$?
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

_NAME="$(basename "$(readlink -f "$0")")"
NAME="${_NAME}"

#-------------------------------------------------------------------------------
# DÉBUT DU SCRIPT
#-------------------------------------------------------------------------------
banner "BEGIN SCRIPT: Désinstallation de MongoDB"

# Étape 1: Arrêter et désactiver le service MongoDB
echo "--> Arrêt et désactivation du service mongod..."
cmd "systemctl stop mongod"
cmd "systemctl disable mongod"
lRC=$(($lRC + $?))

# Étape 2: Purger les paquets MongoDB
# L'option 'purge' supprime les paquets ainsi que leurs fichiers de configuration.
# Le joker '*' assure que tous les paquets (mongodb-org, mongodb-org-server, etc.) sont supprimés.
echo "--> Suppression complète des paquets MongoDB..."
cmd "apt-get purge -y mongodb-org*"
lRC=$(($lRC + $?))

# Nettoyer les dépendances qui ne sont plus nécessaires
cmd "apt-get autoremove -y"
lRC=$(($lRC + $?))

# Étape 3: Supprimer les répertoires de données et de logs
echo "--> ATTENTION: Suppression des données et des logs de MongoDB..."
echo "    Répertoire de données : /var/lib/mongodb"
echo "    Répertoire de logs    : /var/log/mongodb"
cmd "rm -rf /var/lib/mongodb"
lRC=$(($lRC + $?))
cmd "rm -rf /var/log/mongodb"
lRC=$(($lRC + $?))

# Étape 4: Nettoyer les fichiers de configuration du dépôt APT
echo "--> Nettoyage des sources APT et des clés GPG de MongoDB..."
cmd "find /etc/apt/sources.list.d -type f -name '*mongodb*.list' -delete"
lRC=$(($lRC + $?))
cmd "find /usr/share/keyrings -type f -name '*mongodb*.gpg' -delete"
lRC=$(($lRC + $?))

# Mettre à jour la liste des paquets après la suppression du dépôt
echo "--> Mise à jour de la liste des paquets..."
cmd "apt-get update"
lRC=$(($lRC + $?))

#-------------------------------------------------------------------------------
# FIN DU SCRIPT
#-------------------------------------------------------------------------------
footer "END SCRIPT: Désinstallation de MongoDB terminée avec le code de retour: $lRC"
exit $lRC
