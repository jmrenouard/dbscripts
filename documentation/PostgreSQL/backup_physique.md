# **Architecture et Stratégies de Protection des Données PostgreSQL : Analyse Comparative des Solutions de Sauvegarde Physique et Logique**

La résilience des données au sein des écosystèmes PostgreSQL modernes n'est plus une simple question d'archivage, mais un impératif d'ingénierie complexe dicté par l'explosion des volumes de données et la réduction drastique des fenêtres de maintenance.1 Alors que les bases de données franchissent régulièrement le seuil du téraoctet, les administrateurs de bases de données (DBA) et les ingénieurs DevOps doivent naviguer entre les limitations structurelles des outils natifs et la sophistication croissante des solutions tierces.3 Le choix d'une architecture de sauvegarde influence directement l'objectif de point de rétablissement (![][image1]) et l'objectif de temps de rétablissement (![][image2]), deux mesures critiques de la survie d'une entreprise face à un sinistre.1 Ce rapport propose une analyse exhaustive des outils de sauvegarde physique — pg\_basebackup, pgBackRest, WAL-G et pg\_pro\_backup — tout en les mettant en perspective avec les méthodes de sauvegarde logique traditionnelles.

## **Fondations de la Sauvegarde Physique : L'Utilitaire pg\_basebackup**

L'outil pg\_basebackup constitue la pierre angulaire de la sauvegarde physique dans l'écosystème PostgreSQL. Intégré nativement au noyau du système de gestion de base de données (SGBD), il garantit une compatibilité immédiate avec chaque version majeure sans nécessiter de dépendances externes.6 Son rôle premier est de créer une copie binaire cohérente d'un cluster de bases de données en cours d'exécution, servant de base indispensable pour la mise en place de la réplication en continu ou de la restauration à un instant précis (![][image3]).4

### **Mécanismes et Protocole de Réplication**

Le fonctionnement de pg\_basebackup repose sur le protocole de réplication de PostgreSQL. Contrairement à une simple copie de fichiers au niveau du système d'exploitation, l'utilitaire établit une connexion de réplication avec le serveur, ce qui lui permet de fluxer les fichiers de données tout en garantissant la cohérence transactionnelle via l'inclusion ou le streaming des journaux de transaction (![][image4]).4

Il existe deux modes principaux pour la gestion des WAL durant l'exécution de pg\_basebackup :

1. **Le mode "fetch"** : Les fichiers WAL nécessaires sont collectés à la fin du processus de sauvegarde. Ce mode présente un risque si les fichiers WAL sont recyclés par le serveur avant la fin de la copie des données.7  
2. **Le mode "stream"** : Un second canal de réplication est ouvert pour transférer les WAL en temps réel pendant que les fichiers de données sont copiés. C'est la méthode recommandée pour garantir que la sauvegarde soit immédiatement utilisable pour une restauration.7

### **Évolutions Récentes et Limitations Structurelles**

Avec l'introduction de PostgreSQL 17, pg\_basebackup a franchi une étape majeure en supportant les sauvegardes incrémentales natives. Ce mécanisme s'appuie sur un manifeste de sauvegarde qui suit les modifications de blocs, permettant de ne transférer que les deltas depuis une sauvegarde de référence.7 Toutefois, malgré cette avancée, pg\_basebackup reste un outil de bas niveau. Il ne possède pas de catalogue de sauvegarde intégré, ce qui signifie que la gestion de la rétention, de la rotation et de l'historique des sauvegardes doit être orchestrée par des scripts externes.2

En termes de performance, bien que pg\_basebackup supporte la compression (gzip, lz4, zstd) côté client ou serveur, ses capacités de parallélisation restent limitées par rapport aux outils spécialisés. Il est capable de compresser les fichiers en parallèle s'il est configuré avec plusieurs threads de travail, mais il ne peut pas distribuer la lecture des fichiers de données de manière aussi granulaire que pgBackRest ou WAL-G.7

## **pgBackRest : L'Orchestrateur de Sauvegarde de Classe Entreprise**

Conçu pour répondre aux exigences des bases de données de plusieurs téraoctets, pgBackRest s'est imposé comme la solution de référence pour les environnements de production critiques.10 Son architecture est bâtie sur des principes d'efficacité, de sécurité et de fiabilité, comblant les lacunes de pg\_basebackup grâce à un protocole personnalisé et une gestion avancée du parallélisme.11

### **Parallélisation Massive et Optimisation de la Compression**

La compression est fréquemment identifiée comme le goulot d'étranglement principal lors des opérations de sauvegarde. pgBackRest résout ce problème en distribuant la charge de travail sur plusieurs processus (configurés via le paramètre process-max).11 Cette parallélisation s'applique non seulement à l'extraction des données mais aussi au calcul des sommes de contrôle et à l'archivage des WAL.11

L'outil supporte des algorithmes de compression modernes tels que lz4 et zstd. Le zstd, en particulier, offre un équilibre exceptionnel entre le ratio de compression et la vitesse de traitement, permettant de réduire considérablement l'espace de stockage sans sacrifier le débit I/O.11

| Algorithme | Vitesse de Compression | Ratio de Compression | Idéal pour |
| :---- | :---- | :---- | :---- |
| **lz4** | Très élevée | Faible | Sauvegardes locales rapides 15 |
| **zstd** | Élevée | Élevé | Stockage objet, Cloud 15 |
| **gzip** | Moyenne | Moyen | Compatibilité héritée 7 |

### **Gestion de l'Intégrité et Sécurité des Données**

La fiabilité d'une sauvegarde ne se mesure pas à sa création, mais à sa capacité à être restaurée. pgBackRest calcule des checksums pour chaque fichier et les vérifie systématiquement lors de la restauration.11 Plus impressionnant encore, il propose une validation des checksums au niveau de la page (si activée dans PostgreSQL). Durant la sauvegarde, pgBackRest valide chaque page copiée ; si une corruption est détectée, elle est consignée dans les logs, permettant une détection précoce des défaillances matérielles ou logicielles avant que les sauvegardes valides ne soient expirées.11

