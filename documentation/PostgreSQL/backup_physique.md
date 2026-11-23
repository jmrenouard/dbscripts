# **Architecture et Stratégies de Protection des Données PostgreSQL : Analyse Comparative des Solutions de Sauvegarde Physique et Logique**

La résilience des données au sein des écosystèmes PostgreSQL modernes n'est plus une simple question d'archivage, mais un impératif d'ingénierie complexe dicté par l'explosion des volumes de données et la réduction drastique des fenêtres de maintenance.1 Alors que les bases de données franchissent régulièrement le seuil du téraoctet, les administrateurs de bases de données (DBA) doivent naviguer entre les limitations des outils natifs et la sophistication des solutions tierces.3 Le choix d'une architecture de sauvegarde influence directement l'objectif de point de rétablissement (RPO) et l'objectif de temps de rétablissement (RTO).1 Ce rapport propose une analyse exhaustive des outils de sauvegarde physique — pg\_basebackup, pgBackRest, WAL-G, pg\_probackup et Barman — tout en les comparant aux méthodes de sauvegarde logique traditionnelles.

## **Fondations de la Sauvegarde Physique : L'Utilitaire pg\_basebackup**

L'outil pg\_basebackup constitue la pierre angulaire de la sauvegarde physique dans l'écosystème PostgreSQL. Intégré nativement, il garantit une compatibilité immédiate avec chaque version majeure sans nécessiter de dépendances externes.6 Son rôle est de créer une copie binaire cohérente d'un cluster, servant de base indispensable pour la réplication ou la restauration à un instant précis (PITR).4

### **Mécanismes et Protocole de Réplication**

Le fonctionnement de pg\_basebackup repose sur le protocole de réplication de PostgreSQL. Il établit une connexion de réplication pour transférer les fichiers de données tout en garantissant la cohérence via le streaming des journaux de transaction (WAL).4 Bien que PostgreSQL 17 ait introduit les sauvegardes incrémentales natives, l'outil reste de bas niveau : il ne possède pas de catalogue intégré, nécessitant une orchestration externe pour la rétention et la rotation.2

## **pgBackRest : L'Orchestrateur de Sauvegarde de Classe Entreprise**

Conçu pour les bases de données de plusieurs téraoctets, pgBackRest est la solution de référence pour les environnements critiques.10 Son architecture comble les lacunes de pg\_basebackup grâce à un protocole personnalisé et une gestion avancée du parallélisme.11

### **Parallélisation Massive et Optimisation de la Compression**

pgBackRest distribue la charge de travail sur plusieurs processus pour l'extraction, la compression (lz4, zstd) et le calcul des sommes de contrôle.11 Il supporte la validation des checksums au niveau de la page durant la sauvegarde, permettant de détecter les corruptions matérielles avant que les sauvegardes valides ne soient expirées.11 Sa capacité à gérer plusieurs dépôts (ex: local pour le RTO, S3 pour la rétention) en fait un outil extrêmement flexible.10

## **WAL-G : L'Evolution Cloud-Native**

WAL-G est la réimplémentation en Go de WAL-E. Conçu pour la vitesse, il est particulièrement prisé dans les environnements Kubernetes et cloud pour sa simplicité et ses performances brutes de streaming vers le stockage objet.3

Il utilise des goroutines pour une gestion concurrente efficace et privilégie un transfert direct vers S3, GCS ou Azure sans stockage local intermédiaire.3 WAL-G supporte des sauvegardes "delta" au niveau du bloc, réduisant drastiquement le temps de sauvegarde et la bande passante consommée en ne transférant que les pages modifiées.3

## **pg\_probackup : Précision Chirurgicale et Performance de Blocs**

Développé par Postgres Professional, pg\_probackup se distingue par son approche axée sur la réduction de l'impact I/O sur les serveurs de production.19

### **Modes Incrémentaux et Fusion de Sauvegardes**

L'outil propose trois modes incrémentaux : DELTA, PAGE (scan des WAL) et PTRACK (suivi des modifications via une extension noyau).19 Une fonctionnalité majeure est la fusion de sauvegardes ("merge"), qui permet d'intégrer une sauvegarde incrémentale dans sa parente pour créer une nouvelle base complète sans lecture totale du disque.21 Comme pgBackRest, il offre des fonctions de validation d'intégrité (validate) et de vérification d'instance en ligne (checkdb).19

## **Barman : La Gestion Centralisée pour l'Entreprise**

Barman (Backup and Recovery Manager) est une solution Python conçue pour la gestion centralisée de nombreux serveurs PostgreSQL depuis un point unique ("pull model").22

### **Architecture et Polyvalence**

