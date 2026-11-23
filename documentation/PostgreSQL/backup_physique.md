# PostgreSQL Data Protection Architecture and Strategies: Physical vs. Logical Backup Solutions

Data resilience in modern PostgreSQL ecosystems is an engineering requirement driven by growing data volumes and shrinking maintenance windows. As databases routinely exceed the terabyte scale, DBAs must balance the limits of native tools against third-party backup orchestrators. Choosing a backup architecture directly determines Recovery Point Objective (RPO) and Recovery Time Objective (RTO). This guide analyzes physical backup tools (`pg_basebackup`, `pgBackRest`, `WAL-G`, `pg_probackup`, and `Barman`) alongside traditional logical backups.

## Physical Backup Foundations: `pg_basebackup`

`pg_basebackup` is the built-in cornerstone of PostgreSQL physical backups. Shipped natively with PostgreSQL, it guarantees immediate compatibility across every major version with zero external dependencies. It creates a consistent binary cluster copy required for streaming replication or Point-In-Time Recovery (PITR).

### Mechanisms and Replication Protocol

`pg_basebackup` uses the PostgreSQL replication protocol to transfer data files while streaming Write-Ahead Logs (WAL) for crash-consistent recovery. Although PostgreSQL 17 introduced native incremental backups, `pg_basebackup` remains low-level: it has no built-in catalog and requires external orchestration for retention and rotation.

## `pgBackRest`: Enterprise-Grade Backup Orchestrator

Designed for multi-terabyte databases, `pgBackRest` is the standard solution for mission-critical workloads. Its architecture addresses `pg_basebackup` gaps using a custom protocol and advanced parallelism.

### Parallel Execution and Compression Optimization

`pgBackRest` distributes extraction, compression (`lz4`, `zstd`), and checksum verification across multiple processes. It validates page-level checksums during backup to detect storage corruption before older valid backups expire. Multi-repository support (such as local storage for fast RTO and S3 for retention) makes it highly flexible.

## `WAL-G`: Cloud-Native Streaming Backup

`WAL-G` is the Go successor to `WAL-E`. Built for speed, it is widely used in Kubernetes and cloud environments for lightweight streaming directly to object storage.

Using Go concurrency (`goroutines`), it streams directly to S3, GCS, or Azure without intermediate local storage. `WAL-G` supports block-level delta backups, reducing backup duration and network bandwidth by transferring only modified pages.

## `pg_probackup`: Granular Incremental Control and Block Performance

Developed by Postgres Professional, `pg_probackup` minimizes production I/O overhead.

### Incremental Modes and Backup Merging

It provides three incremental modes: `DELTA`, `PAGE` (WAL scan), and `PTRACK` (kernel-extension change tracking). Its `merge` feature folds incremental backups into a parent full backup without full disk reads. Like `pgBackRest`, it supports backup integrity validation (`validate`) and online instance verification (`checkdb`).

## `Barman`: Centralized Enterprise Backup Management

`Barman` (Backup and Recovery Manager) is a Python tool designed for centralized management of many PostgreSQL instances from a single pull-model server.

### Architecture and Versatility

`Barman` supports transfers over `rsync` or PostgreSQL streaming replication and offers high visibility through a centralized catalog. While it supports parallelism and cloud object storage (`barman-cloud`), it cannot resume an interrupted backup like `pgBackRest`. It remains well suited for complex on-premises topologies managed by traditional DBA teams.

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
