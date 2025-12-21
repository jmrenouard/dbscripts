#!/bin/bash

# ==============================================================================
# Script: Installation de Gemini CLI sur Ubuntu
# ==============================================================================

set -e
set -o pipefail

# --- Couleurs et Fonctions ---
C_RESET='\033[0m'; C_RED='\033[0;31m'; C_GREEN='\033[0;32m'; C_YELLOW='\033[0;33m'; C_BLUE='\033[0;34m'
info() { echo -e    "${C_BLUE}[INFO   ]${C_RESET}ℹ️ $1"; }
success() { echo -e "${C_GREEN}[SUCCESS]${C_RESET}✅ $1"; }
warn() { echo -e    "${C_YELLOW}[WARN   ]${C_RESET}⚠️ $1"; }
error() { echo -e   "${C_RED}[ERROR  ]${C_RESET}❌ $1" >&2; echo ".... Fin le script avec une erreur"; exit 1; }
start_script() { echo -e "${C_BLUE}[START  ]${C_RESET}🏁 $1🚀"; }
end_success() { echo -e "${C_GREEN}[END    ]${C_RESET}🏁 $1"; exit 0; }

# --- Variables de Configuration ---
NODE_PCK_LIST="nodejs npm"
GEMINI_PCK="@google/gemini-cli"
# --- Début du script ---
start_script "### Installation de Gemini CLI ###"

# --- Tests Prérequis ---
info "Vérification des prérequis..."
if command -v gemini &>/dev/null; then
    warn "Gemini CLI semble déjà installé."
    gemini --version
    end_success "Gemini CLI est déjà présent sur le système."
fi
# --- Vérification et Installation de Node.js ---
if command -v node &>/dev/null; then
  info "Node.js est déjà installé (version: $(node --version))."
  # Check if Node.js version is at least 24
  NODE_MAJOR_VERSION=$(node -v | cut -d. -f1 | sed 's/v//')
  if [ "$NODE_MAJOR_VERSION" -lt 24 ]; then
    warn "Node.js version est inférieure à 24. Mise à jour vers Node.js 24."
    # Remove existing Node.js installation
    apt-get purge -y nodejs npm &>/dev/null
    # Install Node.js 24 using NodeSource
    curl -fsSL https://deb.nodesource.com/setup_24.x | bash -
    apt-get install -y nodejs &>/dev/null || error "L'installation de Node.js 24 a échoué."
    success "Node.js 24 a été installé avec succès."
  fi
else
  info "Node.js n'est pas installé. Installation de Node.js 24 en cours..."
  info "Mise à jour du cache APT..."
  apt-get update >/dev/null || error "La mise à jour APT a échoué."
  # Install Node.js 24 using NodeSource
  curl -fsSL https://deb.nodesource.com/setup_24.x | bash -
  apt-get install -y nodejs &>/dev/null || error "L'installation de Node.js 24 a échoué."
  success "Node.js 24 a été installé avec succès."
fi

# --- Vérification et Installation de NPM ---
# NPM est installé avec Node.js via NodeSource, donc cette section peut être simplifiée.
if command -v npm &>/dev/null; then
  info "NPM est déjà installé (version: $(npm --version))."
else
  error "NPM n'a pas été installé avec Node.js. Veuillez vérifier l'installation de Node.js."
fi

# --- Installation de Gemini CLI ---
info "Installation de Gemini CLI via NPM..."
npm install -g $GEMINI_PCK &>/dev/null || error "L'installation de Gemini CLI a échoué."
success "Gemini CLI a été installé avec succès au niveau global."

# --- Tests Post-Installation ---
info "Validation de l'installation de Gemini CLI..."
if ! command -v gemini &>/dev/null; then
    error "La commande 'gemini' n'a pas été trouvée dans le PATH après l'installation. Essayez de recharger votre shell."
fi

info "Version de Gemini CLI installée :"
gemini --version || error "Impossible d'exécuter 'gemini --version'."
success "Gemini CLI est installé et fonctionnel."


info "Installation de l'extension chrome-devtools-mcp..."
gemini extensions install https://github.com/ChromeDevTools/chrome-devtools-mcp --consent
info "Installation de l'extension genai-toolbox..."
gemini extensions install https://github.com/googleapis/genai-toolbox --consent

info "Installation de l'extension nanobanana..."
gemini extensions install https://github.com/gemini-cli-extensions/nanobanana --consent

info "Installation de l'extension security..."
gemini extensions install https://github.com/gemini-cli-extensions/security --consent
info "Installation de l'extension gemini-flow..."
gemini extensions install https://github.com/clduab11/gemini-flow --consent
info "Installation de l'extension jules..."
gemini extensions install https://github.com/gemini-cli-extensions/jules --consent

info "Installation de l'extension gemini-cli-prompt-library..."
gemini extensions install https://github.com/harish-garg/gemini-cli-prompt-library --consent

info "Installation de l'extension slash-criticalthink..."
gemini extensions install https://github.com/abagames/slash-criticalthink --consent

info "Installation de l'extension GeminiCLI_ComputerUse_Extension..."
gemini extensions install https://github.com/automateyournetwork/GeminiCLI_ComputerUse_Extension --consent

info "Installation de l'extension gemini-plan-commands..."
gemini extensions install https://github.com/ddobrin/gemini-plan-commands --consent

info "Installation de l'extension gemini-agent-creator..."
gemini extensions install https://github.com/jduncan-rva/gemini-agent-creator --consent

info "Installation de l'extension gemini-cli-git..."
gemini extensions install https://github.com/ox01024/gemini-cli-git --consent

info "Installation de l'extension gemini-mentor..."
gemini extensions install https://github.com/JayadityaGit/gemini-mentor --consent

info "Installation de l'extension gemini-cli-ssh-extension..."
gemini extensions install https://github.com/involvex/gemini-cli-ssh-extension --consent

end_success "Installation de Gemini CLI terminée avec succès."