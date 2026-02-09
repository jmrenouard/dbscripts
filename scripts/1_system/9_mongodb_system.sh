#!/bin/bash
# ==============================================================================
#
#    Script de Préparation et Vérification pour MongoDB en Production
#
# Auteur:         Généré par Gemini pour Jean-Marie Renouard
# Version:        1.1
# Description:    Ce script vérifie et configure les prérequis système pour
#                 une instance MongoDB, en se basant sur la checklist
#                 officielle de MongoDB pour les opérations de production.
#
# Documentation:  https://www.mongodb.com/docs/manual/administration/production-checklist-operations/
#
# Utilisation:    Exécuter en tant que root ou avec sudo.
#                 sudo ./prepare_mongo_system.sh
#
# ==============================================================================

source /etc/os-release

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

# Replacement for title function used in this script
title() { title1 "$*"; }

# --- Vérification des privilèges ---
if [ "$(id -u)" -ne 0 ]; then
   echo "Ce script doit être exécuté en tant que root ou avec sudo." >&2
   exit 1
fi

# --- Début du script ---
_NAME=$(basename "$(readlink -f "$0")")
NAME="${_NAME}"
lRC=0
banner "BEGIN SCRIPT: ${_NAME}"

# --- Détection du gestionnaire de paquets ---
PCKMANAGER="yum"
OS_ID=$(grep -oP '(?<=^ID=).+' /etc/os-release | tr -d '"')
[ "$OS_ID" = "ubuntu" -o "$OS_ID" = "debian" ] && PCKMANAGER="apt"
info "Gestionnaire de paquets détecté: $PCKMANAGER"
info "Système d'exploitation détecté: $OS_ID"

# =================================================
# 1. Mises à jour du système et paquets essentiels
# =================================================
title "1. Mises à jour et paquets"
cmd "Mise à jour de la liste des paquets" "$PCKMANAGER -y update"
lRC=$(($lRC + $?))

cmd "Installation des outils réseau et de diagnostic" "$PCKMANAGER -y install net-tools sysstat numactl"
lRC=$(($lRC + $?))

# =================================================
# 2. Configuration du Noyau et des Limites
# =================================================
title "2. Configuration du Noyau (Kernel)"

# --- Désactivation des Transparent Huge Pages (THP) ---
info "Vérification des Transparent Huge Pages (THP)..."
THP_STATUS=$(cat /sys/kernel/mm/transparent_hugepage/enabled)
if [[ "$THP_STATUS" == *"[never]"* ]]; then
    info "THP est déjà désactivé. Aucune action requise."
else
    info "THP est activé. Création d'un service systemd pour le désactiver au démarrage."
    cmd "Création du service de désactivation de THP" "cat << EOF > /etc/systemd/system/disable-thp.service
[Unit]
Description=Disable Transparent Huge Pages (THP)
DefaultDependencies=no
After=sysinit.target local-fs.target
Before=mongod.service

[Service]
Type=oneshot
ExecStart=/bin/sh -c 'echo never > /sys/kernel/mm/transparent_hugepage/enabled'
ExecStart=/bin/sh -c 'echo never > /sys/kernel/mm/transparent_hugepage/defrag'

[Install]
WantedBy=multi-user.target
EOF"
    lRC=$(($lRC + $?))
    
    cmd "Activation et démarrage du service disable-thp" "systemctl daemon-reload && systemctl enable --now disable-thp.service"
    lRC=$(($lRC + $?))
fi

# --- Configuration des limites système (ulimits) ---
info "Configuration des limites (ulimits) pour l'utilisateur mongod."
# Les valeurs recommandées sont souvent > 64000
cmd "Création du fichier de configuration pour les ulimits de MongoDB" "cat << EOF > /etc/security/limits.d/99-mongodb.conf
# Limites recommandées pour MongoDB
mongod   soft   nofile   64000
mongod   hard   nofile   64000
mongod   soft   nproc    64000
mongod   hard   nproc    64000
EOF"
lRC=$(($lRC + $?))

# --- Configuration du Swappiness ---
info "Vérification du swappiness..."
SWAPPINESS=$(cat /proc/sys/vm/swappiness)
if [ "$SWAPPINESS" -le 1 ]; then
    info "La valeur de swappiness est de $SWAPPINESS (recommandé). Aucune action requise."
else
    info "La valeur de swappiness est de $SWAPPINESS. Réglage à 1 pour la persistance."
    cmd "Réglage du swappiness à 1" "sysctl -w vm.swappiness=1 && echo 'vm.swappiness = 1' >> /etc/sysctl.conf"
    lRC=$(($lRC + $?))
fi


# =================================================
# 3. Sécurité réseau
# =================================================
title "3. Configuration du Firewall"

if command -v firewalld &> /dev/null; then
    cmd "Installation de firewalld" "$PCKMANAGER -y install firewalld"
    cmd "Démarrage et activation de firewalld" "systemctl enable --now firewalld"
    info "Ajout de la règle pour autoriser le port MongoDB (27017)..."
    # IMPORTANT: Remplacez 192.168.1.0/24 par l'IP/sous-réseau de vos serveurs d'application
    cmd "Ouverture du port 27017 pour un sous-réseau spécifique" "firewall-cmd --zone=public --add-rich-rule='rule family=\"ipv4\" source address=\"192.168.1.0/24\" port protocol=\"tcp\" port=\"27017\" accept' --permanent"
    cmd "Rechargement du firewall" "firewall-cmd --reload"
elif command -v ufw &> /dev/null; then
    cmd "Installation de ufw" "$PCKMANAGER -y install ufw"
    cmd "Activation de ufw" "echo 'y' | ufw enable"
    info "Ajout de la règle pour autoriser le port MongoDB (27017)..."
    # IMPORTANT: Remplacez 192.168.1.0/24 par l'IP/sous-réseau de vos serveurs d'application
    cmd "Ouverture du port 27017 pour un sous-réseau spécifique" "ufw allow from 192.168.1.0/24 to any port 27017 proto tcp"
    cmd "Rechargement du firewall" "ufw reload"
else
    info "Aucun gestionnaire de firewall (firewalld, ufw) trouvé. Installation recommandée."
fi
lRC=$(($lRC + $?))


# --- Fin du script ---
footer "END SCRIPT: ${_NAME}"
if [ $lRC -eq 0 ]; then
    info "Toutes les vérifications et configurations de base ont été effectuées avec succès."
    info "N'oubliez pas de configurer NTP et de vérifier le système de fichiers (XFS recommandé)."
else
    info "Certaines commandes ont échoué. Veuillez vérifier les logs ci-dessus."
fi

exit $lRC
