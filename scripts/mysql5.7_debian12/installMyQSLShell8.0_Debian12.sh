#!/bin/bash

# Script d'installation de MySQL Shell 8.0.42 sur Debian 12 (Bookworm)
# Utilise le paquet .deb officiel pour Debian 12.
# Ce script doit être exécuté avec des privilèges root (par exemple, via sudo).

# Vérifier si le script est exécuté en tant que root
if [[ $EUID -ne 0 ]]; then
   echo "Ce script doit être exécuté en tant que root ou avec sudo."
   exit 1
fi

# --- Définir les variables ---
# Version de MySQL Shell à installer
SHELL_VERSION="8.0.42"
# Version de Debian cible
DEBIAN_VERSION="12"
# Nom du fichier du paquet .deb
PACKAGE_FILE="mysql-shell_${SHELL_VERSION}-1debian${DEBIAN_VERSION}_amd64.deb"
# URL de base pour le téléchargement (supposée, basée sur le pattern de MySQL Router)
# Note: L'URL fournie initialement pointe vers une page, non le fichier direct.
#       Nous construisons l'URL directe probable ici.
DOWNLOAD_BASE_URL="https://dev.mysql.com/get/Downloads/MySQL-Shell"
# URL de téléchargement complète du paquet
DOWNLOAD_URL="${DOWNLOAD_BASE_URL}/${PACKAGE_FILE}"
# Répertoire où télécharger le paquet
INSTALL_DIR="/usr/src"

echo "--- Début de l'installation de MySQL Shell ${SHELL_VERSION} sur Debian ${DEBIAN_VERSION} ---"

###############################################################################
# 1. Préparation du système et téléchargement du paquet
###############################################################################
echo "-----------------------------------------------------------------------"
echo "1. Préparation du système et téléchargement du paquet..."
echo "-----------------------------------------------------------------------"

# Se déplacer dans le répertoire de téléchargement
cd "${INSTALL_DIR}" || { echo "Erreur: Impossible de changer de répertoire vers ${INSTALL_DIR}. Assurez-vous qu'il existe et que vous avez les permissions (exécutez avec sudo)."; exit 1; }

# --- Téléchargement conditionnel du paquet ---
echo "Vérification de la présence du paquet ${PACKAGE_FILE}..."
if [ -f "${PACKAGE_FILE}" ]; then
    echo "Le fichier ${PACKAGE_FILE} existe déjà dans ${INSTALL_DIR}. Saut du téléchargement."
else
    echo "Téléchargement du paquet ${PACKAGE_FILE} depuis ${DOWNLOAD_URL}..."
    # Utiliser wget pour télécharger le fichier .deb
    # L'option -O permet de spécifier le nom du fichier de sortie
    wget "${DOWNLOAD_URL}" -O "${PACKAGE_FILE}"
    # Vérifier si le téléchargement a réussi
    if [ $? -ne 0 ]; then
        echo "Erreur: Échec du téléchargement du fichier ${PACKAGE_FILE}."
        echo "Vérifiez l'URL (${DOWNLOAD_URL}) et votre connexion internet."
        # Nettoyer le fichier potentiellement incomplet
        rm -f "${PACKAGE_FILE}"
        exit 1
    else
        echo "Téléchargement de ${PACKAGE_FILE} réussi."
    fi
fi
# --- Fin Téléchargement conditionnel ---

###############################################################################
# 2. Installation du paquet MySQL Shell
###############################################################################
echo "-----------------------------------------------------------------------"
echo "2. Installation du paquet MySQL Shell..."
echo "-----------------------------------------------------------------------"

echo "Installation du paquet ${PACKAGE_FILE} avec dpkg..."
# Tenter d'installer le paquet avec dpkg
dpkg -i "${PACKAGE_FILE}"

# Vérifier si dpkg a signalé des problèmes de dépendances
if [ $? -ne 0 ]; then
    echo "dpkg a rencontré des erreurs lors de l'installation (probablement des dépendances manquantes)."
    echo "Tentative de résolution des dépendances manquantes avec 'apt --fix-broken install'..."
    # Utiliser apt pour télécharger et installer les dépendances manquantes
    # L'option -y répond automatiquement oui aux questions
    apt --fix-broken install -y
    # Vérifier si la résolution des dépendances a réussi
    if [ $? -ne 0 ]; then
        echo "Erreur: Échec de la résolution des dépendances avec 'apt --fix-broken install'."
        echo "Vous devrez peut-être résoudre les problèmes manuellement (ex: apt update, apt upgrade)."
        exit 1
    fi
    # Réessayer l'installation avec dpkg après la résolution des dépendances
    # Normalement, apt --fix-broken install devrait avoir terminé l'installation,
    # mais une nouvelle tentative avec dpkg peut être utile dans certains cas.
    echo "Réessayer l'installation de ${PACKAGE_FILE} après la tentative de résolution des dépendances..."
    dpkg -i "${PACKAGE_FILE}" || { echo "Erreur: Échec persistant de l'installation du paquet MySQL Shell ${PACKAGE_FILE}. Vérifiez les messages d'erreur."; exit 1; }
fi

echo "Installation de MySQL Shell semble réussie."

###############################################################################
# 3. Vérification
###############################################################################
echo "-----------------------------------------------------------------------"
echo "3. Vérification..."
echo "-----------------------------------------------------------------------"

# Vérifier si la commande mysqlsh est disponible
if command -v mysqlsh &> /dev/null; then
    echo "MySQL Shell (mysqlsh) est maintenant installé."
    echo "Vous pouvez le lancer en tapant : mysqlsh"
    # Afficher la version installée
    mysqlsh --version
else
    echo "Avertissement: La commande 'mysqlsh' n'a pas été trouvée dans le PATH après l'installation."
    echo "Il y a peut-être eu un problème lors de l'installation ou le PATH n'est pas à jour."
    echo "Essayez de fermer et rouvrir votre terminal ou de lancer 'source ~/.bashrc' (ou équivalent)."
fi

echo "--- Fin du script d'installation de MySQL Shell ---"
echo "Si des erreurs sont survenues, veuillez consulter les messages ci-dessus."
echo '[client]
user=root
password=security' >> ~/.my.cnf