Sur le plan de la sécurité, pgBackRest utilise un protocole personnalisé pour les opérations distantes via TLS ou SSH. Cette approche élimine le besoin de donner un accès SQL direct à l'outil de sauvegarde, réduisant ainsi la surface d'attaque sur le serveur de base de données.11 De plus, le chiffrement nativement intégré (AES-256) permet de sécuriser les dépôts de sauvegarde, qu'ils soient stockés sur disque local ou dans le cloud.3

### **Flexibilité des Dépôts et Cloud Native**

L'un des avantages stratégiques de pgBackRest est sa capacité à gérer plusieurs dépôts (repositories). Une architecture courante consiste à maintenir un dépôt local sur un stockage rapide pour des restaurations quasi instantanées, et un second dépôt sur un stockage objet (S3, Azure Blob, GCS) pour la redondance géographique et la rétention à long terme.10

La gestion des WAL est également optimisée grâce à des commandes asynchrones (archive-push et archive-get). Ces commandes utilisent des files d'attente locales pour minimiser le temps de réponse du serveur PostgreSQL, ce qui est critique pour les bases de données supportant un débit transactionnel élevé.11

## **WAL-G : L'Evolution Cloud-Native de WAL-E**

WAL-G est la réimplémentation en langage Go de l'outil historique WAL-E. Conçu pour la vitesse et l'intégration moderne, il est particulièrement prisé dans les environnements Kubernetes et les infrastructures cloud pour sa simplicité et ses performances brutes.3

### **Architecture et Performances en Streaming**

L'utilisation du langage Go permet à WAL-G d'offrir une gestion concurrente extrêmement efficace grâce aux goroutines. L'outil privilégie une approche de streaming pur vers le stockage objet, ce qui signifie que les données sont compressées et chiffrées à la volée avant d'être envoyées vers S3, GCS ou Azure.3 Cette architecture est idéale pour les instances éphémères dans le cloud où le stockage local peut être limité.3

WAL-G supporte des algorithmes de compression variés (lz4, zstd, brotli, lzma).17 Bien que lz4 soit le choix par défaut pour sa rapidité, l'utilisation de zstd ou brotli permet d'atteindre des taux de compression trois fois supérieurs à lz4, ce qui réduit significativement les coûts de stockage cloud.17

### **Sauvegardes Delta et Restauration Optimisée**

Le concept de "sauvegarde delta" dans WAL-G est une innovation majeure. Au lieu de copier des fichiers entiers, WAL-G peut identifier les blocs modifiés au niveau de la page de données.3 Lors de la création d'une sauvegarde incrémentale, seuls les deltas sont transférés. Cette approche réduit non seulement le temps de sauvegarde mais aussi la bande passante consommée.3

Lors de la restauration, WAL-G utilise un mécanisme de "delta restore" (souvent appelé reverse-unpack) qui permet de ne télécharger que les fichiers ou blocs nécessaires pour ramener le répertoire de données local à l'état souhaité, en se basant sur ce qui est déjà présent sur le disque.3 Cela permet des restaurations beaucoup plus rapides que les méthodes traditionnelles qui exigent la suppression et le retéléchargement de l'intégralité du cluster.19

### **Sécurité et Support Multi-Cloud**

La sécurité dans WAL-G est assurée par le support du chiffrement GPG ou via la bibliothèque libsodium (chiffrement symétrique).3 L'intégration avec les politiques IAM des fournisseurs de cloud permet de gérer finement les accès aux buckets S3 ou GCS sans stocker de clés statiques sur le serveur.3 WAL-G est aujourd'hui utilisé par de grands acteurs du cloud comme Heroku pour gérer des milliers de bases de données PostgreSQL.10

## **pg\_pro\_backup : Précision Chirurgicale et Performance de Blocs**

Développé par Postgres Professional, pg\_pro\_backup se distingue par son approche axée sur la performance granulaire et la réduction de l'impact sur les serveurs de production.24 C'est un outil particulièrement puissant pour les environnements qui ne peuvent tolérer une charge I/O élevée durant les sauvegardes.

### **Les Trois Modes de Sauvegarde Incrémentale**

pg\_pro\_backup propose trois modes incrémentaux distincts, chacun répondant à des contraintes spécifiques :

1. **DELTA** : L'outil lit l'intégralité du répertoire de données et compare les fichiers pour ne copier que les pages modifiées. Ce mode est sûr mais génère une charge de lecture importante.24  
2. **PAGE** : L'outil scanne les journaux WAL archivés depuis la dernière sauvegarde pour identifier les pages modifiées. Il ne lit alors que ces pages spécifiques, minimisant radicalement l'impact I/O sur le serveur.24  
3. **PTRACK** : Ce mode nécessite une extension noyau pour PostgreSQL qui suit les modifications de pages en temps réel via une carte binaire (bitmap). C'est la méthode la plus rapide et la moins intrusive, permettant des sauvegardes incrémentales quasi instantanées.24

### **Restauration Incrémentale et Fusion de Sauvegardes**

Une fonctionnalité différenciatrice majeure de pg\_pro\_backup est la "fusion de sauvegardes" (merge). Contrairement à d'autres outils qui exigent de conserver une chaîne de fichiers incrémentaux, pg\_pro\_backup permet de fusionner une sauvegarde incrémentale dans sa sauvegarde parente (complète ou incrémentale) pour créer une nouvelle base cohérente.26 Cela permet de maintenir un cycle de sauvegarde "incrémental à vie", réduisant l'espace de stockage et simplifiant la gestion de la rétention.26

La restauration incrémentale de pg\_pro\_backup fonctionne sur le même principe que le delta restore : elle réutilise les pages valides déjà présentes dans le répertoire cible pour ne restaurer que les blocs manquants ou corrompus.24 Pour une base de données de plusieurs téraoctets avec seulement quelques gigaoctets de corruption, le gain de temps est colossal.

### **Validation et Vérification de l'Intégrité**

