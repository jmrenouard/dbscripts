#!/bin/bash

#-------------------------------------------------------------------------------
# METADATA
#-------------------------------------------------------------------------------
##title_en: Ubuntu MongoDB server installation
##title_fr: Installation du serveur MongoDB sur OS Ubuntu
##goals_en: Package software installation for MongoDB / Related tools installation / Last security packages installation
##goals_fr: Installation des packages logiciels pour MongoDB / Installation des logiciels tiers / Installation des dernières versions logicielles

#-------------------------------------------------------------------------------
# CONFIGURATION
#-------------------------------------------------------------------------------
# Définit la version de MongoDB à installer. Peut être surchargé par le premier argument du script.
# Exemple: ./install_mongodb.sh 6.0
VERSION=${1:-"7.0"}

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
banner "BEGIN SCRIPT: Installation de MongoDB v${VERSION}"

# Nettoyage des anciennes listes de dépôts MongoDB pour éviter les conflits
echo "--> Nettoyage des anciens fichiers de dépôt MongoDB..."
find /etc/apt/sources.list.d -type f -iname '*mongodb*.list' -exec rm -f {} \;
lRC=$(($lRC + $?))

# Installation des dépendances et outils de base
echo "--> Installation des dépendances et des outils système..."
cmd "apt-get update"
cmd "apt-get -y install pv gnupg curl python3 cracklib-runtime python3-cracklib python3-pip"
lRC=$(($lRC + $?))

# Ajout du dépôt officiel de MongoDB
echo "--> Configuration du dépôt APT pour MongoDB v${VERSION}..."
# 1. Importation de la clé GPG publique de MongoDB
cmd "curl -fsSL https://pgp.mongodb.com/server-${VERSION}.asc | gpg -o /usr/share/keyrings/mongodb-server-${VERSION}.gpg --dearmor"
lRC=$(($lRC + $?))

# 2. Création du fichier de liste pour les sources MongoDB
# Utilise lsb_release pour s'adapter à la version d'Ubuntu (ex: jammy, focal)
cmd "echo \"deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-${VERSION}.gpg ] https://repo.mongodb.org/apt/ubuntu $(lsb_release -cs)/mongodb-org/${VERSION} multiverse\" | tee /etc/apt/sources.list.d/mongodb-org-${VERSION}.list"
lRC=$(($lRC + $?))

# Mise à jour de la base de données des paquets APT
echo "--> Mise à jour de la liste des paquets..."
cmd "apt-get update"
lRC=$(($lRC + $?))

# Installation des paquets MongoDB
echo "--> Installation des paquets MongoDB..."
# Le paquet mongodb-org est un méta-paquet qui installe le serveur, le shell, les outils, etc.
cmd "apt-get -y install mongodb-org"
lRC=$(($lRC + $?))

# Installation des outils de base de données (mongodump, mongorestore, etc.)
# qui sont parfois dans un paquet séparé.
cmd "apt-get -y install mongodb-database-tools"
lRC=$(($lRC + $?))


# Installation d'outils réseau et système utiles
echo "--> Installation des outils complémentaires (réseau, système)..."
cmd "apt-get -y install sysbench tree telnet netcat-openbsd rsync nmap lsof pigz git pwgen net-tools"
lRC=$(($lRC + $?))

# Installation des plugins de supervision
echo "--> Installation des plugins de supervision (Nagios/Centreon)..."
cmd "apt-get -y install nagios-nrpe-server nagios-nrpe-plugin centreon-plugins monitoring-plugins monitoring-plugins-contrib nagios-snmp-plugins"
lRC=$(($lRC + $?))

# Démarrage et activation du service MongoDB
echo "--> Démarrage du service MongoDB..."
cmd "systemctl daemon-reload"
cmd "systemctl enable mongod"
cmd "systemctl start mongod"
lRC=$(($lRC + $?))

echo "--> Vérification du statut du service mongod :"
systemctl status mongod --no-pager

#-------------------------------------------------------------------------------
# FIN DU SCRIPT
#-------------------------------------------------------------------------------
footer "END SCRIPT: Installation de MongoDB terminée avec le code de retour: $lRC"
exit $lRC
