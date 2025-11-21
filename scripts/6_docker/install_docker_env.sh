#!/bin/bash

# Script pour installer et lancer l'environnement de test Docker pour Rundeck.
#
# Ce script vérifie les prérequis (Docker, Docker Compose), configure le fichier .env
# à partir du modèle .env.example, puis lance les services définis dans docker-compose.yml.

# Arrête le script si une commande échoue
set -e
# Gère les erreurs dans les pipelines
set -o pipefail

# --- Définition des couleurs pour les logs ---
C_RESET='\033[0m'
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_BLUE='\033[0;34m'

# --- Fonctions de logging ---
# Affiche un message d'information (bleu)
info() {
    echo -e "${C_BLUE}[INFO] ${1}${C_RESET}"
}

# Affiche un message de succès (vert)
success() {
    echo -e "${C_GREEN}[SUCCESS] ${1}${C_RESET}"
}

# Affiche un message d'avertissement (jaune)
warn() {
    echo -e "${C_YELLOW}[WARNING] ${1}${C_RESET}"
}

# Affiche un message d'erreur (rouge) et quitte le script
error() {
    echo -e "${C_RED}[ERROR] ${1}${C_RESET}" >&2
    exit 1
}

# --- Début du script ---
info "Démarrage du script d'installation de l'environnement Docker..."

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
success "Docker est installé."

# Vérifie si Docker Compose est installé
if ! command -v docker-compose &> /dev/null; then
  sudo apt -y install docker-compose
  success "Docker Compose a été installé."
else
  success "Docker Compose est déjà installé."
fi
# Vérifie si Docker Compose est installé
if ! command -v docker-compose &> /dev/null; then
    error "Docker Compose n'est pas installé. Veuillez l'installer avant de continuer."
fi
success "Docker Compose est installé."

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

    cp "$ENV_EXAMPLE_FILE" "$ENV_FILE"
    success "Le fichier '$ENV_FILE' a été créé."
    warn "Veuillez vérifier et personnaliser les variables dans '$ENV_FILE' si nécessaire."
else
    success "Le fichier de configuration '$ENV_FILE' existe déjà."
fi

# --- Lancement de l'environnement Docker ---
info "Lancement des conteneurs Docker via docker-compose..."
info "Le démarrage peut prendre quelques minutes, en particulier lors du premier lancement..."

# Se déplace dans le répertoire docker et lance les services en arrière-plan
cd "$DOCKER_DIR"
sudo docker-compose up -d

info "La commande 'sudo docker-compose up -d' a été lancée."

# Charge les variables d'environnement pour afficher l'URL
set -a
source "$ENV_FILE"
set +a

success "Environnement Rundeck démarré avec succès !"
info "Rundeck devrait être accessible à l'adresse : ${C_YELLOW}${RUNDECK_GRAILS_URL}${C_RESET}"
info "Utilisez 'cd docker && docker-compose logs -f' pour voir les logs."
info "Utilisez 'cd docker && docker-compose down' pour arrêter l'environnement."

info "Les droits d'exécution ont déjà été ajoutés à ce script."