L'outil offre des capacités avancées de validation des sauvegardes sans nécessiter de restauration complète. La commande validate vérifie la cohérence des fichiers et des sommes de contrôle dans le catalogue de sauvegarde.24 De plus, la commande checkdb permet de vérifier l'intégrité d'une instance PostgreSQL en ligne, détectant les corruptions de pages de manière proactive.24

## **Comparaison des Outils Physiques sur la Base des Critères pgBackRest**

Le tableau suivant offre une vue synthétique des capacités de chaque outil en utilisant les standards de comparaison définis par l'architecture de pgBackRest.

| Critères de Comparaison | pg\_basebackup | pgBackRest | WAL-G | pg\_pro\_backup |
| :---- | :---- | :---- | :---- | :---- |
| **Parallélisme (Backup/Restore)** | Limité (WAL stream) 7 | Complet (Processus) 11 | Complet (Go-routines) 17 | Complet (Threads) 24 |
| **Compression (lz4, zstd)** | Supporté (v15+) 7 | Natif et optimisé 11 | Natif et varié 17 | Supporté 24 |
| **Opération Distante** | Réplication PG 7 | TLS/SSH custom 11 | SSH / Cloud APIs 3 | SSH natif 26 |
| **Dépôts Multiples** | Non supporté | Supporté (Local/Cloud) 11 | Experimental 29 | Via Catalogue 24 |
| **Sauvegarde Incrémentale** | Bloc (v17+) 7 | Fichier/Bloc 11 | Delta (Page) 3 | Page/Ptrack 24 |
| **Rétention / Expiration** | Manuel | Automatique (Full/Diff) 11 | Automatique 20 | Flexible (TTL/Count) 24 |
| **Intégrité (Checksums)** | Non 7 | Systématique 11 | Flag \--verify 30 | Validation catalogue 24 |
| **Page Checksums** | Non | Validation durant backup 14 | Flag \--verify 30 | Via checkdb 26 |
| **Reprise de Sauvegarde** | Non | Oui (Resume) 11 | Upload partiel 19 | Non 28 |
| **Restauration Delta** | Non | Oui 14 | Oui 19 | Oui 26 |
| **WAL Push/Get Asynchrone** | Non | Oui 11 | Oui (Prefetch) 19 | Non 26 |
| **Tablespace / Liens** | Supporté 7 | Complet (Remap) 11 | Partiel 31 | Supporté 27 |
| **Stockage Objet (S3/Azure)** | Manuel / v17+ | Natif 11 | Natif 3 | Version Pro/Ent 26 |
| **Chiffrement** | Non | AES-256 11 | GPG/Libsodium 17 | AES-256 32 |
| **Compatibilité Versions** | Toutes | 10 dernières versions 11 | Versions 9.5+ 33 | Versions 11+ 26 |

## **Sauvegarde Physique vs Sauvegarde Logique : Le Dilemme Stratégique**

Pour comprendre la place des outils physiques, il est essentiel de les confronter aux méthodes de sauvegarde logique représentées par pg\_dump et pg\_dumpall. Ces outils, bien que fondamentaux, répondent à des problématiques radicalement différentes.1

### **Nature et Mécanisme des Sauvegardes Logiques**

pg\_dump crée une sauvegarde en extrayant les données et les définitions de schéma sous forme de scripts SQL ou de formats d'archives compressés. Ce processus s'appuie sur le mécanisme de contrôle de concurrence multi-version (MVCC) de PostgreSQL, garantissant une vue cohérente de la base de données au moment où le dump commence, sans bloquer les autres utilisateurs.4

pg\_dumpall étend cette fonctionnalité à l'intégralité d'un cluster, incluant les objets globaux tels que les rôles (utilisateurs et permissions) et les définitions de tablespaces.34

### **Avantages de l'Approche Logique**

La force de la sauvegarde logique réside dans sa flexibilité et sa portabilité :

* **Indépendance de Version** : Un dump réalisé sur une version ancienne de PostgreSQL peut généralement être restauré sur une version plus récente, ce qui en fait l'outil de choix pour les montées de version majeures.2  
* **Portabilité d'Architecture** : Les sauvegardes logiques peuvent être restaurées sur des systèmes d'exploitation ou des architectures CPU différents (ex: de Linux vers Windows, ou de x86 vers ARM).4  
* **Granularité Fine** : Il est possible de sauvegarder ou de restaurer uniquement une table, un schéma ou une base de données spécifique sans affecter le reste du cluster.2  
* **Taille Réduite** : En n'incluant pas les index (qui sont reconstruits lors de la restauration) et en éliminant les "dead tuples" (bloat), les sauvegardes logiques sont souvent 20% à 50% plus petites que les fichiers physiques originaux.2

### **Limitations et Coûts de Performance**

Le revers de la médaille est la performance, particulièrement critique pour les bases de données volumineuses :

* **Vitesse de Sauvegarde** : pg\_dump doit lire chaque ligne de la base de données via l'interface SQL, ce qui est beaucoup plus lent que la lecture directe de blocs de fichiers.2  
* **Vitesse de Restauration** : La restauration est un processus extrêmement coûteux car le système doit réexécuter chaque commande SQL, recréer tous les index et valider toutes les contraintes de clés étrangères.2  
* **Absence de PITR** : Une sauvegarde logique est un instantané figé. Elle ne permet pas de rejouer des transactions pour restaurer la base de données à un moment précis entre deux sauvegardes.1

| Métrique | 100 GB Database | 1 TB Database | 5 TB Database |
| :---- | :---- | :---- | :---- |
| **Backup Physique (Temps)** | 10–20 min 4 | 1–2 h 4 | 5–10 h 4 |
| **Backup Logique (Temps)** | 1–3 h 4 | 8–16 h 4 | 40–80 h 4 |
| **Restore Physique (Temps)** | 15–30 min 4 | 1.5–3 h 4 | 8–15 h 4 |
| **Restore Logique (Temps)** | 2–6 h 4 | 16–32 h 4 | 80–160 h 4 |

## **Deep Insights : Défis de la Sauvegarde dans le Cloud et Résilience Moderne**

L'évolution des infrastructures vers le "Sovereign Cloud" et le cloud public a transformé les outils de sauvegarde en véritables gestionnaires de données distribuées.18

