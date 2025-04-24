#!/bin/bash

# Script d'installation de MySQL Server 5.7.42 sur Debian 12 (Bookworm)
# Basé sur la procédure manuelle utilisant les paquets .deb de Debian 10.
# Ce script doit être exécuté avec des privilèges root (par exemple, via sudo).

# Vérifier si le script est exécuté en tant que root
if [[ $EUID -ne 0 ]]; then
   echo "Ce script doit être exécuté en tant que root ou avec sudo."
   exit 1
fi

# Définir les variables
MYSQL_VERSION="5.7.42"
DEBIAN_VERSION_PACKAGES="10" # Les paquets sont compilés pour Debian 10 (Buster)
TARBALL_FILE="mysql-server_${MYSQL_VERSION}-1debian${DEBIAN_VERSION_PACKAGES}_amd64.deb-bundle.tar"
DOWNLOAD_URL="https://downloads.mysql.com/archives/get/p/23/file/${TARBALL_FILE}"
INSTALL_DIR="/usr/src"
# Un fichier représentatif pour vérifier si l'extraction a déjà eu lieu
CHECK_FILE="mysql-common_${MYSQL_VERSION}-1debian${DEBIAN_VERSION_PACKAGES}_amd64.deb"


echo "--- Début de l'installation de MySQL ${MYSQL_VERSION} sur Debian 12 ---"


###############################################################################
# 1. Préparation du système et téléchargement
###############################################################################
echo "-----------------------------------------------------------------------"
echo "1. Préparation du système et téléchargement..."
echo "-----------------------------------------------------------------------"
cd "${INSTALL_DIR}" || { echo "Erreur: Impossible de changer de répertoire vers ${INSTALL_DIR}. Exécutez ce script avec sudo."; exit 1; }

# --- Modification : Téléchargement conditionnel ---
echo "Vérification de la présence du bundle de paquets..."
if [ -f "${TARBALL_FILE}" ]; then
    echo "Le fichier ${TARBALL_FILE} existe déjà. Saut du téléchargement."
else
    echo "Téléchargement du bundle de paquets..."
    wget "${DOWNLOAD_URL}" -O "${TARBALL_FILE}" || { echo "Erreur: Échec du téléchargement du fichier."; exit 1; }
fi
# --- Fin Modification ---

# --- Modification : Extraction conditionnelle ---
echo "Vérification de la présence des paquets extraits..."
if [ -f "${CHECK_FILE}" ]; then
    echo "Les paquets semblent déjà extraits (fichier ${CHECK_FILE} trouvé). Saut de l'extraction."
else
    echo "Extraction des paquets..."
    tar xvf "${TARBALL_FILE}" || { echo "Erreur: Échec de l'extraction de l'archive."; exit 1; }
fi
# --- Fin Modification ---


###############################################################################
# 2. Nettoyage des paquets MySQL existants
###############################################################################
echo "-----------------------------------------------------------------------"
echo "2. Nettoyage des paquets MySQL existants..."
echo "-----------------------------------------------------------------------"
# Utiliser -y pour accepter automatiquement la suppression
apt remove -y --purge "libmysqlclient*" "mysql*"


###############################################################################
# 3. Installation des dépendances et paquets dans l'ordre
###############################################################################
echo "-----------------------------------------------------------------------"
echo "3. Installation des dépendances et paquets dans l'ordre..."
echo "-----------------------------------------------------------------------"

echo "Installation de la dépendance libsuma1..."
apt install -y libsuma1 || { echo "Avertissement: Impossible d'installer libsuma1. L'installation pourrait échouer."; }

echo "Installation de mysql-common..."
dpkg -i "mysql-common_${MYSQL_VERSION}-1debian${DEBIAN_VERSION_PACKAGES}_amd64.deb" || { echo "Erreur: Échec de l'installation de mysql-common."; exit 1; }

echo "Pré-configuration de mysql-community-server..."
# Note: Cette commande peut demander une interaction utilisateur pour définir le mot de passe root.
# Pour une automatisation complète, il faudrait utiliser debconf-set-selections.
# Pour l'instant, soyez prêt à entrer le mot de passe root si demandé.
dpkg-preconfigure "mysql-community-server_${MYSQL_VERSION}-1debian${DEBIAN_VERSION_PACKAGES}_amd64.deb"

# --- AJOUT : Installation de libatomic1 avant libmysqlclient20 ---
echo "Installation de la dépendance libatomic1..."
apt install -y libatomic1 || { echo "Erreur: Impossible d'installer libatomic1. L'installation de libmysqlclient20 échouera."; exit 1; }
# --- FIN AJOUT ---


