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

# --- Sourcer les utilitaires si disponibles ---
[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh
[ -f "$(pwd)/utils.sh" ] && source "$(pwd)/utils.sh"

# --- Fonctions utilitaires de base (si non sourcées) ---
if ! type "banner" &> /dev/null; then
    banner() { echo "=================================================="; echo "== $1"; echo "=================================================="; }
    footer() { banner "$1"; }
    cmd() { 
        local l_label="$1"
        shift
        local l_cmd="$@"
        echo -e "\n--> $l_label..."
        eval "$l_cmd"
        local l_rc=$?
        if [ $l_rc -eq 0 ]; then
            echo "[OK] La commande a réussi."
        else
            echo "[ERREUR] La commande a échoué avec le code $l_rc."
        fi
        return $l_rc
    }
    info() { echo "[INFO] $1"; }
fi

# --- Vérification des privilèges ---
if [ "$(id -u)" -ne 0 ]; then
   echo "Ce script doit être exécuté en tant que root ou avec sudo." >&2
   exit 1
fi

# --- Début du script ---
_NAME=$(basename "$0")
lRC=0
banner "DEBUT DU SCRIPT: $_NAME"

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
footer "FIN DU SCRIPT: $_NAME"
if [ $lRC -eq 0 ]; then
    info "Toutes les vérifications et configurations de base ont été effectuées avec succès."
    info "N'oubliez pas de configurer NTP et de vérifier le système de fichiers (XFS recommandé)."
else
    info "Certaines commandes ont échoué. Veuillez vérifier les logs ci-dessus."
fi

exit $lRC
