## Documentation de l'Installation d'Ops Manager

### Vue d'ensemble
Ce tutoriel décrit comment installer Ops Manager en utilisant un package `.deb`. Si vous souhaitez mettre à niveau un déploiement existant, veuillez consulter la section "Mettre à niveau Ops Manager".

### Prérequis
- Vous devez avoir un accès administratif aux hôtes sur lesquels vous installez Ops Manager.
- Avant d'installer Ops Manager, vous devez :
  - Planifier votre configuration. Consultez la "Liste de contrôle de l'installation".
  - Déployer des hôtes répondant aux exigences système d'Ops Manager.
- **Avertissement** : Votre instance Ops Manager peut échouer en production si vous ne configurez pas correctement les éléments suivants :
  - Les hôtes Ops Manager selon les exigences système d'Ops Manager.
  - Les hôtes MongoDB selon les notes de production du manuel MongoDB. Les instances MongoDB dans Ops Manager incluent :
    - La base de données de l'application Ops Manager.
    - Chaque blockstore.
  - Installez la base de données de l'application Ops Manager et la base de données de sauvegarde optionnelle. Les bases de données nécessitent des instances MongoDB dédiées. Ne pas utiliser les installations MongoDB qui stockent d'autres données. Ops Manager nécessite la base de données de sauvegarde si vous utilisez la fonctionnalité de sauvegarde.
  - L'application Ops Manager doit s'authentifier auprès des bases de données de support en tant qu'utilisateur MongoDB avec les accès appropriés.

### Voir aussi :
- Pour en savoir plus sur la connexion à votre base de données de support avec l'authentification, consultez `mongo.mongoUri`.
- **Note** : Vous devez déployer les bases de données d'application manuellement. Cependant, vous pouvez déployer les bases de données de sauvegarde avec Ops Manager. Pour plus d'informations, consultez "Déployer les bases de données de support".
- Installez et vérifiez un serveur de messagerie. Ops Manager a besoin d'un serveur de messagerie pour envoyer des alertes et récupérer les comptes utilisateur. Vous pouvez utiliser un serveur SMTP ou un serveur AWS SES. Pour configurer votre serveur de messagerie, consultez "Configuration de la méthode de livraison des emails".

### Installation d'Ops Manager

#### Étape 1 : Télécharger le package Ops Manager
1. Ouvrez votre navigateur préféré pour visiter le Centre de téléchargement MongoDB sur MongoDB.com.
2. Si vous commencez depuis MongoDB.com, cliquez sur "Produits" > "Ops Manager" > "Essayer maintenant".
3. Dans le menu déroulant "Plateformes", cliquez sur "Ubuntu 24.04".
4. Dans le menu déroulant "Packages", cliquez sur "DEB pour architecture x86_64".
5. Cliquez sur "Télécharger".
6. Le package téléchargé est nommé `mongodb-mms-<version>.x86_64.deb`, où `<version>` est le numéro de version.

#### Étape 2 : Vérifier l'intégrité du package Ops Manager (optionnel)
Pour vérifier l'intégrité du téléchargement d'Ops Manager, consultez "Vérifier l'intégrité des packages Ops Manager".

#### Étape 3 : Installer le package Ops Manager
1. Installez le package `.deb` en émettant la commande suivante, où `<version>` est la version du package `.deb` :
   ```bash
   sudo dpkg --install mongodb-mms_<version>_x86_64.deb
   ```
2. Lorsque installé, le répertoire de base pour le logiciel Ops Manager est `/opt/mongodb/mms/`. Le package `.deb` crée un nouvel utilisateur système `mongodb-mms` sous lequel le serveur s'exécutera.

#### Étape 4 : Configurer la connexion d'Ops Manager à la base de données de l'application Ops Manager
1. Sur un serveur qui doit exécuter Ops Manager, ouvrez `/opt/mongodb/mms/conf/conf-mms.properties` avec des privilèges root et configurez les paramètres décrits ici, selon les besoins.
2. Configurez le paramètre suivant pour fournir la chaîne de connexion que Ops Manager utilise pour se connecter à la base de données :
   ```properties
   mongo.mongoUri
   ```
