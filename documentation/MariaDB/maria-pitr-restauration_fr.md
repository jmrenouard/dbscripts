# Documentation Technique - Restauration PITR avec Binlogs MariaDB

## 1. Introduction
La restauration **PITR (Point-In-Time Recovery)** permet de restaurer une base de données MariaDB jusqu'à un instant précis en utilisant les **binlogs**. Cette méthode est essentielle pour récupérer des données après une suppression accidentelle ou une corruption.

Ce document décrit le fonctionnement d'un script Bash permettant d'automatiser la restauration via les binlogs, ainsi que la procédure détaillée pour effectuer une restauration PITR.

---
## 2. Fonctionnalité du script

### 2.1 Objectif
Le script **Restore Binlog GTID** permet de restaurer les événements MariaDB binlog à partir d'un **GTID donné** jusqu'à une date et heure précises.

### 2.2 Étapes du script
1. **Récupération de la position courante du GTID.**
2. **Identification du fichier binlog contenant ce GTID.**
3. **Sélection des fichiers binlog suivants pour la restauration.**
4. **Exécution de `mariadb-binlog` pour rejouer les transactions jusqu'à la date spécifiée.**

### 2.3 Paramètres du script
| Paramètre  | Description |
|------------|-------------|
| `$1` | Chemin du répertoire contenant les fichiers binlog |
| `$2` | Date limite de la restauration (format YYYY-MM-DD) |
| `$3` | Heure limite de la restauration (format HH:MM:SS) |

### 2.4 Exécution du script
```bash
./script.sh /var/lib/mysql/binlogs 2025-03-12 09:30:00
```

---
## 3. Procédure de Restauration PITR avec Binlogs MariaDB

### 3.1 Prérequis
- Disposer de la solution **CommVault** pour la restauration initiale des snapshots et des binlogs.
- Avoir une sauvegarde complète de la base de données avant l'événement à restaurer.
- Disposer des binlogs activés (`log_bin` doit être activé dans MariaDB).
- Connexion à un utilisateur MariaDB avec les privilèges nécessaires.

### 3.2 Étapes de restauration

#### **Étape 1 : Restaurer la base de données via un snapshot CommVault**
Commencez par restaurer un **snapshot complet** de la base de données à une date antérieure à l'incident.
Une fois la restauration du snapshot terminée, assurez-vous que le serveur MariaDB est opérationnel.

#### **Étape 2 : Restaurer les binlogs avec CommVault**
Les fichiers binlogs nécessaires doivent être restaurés depuis CommVault dans un répertoire spécifique, défini par l'utilisateur.
Assurez-vous que les binlogs restaurés sont complets et disponibles dans ce répertoire.

Exemple :
```bash
ls -lah /chemin/vers/binlogs-restaures/
```

#### **Étape 3 : Identifier le dernier GTID connu**
Si les GTIDs sont activés, notez le dernier GTID connu après la restauration du snapshot :
```sql
SHOW VARIABLES LIKE 'gtid_current_pos';
```

#### **Étape 4 : Localiser les fichiers binlogs à utiliser**
Les binlogs contiennent les transactions après le dernier GTID connu. Repérez ceux qui contiennent votre GTID :
```bash
ls -lah /chemin/vers/binlogs-restaures/
```

#### **Étape 5 : Exécuter le script de restauration**
Lancez la restauration jusqu'à la date et l'heure souhaitées :
```bash
./script.sh /chemin/vers/binlogs-restaures 2025-03-12 09:30:00
```
Cela appliquera tous les changements contenus dans les binlogs jusqu'à l'instant spécifié.

#### **Étape 6 : Vérifier la cohérence des données**
Après la restauration, validez que les données sont correctes :
```sql
SELECT * FROM table_impactee WHERE ...;
```

#### **Étape 7 : Redémarrer MariaDB et tester**
Une fois la restauration terminée, redémarrez MariaDB si nécessaire :
```bash
systemctl restart mariadb
```
Testez ensuite l’application pour valider le bon fonctionnement.

---
## 4. Conclusion
L'utilisation des **snapshots CommVault** combinés aux **binlogs** permet une restauration PITR précise et efficace. Grâce à cette approche, la restauration est facilitée et assure une meilleure gestion des sauvegardes. Ce processus est crucial en cas de suppression accidentelle ou de corruption partielle des données. Il est recommandé d'automatiser ces étapes et de tester régulièrement la restauration pour garantir une récupération rapide en cas d'incident.

---
## 5. Références
- [Documentation officielle MariaDB sur les binlogs](https://mariadb.com/kb/en/binary-log/)
- [Point-in-Time Recovery Guide](https://mariadb.com/kb/en/point-in-time-recovery/)
- [CommVault Documentation](https://documentation.commvault.com/)