Barman supporte le transfert via rsync (historique) ou via le protocole postgres (streaming).22 Il excelle dans la visibilité grâce à son catalogue centralisé. S'il supporte le parallélisme et l'intégration cloud (via barman-cloud), sa principale limite reste l'impossibilité de reprendre une sauvegarde interrompue (resume), contrairement à pgBackRest.22 Il est cependant l'outil de prédilection pour les infrastructures "on-premise" complexes gérées par des équipes de DBA traditionnelles.3

## **Comparaison des Outils Physiques sur la Base des Critères pgBackRest**

Le tableau suivant synthétise les capacités de chaque solution selon les standards d'exigence définis par pgBackRest.

| Critères de Comparaison | pg\_basebackup | pgBackRest | WAL-G | pg\_probackup | Barman |
| :---- | :---- | :---- | :---- | :---- | :---- |
| **Parallélisme (Backup/Restore)** | Limité 7 | Complet 11 | Complet 15 | Complet 19 | Oui (v2.2+) |
| **Compression (lz4, zstd)** | Supporté 7 | Natif 11 | Natif 15 | Supporté 19 | gzip, lz4, zstd |
| **Opération Distante** | Réplication 7 | TLS/SSH custom 11 | SSH / Cloud 3 | SSH natif 21 | SSH / Réplication |
| **Dépôts Multiples** | Non | Supporté 11 | Expérimental 25 | Via Catalogue 19 | Géo-redondance |
| **Sauvegarde Incrémentale** | Bloc (v17+) 7 | Bloc 11 | Page (Delta) 3 | Page / Ptrack 19 | Fichier / Bloc |
| **Rétention / Expiration** | Manuel | Auto 11 | Auto 26 | Flexible 19 | Centralisée |
| **Intégrité (Checksums)** | Non 7 | Systématique 11 | Flag verify 27 | Validation 19 | barman check |
| **Page Checksums** | Non | Validation live 14 | Flag verify 27 | checkdb 21 | Via PG |
| **Reprise de Sauvegarde** | Non | Oui (Resume) 11 | Upload partiel 17 | Non 23 | Non 22 |
| **Restauration Delta** | Non | Oui 14 | Oui 17 | Oui 21 | Non (Full) 3 |
| **WAL Push/Get Asynchrone** | Non | Oui 11 | Oui 17 | Non 21 | Oui 22 |
| **Tablespace / Liens** | Supporté 7 | Complet (Remap) 11 | Partiel 28 | Supporté 22 | Supporté (Remap) |
| **Stockage Objet (S3/Azure)** | Manuel / v17+ | Natif 11 | Natif 3 | Version Pro 21 | barman-cloud |
| **Chiffrement** | Non | AES-256 11 | GPG/Libsodium 15 | AES-256 29 | Externe (GPG) |
| **Compatibilité Versions** | Toutes | 10 dernières 11 | 9.5+ 30 | 11+ 21 | Multi-versions |

## **Sauvegarde Physique vs Sauvegarde Logique (pg\_dump / pg\_dumpall)**

Pour une stratégie complète, il faut distinguer ces outils physiques de la sauvegarde logique représentée par pg\_dump (une base) et pg\_dumpall (tout le cluster incluant rôles et tablespaces).31

### **Avantages de l'Approche Logique**

* **Indépendance et Portabilité** : Les dumps SQL peuvent être restaurés sur des versions plus récentes ou des architectures CPU différentes.2  
* **Granularité** : Permet de restaurer une seule table ou un schéma spécifique.2  
* **Taille** : Souvent 20% à 50% plus petits car ils n'incluent pas les index et éliminent le "bloat".2

### **Limitations Critiques**

* **Performance** : La restauration est extrêmement lente (reconstruction des index, validation des contraintes).2 Pour 1 To, là où un restore physique prend 2h, un restore logique peut prendre 30h.4  
* **Pas de PITR** : Un dump est une photo fixe. Seule la sauvegarde physique permet de restaurer à une seconde précise entre deux sauvegardes.1

## **Recommandations Opérationnelles**

1. **Priorité Cloud/Kubernetes** : **WAL-G** est le choix stratégique pour son architecture légère et son intégration S3 native.3  
2. **Gestion Multi-Serveurs Classique** : **Barman** reste idéal pour centraliser la sécurité de dizaines d'instances "on-premise".24  
3. **Bases de Données Géantes (\>1 To)** : **pgBackRest** ou **pg\_probackup** (avec PTRACK) sont nécessaires pour leurs performances de parallélisme et de gestion des blocs modifiés.11  
4. **Tests et Migrations** : **pg\_dump** demeure indispensable pour les montées de version et les environnements de développement.4

En 2026, la meilleure stratégie est hybride : sauvegarde physique quotidienne pour le RTO, archivage WAL pour le PITR, et dumps logiques hebdomadaires pour la flexibilité.1