3. Pour configurer Ops Manager pour utiliser la base de données de l'application Ops Manager via TLS, configurez les paramètres TLS suivants :
   ```properties
   mongo.ssl
   mongodb.ssl.CAFile
   mongodb.ssl.PEMKeyFile
   mongodb.ssl.PEMKeyFilePassword
   ```
   Ops Manager utilise également ces paramètres pour les connexions TLS aux bases de données de sauvegarde.
4. Pour configurer Ops Manager pour utiliser Kerberos afin de gérer l'accès à la base de données de l'application Ops Manager, configurez les paramètres Kerberos suivants :
   ```properties
   jvm.java.security.krb5.conf
   jvm.java.security.krb5.kdc
   jvm.java.security.krb5.realm
   mms.kerberos.principal
   mms.kerberos.keyTab
   ```

#### Étape 5 : Démarrer Ops Manager
1. Émettez la commande suivante :
   - Pour Ubuntu 15.X ou ultérieur :
     ```bash
     sudo systemctl start mongodb-mms.service
     ```
   - Pour Ubuntu 14.04+ :
     ```bash
     sudo start mongodb-mms
     ```

#### Étape 6 : Ouvrir la page d'accueil d'Ops Manager et enregistrer le premier utilisateur
1. Entrez l'URL suivante dans un navigateur, où `<host>` est le nom de domaine complet du serveur :
   ```url
   http://<OpsManagerHost>:8080
   ```
2. Cliquez sur le lien "S'inscrire" et suivez les invites pour enregistrer le premier utilisateur et créer le premier projet. Le premier utilisateur est automatiquement attribué au rôle de Propriétaire global.

#### Étape 7 : Configurer Ops Manager
1. Ops Manager vous guide à travers plusieurs pages de configuration. Les paramètres obligatoires sont marqués d'une astérisque. Entrez les informations appropriées. Une fois la configuration terminée, Ops Manager ouvre la page "Déploiement".
2. En plus des paramètres obligatoires courants, les paramètres suivants sont obligatoires pour des configurations de déploiement particulières. Pour plus d'informations sur un paramètre, consultez "Paramètres de configuration d'Ops Manager".

#### Configuration
- **Paramètres obligatoires** :
  - Si vous exécutez plusieurs instances d'Ops Manager derrière un équilibreur de charge :
    - Définissez "Load Balancer Remote IP Header" sur le nom de l'en-tête que l'équilibreur de charge utilisera pour transmettre l'adresse IP du client au serveur d'application. Si vous définissez cela, ne permettez pas aux clients de se connecter directement à l'un des serveurs d'application. L'équilibreur de charge ne doit pas retourner de contenu mis en cache. Vous configurerez les serveurs supplémentaires dans les étapes suivantes de cette procédure.
  - Si vous utilisez Automation ou Backup sans connexion Internet :
    - Définissez les paramètres de gestion des versions MongoDB. Vous devrez mettre les tarballs de chaque version MongoDB utilisée dans votre déploiement dans le répertoire des versions configuré sur chaque hôte Ops Manager. Pour plus d'informations, consultez "Configurer le déploiement pour une connexion Internet limitée".

#### Étape 8 : Copier le fichier `gen.key` vers les autres serveurs
1. Ops Manager nécessite un fichier `gen.key` identique stocké sur les deux serveurs exécutant Ops Manager et utilise le fichier pour chiffrer les données au repos dans la base de données de l'application Ops Manager et la base de données de sauvegarde.
2. Vous devez copier le fichier `gen.key` depuis le serveur actuel, sur lequel vous venez d'installer Ops Manager, vers chaque serveur qui exécutera Ops Manager. Vous devez copier le fichier `gen.key` vers les autres serveurs avant de démarrer Ops Manager sur eux.
3. Utilisez `scp` pour copier le fichier `gen.key` depuis le répertoire `/etc/mongodb-mms/` du serveur actuel vers le même répertoire sur les autres serveurs.
4. **Important** : Sauvegardez le fichier `gen.key` dans un emplacement sécurisé.

