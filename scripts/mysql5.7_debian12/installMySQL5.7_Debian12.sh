vim 
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
