#!/bin/bash

# Arrêter l'exécution à la première erreur
set -e

# Script de synchronisation d'un serveur replica MySQL à partir d'un serveur primaire
# Ce script utilise Percona XtraBackup pour effectuer une sauvegarde complète des données du serveur primaire,
# puis les transfère et les restaure sur le serveur replica. Ensuite, il configure la réplication logique.
# Le script est à exécuter sur le serveur replica.
# 
# Prérequis :
# 1. Les accès MySQL doivent être configurés dans les fichiers .my.cnf sur les deux serveurs (primaire et replica).
#    Cela permet d'éviter d'entrer les identifiants MySQL à chaque commande.
#    Exemple de configuration du fichier .my.cnf :
#    [client]
#    user=root
#    password=votre_mot_de_passe_mysql
#
# 2. La configuration SSH doit être définie dans le fichier .ssh/config pour permettre l'accès au serveur primaire
#    sans saisir le mot de passe à chaque fois. Les clés SSH privées doivent être configurées et les utilisateurs définis.
#    Exemple de configuration du fichier .ssh/config :
#    Host primary_host
#        HostName primary_host_ip
#        User votre_utilisateur_ssh
#        IdentityFile ~/.ssh/votre_cle_privee
#
# Utilisation :
# Le script accepte des arguments pour faciliter la configuration.
#   -h ou --primary-host : Adresse IP ou nom d'hôte du serveur primaire
#   -u ou --replication-user : Utilisateur de réplication MySQL
#   -P ou --replication-password : Mot de passe de l'utilisateur de réplication
#   -d ou --data-dir : Chemin vers le répertoire de données MySQL (optionnel, par défaut : /var/lib/mysql)
#   -t ou --backup-tool : Outil de sauvegarde à utiliser (xtrabackup/xbstream ou mariabackup/mbstream, par défaut : xtrabackup/xbstream)

# Exemple : ./script.sh -h primary_host_ip -u replica_user -P replica_password -d /chemin/vers/data_dir -t xtrabackup/xbstream

# Gestion des arguments
# Ajout de l'argument pour spécifier le chemin vers le répertoire de données
# Ajout de l'argument pour sélectionner l'outil de sauvegarde et de streaming (xtrabackup/xbstream ou mariabackup/mbstream)
MYSQL_DATA_DIR="/var/lib/mysql"
REPLICATION_USER=replication
REPLICATION_PASSWORD=$(cat $HOME/.my_replication.txt)
BACKUP_TOOL="xtrabackup/xbstream"
PRIMARY_HOST="prod-mysql-1.imporelec.local"
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -t|--backup-tool)
            BACKUP_TOOL="$2"
            shift # past argument
            shift # past value
            ;;
        -d|--data-dir)
            MYSQL_DATA_DIR="$2"
            shift # past argument
            shift # past value
            ;;
        -h|--primary-host)
            PRIMARY_HOST="$2"
            shift # past argument
            shift # past value
            ;;
        -u|--replication-user)
            REPLICATION_USER="$2"
            shift # past argument
            shift # past value
            ;;
        -P|--replication-password)
            REPLICATION_PASSWORD="$2"
            shift # past argument
            shift # past value
            ;;
        *)
            echo "Option inconnue: $1"
            exit 1
            ;;
    esac
done

# Vérification des variables requises
if [ -z "$PRIMARY_HOST" ] || [ -z "$REPLICATION_USER" ] || [ -z "$REPLICATION_PASSWORD" ] || [ -z "$BACKUP_TOOL" ]; then
    echo "Erreur : Vous devez spécifier les arguments --primary-host (-h), --replication-user (-u), --replication-password (-P), et --backup-tool (-t)."
    exit 1
fi


echo "Étape 1 : Création et streaming de la sauvegarde complète du serveur primaire..."
# Étape 1 : Créer une sauvegarde complète du serveur primaire en utilisant Percona XtraBackup et streamer directement vers le serveur replica
# Objectif : Capturer l'état actuel des données du serveur primaire et les transférer directement au serveur replica
if [[ "$BACKUP_TOOL" == "xtrabackup/xbstream" ]]; then
    ssh $PRIMARY_HOST "xtrabackup --backup --stream=xbstream --target-dir=/tmp" | xbstream -x -C $MYSQL_DATA_DIR
elif [[ "$BACKUP_TOOL" == "mariabackup/mbstream" ]]; then
    ssh $PRIMARY_HOST "mariabackup --backup --stream=mbstream --target-dir=/tmp" | mbstream -x -C $MYSQL_DATA_DIR
else
    echo "Erreur : Outil de sauvegarde non reconnu. Veuillez spécifier 'xtrabackup/xbstream' ou 'mariabackup/mbstream'."
    exit 1
fi
if [ $? -ne 0 ]; then
    echo "Erreur lors de la création et du streaming de la sauvegarde sur le serveur primaire."
    exit 1
fi

echo "Étape 2 : Lister le nouveau contenu du repertoire $MYSQL_DATA_DIR..."
# Étape 2 : Lister le nouveau contenu du repertoire $MYSQL_DATA_DIR...
# Objectif : Vérifier les fichiers extraits dans le répertoire de données MySQL
ls -lhs $MYSQL_DATA_DIR

echo "Étape 3 : Arrêt de MySQL sur le serveur replica..."
# Étape 3 : Arrêter MySQL sur le serveur replica
# Objectif : Préparer le serveur replica pour la restauration des données en s'assurant que MySQL est arrêté
systemctl stop mysqld
if [ $? -ne 0 ]; then
    echo "Erreur lors de l'arrêt de MySQL sur le serveur replica."
    exit 1
