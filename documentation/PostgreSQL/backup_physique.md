# **Architecture et Stratégies de Protection des Données PostgreSQL : Analyse Comparative des Solutions de Sauvegarde Physique et Logique**

La résilience des données au sein des écosystèmes PostgreSQL modernes n'est plus une simple question d'archivage, mais un impératif d'ingénierie complexe dicté par l'explosion des volumes de données et la réduction drastique des fenêtres de maintenance.1 Alors que les bases de données franchissent régulièrement le seuil du téraoctet, les administrateurs de bases de données (DBA) doivent naviguer entre les limitations des outils natifs et la sophistication des solutions tierces.3 Le choix d'une architecture de sauvegarde influence directement l'objectif de point de rétablissement (![][image1]) et l'objectif de temps de rétablissement (![][image2]).1 Ce rapport propose une analyse exhaustive des outils de sauvegarde physique — pg\_basebackup, pgBackRest, WAL-G, pg\_probackup et Barman — tout en les comparant aux méthodes de sauvegarde logique traditionnelles.

## **Fondations de la Sauvegarde Physique : L'Utilitaire pg\_basebackup**

L'outil pg\_basebackup constitue la pierre angulaire de la sauvegarde physique dans l'écosystème PostgreSQL. Intégré nativement, il garantit une compatibilité immédiate avec chaque version majeure sans nécessiter de dépendances externes.6 Son rôle est de créer une copie binaire cohérente d'un cluster, servant de base indispensable pour la réplication ou la restauration à un instant précis (![][image3]).4

### **Mécanismes et Protocole de Réplication**

