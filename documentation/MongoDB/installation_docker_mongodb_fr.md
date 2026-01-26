Voici la documentation en français pour l'installation de MongoDB Community avec Docker :

# Installation de MongoDB Community avec Docker

## Vue d'ensemble
Vous pouvez exécuter MongoDB Community Edition en tant que conteneur Docker en utilisant l'image officielle MongoDB Community. Utiliser une image Docker pour exécuter votre déploiement MongoDB est utile pour :
- Mettre en place rapidement un déploiement.
- Gérer les fichiers de configuration.
- Tester différentes fonctionnalités sur plusieurs versions de MongoDB.

## À propos de cette tâche
Cette page décrit les instructions d'installation Docker pour MongoDB Community Edition. L'image Docker MongoDB Enterprise et l'opérateur Kubernetes MongoDB Enterprise sont recommandés pour les déploiements en production et doivent être utilisés ensemble. Pour les instructions Enterprise, consultez **Install MongoDB Enterprise with Docker**.

Cette procédure utilise l'image officielle MongoDB Community, maintenue par MongoDB.

Une description complète de Docker dépasse le cadre de cette documentation. Cette page suppose une connaissance préalable de Docker.

Les images Docker de MongoDB 5.0+ nécessitent le support AVX sur votre système. Si votre système ne supporte pas AVX, vous pouvez utiliser une image Docker de MongoDB antérieure à la version 5.0.

### Avertissement
Les versions de MongoDB antérieures à 5.0 sont EOL (End Of Life) et ne sont plus supportées par MongoDB. Ces versions doivent être utilisées uniquement à des fins de test.

MongoDB nécessite un système de fichiers qui supporte `fsync()` sur les répertoires. Les données créées par des images MongoDB non supportées dans Docker peuvent ne pas persister entre les redémarrages sur Windows et macOS.

Pour éviter un problème de système de fichiers lors de l'exécution de MongoDB dans Docker, utilisez l'image officielle MongoDB Community ci-dessus.

## Avant de commencer
- **Installer Docker**
- **Installer mongosh**

## Procédure

### Étape 1 : Tirer l'image Docker de MongoDB
```bash
docker pull mongodb/mongodb-community-server:latest
```

### Étape 2 : Exécuter l'image en tant que conteneur
```bash
docker run --name mongodb -p 27017:27017 -d mongodb/mongodb-community-server:latest
```
L'option `-p 27017:27017` dans cette commande mappe le port du conteneur au port de l'hôte. Cela vous permet de vous connecter à MongoDB avec une chaîne de connexion `localhost:27017`.

Pour installer une version spécifique de MongoDB, spécifiez la version après le `:` dans la commande `docker run`. Docker tire et exécute la version spécifiée.

Par exemple, pour exécuter MongoDB 5.0 :
```bash
docker run --name mongodb -p 27017:27017 -d mongodb/mongodb-community-server:5.0-ubuntu2004
```
Pour une liste complète des versions disponibles, consultez les **Tags**.

### Note
**Ajouter des options de ligne de commande**
Vous pouvez utiliser les options de ligne de commande `mongod` en ajoutant les options de ligne de commande à la commande `docker run`.

Par exemple, considérons l'option de ligne de commande `mongod --replSet` :
```bash
docker run -p 27017:27017 -d mongodb/mongodb-community-server:latest --name mongodb --replSet myReplicaSet
```

### Étape 3 : Vérifier que le conteneur est en cours d'exécution
Pour vérifier l'état de votre conteneur Docker, exécutez la commande suivante :
```bash
docker container ls
```
La sortie de la commande `ls` liste les champs suivants qui décrivent le conteneur en cours d'exécution :
- **Container ID**
- **Image**
- **Command**
- **Created**
- **Status**
- **Port**
- **Names**

Exemple de sortie :
```
CONTAINER ID   IMAGE                                      COMMAND                  CREATED         STATUS         PORTS                      NAMES
c29db5687290   mongodb/mongodb-community-server:5.0-ubi8   "docker-entrypoint.s…"   4 seconds ago   Up 3 seconds   27017/tcp                  mongo
```

### Étape 4 : Se connecter au déploiement MongoDB avec mongosh
```bash
mongosh --port 27017
```

### Étape 5 : Valider votre déploiement
Pour confirmer que votre instance MongoDB est en cours d'exécution, exécutez la commande Hello :
```javascript
db.runCommand({ hello: 1 })
```
Le résultat de cette commande retourne un document décrivant votre déploiement `mongod` :
```json
{
  isWritablePrimary: true,
  topologyVersion: {
    processId: ObjectId("63c00e27195285e827d48908"),
    counter: Long("0")
  },
  maxBsonObjectSize: 16777216,
  maxMessageSizeBytes: 48000000,
  maxWriteBatchSize: 100000,
  localTime: ISODate("2023-01-12T16:51:10.132Z"),
  logicalSessionTimeoutMinutes: 30,
  connectionId: 18,
  minWireVersion: 0,
  maxWireVersion: 20,
  readOnly: false,
  ok: 1
}
```

## Étapes suivantes (optionnelles)
Vous pouvez utiliser Cosign pour vérifier la signature MongoDB pour les images de conteneurs.

Cette procédure est optionnelle. Vous n'avez pas besoin de vérifier la signature MongoDB pour exécuter MongoDB sur Docker ou toute autre plateforme conteneurisée.

Pour vérifier la signature du conteneur MongoDB, effectuez les étapes suivantes :

### Étape 1 : Télécharger et installer Cosign
Pour les instructions d'installation, consultez le dépôt GitHub de Cosign.

### Étape 2 : Télécharger la clé publique de l'image du conteneur MongoDB Server
```bash
curl https://cosign.mongodb.com/server.pem > server.pem
```

### Étape 3 : Vérifier la signature
Exécutez la commande suivante pour vérifier la signature par tag :
```bash
COSIGN_REPOSITORY=docker.io/mongodb/signatures cosign verify --private-infrastructure --key=./server.pem docker.io/mongodb/mongodb-community-server:latest
```

```

Vous pouvez utiliser le bouton **Apply** dans le bloc de code ou passer en mode **Agent** pour appliquer automatiquement les modifications suggérées.