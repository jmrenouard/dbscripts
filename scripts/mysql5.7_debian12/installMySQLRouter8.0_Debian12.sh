#!/bin/bash

# Script d'installation de MySQL Router 8.0.42 sur Debian 12 (Bookworm)
# Utilise les paquets .deb officiels pour Debian 12.
# Ce script doit être exécuté avec des privilèges root (par exemple, via sudo).

# Vérifier si le script est exécuté en tant que root
if [[ $EUID -ne 0 ]]; then
   echo "Ce script doit être exécuté en tant que root ou avec sudo."
   exit 1
fi

# Définir les variables
ROUTER_VERSION="8.0.42"
DEBIAN_VERSION="12"
MAIN_PACKAGE_FILE="mysql-router_${ROUTER_VERSION}-1debian${DEBIAN_VERSION}_amd64.deb"
COMMUNITY_PACKAGE_FILE="mysql-router-community_${ROUTER_VERSION}-1debian${DEBIAN_VERSION}_amd64.deb" # Nom du paquet de dépendance
DOWNLOAD_BASE_URL="https://dev.mysql.com/get/Downloads/MySQL-Router"
MAIN_DOWNLOAD_URL="${DOWNLOAD_BASE_URL}/${MAIN_PACKAGE_FILE}"
COMMUNITY_DOWNLOAD_URL="${DOWNLOAD_BASE_URL}/${COMMUNITY_PACKAGE_FILE}" # URL pour le paquet de dépendance
INSTALL_DIR="/usr/src"

echo "--- Début de l'installation de MySQL Router ${ROUTER_VERSION} sur Debian ${DEBIAN_VERSION} ---"


###############################################################################
# 1. Préparation du système et téléchargement des paquets
###############################################################################
echo "-----------------------------------------------------------------------"
echo "1. Préparation du système et téléchargement des paquets..."
echo "-----------------------------------------------------------------------"
cd "${INSTALL_DIR}" || { echo "Erreur: Impossible de changer de répertoire vers ${INSTALL_DIR}. Exécutez ce script avec sudo."; exit 1; }

# --- Téléchargement conditionnel du paquet community ---
echo "Vérification de la présence du paquet de dépendance ${COMMUNITY_PACKAGE_FILE}..."
if [ -f "${COMMUNITY_PACKAGE_FILE}" ]; then
    echo "Le fichier ${COMMUNITY_PACKAGE_FILE} existe déjà. Saut du téléchargement."
else
    echo "Téléchargement du paquet de dépendance ${COMMUNITY_PACKAGE_FILE}..."
    wget "${COMMUNITY_DOWNLOAD_URL}" -O "${COMMUNITY_PACKAGE_FILE}" || { echo "Erreur: Échec du téléchargement du fichier ${COMMUNITY_PACKAGE_FILE}. Vérifiez l'URL."; exit 1; }
fi
# --- Fin Téléchargement conditionnel du paquet community ---

# --- Téléchargement conditionnel du paquet principal ---
echo "Vérification de la présence du paquet principal ${MAIN_PACKAGE_FILE}..."
if [ -f "${MAIN_PACKAGE_FILE}" ]; then
    echo "Le fichier ${MAIN_PACKAGE_FILE} existe déjà. Saut du téléchargement."
else
    echo "Téléchargement du paquet principal ${MAIN_PACKAGE_FILE}..."
    wget "${MAIN_DOWNLOAD_URL}" -O "${MAIN_PACKAGE_FILE}" || { echo "Erreur: Échec du téléchargement du fichier ${MAIN_PACKAGE_FILE}. Vérifiez l'URL."; exit 1; }
fi
# --- Fin Téléchargement conditionnel du paquet principal ---


###############################################################################
# 2. Installation des paquets MySQL Router
###############################################################################
echo "-----------------------------------------------------------------------"
echo "2. Installation des paquets MySQL Router..."
echo "-----------------------------------------------------------------------"

# --- Installation du paquet de dépendance en premier ---
echo "Installation du paquet de dépendance ${COMMUNITY_PACKAGE_FILE} avec dpkg..."
dpkg -i "${COMMUNITY_PACKAGE_FILE}" || { echo "Erreur: Échec de l'installation du paquet de dépendance ${COMMUNITY_PACKAGE_FILE}. Tentative de résolution des dépendances."; apt --fix-broken install -y; dpkg -i "${COMMUNITY_PACKAGE_FILE}"; }
# Note: apt --fix-broken install est appelé en cas d'échec initial de dpkg sur le paquet community.


echo "Installation du paquet principal ${MAIN_PACKAGE_FILE} avec dpkg..."
dpkg -i "${MAIN_PACKAGE_FILE}"

# Vérifier si dpkg a signalé des problèmes de dépendances pour le paquet principal
if [ $? -ne 0 ]; then
    echo "dpkg a rencontré des erreurs lors de l'installation du paquet principal. Tentative de résolution des dépendances manquantes avec apt --fix-broken install..."
    # Utiliser apt --fix-broken install pour installer les dépendances requises
    apt --fix-broken install -y
    # Réessayer l'installation avec dpkg au cas où apt --fix-broken n'aurait pas tout résolu
    echo "Réessayer l'installation de ${MAIN_PACKAGE_FILE} après résolution des dépendances..."
    dpkg -i "${MAIN_PACKAGE_FILE}" || { echo "Erreur: Échec persistant de l'installation du paquet principal MySQL Router."; exit 1; }
fi


###############################################################################
# 3. Vérification et démarrage du service
###############################################################################
echo "-----------------------------------------------------------------------"
echo "3. Vérification et démarrage du service..."
echo "-----------------------------------------------------------------------"

echo "Rechargement des unités systemd..."
systemctl daemon-reload

echo "Démarrage du service mysqlrouter..."
systemctl start mysqlrouter || { echo "Avertissement: Impossible de démarrer le service mysqlrouter. Vérifiez son état avec 'systemctl status mysqlrouter'."; }

echo "Activation du démarrage automatique du service mysqlrouter au boot..."
systemctl enable mysqlrouter || { echo "Avertissement: Impossible d'activer le démarrage automatique du service mysqlrouter."; }


echo "--- Installation de MySQL Router potentiellement terminée ---"
echo "Veuillez vérifier l'état du service mysqlrouter avec 'systemctl status mysqlrouter'."
echo "La configuration par défaut de MySQL Router se trouve généralement dans /etc/mysqlrouter/mysqlrouter.conf."
echo "Si l'installation a échoué, vérifiez les messages d'erreur et les journaux système."
echo "Pour plus d'informations, consultez la documentation officielle de MySQL Router."