fi

echo "Étape 4 : Nettoyage des données existantes et préparation du répertoire de données..."
# Étape 4 : Nettoyer les données existantes sur le replica et préparer le répertoire de données
# Objectif : Supprimer les anciennes données et créer un répertoire vide pour la restauration
mv "$MYSQL_DATA_DIR"/* "$MYSQL_DATA_DIR/backup_$(date +%F_%T)" || echo "Aucune ancienne donnée trouvée."
rm -rf "$MYSQL_DATA_DIR"/*
mkdir -p $MYSQL_DATA_DIR

echo "Étape 5 : Extraction de la sauvegarde sur le serveur replica..."
# Étape 5 : Extraire la sauvegarde sur le serveur replica
# Objectif : Restaurer les fichiers de la sauvegarde dans le répertoire de données MySQL
tar -xzvf $TAR_BACKUP_PATH -C $MYSQL_DATA_DIR
if [ $? -ne 0 ]; then
    echo "Erreur lors de l'extraction de la sauvegarde sur le serveur replica."
    exit 1
fi

echo "Étape 6 : Application des logs pour rendre la sauvegarde cohérente..."
# Étape 6 : Appliquer les logs pour rendre la sauvegarde cohérente
# Objectif : S'assurer que les données sont prêtes à être utilisées en appliquant les journaux de transactions
$BACKUP_TOOL --prepare --target-dir=$MYSQL_DATA_DIR
if [ $? -ne 0 ]; then
    echo "Erreur lors de la préparation de la sauvegarde sur le serveur replica."
    exit 1
fi

echo "Étape 7 : Ajustement des permissions des fichiers..."
# Étape 7 : Ajuster la propriété et les permissions des fichiers
# Objectif : S'assurer que MySQL a les permissions appropriées pour accéder aux fichiers restaurés
chown -R mysql:mysql $MYSQL_DATA_DIR

echo "Étape 8 : Démarrage de MySQL sur le serveur replica..."
# Étape 8 : Démarrer MySQL sur le serveur replica
# Objectif : Relancer MySQL pour que le serveur puisse reprendre son fonctionnement
systemctl start mysqld
if [ $? -ne 0 ]; then
    echo "Erreur lors du démarrage de MySQL sur le serveur replica."
    exit 1
fi

echo "Étape 9 : Obtention des coordonnées de réplication à partir de la sauvegarde..."
# Étape 9 : Obtenir les coordonnées de réplication à partir de la sauvegarde
# Objectif : Récupérer les informations nécessaires pour configurer la réplication (fichier de journal binaire et position)
LOG_FILE=$(grep 'binlog' $MYSQL_DATA_DIR/xtrabackup_binlog_info | awk '{print $1}')
LOG_POS=$(grep 'binlog' $MYSQL_DATA_DIR/xtrabackup_binlog_info | awk '{print $2}')

echo "Étape 10 : Configuration de la réplication sur le serveur replica..."
# Étape 10 : Configurer la réplication sur le serveur replica
# Objectif : Définir le serveur primaire, l'utilisateur de réplication et les coordonnées de réplication
mysql -e "RESET SLAVE;"
if [ $? -ne 0 ]; then
    echo "Erreur lors de la réinitialisation de la réplication sur le serveur replica."
    exit 1
fi
mysql -e "CHANGE MASTER TO \
    MASTER_HOST='$PRIMARY_HOST', \
    MASTER_USER='$REPLICATION_USER', \
    MASTER_PASSWORD='$REPLICATION_PASSWORD', \
    MASTER_LOG_FILE='$LOG_FILE', \
    MASTER_LOG_POS=$LOG_POS, \
    MASTER_CONNECT_RETRY=10;"
if [ $? -ne 0 ]; then
    echo "Erreur lors de la configuration de la réplication sur le serveur replica."
    exit 1
fi

echo "Étape 11 : Démarrage de la réplication..."
# Étape 11 : Démarrer la réplication
# Objectif : Lancer le processus de réplication pour synchroniser les données avec le serveur primaire
mysql -e "START SLAVE;"
if [ $? -ne 0 ]; then
    echo "Erreur lors du démarrage de la réplication sur le serveur replica."
    exit 1
fi

echo "Étape 12 : Vérification de l'état de la réplication..."
# Étape 12 : Vérifier l'état de la réplication
# Objectif : S'assurer que la réplication fonctionne correctement et qu'il n'y a pas d'erreurs
mysql -e "SHOW SLAVE STATUS\\G"
if [ $? -ne 0 ]; then
    echo "Erreur lors de la vérification de l'état de la réplication sur le serveur replica."
    exit 1
fi

echo "Étape 13 : Nettoyage des fichiers de sauvegarde temporaires..."
# Nettoyer les fichiers de sauvegarde temporaires
# Objectif : Libérer l'espace disque en supprimant les fichiers temporaires utilisés pour la sauvegarde
rm -f $TAR_BACKUP_PATH
if [ $? -ne 0 ]; then
    echo "Erreur lors de la suppression des fichiers temporaires sur le serveur replica."
    exit 1
fi
echo "OK : Étape 13 terminée avec succès."
ssh $PRIMARY_HOST "rm -rf $BACKUP_DIR $TAR_BACKUP_PATH"
if [ $? -ne 0 ]; then
    echo "Erreur lors de la suppression des fichiers temporaires sur le serveur primaire."
    exit 1
fi

echo "Replication setup completed."
