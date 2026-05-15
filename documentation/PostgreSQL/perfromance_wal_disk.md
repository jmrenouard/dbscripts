# **PostgreSQL : Déporter le répertoire pg\_wal sur un disque dédié**

L'utilisation de pg\_basebackup et pgbackrest avec un répertoire pg\_wal déporté via un lien symbolique présente des comportements distincts qu'il est crucial de maîtriser pour garantir la validité de votre stratégie de reprise après sinistre (Disaster Recovery).

## **🚀 Optimisation I/O : LVM2 et Agrégation de Disques (Striping)**

Pour maximiser les performances d'écriture des WAL, l'utilisation de plusieurs disques physiques agrégés via LVM2 permet de répartir la charge I/O (IOPS) et d'augmenter la bande passante.

### **1\. RAID 0 (Striping) : Performance Maximale**

Le striping répartit les segments de données sur plusieurs disques. Pour PostgreSQL, cela signifie que l'écriture d'un fichier WAL est parallélisée au niveau matériel.

* **Avantage** : Gain de performance quasi linéaire selon le nombre de disques.  
* **Risque** : **Aucune redondance**. La perte d'un seul disque entraîne la perte de tous les WAL, ce qui rend le crash recovery impossible sans backup.  
* **Implémentation LVM** :  
  \# Création du volume avec 3 disques en mode stripe (-i 3\)  
  lvcreate \-i 3 \-I 64k \-L 100G \-n lv\_postgres\_wal vg\_data /dev/sdb /dev/sdc /dev/sdd

### **2\. RAID 10 (Striping \+ Mirroring) : Le compromis idéal**

Le RAID 10 combine la rapidité du RAID 0 et la sécurité du RAID 1\. Il nécessite au moins 4 disques.

* **Avantage** : Excellentes performances en lecture/écriture et tolérance à la panne (un disque par miroir).  
* **Usage recommandé** : Environnements de production critique où le débit WAL est très élevé.  
* **Implémentation LVM** :  
  \# Création d'un volume RAID 10 (2 stripes, chaque stripe est un miroir)  
  lvcreate \--type raid10 \-i 2 \-L 100G \-n lv\_postgres\_wal vg\_data

| Configuration | Performance I/O | Sécurité | Nombre de disques min. |
| :---- | :---- | :---- | :---- |
| **Simple Disque** | Standard | Aucune | 1 |
| **LVM RAID 0** | **Maximale** | Nulle (Risqué) | 2 |
| **LVM RAID 10** | Haute | Élevée | 4 |

## **Comportement des outils face aux liens symboliques**

Le défi technique réside dans la manière dont ces outils traitent les fichiers situés en dehors du répertoire principal (PGDATA). Par défaut, un lien symbolique pointe vers un chemin absolu qui peut ne pas exister sur le serveur de backup ou lors d'une restauration sur une autre machine.

### **💻 Cas de pg\_basebackup**

Par défaut, pg\_basebackup adopte un comportement de "déréférencement" : il suit le lien et copie les fichiers WAL réels dans un répertoire physique pg\_wal au sein de la destination. Le lien symbolique est alors perdu.

**L'alternative \--waldir (ou \-X stream \--waldir=chemin\_absolu) :** Cette option permet de forcer l'emplacement des WAL lors de la sauvegarde pour reconstruire une structure déportée sur la cible.

* **Syntaxe type** :  
  pg\_basebackup \-h localhost \-D /var/lib/postgresql/backup/data \\  
                \-Fp \-X stream \\  
                \--waldir=/mnt/dedicated\_wal/pg\_wal \-P

* **Contraintes majeures** :  
  * Exclusif au format **plain** (-Fp).  
  * Le chemin doit être **absolu**.  
  * Si le répertoire existe, il doit impérativement être **vide**.

#### **🔍 Focus sur l'option \-n (--no-clean)**

Par défaut, en cas d'erreur, pg\_basebackup supprime les répertoires créés. L'activation de \--no-clean modifie ce comportement :

**Les Avantages :**

* **Diagnostic (Post-mortem)** : Permet d'analyser l'état des fichiers (Data et WAL) au moment précis du crash pour identifier la source de l'erreur (corruption, troncature, problème de droits).  
* **Reprise partielle** : Dans certains scénarios complexes, cela permet de conserver les fichiers déjà transférés pour une inspection manuelle ou un rsync correctif.

**Les Impacts et Risques :**

* **Fichiers orphelins** : En cas d'échec, des gigaoctets de données peuvent rester sur le disque, saturant inutilement l'espace.  
* **Blocage des tentatives suivantes** : Puisque \--waldir exige un répertoire vide, une nouvelle tentative échouera immédiatement car les fichiers de la tentative précédente n'auront pas été nettoyés.

### **⚙️ Cas de pgbackrest**

pgbackrest gère nativement les liens symboliques :

* **Pendant le backup** : Il stocke la cible du lien dans son manifeste.  
* **Pendant la restauration** : Il propose l'option \--link-all ou \--link-map pour recréer les liens.

## **📊 Tableau comparatif des fonctionnalités**

| Fonctionnalité | pg\_basebackup (par défaut) | pg\_basebackup (--waldir) | pgbackrest |
| :---- | :---- | :---- | :---- |
| **Gestion pg\_wal** | Déréférencement | Cible forcée | Stocke et recrée le lien |
| **Format supporté** | Plain & Tar | **Plain uniquement** | Tous formats |
| **Nettoyage erreur** | Automatique | Configurable (--no-clean) | Automatique (via verrou) |
| **Automatisation** | Faible | Moyenne | Haute |

## **📈 Flux de sauvegarde et restauration**
```mermaid
graph TD  
    subgraph "Serveur Source"  
        DATA1\[PGDATA /var/lib/postgresql\]  
        WAL1\[Disque LVM Stripe /mnt/pg\_wal\]  
        DATA1 \-- "Lien symbolique" \--\> WAL1  
    end

    subgraph "Processus de Backup"  
        PGB\[pg\_basebackup \--waldir=/mnt/new\_wal\]  
        PGR\[pgbackrest\]  
    end

    subgraph "Serveur Restauré"  
        DATA2\[PGDATA Restauration\]  
        WAL2\_New\[Répertoire WAL /mnt/new\_wal\]  
        WAL2\_Link\[Lien symbolique RECRÉÉ\]  
          
        PGB \--\>|Cible forcée| WAL2\_New  
        PGR \--\>|Option link-map| WAL2\_Link  
    end

    DATA1 \--\> PGB  
    DATA1 \--\> PGR
```

## **⚠️ Risques de Sécurité et de Continuité**

* **Permissions** : L'utilisateur postgres doit posséder les droits sur le répertoire cible.  
* **Saturation** : Si \--no-clean est utilisé, un nettoyage manuel devient obligatoire après chaque échec avant de relancer le backup.  
* **Incohérence de chemin** : Si le point de montage change (/mnt/wal1 vers /mnt/wal2), les scripts de restauration basés sur des chemins codés en dur échoueront.  
* **Fiabilité Matérielle** : En RAID 0, l'augmentation du nombre de disques augmente statistiquement le risque de panne globale du volume WAL.

**Sources et références**

1. [PostgreSQL Documentation: pg\_basebackup (Options)](https://www.postgresql.org/docs/current/app-pgbasebackup.html)  
2. [pgBackRest User Guide: Link Handling](https://pgbackrest.org/user-guide.html#concept/link-handling)  
3. [LVM2 Resource: Striped Logical Volumes](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/configuring_and_managing_logical_volumes/creating-a-striped-logical-volume_configuring-and-managing-logical-volumes)