Le fonctionnement de pg\_basebackup repose sur le protocole de réplication de PostgreSQL. Il établit une connexion de réplication pour transférer les fichiers de données tout en garantissant la cohérence via le streaming des journaux de transaction (![][image4]).4 Bien que PostgreSQL 17 ait introduit les sauvegardes incrémentales natives, l'outil reste de bas niveau : il ne possède pas de catalogue intégré, nécessitant une orchestration externe pour la rétention et la rotation.2

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
15. wal-g/wal-g: Archival and Restoration for databases in the Cloud \- GitHub, consulté le mai 6, 2026, [https://github.com/wal-g/wal-g](https://github.com/wal-g/wal-g)  
16. Top Open-Source Postgres Backup Solutions in 2026 \- Bytebase, consulté le mai 6, 2026, [https://www.bytebase.com/blog/top-open-source-postgres-backup-solution/](https://www.bytebase.com/blog/top-open-source-postgres-backup-solution/)  
17. PostgreSQL \- WAL-G \- Read the Docs, consulté le mai 6, 2026, [https://wal-g.readthedocs.io/PostgreSQL/](https://wal-g.readthedocs.io/PostgreSQL/)  
18. J.7. wal-g — Tantor Special Edition 16.13 documentation, consulté le mai 6, 2026, [https://docs.tantorlabs.ru/tdb/en/16\_13/se/wal-g.html](https://docs.tantorlabs.ru/tdb/en/16_13/se/wal-g.html)  
19. Postgres Pro Standard : Documentation: 18: pg\_probackup, consulté le mai 6, 2026, [https://postgrespro.com/docs/postgrespro/current/app-pgprobackup](https://postgrespro.com/docs/postgrespro/current/app-pgprobackup)  
20. If not pgBackRest, then what? Rethinking PostgreSQL Backups in 2026 | by Tomasz Gintowt, consulté le mai 6, 2026, [https://tomasz-gintowt.medium.com/if-not-pgbackrest-then-what-rethinking-postgresql-backups-in-2026-3b8e36d5ec84?source=rss-------1](https://tomasz-gintowt.medium.com/if-not-pgbackrest-then-what-rethinking-postgresql-backups-in-2026-3b8e36d5ec84?source=rss-------1)  
21. Postgres Pro Enterprise : Documentation: 18: pg\_probackup, consulté le mai 6, 2026, [https://postgrespro.com/docs/enterprise/current/app-pgprobackup](https://postgrespro.com/docs/enterprise/current/app-pgprobackup)  
22. The Current State of Open Source Backup Management for PostgreSQL \- Severalnines, consulté le mai 6, 2026, [https://severalnines.com/blog/current-state-open-source-backup-management-postgresql/](https://severalnines.com/blog/current-state-open-source-backup-management-postgresql/)  
23. GitHub \- postgrespro/pg\_probackup: Backup and recovery manager ..., consulté le mai 6, 2026, [https://github.com/postgrespro/pg\_probackup](https://github.com/postgrespro/pg_probackup)  
24. Top 5 PostgreSQL backup tools in 2026 | by Rostislav Dugin \- Medium, consulté le mai 6, 2026, [https://medium.com/@rostislavdugin/top-5-postgresql-backup-tools-in-2025-82da772c89e5](https://medium.com/@rostislavdugin/top-5-postgresql-backup-tools-in-2025-82da772c89e5)  
25. J.7. wal-g — Tantor Special Edition 15.17 documentation, consulté le mai 6, 2026, [https://docs.tantorlabs.ru/tdb/en/15\_17/se/wal-g.html](https://docs.tantorlabs.ru/tdb/en/15_17/se/wal-g.html)  
26. PostgreSQL Backups: WAL-G \- GitLab Runbooks, consulté le mai 6, 2026, [https://runbooks.gitlab.com/patroni/postgresql-backups-wale-walg/](https://runbooks.gitlab.com/patroni/postgresql-backups-wale-walg/)  
27. From Backup to Integrity: Leveraging WAL-G for PostgreSQL \- Data Egret, consulté le mai 6, 2026, [https://dataegret.com/2024/11/from\_backup\_to\_integrity\_leveraging\_wal-g\_for\_postgresql/](https://dataegret.com/2024/11/from_backup_to_integrity_leveraging_wal-g_for_postgresql/)  
28. Documentation for tablespace support? · Issue \#631 · wal-g/wal-g \- GitHub, consulté le mai 6, 2026, [https://github.com/wal-g/wal-g/issues/631](https://github.com/wal-g/wal-g/issues/631)  
29. pg\_probackup download | SourceForge.net, consulté le mai 6, 2026, [https://sourceforge.net/projects/pg-probackup.mirror/](https://sourceforge.net/projects/pg-probackup.mirror/)  
30. Ecosystem:Backup \- PostgreSQL wiki, consulté le mai 6, 2026, [https://wiki.postgresql.org/wiki/Ecosystem:Backup](https://wiki.postgresql.org/wiki/Ecosystem:Backup)  
31. PostgreSQL Backup \- pg\_dump & pg\_dumpall \- Neon, consulté le mai 6, 2026, [https://neon.com/postgresql/administration/backup-database](https://neon.com/postgresql/administration/backup-database)  
32. Best Open Source Tools for PostgreSQL Backup and Restore |…, consulté le mai 6, 2026, [https://vela.simplyblock.io/articles/best-open-source-postgresql-backup-restore-tools/](https://vela.simplyblock.io/articles/best-open-source-postgresql-backup-restore-tools/)

[image1]: <data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACoAAAAYCAYAAACMcW/9AAADeklEQVR4AeyWWahOURSAzzVlnsk8PJiHzJRMmRIpEUqSiCceCIXyYHhAHjxIipQ8EC+UB5RZITMhETKHzGT+vtM9v3POf/7bVTdR97a+s/Ze65xz19l7rbX/CsF/8lceaFlv1L+yopX5sC4wCUZBHUhIOtBheJ/AzxjPGX+B73AGJkJFiEtDJsfAe6JnfeZhsU27/s7M41KbyTq4CRNA6cflLmivhg4lHegRrE1hK3yDQdAYqhSjfTfjhVAEkbxgMATGgbKGi8+0QPtR9dDv4RT0BKUHl/Ogvyt6FewB9Rj0bNgAlSBIB6qtFpcO8ABuQySuyn4mrtJctB+ASkgUxMmENQjeMj8OdWEm9IFD4MIsQX+CuJxlsgOmQkcIsgJ1Fdyii9zwEuKirxGGz2DgqJxUZTQQnsItSIvbrO0Hl+3wDJbDV8gS08wP852ZgbbjqfrgF7v9DHMylpF5sw3tdqNy0oCRBXEdbRConFgcw5mZt469bzNz8x9VohhsZqAjeMwA/YcMQ7EqZzGaB4thI6SlE4ZW4Ep8QEdiLpsqFsl6jCPBVT+ALknc1Zw/vfU18XQHK3ct+ijcAFfCvGrP2GrM2q7e+AyqL3pLjAuMJ8NQMPeao7U9RhcS08hi0x/WSTrQlni6wT4YDL7cL1vKeA70gizxxd7/GudKWBHDludHWkxhYeC7A+Y5KlPaYh0Aj8Baydv6KD9Pc4Pbjwpc3YMMfPEUdJZE+XkN5yWwF0cYPKaEGEDCkJqMZ26d2K7uMc4LNMpPt0h/hCtRnUm6SDCFEuWnX/8utGRfsoJO39kGg7vnIWBOu1CJQO2f9sF0/+S5oL8XsB+i8sRCMT8P53mShitMzXfzOGzkzONi0ZpmruYMHPZsVJAItDUWTwhXJd4/fWETfHFZxsTVRwW2K/PzFZMw8dGF5BwOW5snj8XHNCc1GFmEnvWS2FWLyWPyPjddBXuWZ7kVaZ5gCszVXQxs1L58OmO3x25gr33DfDS4CpfRO8E0QeWJ71qAdRN4Kq1G+0PExu/7TBu7jh+E67cY6AmmrmYROsLj0crHFMpers3AY80eOJ+xBWFP9EyPnnM8Dd9HKCQel4tw+pvCHyoMA4vV1ud7M9PLQL2xNFhInvWuov+sNM+UdI87YYBWtttsVyl4/58EWvAlf8NRHmhZr3L5ipb1iv4CAAD//1FB3VwAAAAGSURBVAMAMIuxMQcp+G0AAAAASUVORK5CYII=>

[image2]: <data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACkAAAAYCAYAAABnRtT+AAADYUlEQVR4AeyWWahOURSAzzVlJmWek3nITJlLIqVEeBFFPPFAKDzyYnrwIClSnogSpVCGhBDKLEPIHBmLzN936hznnHt+91d/cuu/rW+vvdfe5/zr7L3W2rdGUA3+yk6W6pD+h52szcf0hukwAZpASrJOjmP2GfxM8JL+F/gO52Aa1ASlBc0xeFQkm1gXSWM66+EWTAVlKM190F4PHUrWyeNYW8N2+AajQEfqoEX7HvpLoQIGgutno7tAB1gI7eEAdARtw9F34RUo/Wkugh/bB70G9oJ6Eno++EG10EHWSW2NaLqDu3MHHYk7eZDBY9CRlmiPZzH6JHwFZaQNHAFPBBU8pTkM7tpg9FFwQ1agP0FSzjPYBbOgB+Q62Y6JXnAZXkNSnGuO4TN4XB7JWfqRNKAzDJ7DNUiKG/IRw054Aash+jC6KTGsmmIZAblOdmWiGfi1HjndWCbT07EdaI/C3fGHGYbi7poEtxkZy6hY/OCJjJzfis7OY6okOprr5HiW6tx1dCRm4DwGi2A5bIYbsB+SYpi0wnAaks4zDPzoGXTc5UPoP4knGc97BPGATkPoB8bSOvQJuAlmt7HUjb6ZV+iYonj0uFiakr6M2sIlMEZRuVIXq4mFCsKcyDppVvoyM3M0q8aCX7USvQDMZlSu+IHGkDuVjUcf6GkD98CYRuVKZ6xWgydo86LScUfxeIYFHjkqcFfNVF88U0MBLFUed148Jh/xx5PjbH8KBnPCkvSAfiUno3i0DDgfYSmoz8CsROWK9a5QPPrAW5sq6MS8J2ap2kDfDUo5aX0cwES2PmIKLCvq9zYFiNbkxaOPXKExtoegrQyolJichpW7OIcZ6zEqSDnp7eBuGAeWi3ABjS90h+jGsoqeu44Kpap4dNEFGkuXN8og+kmxvm7D4OUgqZM0cbz6HrLgKliXvJvNPmMDU2Bs7qbzA3y5V6DH4rVmYXbtB+bGgB9jRroLXp2YYvE9SxhtAW+btWj/qbCoW0F8h5XFj2Hqt+jkKYbuYgU6wiQwwzGFso+2DXhdmb1ehW8YzwXt0XNq72Nvpo3MZcUrcBlG73uvUrqBSWlp85254aSTLiwGk8a726LsjxXzTKE175jQOTPYo7VyYMqXv3Ey/w3/wFp2slSbXN7JUu3kLwAAAP//SyqraQAAAAZJREFUAwAKC7AxYJHKaQAAAABJRU5ErkJggg==>

[image3]: <data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADMAAAAYCAYAAABXysXfAAADv0lEQVR4AeyWWaiNURTHj6lwzWTKLHHNkpC5RHkUL8oDnpQnTyIUj16UJyTJkzLmgQcyC5HMU2TKVMiUa7iu3+/07a99vvO5zuO9t3ta/732Xnvtffbaa9hfy0IT+jUb01Cd2aQ9M4dbfw3qInyg/w4o+wrfCjqBLK1H4Lx6Aa6di1xaTvO8QtxEbwxYAdwj7Cf3fLXIf4LjYCZoAQpZz5xC2AfsAr/BDNAN9AQucOES+vtBBxDTZga9wRngAUbCXXsC3g4sAvvAJDAAVIOHoCNYAJQNha8B6n+Ee47+8JPgDXDe87Wi3xlcBZ55IbzMGGVuPpyOt/gIHpN/fheBtz0FniWNdu0tJl6AQB7iLYMNQA4r9KIZBW6Ap0D6RePhrsA/AakrzQhwB4S1dAvfaQ6BGrASVGU9g6zQj8ZbvQ5/D2Jqw6AK6GY3oVtCoxnpnQtwQw5WpKm0/rEHoFskjc7T1St6IazXkL6suAy+gZgGMmgPfoDaPGOGMWF4XIQbarCU3Hgso2vA24eV0ORkdD7hstY2QANhKU1Peh4y6RaZ+v63+aFgog3QY7CU1FvM6A/YDmryjDGENEJXo5OSMWpefEayCoQwoFskc2gaPW/1ATyQe+1kEHtZ72q4ureZi8lQPpAI2sLNU8PrCf1Arl/HYB4wh4/Cy3LGA3nzWmsc7kBJ7IHfA+bBBLiJByuhkC/Z2C5RSgYhXzTaSpmIy1h3JOaVh99N/zQwl7/ArWYWDYtK0YtZz1g5LIlnUV4LNiawwgyhvwy8BHkU8sWwycZ2Vj/oGnohN7I6jq14Hngbg1lgNrCYeLmr6Q8CKWWNCflifD5Dy5oekJfwqKRk2DiI88VxHoKuhufNB5n54pMQ72nFO4hCDzAfpJQ1xnzRZdl8SRf8o2N45uVLnnqsm82XWD/ki3llOMZz4Vkwl1J5bIzvi/lgTJofqVIFnZAv/ml9OeBWlep68+NYkM1BjRyPXLIYyYuIjbFmG8sujitPUfE/jevy3oy8ZZXqqpf3vmiMhoa9LdHmVLXG+MlifvhudEHDT4tXcL+LYPXSJmb1xBG4ZNGwQPiN5zjA/3jMwGSPdf3suYTchxpWpKW07nkMbr64p18i5g+igk9CKN2WbZ8JPXRfY86hoVdcGOCj6XcRU/WSnyeGTVgn92AWkHih/2EVMl/UCfB/jH8vIOjvpZPd08LkQ81UwZzeQmcwsBr6THiOOo1B1uhIg/yeO8zJrXR+XpU9msw1TvLUjdUznr0MzcaUXUkDETQpz/wFAAD//yiQUSEAAAAGSURBVAMAF+PWMVa0CBIAAAAASUVORK5CYII=>

[image4]: <data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADEAAAAYCAYAAABTPxXiAAADgUlEQVR4AeyWSchOXxzH7/9vyBSReQoZMmXMFMWSBQsbc8LCggVFigUrFqKUskBkKDtTsRHJkMwZQso8Zp6n4vO5Om/nuc97X1eSN3n6fu455/c7z73nd4bfvf8nf8HvXxDVZRH/5EpMYBJGwy/LIJpyl+PwNeIB9QHQFs5C7LtGuyuoKVxi3y7a9eFH6kyHVdAP8jQTxxuI7297E7Y6UCGDeEJrKCwCNZdLKzgNd8EHLaZU47kYgIFQTbZy6QMHoSOMg7dQlWri9Fk+oxv1PG3A0QIOwAvoDQ1gOnyAChlEaDhg61XNZF07RPxHfSwsh5tQRKPoNAS+gM8yKKqVyiB64jkPufePg3hFR1XDS0QH6i4tReL2sgz0oNIQDkEROZOz6DgP7oNbuWRrYIvViYaBHKV0K1GUKw7iPW73X7zEzrQP3YMvK2fQM7EZx2coIvufouNFUK5ELSs5uGqO4USOPzXHQTzHYiAUFepPzcEeplTOvKV4jly9yzYK0I4+I2AjvIYb0BzyVkJ7X/wPIQRNtVxxEMHbhkqYoWnU18MteAdBbotJNDzYrh7VKuVszqHHDngKQbWpZM8ZplStuTqJlygfQa7iINyjZipn3oeO5F/O1nXKoBCgWegcxjtQRIPo1AT2gTK7+CzPU2MNlRDOg1upsoxXj/+k5zcOAlsqV6EltYmwHZSr4IMNUN8wjNugiJzpJXT0bH2idOU8Q6ZrfXlBhPNwhP9k5f/MiCaGJA7CQT6mt/t0MqWzZptqYp42Oxi5vp1Jktim+KFMwSfp5bNc4YDvCusOCHeJnMjBWDwPVymzGojhI6Tj88bUUzk7LpsHsDuWvZDVcAz6iqZUU7Izvo7/uQIUZepSZkkS06rvBwNIBxr1aUR9IeyG9J5xEBp8ARnMWjrEmSpkE7fVSnz2oahS9fEuAw9mdiCYE8+bZWUpthcOt232/WD6d4s3w38BUsVBuAr3sG4Bv6UoyuT3zpkya6nB1Og93G4zcC2F1RDk54OfLWYqbSu43AbP2WxKA/YbjGqygIs+k46TfIX2GNgPLyFVHISGNVzcq64I1Qo5oPm0HIw3o5orz9ZUvO73gG9oTKmcQb+/gs+yPZ5j4LbzTGoTU7A+063tgBND9+/KBuFHn6nvu7f06go8KzVVj1Y2iOoxqp8cRXUOonAo/4IoPFW/ueNfsRLfAAAA//8A5x9oAAAABklEQVQDAP9lqDERe1KPAAAAAElFTkSuQmCC>
