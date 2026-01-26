# Installation de MongoDB Shell (mongosh)

## Prérequis

Pour utiliser MongoDB Shell, vous devez avoir un déploiement MongoDB auquel vous pouvez vous connecter. Pour un déploiement auto-hébergé gratuit, vous pouvez utiliser MongoDB Atlas. Pour apprendre à exécuter un déploiement local MongoDB, consultez [Install MongoDB](https://docs.mongodb.com/manual/installation/).

## Versions de MongoDB Supportées

Vous pouvez utiliser MongoDB Shell pour vous connecter à MongoDB version 4.2 ou ultérieure.

## Systèmes d'exploitation supportés

Vous pouvez installer MongoDB Shell 2.0.0 sur les systèmes d'exploitation suivants :

| Système d'exploitation | Versions supportées |
|------------------------|---------------------|
| macOS                  | 11+ (x64 et ARM64)  |
| Microsoft Windows      | Windows Server 2016+ et Windows 10+ |
| Linux                  | Red Hat Enterprise Linux (RHEL) 8+ (x64, ARM64, ppc64le, et s390x) |
|                        | Ubuntu 20.04+ (x64 et ARM64) |
|                        | Amazon Linux 2023 (x64 et ARM64) |
|                        | Amazon Linux 2 (x64 et ARM64) |
|                        | Debian 11+ |
|                        | SLES 15 |
|                        | Oracle Linux 8+ (RHCK) |

**Note** : MongoDB Shell ne supporte pas le noyau Unbreakable Enterprise Kernel (UEK).

## Considérations de compatibilité

À partir de la version mongosh 2.0.0 :
- Amazon Linux 1, Debian 9 et macOS 10.14 ne sont plus supportés.
- Le support pour Red Hat Enterprise Linux (RHEL) 7, Amazon Linux 2, SUSE Linux Enterprise Server (SLES) 12 et Ubuntu 18.04 est déprécié et pourrait être supprimé dans une version ultérieure de mongosh.

## Procédure

Sélectionnez l'onglet approprié pour votre système d'exploitation :

- **Windows**
- **macOS**
- **Linux**

**Note** : Sur Windows, les préférences et options de configuration de mongosh sont stockées dans le répertoire `%APPDATA%/mongodb/mongosh`.

### Installation sur Windows

#### Installation à partir du fichier MSI

1. **Ouvrir la page de téléchargement de MongoDB Shell**
   - Accédez au [MongoDB Download Center](https://www.mongodb.com/try/download/shell).

2. **Sélectionner la plateforme**
   - Dans le menu déroulant **Platform**, sélectionnez **Windows 64-bit (8.1+) (MSI)**.

3. **Télécharger le fichier**
   - Cliquez sur **Download**.

4. **Exécuter l'installateur**
   - Double-cliquez sur le fichier d'installation téléchargé.

5. **Suivre les instructions**
   - Suivez les invites pour installer mongosh.

#### Installation à partir du fichier .zip

1. **Ouvrir la page de téléchargement de MongoDB Shell**
   - Accédez au [MongoDB Download Center](https://www.mongodb.com/try/download/shell).

2. **Télécharger l'archive d'installation**
   - Téléchargez l'archive d'installation de mongosh pour votre système d'exploitation.

3. **Extraire les fichiers**
   - Extrayez les fichiers de l'archive téléchargée.
   - Ouvrez une invite de commande et exécutez la commande suivante depuis le répertoire contenant l'archive `.zip` :

     ```sh
     tar -xf mongosh-2.5.1-win32-x64.zip
     ```

   - L'archive extraite contient un dossier `bin` avec deux fichiers : `mongosh.exe` et `mongosh_crypt_v1.dll`.

4. **Ajouter le binaire mongosh à votre variable d'environnement PATH**
   - Assurez-vous que le binaire mongosh extrait est dans le répertoire souhaité de votre système de fichiers, puis ajoutez ce répertoire à votre variable d'environnement PATH.

   Pour ajouter le binaire mongosh à votre variable d'environnement PATH :

   - Ouvrez le **Panneau de configuration**.
   - Dans la catégorie **Système et sécurité**, cliquez sur **Système**.
   - Cliquez sur **Paramètres système avancés**. La fenêtre **Propriétés système** s'affiche.
   - Cliquez sur **Variables d'environnement**.
   - Dans la section **Variables système**, sélectionnez **Path** et cliquez sur **Modifier**. La fenêtre **Modifier la variable d'environnement** s'affiche.
   - Cliquez sur **Nouveau** et ajoutez le chemin vers votre binaire mongosh.
   - Cliquez sur **OK** pour confirmer vos modifications. Cliquez sur **OK** sur chaque autre fenêtre pour confirmer vos modifications.

   Pour vérifier que votre variable d'environnement PATH est correctement configurée pour trouver mongosh, ouvrez une invite de commande et entrez la commande `mongosh --help`. Si votre PATH est correctement configuré, une liste de commandes valides s'affiche.

### Installation sur macOS

1. **Ouvrir la page de téléchargement de MongoDB Shell**
   - Accédez au [MongoDB Download Center](https://www.mongodb.com/try/download/shell).

2. **Sélectionner la plateforme**
   - Dans le menu déroulant **Platform**, sélectionnez **macOS**.

3. **Télécharger le fichier**
   - Cliquez sur **Download**.

4. **Extraire les fichiers**
   - Ouvrez le fichier `.tgz` téléchargé et extrayez son contenu.

5. **Ajouter le binaire mongosh à votre PATH**
   - Déplacez le répertoire extrait vers un emplacement de votre choix, puis ajoutez ce répertoire à votre variable d'environnement PATH.

   Pour ajouter le binaire mongosh à votre PATH :

   ```sh
   export PATH=/path/to/mongosh/bin:$PATH
   ```

   Remplacez `/path/to/mongosh/bin` par le chemin réel vers le répertoire extrait.

6. **Vérifier l'installation**
   - Ouvrez un terminal et entrez la commande `mongosh --help`. Si votre PATH est correctement configuré, une liste de commandes valides s'affiche.

### Installation sur Linux

1. **Ouvrir la page de téléchargement de MongoDB Shell**
   - Accédez au [MongoDB Download Center](https://www.mongodb.com/try/download/shell).

2. **Sélectionner la plateforme**
   - Dans le menu déroulant **Platform**, sélectionnez votre distribution Linux et architecture.

3. **Télécharger le fichier**
   - Cliquez sur **Download**.

4. **Extraire les fichiers**
   - Ouvrez le fichier `.tgz` téléchargé et extrayez son contenu.

5. **Ajouter le binaire mongosh à votre PATH**
   - Déplacez le répertoire extrait vers un emplacement de votre choix, puis ajoutez ce répertoire à votre variable d'environnement PATH.

   Pour ajouter le binaire mongosh à votre PATH :

   ```sh
   export PATH=/path/to/mongosh/bin:$PATH
   ```

   Remplacez `/path/to/mongosh/bin` par le chemin réel vers le répertoire extrait.

6. **Vérifier l'installation**
   - Ouvrez un terminal et entrez la commande `mongosh --help`. Si votre PATH est correctement configuré, une liste de commandes valides s'affiche.

---

Cette documentation vous guide à travers le processus d'installation de MongoDB Shell (mongosh) sur différents systèmes d'exploitation, en utilisant des fichiers MSI, des archives .zip ou .tgz, et en configurant la variable d'environnement PATH pour permettre l'exécution de mongosh directement depuis la ligne de commande.