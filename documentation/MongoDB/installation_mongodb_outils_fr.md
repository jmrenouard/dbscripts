# Installation des MongoDB Database Tools sur Linux

## Vue d'ensemble

Les MongoDB Database Tools sont une suite d'utilitaires en ligne de commande pour travailler avec MongoDB. Ce guide vous explique comment installer les Database Tools sur la plateforme Linux. Vous pouvez utiliser ces outils pour migrer depuis un déploiement auto-hébergé vers MongoDB Atlas, qui est un service géré pour les déploiements MongoDB dans le cloud. Pour en savoir plus, consultez [Seeder avec mongorestore](https://docs.mongodb.com/database-tools/mongorestore/).

Pour découvrir toutes les façons de migrer vers MongoDB Atlas, consultez [Migrer ou importer des données](https://docs.mongodb.com/cloud/import/).

## Versioning

À partir de MongoDB 6.0, les MongoDB Database Tools sont publiés séparément du MongoDB Server et utilisent leur propre versioning, avec une version initiale de 100.0.0. Précédemment, ces outils étaient publiés avec le MongoDB Server et utilisaient un versioning correspondant.

## Compatibilité

### Compatibilité avec MongoDB Server

La version 100.12.1 des MongoDB Database Tools est compatible avec les versions suivantes du MongoDB Server :
- MongoDB 8.0
- MongoDB 7.0
- MongoDB 6.0
- MongoDB 5.0
- MongoDB 4.4
- MongoDB 4.2

Bien que les outils puissent fonctionner sur des versions antérieures du MongoDB Server, aucune compatibilité n'est garantie.

### Support des Plateformes

La version 100.12.1 des MongoDB Database Tools est supportée sur les plateformes Linux suivantes avec l'architecture x86_64 :
- Amazon Linux 2 et 2013.03+
- Debian 10 et 9
- RHEL / CentOS 8, 7, et 6
- SUSE 12
- Ubuntu 20.04, 18.04, et 16.04

En plus, les Database Tools supportent certaines plateformes Linux sur les architectures arm64, ppc64le, et s390x. Pour plus d'informations, consultez [Supported Platforms](https://docs.mongodb.com/database-tools/platform-support/).

**Note** : À partir de la version 100.9.5, les outils de base de données ne supportent plus le système d'exploitation Debian 8.

## Installation

Les MongoDB Database Tools peuvent être installés avec le gestionnaire de paquets de votre distribution Linux ou téléchargés sous forme d'archive `.tgz`. Sélectionnez l'onglet approprié en fonction de votre distribution Linux et du paquet souhaité.

- Pour installer le paquet `.deb` sur Ubuntu et Debian, cliquez sur l'onglet **DEB Package**.
- Pour installer le paquet `.rpm` sur RHEL / CentOS / SUSE, cliquez sur l'onglet **RPM Package**.
- Pour installer l'archive `.tgz`, cliquez sur l'onglet **TGZ Archive**.

**Note** : Si vous avez déjà installé le MongoDB Server via le gestionnaire de paquets de votre système, vous avez probablement déjà les Database Tools installés. La commande suivante déterminera si les Database Tools sont déjà installés sur votre système :

```sh
sudo dpkg -l mongodb-database-tools
```

### Installation du Paquet `.deb` sur Ubuntu et Debian

1. **Télécharger le paquet `.deb` des Database Tools**

   - Ouvrez le [MongoDB Download Center](https://www.mongodb.com/try/download/database-tools).
   - Utilisez le menu déroulant sur le côté droit de la page :
     - Sélectionnez votre plateforme Linux et architecture.
     - Sélectionnez le paquet `deb`.
     - Cliquez sur le bouton **Download**.
   - Si vous installez sur un système Linux sans interface graphique, cliquez sur **Copy Link** à droite du bouton **Download** pour copier le lien de téléchargement, puis utilisez un outil en ligne de commande comme `wget` ou `curl` pour télécharger le `.deb` directement sur votre système Linux.

2. **Installer le paquet téléchargé**

   Naviguez dans le répertoire contenant le paquet `.deb` téléchargé, puis exécutez la commande suivante pour installer les Database Tools en utilisant le gestionnaire de paquets `apt` :

   ```sh
   sudo apt install ./mongodb-database-tools-*-100.12.1.deb
   ```

   **Note** : Assurez-vous d'inclure le `./` au début de la commande, ce qui indique à `apt` de rechercher ce fichier dans le répertoire local au lieu de rechercher dans les dépôts distants.

3. **Exécuter les outils installés**

   Une fois installés, vous pouvez exécuter n'importe quel outil des Database Tools directement depuis la ligne de commande de votre système. Consultez la page de référence de l'outil spécifique que vous souhaitez utiliser pour obtenir sa syntaxe complète et son utilisation.

### Installation du Paquet `.rpm` sur RHEL / CentOS / SUSE

1. **Télécharger le paquet `.rpm` des Database Tools**

   - Ouvrez le [MongoDB Download Center](https://www.mongodb.com/try/download/database-tools).
   - Utilisez le menu déroulant sur le côté droit de la page :
     - Sélectionnez votre plateforme Linux et architecture.
     - Sélectionnez le paquet `rpm`.
     - Cliquez sur le bouton **Download**.
   - Si vous installez sur un système Linux sans interface graphique, cliquez sur **Copy Link** à droite du bouton **Download** pour copier le lien de téléchargement, puis utilisez un outil en ligne de commande comme `wget` ou `curl` pour télécharger le `.rpm` directement sur votre système Linux.

2. **Installer le paquet téléchargé**

   Naviguez dans le répertoire contenant le paquet `.rpm` téléchargé, puis exécutez la commande suivante pour installer les Database Tools en utilisant le gestionnaire de paquets `yum` ou `dnf` :

   ```sh
   sudo yum install ./mongodb-database-tools-*-100.12.1.rpm
   ```

   ou

   ```sh
   sudo dnf install ./mongodb-database-tools-*-100.12.1.rpm
   ```

3. **Exécuter les outils installés**

   Une fois installés, vous pouvez exécuter n'importe quel outil des Database Tools directement depuis la ligne de commande de votre système. Consultez la page de référence de l'outil spécifique que vous souhaitez utiliser pour obtenir sa syntaxe complète et son utilisation.

### Installation de l'archive `.tgz`

1. **Télécharger l'archive `.tgz` des Database Tools**

   - Ouvrez le [MongoDB Download Center](https://www.mongodb.com/try/download/database-tools).
   - Utilisez le menu déroulant sur le côté droit de la page :
     - Sélectionnez votre plateforme Linux et architecture.
     - Sélectionnez l'archive `tgz`.
     - Cliquez sur le bouton **Download**.
   - Si vous installez sur un système Linux sans interface graphique, cliquez sur **Copy Link** à droite du bouton **Download** pour copier le lien de téléchargement, puis utilisez un outil en ligne de commande comme `wget` ou `curl` pour télécharger l'archive `.tgz` directement sur votre système Linux.

2. **Extraire l'archive**

   Naviguez dans le répertoire contenant l'archive `.tgz` téléchargée, puis exécutez les commandes suivantes pour extraire l'archive :

   ```sh
   tar -zxvf mongodb-database-tools-*-100.12.1.tgz
   ```

3. **Ajouter les outils à votre PATH**

   Ajoutez le répertoire extrait à votre variable d'environnement `PATH` pour pouvoir exécuter les outils directement depuis la ligne de commande :

   ```sh
   export PATH=<path-to-extracted-folder>/bin:$PATH
   ```

   Remplacez `<path-to-extracted-folder>` par le chemin réel vers le répertoire extrait.

4. **Exécuter les outils installés**

   Une fois ajoutés au `PATH`, vous pouvez exécuter n'importe quel outil des Database Tools directement depuis la ligne de commande de votre système. Consultez la page de référence de l'outil spécifique que vous souhaitez utiliser pour obtenir sa syntaxe complète et son utilisation.

---

Cette documentation vous guide à travers le processus d'installation des MongoDB Database Tools sur différentes distributions Linux, en utilisant les gestionnaires de paquets ou en téléchargeant des archives.