echo "Installation de libmysqlclient20..."
dpkg -i "libmysqlclient20_${MYSQL_VERSION}-1debian${DEBIAN_VERSION_PACKAGES}_amd64.deb" || { echo "Erreur: Échec de l'installation de libmysqlclient20."; exit 1; }

echo "Installation de libmysqlclient-dev..."
dpkg -i "libmysqlclient-dev_${MYSQL_VERSION}-1debian${DEBIAN_VERSION_PACKAGES}_amd64.deb" || { echo "Avertissement: Échec de l'installation de libmysqlclient-dev. Tentative de résolution des dépendances cassées."; apt --fix-broken install -y; }


###############################################################################
# 4. Gestion des dépendances potentielles (libc6-dev)
# Cette partie est complexe à automatiser parfaitement dans un script simple.
# Le script tente de gérer le cas le plus fréquent mentionné dans la procédure.
###############################################################################
echo "-----------------------------------------------------------------------"
echo "4. Gestion potentielle de la dépendance libc6-dev..."
echo "-----------------------------------------------------------------------"
# Tentative de suppression de libc6-dev si l'installation précédente a échoué
if dpkg -s libmysqlclient-dev 2>/dev/null | grep -q "Status: install ok installed"; then
    echo "libmysqlclient-dev installé avec succès, pas de conflit libc6-dev apparent."
else
    echo "Tentative de suppression de libc6-dev pour résoudre un conflit..."
    apt remove -y --purge libc6-dev
    echo "Tentative de réinstaller libmysqlclient-dev après suppression de libc6-dev..."
    dpkg -i "libmysqlclient-dev_${MYSQL_VERSION}-1debian${DEBIAN_VERSION_PACKAGES}_amd64.deb" || { echo "Erreur: Échec persistant de l'installation de libmysqlclient-dev."; }
fi


###############################################################################
# 5. Suite de l'installation des paquets
###############################################################################
echo "-----------------------------------------------------------------------"
echo "5. Suite de l'installation des paquets..."
echo "-----------------------------------------------------------------------"

echo "Installation de libmysqld-dev..."
dpkg -i "libmysqld-dev_${MYSQL_VERSION}-1debian${DEBIAN_VERSION_PACKAGES}_amd64.deb" || { echo "Avertissement: Échec de l'installation de libmysqld-dev."; }

echo "Installation de mysql-community-client..."
dpkg -i "mysql-community-client_${MYSQL_VERSION}-1debian${DEBIAN_VERSION_PACKAGES}_amd64.deb" || { echo "Avertissement: Échec de l'installation de mysql-community-client. Tentative de résolution des dépendances cassées."; apt --fix-broken install -y; }


###############################################################################
# 6. Gestion des dépendances potentielles (libaio1)
###############################################################################
echo "-----------------------------------------------------------------------"
echo "6. Gestion potentielle de la dépendance libaio1..."
echo "-----------------------------------------------------------------------"
if ! dpkg -s libaio1 2>/dev/null | grep -q "Status: install ok installed"; then
    echo "Installation de la dépendance libaio1..."
    apt install -y libaio1 || { echo "Avertissement: Impossible d'installer libaio1. L'installation pourrait échouer."; }
fi

# Réessayer d'installer le client communautaire si l'installation précédente a échoué
if ! dpkg -s mysql-community-client 2>/dev/null | grep -q "Status: install ok installed"; then
    echo "Réessayer l'installation de mysql-community-client..."
    dpkg -i "mysql-community-client_${MYSQL_VERSION}-1debian${DEBIAN_VERSION_PACKAGES}_amd64.deb" || { echo "Erreur: Échec persistant de l'installation de mysql-community-client."; }
fi


###############################################################################
# 7. Fin de l'installation des paquets
###############################################################################
echo "-----------------------------------------------------------------------"
echo "7. Fin de l'installation des paquets..."
echo "-----------------------------------------------------------------------"

echo "Installation de mysql-client..."
dpkg -i "mysql-client_${MYSQL_VERSION}-1debian${DEBIAN_VERSION_PACKAGES}_amd64.deb" || { echo "Avertissement: Échec de l'installation de mysql-client."; }

echo "Réinstallation de mysql-common pour s'assurer de la configuration..."
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

echo "--- Installation potentiellement terminée ---"
echo "Veuillez vérifier l'état du service MySQL avec 'systemctl status mysql'."
echo "Si des erreurs sont survenues, examinez attentivement la sortie du script et les journaux système."
echo "N'oubliez pas de sécuriser votre installation MySQL (par exemple, avec 'mysql_secure_installation')."