### **Le Goulot d'Étranglement I/O vs CPU**

Dans les environnements modernes équipés de disques NVMe et de réseaux à 10 ou 25 Gbps, le facteur limitant n'est plus le stockage mais la puissance de calcul nécessaire pour compresser et chiffrer les données.11 pgBackRest et WAL-G ont répondu à ce défi en adoptant massivement zstd, qui permet des débits de plusieurs téraoctets par heure en exploitant efficacement les processeurs multi-cœurs.11

### **Ransomware et Immutabilité**

La menace des ransomwares a imposé de nouvelles exigences d'intégrité. La simple sauvegarde ne suffit plus ; elle doit être immuable. Les outils supportant nativement le stockage objet (S3) tirent parti des fonctionnalités de "Object Lock" pour empêcher la suppression ou la modification des sauvegardes, même en cas de compromission totale du serveur de base de données.37 De plus, les capacités de vérification d'intégrité proactive de pgBackRest et pg\_pro\_backup permettent de détecter si une base de données a été silencieusement corrompue (ou chiffrée par un malware) avant que les sauvegardes saines ne soient purgées du système de rétention.14

### **L'Archive de pgBackRest en 2026 : Un Signal d'Alarme**

Un point d'attention majeur est le signalement de l'archivage du projet pgBackRest en avril 2026\.18 Si l'outil reste fonctionnel, l'absence de mises à jour futures et d'ajustements pour les prochaines versions majeures de PostgreSQL pourrait forcer une migration vers WAL-G (Cloud-Native) ou pg\_pro\_backup (Enterprise).3 Cette situation souligne l'importance pour les entreprises de ne pas s'enclaver dans un outil unique sans une stratégie de sortie ou de transition.

## **Analyse des Tablespaces et Mapping de Restauration**

La gestion des tablespaces est souvent une source de complexité lors de la restauration physique, car elle implique la gestion de liens symboliques pointant vers des emplacements hors du répertoire de données principal.7

### **pgBackRest : La Référence du Remappage**

pgBackRest offre une flexibilité totale lors de la restauration. Il permet de remapper tous les tablespaces vers un seul emplacement (utile pour le développement) ou de redéfinir chaque chemin individuellement.11 Cette fonctionnalité est gérée de manière transparente en reconstruisant les liens symboliques dans pg\_tblspc, ce qui évite les erreurs manuelles fréquentes avec pg\_basebackup.11

### **Les Défis de WAL-G et pg\_basebackup**

WAL-G a historiquement montré des faiblesses dans la gestion des tablespaces lors des restaurations delta, où la présence de liens existants peut bloquer le processus d'extraction.31 De son côté, pg\_basebackup nécessite l'option \--tablespace-mapping lors de la prise de vue, ou une manipulation manuelle post-restauration des fichiers de configuration et des liens, ce qui augmente le risque d'erreur opérationnelle lors d'une crise.7

## **Conclusions Techniques et Recommandations Opérationnelles**

Le choix entre ces outils ne doit pas se faire sur une base de préférences, mais sur une analyse rigoureuse des besoins en RTO/RPO et de l'architecture d'hébergement.

1. **Priorité Cloud et Kubernetes** : **WAL-G** est le choix stratégique. Sa conception orientée streaming vers le stockage objet et sa faible empreinte mémoire en font l'outil idéal pour les architectures conteneurisées où la résilience est déléguée aux APIs de stockage cloud.3  
2. **Bases de Données Massives sur Site (On-Premise)** : **pgBackRest** demeure, malgré son statut incertain en 2026, l'outil le plus robuste pour les installations traditionnelles et mixtes. Ses fonctionnalités de parallélisme asynchrone, de validation des pages et de gestion de dépôts multiples offrent une sécurité opérationnelle qu'aucun autre outil n'égalise encore pleinement.10  
3. **Performance Critique et Impact Minimal** : **pg\_pro\_backup** avec le mode **PTRACK** est la solution ultime pour les bases de données supportant une charge de travail intense. La capacité de réaliser des sauvegardes incrémentales sans lecture complète du disque et de fusionner les sauvegardes en arrière-plan transforme la gestion du stockage pour les DBA.24  
4. **Besoins de Migration et Développement** : La sauvegarde logique via **pg\_dump** reste indispensable. Aucun outil physique ne peut remplacer la portabilité et la granularité d'un dump SQL pour transférer des données entre versions majeures ou pour restaurer une seule table supprimée par accident.2

Une stratégie de sauvegarde "Best-in-Class" en 2026 repose sur un modèle hybride : des sauvegardes physiques quotidiennes (incrémentales ou différentielles) avec archivage continu des WAL pour la protection contre les sinistres majeurs, complétées par des dumps logiques hebdomadaires pour la flexibilité et l'indépendance technologique.1 La mise en place d'une validation automatisée (automated restore testing) est le seul moyen de garantir que le contrat de service (SLA) de l'entreprise sera respecté le jour où la production défaillira.1

#### **Sources des citations**

