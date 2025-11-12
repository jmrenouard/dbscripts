Voici la mise à jour du fichier `install_mongodb_ubuntu.md` incluant la description des packages MongoDB Community Edition :

```markdown
# Installation de MongoDB Community Edition sur Ubuntu

## Vue d'ensemble
Ce tutoriel vous guide à travers l'installation de MongoDB 8.0 Community Edition sur les versions LTS (long-term support) d'Ubuntu Linux en utilisant le gestionnaire de paquets `apt`.

## Version de MongoDB
Ce tutoriel installe MongoDB 8.0 Community Edition. Pour installer une autre version de MongoDB Community, utilisez le menu déroulant des versions en haut à gauche de cette page pour sélectionner la documentation de cette version.

## Considérations
### Support de la Plateforme
MongoDB 8.0 Community Edition prend en charge les versions LTS suivantes d'Ubuntu sur l'architecture x86_64 :
- 24.04 LTS ("Noble")
- 22.04 LTS ("Jammy")
- 20.04 LTS ("Focal")

MongoDB ne supporte que les versions 64 bits de ces plateformes. Pour déterminer la version d'Ubuntu que votre hôte exécute, exécutez la commande suivante dans le terminal de l'hôte :
```bash
cat /etc/lsb-release
```

MongoDB 8.0 Community Edition sur Ubuntu supporte également l'architecture ARM64 sur certaines plateformes. Pour plus d'informations, consultez le support de la plateforme.

### Notes de Production
Avant de déployer MongoDB dans un environnement de production, consultez le document **Production Notes for Self-Managed Deployments** qui offre des considérations de performance et des recommandations de configuration pour les déploiements MongoDB en production.

## Paquets Officiels MongoDB
Pour installer MongoDB Community sur votre système Ubuntu, ces instructions utiliseront le paquet officiel `mongodb-org`, maintenu et supporté par MongoDB Inc. Le paquet officiel `mongodb-org` contient toujours la dernière version de MongoDB et est disponible à partir de son propre dépôt dédié.

### Important
Le paquet `mongodb` fourni par Ubuntu n'est pas maintenu par MongoDB Inc. et entre en conflit avec le paquet officiel `mongodb-org`. Si vous avez déjà installé le paquet `mongodb` sur votre système Ubuntu, vous devez d'abord le désinstaller avant de suivre ces instructions.

Pour la liste complète des paquets officiels, consultez **MongoDB Community Edition Packages**.

## Installation de MongoDB Community Edition

### Étape 1 : Importer la clé publique
Installez `gnupg` et `curl` s'ils ne sont pas déjà disponibles :
```bash
sudo apt-get install gnupg curl
```

Importez la clé publique MongoDB :
```bash
curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | \
sudo gpg -o /usr/share/keyrings/mongodb-server-8.0.gpg --dearmor
```

### Étape 2 : Créer le fichier de liste
Créez le fichier de liste `/etc/apt/sources.list.d/mongodb-org-8.0.list` pour votre version d'Ubuntu.

#### Ubuntu 24.04 (Noble)
```bash
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/ubuntu noble/mongodb-org/8.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list
```

#### Ubuntu 22.04 (Jammy)
```bash
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/8.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list
```

#### Ubuntu 20.04 (Focal)
```bash
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/8.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list
```

### Étape 3 : Recharger la base de données des paquets
Rechargez la base de données locale des paquets :
```bash
sudo apt-get update
```

### Étape 4 : Installer MongoDB Community Server
Vous pouvez installer soit la dernière version stable de MongoDB, soit une version spécifique de MongoDB.

#### Dernière Version Stable
```bash
sudo apt-get install -y mongodb-org
```

#### Version Spécifique
Pour installer une version spécifique, utilisez la commande suivante :
```bash
sudo apt-get install -y mongodb-org=8.0.x
```

Pour obtenir de l'aide concernant les erreurs rencontrées lors de l'installation de MongoDB sur Ubuntu, consultez notre guide de dépannage.

## Exécuter MongoDB Community Edition

### Considérations ulimit
La plupart des systèmes d'exploitation Unix limitent les ressources système qu'un processus peut utiliser. Ces limites peuvent avoir un impact négatif sur le fonctionnement de MongoDB et doivent être ajustées. Consultez **UNIX ulimit Settings for Self-Managed Deployments** pour les paramètres recommandés pour votre plateforme.

### Note
Si la valeur ulimit pour le nombre de fichiers ouverts est inférieure à 64000, MongoDB génère un avertissement au démarrage.

### Répertoires
Si vous avez installé via le gestionnaire de paquets, les répertoires de données `/var/lib/mongodb` et les répertoires de logs `/var/log/mongodb` sont créés pendant l'installation.

Par défaut, MongoDB s'exécute avec le compte utilisateur `mongodb`. Si vous changez l'utilisateur qui exécute le processus MongoDB, vous devez également modifier les permissions des répertoires de données et de logs pour donner à cet utilisateur l'accès à ces répertoires.

### Fichier de Configuration
Le paquet officiel MongoDB inclut un fichier de configuration (`/etc/mongod.conf`). Ces paramètres (tels que les spécifications des répertoires de données et de logs) prennent effet au démarrage. C'est-à-dire que si vous modifiez le fichier de configuration pendant que l'instance MongoDB est en cours d'exécution, vous devez redémarrer l'instance pour que les modifications prennent effet.

## Procédure

### Système d'Initialisation
Pour exécuter et gérer votre processus `mongod`, vous utiliserez le système d'initialisation intégré de votre système d'exploitation. Les versions récentes de Linux tendent à utiliser `systemd` (qui utilise la commande `systemctl`), tandis que les versions plus anciennes de Linux tendent à utiliser `System V init` (qui utilise la commande `service`).

Si vous n'êtes pas sûr du système d'initialisation utilisé par votre plateforme, exécutez la commande suivante :
```bash
ps --no-headers -o comm 1
```

Ensuite, sélectionnez l'onglet approprié ci-dessous en fonction du résultat :

#### systemd (systemctl)
1. **Démarrer MongoDB**
   ```bash
   sudo systemctl start mongod
   ```
   Si vous recevez une erreur similaire à celle-ci lors du démarrage de `mongod` :
   ```
   Failed to start mongod.service: Unit mongod.service not found.
   ```
   Exécutez d'abord la commande suivante :
   ```bash
   sudo systemctl daemon-reload
   ```
   Ensuite, exécutez à nouveau la commande de démarrage ci-dessus.

2. **Vérifier que MongoDB a démarré avec succès**
   ```bash
   sudo systemctl status mongod
   ```
   Vous pouvez également vous assurer que MongoDB démarrera après un redémarrage du système en exécutant la commande suivante :
   ```bash
   sudo systemctl enable mongod
   ```

3. **Arrêter MongoDB**
   ```bash
   sudo systemctl stop mongod
   ```

4. **Redémarrer MongoDB**
   ```bash
   sudo systemctl restart mongod
   ```
   Vous pouvez suivre l'état du processus pour les erreurs ou les messages importants en surveillant la sortie dans le fichier `/var/log/mongodb/mongod.log`.

5. **Commencer à utiliser MongoDB**
   Démarrez une session `mongosh` sur la même machine hôte que `mongod`. Vous pouvez exécuter `mongosh` sans aucune option de ligne de commande pour vous connecter à un `mongod` en cours d'exécution sur votre localhost avec le port par défaut 27017.
   ```bash
   mongosh
   ```
   Pour plus d'informations sur la connexion à l'aide de `mongosh`, telles que pour se connecter à une instance `mongod` en cours d'exécution sur un autre hôte et/ou port, consultez la documentation `mongosh`.

#### System V Init (service)
1. **Démarrer MongoDB**
   ```bash
   sudo service mongod start
   ```

2. **Vérifier que MongoDB a démarré avec succès**
   ```bash
   sudo service mongod status
   ```
   Vous pouvez également vous assurer que MongoDB démarrera après un redémarrage du système en exécutant la commande suivante :
   ```bash
   sudo systemctl enable mongod
   ```

3. **Arrêter MongoDB**
   ```bash
   sudo service mongod stop
   ```

4. **Redémarrer MongoDB**
   ```bash
   sudo service mongod restart
   ```
   Vous pouvez suivre l'état du processus pour les erreurs ou les messages importants en surveillant la sortie dans le fichier `/var/log/mongodb/mongod.log`.

5. **Commencer à utiliser MongoDB**
   Démarrez une session `mongosh` sur la même machine hôte que `mongod`. Vous pouvez exécuter `mongosh` sans aucune option de ligne de commande pour vous connecter à un `mongod` en cours d'exécution sur votre localhost avec le port par défaut 27017.
   ```bash
   mongosh
   ```
   Pour plus d'informations sur la connexion à l'aide de `mongosh`, telles que pour se connecter à une instance `mongod` en cours d'exécution sur un autre hôte et/ou port, consultez la documentation `mongosh`.

## Désinstallation de MongoDB Community Edition

Pour désinstaller complètement MongoDB d'un système, vous devez supprimer les applications MongoDB elles-mêmes, les fichiers de configuration, et tous les répertoires contenant les données et les logs. Les étapes suivantes vous guident à travers les étapes nécessaires.

### Avertissement
Ce processus supprimera complètement MongoDB, sa configuration, et toutes les bases de données. Ce processus n'est pas réversible, donc assurez-vous que toutes vos configurations et données sont sauvegardées avant de continuer.

1. **Arrêter MongoDB**
   ```bash
   sudo service mongod stop
   ```

2. **Supprimer les Paquets**
   ```bash
   sudo apt-get purge mongodb-org*
   ```

3. **Supprimer les Répertoires de Données**
   ```bash
   sudo rm -r /var/log/mongodb
   sudo rm -r /var/lib/mongodb
   ```

## Informations Complémentaires

### Liaison à localhost par Défaut
Par défaut, MongoDB démarre avec `bindIp` défini sur `127.0.0.1`, ce qui lie à l'interface réseau localhost. Cela signifie que `mongod` ne peut accepter des connexions que des clients s'exécutant sur la même machine. Les clients distants ne pourront pas se connecter à `mongod`, et `mongod` ne pourra pas initialiser un ensemble de réplicas à moins que cette valeur ne soit définie sur une interface réseau valide.

Cette valeur peut être configurée soit :
- dans le fichier de configuration MongoDB avec `bindIp`, soit
- via l'argument de ligne de commande `--bind_ip`

### Avertissement
Avant de lier votre instance à une adresse IP accessible publiquement, vous devez sécuriser votre cluster contre un accès non autorisé. Pour une liste complète des recommandations de sécurité, consultez **Security Checklist for Self-Managed Deployments**. Au minimum, envisagez d'activer l'authentification et de renforcer l'infrastructure réseau.

Pour plus d'informations sur la configuration de `bindIp`, consultez **IP Binding in Self-Managed Deployments**.

## Paquets MongoDB Community Edition

MongoDB Community Edition est disponible à partir de son propre dépôt dédié et contient les paquets officiellement supportés suivants :

| **Nom du Paquet**         | **Description**                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
|---------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `mongodb-org`             | Un méta-paquet qui installe automatiquement les paquets de composants listés ci-dessous.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| `mongodb-org-database`    | Un méta-paquet qui installe automatiquement les paquets de composants listés ci-dessous.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| `mongodb-org-server`      | Contient le démon `mongod`, le script d'initialisation associé, et un fichier de configuration (`/etc/mongod.conf`). Vous pouvez utiliser le script d'initialisation pour démarrer `mongod` avec le fichier de configuration. Pour plus de détails, consultez la section "Exécuter MongoDB Community Edition" ci-dessus.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| `mongodb-org-mongos`      | Contient le démon `mongos`.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| `mongodb-mongosh`         | Contient le MongoDB Shell (`mongosh`).                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| `mongodb-org-tools`       | Un méta-paquet qui installe automatiquement les paquets de composants listés ci-dessous.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| `mongodb-database-tools`  | Contient les outils suivants pour MongoDB :                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
|                           | - `mongodump`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
|                           | - `mongorestore`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
|                           | - `bsondump`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
|                           | - `mongoimport`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
|                           | - `mongoexport`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
|                           | - `mongostat`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
|                           | - `mongotop`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
|                           | - `mongofiles`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| `mongodb-org-database-tools-extra` | Contient le script `install_compass`.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |

```

Vous pouvez utiliser le bouton **Apply** dans le bloc de code ou passer en mode **Agent** pour appliquer automatiquement les modifications suggérées.