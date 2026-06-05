#!/bin/bash

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
my_private_ipv4=$(ip a | grep inet | grep 'brd' | grep -E '(192.168|172.2)'| cut -d/ -f1 | awk '{print $2}'|head -n1)

banner "### Installation de MySQL 5.7 on Debian 12 ###"
lRC=0

dpkg -i "mysql-common_${MYSQL_VERSION}-1debian${DEBIAN_VERSION_PACKAGES}_amd64.deb" || { echo "Avertissement: Échec de la réinstallation de mysql-common."; }

echo "Installation des dépendances supplémentaires (libmecab2 psmisc)..."
apt install -y libmecab2 psmisc || { echo "Avertissement: Impossible d'installer les dépendances supplémentaires."; }

echo "Installation de mysql-community-server..."
dpkg -i "mysql-community-server_${MYSQL_VERSION}-1debian${DEBIAN_VERSION_PACKAGES}_amd64.deb" || { echo "Erreur: Échec de l'installation de mysql-community-server. L'installation pourrait ne pas être complète."; exit 1; }

echo "Installation de mysql-server..."
dpkg -i "mysql-server_${MYSQL_VERSION}-1debian${DEBIAN_VERSION_PACKAGES}_amd64.deb" || { echo "Avertissement: Échec de l'installation de mysql-server (métapaquet)."; }


###############################################################################
# 8. Démarrage du service
###############################################################################
echo "-----------------------------------------------------------------------"
echo "8. Démarrage du service MySQL..."
echo "-----------------------------------------------------------------------"
systemctl start mysql || { echo "Erreur: Impossible de démarrer le service MySQL. Vérifiez les journaux."; }

footer "END SCRIPT: ${_NAME}"
exit $lRC