1. PostgreSQL Backup Strategies for Enterprise-Grade Environments \- Percona, consulté le mai 6, 2026, [https://www.percona.com/blog/postgresql-backup-strategy-enterprise-grade-environment/](https://www.percona.com/blog/postgresql-backup-strategy-enterprise-grade-environment/)  
2. Database Backups and Disaster Recovery in PostgreSQL: Your Questions, Answered, consulté le mai 6, 2026, [https://www.tigerdata.com/blog/database-backups-and-disaster-recovery-in-postgresql-your-questions-answered](https://www.tigerdata.com/blog/database-backups-and-disaster-recovery-in-postgresql-your-questions-answered)  
3. PostgreSQL backup tools comparison — Databasus, WAL-G, pgBackRest and Barman, consulté le mai 6, 2026, [https://dev.to/piteradyson/postgresql-backup-tools-comparison-databasus-wal-g-pgbackrest-and-barman-2kg](https://dev.to/piteradyson/postgresql-backup-tools-comparison-databasus-wal-g-pgbackrest-and-barman-2kg)  
4. Physical vs Logical Backups in PostgreSQL: Decisive Comparison ..., consulté le mai 6, 2026, [https://medium.com/@jabaje8193/physical-vs-logical-backups-in-postgresql-decisive-comparison-guide-4fb6d85b9b3d](https://medium.com/@jabaje8193/physical-vs-logical-backups-in-postgresql-decisive-comparison-guide-4fb6d85b9b3d)  
5. Making PostgreSQL Backups 100x Faster via EBS Snapshots and pgBackRest, consulté le mai 6, 2026, [https://www.tigerdata.com/blog/making-postgresql-backups-100x-faster-via-ebs-snapshots-and-pgbackrest](https://www.tigerdata.com/blog/making-postgresql-backups-100x-faster-via-ebs-snapshots-and-pgbackrest)  
6. pg\_basebackup vs pgBackRest | SERHAT CELIK DATABASE BLOG \- WordPress.com, consulté le mai 6, 2026, [https://serhatcelik.wordpress.com/2025/06/21/pg\_basebackup-vs-pgbackrest/](https://serhatcelik.wordpress.com/2025/06/21/pg_basebackup-vs-pgbackrest/)  
7. Documentation: 18: pg\_basebackup \- PostgreSQL, consulté le mai 6, 2026, [https://www.postgresql.org/docs/current/app-pgbasebackup.html](https://www.postgresql.org/docs/current/app-pgbasebackup.html)  
8. PostgreSQL WAL archiving explained — Understanding Write-Ahead Logs for backup and recovery | by Nazar Egorov | Medium, consulté le mai 6, 2026, [https://medium.com/@ngza5tqf/postgresql-wal-archiving-explained-understanding-write-ahead-logs-for-backup-and-recovery-29f512781c50](https://medium.com/@ngza5tqf/postgresql-wal-archiving-explained-understanding-write-ahead-logs-for-backup-and-recovery-29f512781c50)  
9. Pg\_rman: Backup/Restore Tool for PostgreSQL | Hacker News, consulté le mai 6, 2026, [https://news.ycombinator.com/item?id=38915421](https://news.ycombinator.com/item?id=38915421)  
10. Introduction to Postgres Backups | Crunchy Data Blog, consulté le mai 6, 2026, [https://www.crunchydata.com/blog/introduction-to-postgres-backups](https://www.crunchydata.com/blog/introduction-to-postgres-backups)  
11. pgBackRest \- Reliable PostgreSQL Backup & Restore, consulté le mai 6, 2026, [https://pgbackrest.org/](https://pgbackrest.org/)  
12. pgBackRest \- pgEdge Documentation, consulté le mai 6, 2026, [https://docs.pgedge.com/pgbackrest/v2-58-0/](https://docs.pgedge.com/pgbackrest/v2-58-0/)  
13. How to Build PostgreSQL Incremental Backups \- OneUptime, consulté le mai 6, 2026, [https://oneuptime.com/blog/post/2026-01-30-postgresql-incremental-backups/view](https://oneuptime.com/blog/post/2026-01-30-postgresql-incremental-backups/view)  
14. Advanced pgBackRest, consulté le mai 6, 2026, [https://postgresql.us/events/pgconfnyc2023/sessions/session/1358/slides/110/Advanced-pgBackRest-Slides.pdf](https://postgresql.us/events/pgconfnyc2023/sessions/session/1358/slides/110/Advanced-pgBackRest-Slides.pdf)  
15. 15 Data Compression Libraries That Shrink Storage Costs \- Medium, consulté le mai 6, 2026, [https://medium.com/@reliabledataengineering/15-data-compression-libraries-that-shrink-storage-costs-372c81f34a88](https://medium.com/@reliabledataengineering/15-data-compression-libraries-that-shrink-storage-costs-372c81f34a88)  
16. You Can Now Pick Your Favorite Compression Algorithm For Your WALs\! \- EDB, consulté le mai 6, 2026, [https://www.enterprisedb.com/blog/you-can-now-pick-your-favorite-compression-algorithm-your-wals](https://www.enterprisedb.com/blog/you-can-now-pick-your-favorite-compression-algorithm-your-wals)  
17. wal-g/wal-g: Archival and Restoration for databases in the Cloud \- GitHub, consulté le mai 6, 2026, [https://github.com/wal-g/wal-g](https://github.com/wal-g/wal-g)  
18. Top Open-Source Postgres Backup Solutions in 2026 \- Bytebase, consulté le mai 6, 2026, [https://www.bytebase.com/blog/top-open-source-postgres-backup-solution/](https://www.bytebase.com/blog/top-open-source-postgres-backup-solution/)  
19. PostgreSQL \- WAL-G \- Read the Docs, consulté le mai 6, 2026, [https://wal-g.readthedocs.io/PostgreSQL/](https://wal-g.readthedocs.io/PostgreSQL/)  
20. PostgreSQL Backups: WAL-G \- GitLab Runbooks, consulté le mai 6, 2026, [https://runbooks.gitlab.com/patroni/postgresql-backups-wale-walg/](https://runbooks.gitlab.com/patroni/postgresql-backups-wale-walg/)  
21. Set Up Automated Database Backups for PostgreSQL on Kubernetes Using WAL-G, consulté le mai 6, 2026, [https://oneuptime.com/blog/post/2026-02-09-postgresql-backups-walg-kubernetes/view](https://oneuptime.com/blog/post/2026-02-09-postgresql-backups-walg-kubernetes/view)  
22. J.7. wal-g — Tantor Special Edition 16.13 documentation, consulté le mai 6, 2026, [https://docs.tantorlabs.ru/tdb/en/16\_13/se/wal-g.html](https://docs.tantorlabs.ru/tdb/en/16_13/se/wal-g.html)  
23. WAL-G | Aidbox Docs \- Health Samurai, consulté le mai 6, 2026, [https://www.health-samurai.io/docs/aidbox/deployment-and-maintenance/backup-and-restore/wal-g](https://www.health-samurai.io/docs/aidbox/deployment-and-maintenance/backup-and-restore/wal-g)  
24. Postgres Pro Standard : Documentation: 18: pg\_probackup, consulté le mai 6, 2026, [https://postgrespro.com/docs/postgrespro/current/app-pgprobackup](https://postgrespro.com/docs/postgrespro/current/app-pgprobackup)  
25. If not pgBackRest, then what? Rethinking PostgreSQL Backups in 2026 | by Tomasz Gintowt, consulté le mai 6, 2026, [https://tomasz-gintowt.medium.com/if-not-pgbackrest-then-what-rethinking-postgresql-backups-in-2026-3b8e36d5ec84?source=rss-------1](https://tomasz-gintowt.medium.com/if-not-pgbackrest-then-what-rethinking-postgresql-backups-in-2026-3b8e36d5ec84?source=rss-------1)  
26. Postgres Pro Enterprise : Documentation: 18: pg\_probackup, consulté le mai 6, 2026, [https://postgrespro.com/docs/enterprise/current/app-pgprobackup](https://postgrespro.com/docs/enterprise/current/app-pgprobackup)  
27. The Current State of Open Source Backup Management for PostgreSQL \- Severalnines, consulté le mai 6, 2026, [https://severalnines.com/blog/current-state-open-source-backup-management-postgresql/](https://severalnines.com/blog/current-state-open-source-backup-management-postgresql/)  
28. GitHub \- postgrespro/pg\_probackup: Backup and recovery manager ..., consulté le mai 6, 2026, [https://github.com/postgrespro/pg\_probackup](https://github.com/postgrespro/pg_probackup)  
29. J.7. wal-g — Tantor Special Edition 15.17 documentation, consulté le mai 6, 2026, [https://docs.tantorlabs.ru/tdb/en/15\_17/se/wal-g.html](https://docs.tantorlabs.ru/tdb/en/15_17/se/wal-g.html)  
30. From Backup to Integrity: Leveraging WAL-G for PostgreSQL \- Data Egret, consulté le mai 6, 2026, [https://dataegret.com/2024/11/from\_backup\_to\_integrity\_leveraging\_wal-g\_for\_postgresql/](https://dataegret.com/2024/11/from_backup_to_integrity_leveraging_wal-g_for_postgresql/)  
31. Documentation for tablespace support? · Issue \#631 · wal-g/wal-g \- GitHub, consulté le mai 6, 2026, [https://github.com/wal-g/wal-g/issues/631](https://github.com/wal-g/wal-g/issues/631)  
32. pg\_probackup download | SourceForge.net, consulté le mai 6, 2026, [https://sourceforge.net/projects/pg-probackup.mirror/](https://sourceforge.net/projects/pg-probackup.mirror/)  
33. Ecosystem:Backup \- PostgreSQL wiki, consulté le mai 6, 2026, [https://wiki.postgresql.org/wiki/Ecosystem:Backup](https://wiki.postgresql.org/wiki/Ecosystem:Backup)  
34. PostgreSQL Backup \- pg\_dump & pg\_dumpall \- Neon, consulté le mai 6, 2026, [https://neon.com/postgresql/administration/backup-database](https://neon.com/postgresql/administration/backup-database)  
35. Best Open Source Tools for PostgreSQL Backup and Restore |…, consulté le mai 6, 2026, [https://vela.simplyblock.io/articles/best-open-source-postgresql-backup-restore-tools/](https://vela.simplyblock.io/articles/best-open-source-postgresql-backup-restore-tools/)  
36. Documentation: 18: pg\_dumpall \- PostgreSQL, consulté le mai 6, 2026, [https://www.postgresql.org/docs/current/app-pg-dumpall.html](https://www.postgresql.org/docs/current/app-pg-dumpall.html)  
37. Sovereign Cloud, PG-Backups, S3, Dead Man's Switch…why? | by Artem Lajko \- ITNEXT, consulté le mai 6, 2026, [https://itnext.io/sovereign-cloud-pg-backups-s3-dead-mans-switch-why-d83f4d15e44a](https://itnext.io/sovereign-cloud-pg-backups-s3-dead-mans-switch-why-d83f4d15e44a)  
38. Rapid PostgreSQL Backup and Recovery with pgBackRest and FlashBlade, consulté le mai 6, 2026, [https://blog.purestorage.com/purely-technical/rapid-postgresql-backup-and-recovery-with-pgbackrest-and-flashblade/](https://blog.purestorage.com/purely-technical/rapid-postgresql-backup-and-recovery-with-pgbackrest-and-flashblade/)  
39. AWS S3 Backup: Everything You Need to Know \- StarWind, consulté le mai 6, 2026, [https://www.starwindsoftware.com/blog/what-is-aws-s3-backup/](https://www.starwindsoftware.com/blog/what-is-aws-s3-backup/)  
40. The Silent Corruption: Why Backup Integrity Validation Can't Wait Until You Need to Restore, consulté le mai 6, 2026, [https://medium.com/@sabithvm/the-silent-corruption-why-backup-integrity-validation-cant-wait-until-you-need-to-restore-dca5e8b65137](https://medium.com/@sabithvm/the-silent-corruption-why-backup-integrity-validation-cant-wait-until-you-need-to-restore-dca5e8b65137)  
41. Steps to restore a database having multiple tablespaces to different location on the same server, consulté le mai 6, 2026, [https://youkudbhelper.wordpress.com/2021/09/01/steps-to-restore-a-database-having-multiple-tablespaces-to-different-location-on-the-same-server/](https://youkudbhelper.wordpress.com/2021/09/01/steps-to-restore-a-database-having-multiple-tablespaces-to-different-location-on-the-same-server/)  
42. backup-fetch: Error creating tablespace symkink · Issue \#499 · wal-g/wal-g \- GitHub, consulté le mai 6, 2026, [https://github.com/wal-g/wal-g/issues/499](https://github.com/wal-g/wal-g/issues/499)

[image1]: <data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACoAAAAYCAYAAACMcW/9AAADeklEQVR4AeyWWahOURSAzzVlnsk8PJiHzJRMmRIpEUqSiCceCIXyYHhAHjxIipQ8EC+UB5RZITMhETKHzGT+vtM9v3POf/7bVTdR97a+s/Ze65xz19l7rbX/CsF/8lceaFlv1L+yopX5sC4wCUZBHUhIOtBheJ/AzxjPGX+B73AGJkJFiEtDJsfAe6JnfeZhsU27/s7M41KbyTq4CRNA6cflLmivhg4lHegRrE1hK3yDQdAYqhSjfTfjhVAEkbxgMATGgbKGi8+0QPtR9dDv4RT0BKUHl/Ogvyt6FewB9Rj0bNgAlSBIB6qtFpcO8ABuQySuyn4mrtJctB+ASkgUxMmENQjeMj8OdWEm9IFD4MIsQX+CuJxlsgOmQkcIsgJ1Fdyii9zwEuKirxGGz2DgqJxUZTQQnsItSIvbrO0Hl+3wDJbDV8gS08wP852ZgbbjqfrgF7v9DHMylpF5sw3tdqNy0oCRBXEdbRConFgcw5mZt469bzNz8x9VohhsZqAjeMwA/YcMQ7EqZzGaB4thI6SlE4ZW4Ep8QEdiLpsqFsl6jCPBVT+ALknc1Zw/vfU18XQHK3ct+ijcAFfCvGrP2GrM2q7e+AyqL3pLjAuMJ8NQMPeao7U9RhcS08hi0x/WSTrQlni6wT4YDL7cL1vKeA70gizxxd7/GudKWBHDludHWkxhYeC7A+Y5KlPaYh0Aj8Baydv6KD9Pc4Pbjwpc3YMMfPEUdJZE+XkN5yWwF0cYPKaEGEDCkJqMZ26d2K7uMc4LNMpPt0h/hCtRnUm6SDCFEuWnX/8utGRfsoJO39kGg7vnIWBOu1CJQO2f9sF0/+S5oL8XsB+i8sRCMT8P53mShitMzXfzOGzkzONi0ZpmruYMHPZsVJAItDUWTwhXJd4/fWETfHFZxsTVRwW2K/PzFZMw8dGF5BwOW5snj8XHNCc1GFmEnvWS2FWLyWPyPjddBXuWZ7kVaZ5gCszVXQxs1L58OmO3x25gr33DfDS4CpfRO8E0QeWJ71qAdRN4Kq1G+0PExu/7TBu7jh+E67cY6AmmrmYROsLj0crHFMpers3AY80eOJ+xBWFP9EyPnnM8Dd9HKCQel4tw+pvCHyoMA4vV1ud7M9PLQL2xNFhInvWuov+sNM+UdI87YYBWtttsVyl4/58EWvAlf8NRHmhZr3L5ipb1iv4CAAD//1FB3VwAAAAGSURBVAMAMIuxMQcp+G0AAAAASUVORK5CYII=>

[image2]: <data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACkAAAAYCAYAAABnRtT+AAADYUlEQVR4AeyWWahOURSAzzVlJmWek3nITJlLIqVEeBFFPPFAKDzyYnrwIClSnogSpVCGhBDKLEPIHBmLzN936hznnHt+91d/cuu/rW+vvdfe5/zr7L3W2rdGUA3+yk6W6pD+h52szcf0hukwAZpASrJOjmP2GfxM8JL+F/gO52Aa1ASlBc0xeFQkm1gXSWM66+EWTAVlKM190F4PHUrWyeNYW8N2+AajQEfqoEX7HvpLoQIGgutno7tAB1gI7eEAdARtw9F34RUo/Wkugh/bB70G9oJ6Eno++EG10EHWSW2NaLqDu3MHHYk7eZDBY9CRlmiPZzH6JHwFZaQNHAFPBBU8pTkM7tpg9FFwQ1agP0FSzjPYBbOgB+Q62Y6JXnAZXkNSnGuO4TN4XB7JWfqRNKAzDJ7DNUiKG/IRw054Aash+jC6KTGsmmIZAblOdmWiGfi1HjndWCbT07EdaI/C3fGHGYbi7poEtxkZy6hY/OCJjJzfis7OY6okOprr5HiW6tx1dCRm4DwGi2A5bIYbsB+SYpi0wnAaks4zDPzoGXTc5UPoP4knGc97BPGATkPoB8bSOvQJuAlmt7HUjb6ZV+iYonj0uFiakr6M2sIlMEZRuVIXq4mFCsKcyDppVvoyM3M0q8aCX7USvQDMZlSu+IHGkDuVjUcf6GkD98CYRuVKZ6xWgydo86LScUfxeIYFHjkqcFfNVF88U0MBLFUed148Jh/xx5PjbH8KBnPCkvSAfiUno3i0DDgfYSmoz8CsROWK9a5QPPrAW5sq6MS8J2ap2kDfDUo5aX0cwES2PmIKLCvq9zYFiNbkxaOPXKExtoegrQyolJichpW7OIcZ6zEqSDnp7eBuGAeWi3ABjS90h+jGsoqeu44Kpap4dNEFGkuXN8og+kmxvm7D4OUgqZM0cbz6HrLgKliXvJvNPmMDU2Bs7qbzA3y5V6DH4rVmYXbtB+bGgB9jRroLXp2YYvE9SxhtAW+btWj/qbCoW0F8h5XFj2Hqt+jkKYbuYgU6wiQwwzGFso+2DXhdmb1ehW8YzwXt0XNq72Nvpo3MZcUrcBlG73uvUrqBSWlp85254aSTLiwGk8a726LsjxXzTKE175jQOTPYo7VyYMqXv3Ey/w3/wFp2slSbXN7JUu3kLwAAAP//SyqraQAAAAZJREFUAwAKC7AxYJHKaQAAAABJRU5ErkJggg==>

[image3]: <data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADMAAAAYCAYAAABXysXfAAADv0lEQVR4AeyWWaiNURTHj6lwzWTKLHHNkpC5RHkUL8oDnpQnTyIUj16UJyTJkzLmgQcyC5HMU2TKVMiUa7iu3+/07a99vvO5zuO9t3ta/732Xnvtffbaa9hfy0IT+jUb01Cd2aQ9M4dbfw3qInyg/w4o+wrfCjqBLK1H4Lx6Aa6di1xaTvO8QtxEbwxYAdwj7Cf3fLXIf4LjYCZoAQpZz5xC2AfsAr/BDNAN9AQucOES+vtBBxDTZga9wRngAUbCXXsC3g4sAvvAJDAAVIOHoCNYAJQNha8B6n+Ee47+8JPgDXDe87Wi3xlcBZ55IbzMGGVuPpyOt/gIHpN/fheBtz0FniWNdu0tJl6AQB7iLYMNQA4r9KIZBW6Ap0D6RePhrsA/AakrzQhwB4S1dAvfaQ6BGrASVGU9g6zQj8ZbvQ5/D2Jqw6AK6GY3oVtCoxnpnQtwQw5WpKm0/rEHoFskjc7T1St6IazXkL6suAy+gZgGMmgPfoDaPGOGMWF4XIQbarCU3Hgso2vA24eV0ORkdD7hstY2QANhKU1Peh4y6RaZ+v63+aFgog3QY7CU1FvM6A/YDmryjDGENEJXo5OSMWpefEayCoQwoFskc2gaPW/1ATyQe+1kEHtZ72q4ureZi8lQPpAI2sLNU8PrCf1Arl/HYB4wh4/Cy3LGA3nzWmsc7kBJ7IHfA+bBBLiJByuhkC/Z2C5RSgYhXzTaSpmIy1h3JOaVh99N/zQwl7/ArWYWDYtK0YtZz1g5LIlnUV4LNiawwgyhvwy8BHkU8sWwycZ2Vj/oGnohN7I6jq14Hngbg1lgNrCYeLmr6Q8CKWWNCflifD5Dy5oekJfwqKRk2DiI88VxHoKuhufNB5n54pMQ72nFO4hCDzAfpJQ1xnzRZdl8SRf8o2N45uVLnnqsm82XWD/ki3llOMZz4Vkwl1J5bIzvi/lgTJofqVIFnZAv/ml9OeBWlep68+NYkM1BjRyPXLIYyYuIjbFmG8sujitPUfE/jevy3oy8ZZXqqpf3vmiMhoa9LdHmVLXG+MlifvhudEHDT4tXcL+LYPXSJmb1xBG4ZNGwQPiN5zjA/3jMwGSPdf3suYTchxpWpKW07nkMbr64p18i5g+igk9CKN2WbZ8JPXRfY86hoVdcGOCj6XcRU/WSnyeGTVgn92AWkHih/2EVMl/UCfB/jH8vIOjvpZPd08LkQ81UwZzeQmcwsBr6THiOOo1B1uhIg/yeO8zJrXR+XpU9msw1TvLUjdUznr0MzcaUXUkDETQpz/wFAAD//yiQUSEAAAAGSURBVAMAF+PWMVa0CBIAAAAASUVORK5CYII=>

[image4]: <data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADEAAAAYCAYAAABTPxXiAAADgUlEQVR4AeyWSchOXxzH7/9vyBSReQoZMmXMFMWSBQsbc8LCggVFigUrFqKUskBkKDtTsRHJkMwZQso8Zp6n4vO5Om/nuc97X1eSN3n6fu455/c7z73nd4bfvf8nf8HvXxDVZRH/5EpMYBJGwy/LIJpyl+PwNeIB9QHQFs5C7LtGuyuoKVxi3y7a9eFH6kyHVdAP8jQTxxuI7297E7Y6UCGDeEJrKCwCNZdLKzgNd8EHLaZU47kYgIFQTbZy6QMHoSOMg7dQlWri9Fk+oxv1PG3A0QIOwAvoDQ1gOnyAChlEaDhg61XNZF07RPxHfSwsh5tQRKPoNAS+gM8yKKqVyiB64jkPufePg3hFR1XDS0QH6i4tReL2sgz0oNIQDkEROZOz6DgP7oNbuWRrYIvViYaBHKV0K1GUKw7iPW73X7zEzrQP3YMvK2fQM7EZx2coIvufouNFUK5ELSs5uGqO4USOPzXHQTzHYiAUFepPzcEeplTOvKV4jly9yzYK0I4+I2AjvIYb0BzyVkJ7X/wPIQRNtVxxEMHbhkqYoWnU18MteAdBbotJNDzYrh7VKuVszqHHDngKQbWpZM8ZplStuTqJlygfQa7iINyjZipn3oeO5F/O1nXKoBCgWegcxjtQRIPo1AT2gTK7+CzPU2MNlRDOg1upsoxXj/+k5zcOAlsqV6EltYmwHZSr4IMNUN8wjNugiJzpJXT0bH2idOU8Q6ZrfXlBhPNwhP9k5f/MiCaGJA7CQT6mt/t0MqWzZptqYp42Oxi5vp1Jktim+KFMwSfp5bNc4YDvCusOCHeJnMjBWDwPVymzGojhI6Tj88bUUzk7LpsHsDuWvZDVcAz6iqZUU7Izvo7/uQIUZepSZkkS06rvBwNIBxr1aUR9IeyG9J5xEBp8ARnMWjrEmSpkE7fVSnz2oahS9fEuAw9mdiCYE8+bZWUpthcOt232/WD6d4s3w38BUsVBuAr3sG4Bv6UoyuT3zpkya6nB1Og93G4zcC2F1RDk54OfLWYqbSu43AbP2WxKA/YbjGqygIs+k46TfIX2GNgPLyFVHISGNVzcq64I1Qo5oPm0HIw3o5orz9ZUvO73gG9oTKmcQb+/gs+yPZ5j4LbzTGoTU7A+063tgBND9+/KBuFHn6nvu7f06go8KzVVj1Y2iOoxqp8cRXUOonAo/4IoPFW/ueNfsRLfAAAA//8A5x9oAAAABklEQVQDAP9lqDERe1KPAAAAAElFTkSuQmCC>
