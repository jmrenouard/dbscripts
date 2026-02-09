#!/bin/bash

# Script pour installer et lancer l'environnement de test Docker pour Rundeck.
#
# Ce script vérifie les prérequis (Docker, Docker Compose), configure le fichier .env
# à partir du modèle .env.example, puis lance les services définis dans docker-compose.yml.

# Arrête le script si une commande échoue
set -e
# Gère les erreurs dans les pipelines
set -o pipefail

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
lRC=0

banner "BEGIN SCRIPT: ${_NAME}"


# Détermine le répertoire racine du projet (le parent du répertoire 'scripts')
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
PROJECT_ROOT=$(dirname "$SCRIPT_DIR")
DOCKER_DIR="$PROJECT_ROOT/docker"

# --- Vérification des prérequis ---
info "Vérification des prérequis..."

# Vérifie si Docker est installé
if ! command -v docker &> /dev/null; then
    error "Docker n'est pas installé. Veuillez l'installer avant de continuer."
fi
ok "Docker est installé."

# Vérifie si Docker Compose est installé
if ! command -v docker-compose &> /dev/null; then
  cmd "sudo apt -y install docker-compose" "Installation de Docker Compose"
else
  ok "Docker Compose est déjà installé."
fi
# Vérifie si Docker Compose est installé
if ! command -v docker-compose &> /dev/null; then
    error "Docker Compose n'est pas installé. Veuillez l'installer avant de continuer."
fi
ok "Docker Compose est installé."

# --- Gestion du fichier de configuration .env ---
info "Vérification du fichier de configuration .env..."
ENV_FILE="$DOCKER_DIR/.env"
ENV_EXAMPLE_FILE="$DOCKER_DIR/.env.example"

if [ ! -f "$ENV_FILE" ]; then
    warn "Le fichier de configuration '$ENV_FILE' n'a pas été trouvé."
    info "Création du fichier .env à partir du modèle..."

    if [ ! -f "$ENV_EXAMPLE_FILE" ]; then
        error "Le fichier modèle '$ENV_EXAMPLE_FILE' est introuvable. Impossible de continuer."
    fi

    cmd "cp \"$ENV_EXAMPLE_FILE\" \"$ENV_FILE\"" "Création du fichier .env"
    ok "Le fichier '$ENV_FILE' a été créé."
    info "Veuillez vérifier et personnaliser les variables dans '$ENV_FILE' si nécessaire."
else
    ok "Le fichier de configuration '$ENV_FILE' existe déjà."
fi

# --- Lancement de l'environnement Docker ---
info "Lancement des conteneurs Docker via docker-compose..."
info "Le démarrage peut prendre quelques minutes, en particulier lors du premier lancement..."

# Se déplace dans le répertoire docker et lance les services en arrière-plan
cd "$DOCKER_DIR"
cmd "sudo docker-compose up -d" "Démarrage des conteneurs Docker"

# Charge les variables d'environnement pour afficher l'URL
set -a
source "$ENV_FILE"
set +a

ok "Environnement Rundeck démarré avec succès !"
info "Rundeck devrait être accessible à l'adresse : ${RUNDECK_GRAILS_URL}"
info "Utilisez 'cd docker && docker-compose logs -f' pour voir les logs."
info "Utilisez 'cd docker && docker-compose down' pour arrêter l'environnement."

footer "END SCRIPT: ${_NAME}"
exit $lRC