#### Étape 9 : Si vous exécutez plusieurs applications Ops Manager derrière un équilibreur de charge, configurez et démarrez les applications
1. Pour chaque instance d'Ops Manager, répétez l'étape de configuration de la connexion à la base de données de l'application Ops Manager et l'étape de démarrage de l'application.
2. Pour plus d'informations sur l'exécution de plusieurs applications derrière un équilibreur de charge, consultez "Configurer une application Ops Manager hautement disponible".

#### Étape 10 : Si vous exécutez Ops Manager Backup, configurez le démon de sauvegarde et le stockage de sauvegarde
1. Déployez vos bases de données de sauvegarde. Vous pouvez utiliser Ops Manager pour gérer le déploiement d'un ensemble de réplicas après avoir installé MongoDB sur chaque hôte.
2. Sur chaque serveur Ops Manager que vous activez en tant que démon de sauvegarde, créez le répertoire qui sera utilisé comme répertoire principal. Le répertoire doit être :
   - dédié à cette fin sur une partition de disque locale.
   - dimensionné en fonction des exigences système d'Ops Manager.
   - accessible en écriture par l'utilisateur `mongodb-mms`.
3. Configurez le stockage de sauvegarde que vous souhaitez utiliser pour vos snapshots.
4. Ouvrez Ops Manager et vérifiez que vous êtes connecté en tant qu'utilisateur enregistré lors de l'installation d'Ops Manager. Cet utilisateur est le propriétaire global.
5. Cliquez sur le lien "Admin" en haut à droite de la page.
6. Cliquez sur l'onglet "Backup".
7. Suivez les invites pour configurer le démon de sauvegarde et le stockage de sauvegarde. Ops Manager vous guide à travers la configuration du démon et du stockage des snapshots.
8. Une fois que vous avez sélectionné la manière de stocker les snapshots, vous êtes invité à configurer la chaîne de connexion à la base de données de sauvegarde. Si vous utilisez le stockage de fichiers système pour vos snapshots, la base de données de sauvegarde est utilisée uniquement pour le magasin oplog.
9. **AVERTISSEMENT** : Une fois la chaîne de connexion enregistrée, toute modification de la chaîne nécessite de redémarrer toutes les instances d'Ops Manager, y compris celles exécutant des démons de sauvegarde activés. Effectuer la modification et cliquer sur "Enregistrer" ne suffit pas. Ops Manager continuera à utiliser la chaîne précédente jusqu'à ce que vous redémarrez les instances.
10. `<hostname>:<port>` : Entrez une liste séparée par des virgules des noms de domaine complets et des numéros de port pour tous les membres de l'ensemble de réplicas pour la base de données de sauvegarde.
11. **Nom d'utilisateur et mot de passe d'authentification MongoDB** : Entrez les informations d'identification de l'utilisateur si la base de données utilise l'authentification.
12. **AVERTISSEMENT** : Si vous n'avez pas utilisé `credentialstool` pour chiffrer ce mot de passe, il est stocké en texte clair dans la base de données.
13. **Informations d'identification chiffrées** : Cochez cette case si les informations d'identification de l'utilisateur utilisent `credentialstool` d'Ops Manager.
14. **Utiliser SSL** : Cochez cette case si la base de données utilise SSL. Si vous sélectionnez cette option, vous devez configurer les paramètres SSL d'Ops Manager. Consultez "Paramètres de configuration d'Ops Manager".
15. **Options de connexion** : Pour ajouter des options de connexion supplémentaires, entrez-les en utilisant le format URI de chaîne de connexion MongoDB. Ce champ ne prend en charge que les valeurs non échappées.

### Étapes suivantes
- Après avoir installé l'application Ops Manager sur vos hôtes Ops Manager, vous devez installer les agents MongoDB sur les hôtes qui exécuteront vos déploiements MongoDB.
- Vous pouvez activer la surveillance de la base de données d'application.
- Vous pouvez installer l'agent MongoDB sur les hôtes exécutant des déploiements MongoDB existants ou sur les hôtes sur lesquels vous allez créer de nouveaux déploiements MongoDB. Les hôtes servant vos déploiements MongoDB doivent répondre aux exigences minimales de production MongoDB.