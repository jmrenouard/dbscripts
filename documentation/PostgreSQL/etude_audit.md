# Panorama des solutions d'audit et de traçabilité pour PostgreSQL

Les solutions d'audit et de traçabilité pour PostgreSQL se déclinent en plusieurs approches, chacune adaptée à des besoins spécifiques en matière de conformité, sécurité et surveillance des opérations. Ce panorama couvre les différentes versions de PostgreSQL (communauté open source), EnterpriseDB (EDB Postgres Advanced Server) et Percona Distribution for PostgreSQL.

## Solutions d'audit natives de PostgreSQL

PostgreSQL offre plusieurs mécanismes de traçabilité intégrés qui constituent la base de tout système d'audit.[1][2]

**Logging des connexions et déconnexions**

Les paramètres `log_connections` et `log_disconnections` permettent de tracer l'ensemble des connexions au serveur PostgreSQL. Lorsque `log_connections` est activé, trois types d'événements peuvent être enregistrés selon la configuration : `receipt` (réception de la connexion), `authentication` (authentification avec la méthode utilisée comme md5, scram-sha-256 ou trust), et `authorization` (autorisation avec l'utilisateur, la base de données et l'application). Ces logs fournissent également l'adresse IP du client et le fichier pg_hba.conf responsable de la décision d'authentification, facilitant ainsi le débogage de la sécurité.[2][3][4][1]

**Logging des requêtes SQL**

Le paramètre `log_statement` contrôle quelles catégories d'instructions SQL sont enregistrées. Les valeurs possibles sont :[5][2]

- `none` : aucun logging (valeur par défaut)
- `ddl` : enregistre toutes les opérations de définition de données (CREATE, DROP, ALTER)
- `mod` : comme ddl, plus les opérations de modification (INSERT, UPDATE, DELETE)
- `all` : enregistre toutes les requêtes SQL[5]

**Logging basé sur la durée d'exécution**

Le paramètre `log_min_duration_statement` permet de n'enregistrer que les requêtes dépassant un certain seuil de temps d'exécution. Cette approche est particulièrement utile pour identifier les requêtes non optimisées sans générer un volume excessif de logs. Une valeur de -1 désactive cette fonctionnalité, tandis qu'une valeur de 0 enregistre toutes les requêtes avec leur durée.[6][7][8]

**pg_stat_statements**

Cette extension intégrée collecte des statistiques d'exécution pour toutes les requêtes SQL exécutées par le serveur. Elle fournit des informations détaillées incluant le nombre d'exécutions, le temps total d'exécution, les temps minimum, maximum et moyen, ainsi que le nombre de lignes affectées. Bien qu'elle ne soit pas strictement un outil d'audit, elle est précieuse pour l'analyse de performance et peut compléter une stratégie d'audit globale.[9][10][11]

**pg_stat_activity**

Cette vue système offre une visibilité en temps réel sur toutes les connexions actives au serveur PostgreSQL. Elle permet de surveiller qui est connecté, quelles requêtes sont en cours d'exécution, l'état de chaque connexion (active, idle, idle in transaction), et depuis combien de temps. Cette vue est essentielle pour les audits de sécurité et la détection de patterns d'accès inattendus.[12][13][14][15]

## pgAudit : L'extension communautaire de référence

pgAudit est l'extension open source la plus utilisée pour l'audit PostgreSQL, offrant un niveau de détail et de granularité bien supérieur aux mécanismes natifs.[16][17][18]

**Fonctionnalités principales**

pgAudit fournit deux modes d'audit distincts :[19][20][21]

**Audit de session** : Permet de tracer des catégories entières d'opérations SQL via le paramètre `pgaudit.log`. Les catégories disponibles incluent READ (SELECT et COPY), WRITE (INSERT, UPDATE, DELETE, TRUNCATE), FUNCTION (appels de fonctions), ROLE (opérations sur les rôles et privilèges), DDL (toutes les instructions de définition de données), et MISC (commandes diverses).[20][19]

**Audit d'objets** : Offre un contrôle plus fin en auditant uniquement les opérations sur des objets spécifiques. Cette approche utilise le paramètre `pgaudit.role` pour désigner un rôle d'audit principal. Seules les opérations sur les objets pour lesquels ce rôle possède des privilèges sont enregistrées.[22][23][20]

**Paramètres de configuration clés**

- `pgaudit.log` : Définit les catégories d'instructions à auditer[21][19]
- `pgaudit.log_catalog` : Contrôle l'audit des opérations sur les tables système (pg_catalog)[21]
- `pgaudit.log_client` : Détermine si les messages d'audit sont visibles pour le client (psql, etc.)[21]
- `pgaudit.log_level` : Définit le niveau de sévérité des messages d'audit (log, notice, etc.)[19]
- `pgaudit.log_parameter` : Active l'enregistrement des paramètres des requêtes[19]
- `pgaudit.log_relation` : Enregistre les relations (tables) impliquées dans les requêtes DML[19]
- `pgaudit.log_statement_once` : Évite la duplication des logs pour les requêtes complexes[21]
- `pgaudit.role` : Spécifie le rôle d'audit pour l'audit d'objets[24][20]

**Installation et activation**

pgAudit nécessite d'être ajouté à `shared_preload_libraries` dans postgresql.conf, puis installé via `CREATE EXTENSION pgaudit`. L'extension doit être créée avant de configurer `pgaudit.log` pour assurer le bon fonctionnement des event triggers qui enrichissent l'audit DDL avec les types et noms d'objets.[25][16][19]

**Format des logs**

Les entrées d'audit générées par pgAudit sont préfixées par "AUDIT:" et incluent des métadonnées enrichies telles que le type d'audit (SESSION ou OBJECT), la classe de commande, et les détails de la requête. Ce format structuré facilite le parsing automatisé et l'indexation pour l'analyse.[26][16]

**Avantages et limitations**

pgAudit offre plusieurs avantages significatifs : filtrage granulaire des événements, format de log structuré et cohérent, possibilité de redaction des informations sensibles (via `pgaudit.log_parameter`), et conformité avec les exigences réglementaires comme HIPAA, GDPR et PCI-DSS. Cependant, selon la configuration, pgAudit peut générer un volume considérable de données et introduire un overhead de performance, particulièrement dans les environnements à fort trafic.[17][27][28][29][16][26][21]

## Solutions personnalisées avec triggers

Les triggers PostgreSQL permettent de créer des solutions d'audit sur mesure pour tracer les modifications de données au niveau des lignes.[30][31][32]

**Principe de fonctionnement**

Un trigger d'audit typique utilise une fonction PL/pgSQL qui s'exécute AFTER INSERT, UPDATE ou DELETE sur une table cible. La fonction capture l'ancienne valeur (OLD), la nouvelle valeur (NEW), le type d'opération (TG_OP), l'utilisateur, et l'horodatage, puis insère ces informations dans une table d'audit dédiée.[31][32][30]

**Approches d'implémentation**

Deux approches principales existent pour les tables d'audit :[33][31]

**Tables d'audit explicites** : Chaque table auditée possède sa propre table d'audit avec les mêmes colonnes, plus des métadonnées d'audit. Cette approche offre de meilleures performances pour les requêtes complexes et élimine le besoin de syntaxe JSONB.[34]

**Tables d'audit génériques** : Une seule table d'audit stocke les changements de toutes les tables auditées, utilisant JSONB pour stocker les données des lignes. Cette approche simplifie la gestion mais consomme environ deux fois plus d'espace et présente des performances inférieures pour les requêtes historiques fréquentes.[35][34]

**Exemple de code**

La solution audit-trigger 91plus, disponible sur GitHub et documentée sur le wiki PostgreSQL, fournit un framework complet et réutilisable. Elle utilise le type de données hstore pour capturer efficacement les changements et offre des fonctions pour activer facilement l'audit sur n'importe quelle table.[32][36][37]

**Limitations**

Les triggers ne peuvent pas auditer les opérations SELECT. De plus, ils ne capturent pas les instructions DDL ni les modifications sur les tables système. Pour ces cas d'usage, il faut combiner les triggers avec les event triggers (disponibles depuis PostgreSQL 9.3) ou avec pgAudit.[38][39][30]

## EDB Postgres Advanced Server : Audit intégré de niveau entreprise

EnterpriseDB propose EDB Postgres Advanced Server (EPAS), une version commerciale enrichie de PostgreSQL incluant des fonctionnalités d'audit avancées natives.[40][41][42]

**Fonctionnalités d'audit EDB**

EDB Audit Logging est directement intégré à EPAS, sans nécessiter l'installation d'extensions externes. Les capacités d'audit incluent :[41][43][40]

**Paramètres de configuration**

- `edb_audit` : Active l'audit et définit le format (csv, xml, ou json)[44][45][40]
- `edb_audit_connect` : Trace toutes les connexions (all, failed, none)[43][40]
- `edb_audit_disconnect` : Trace toutes les déconnexions[40][43]
- `edb_audit_statement` : Contrôle les catégories d'instructions SQL à auditer (ddl, dml, select, insert, update, delete, truncate, rollback, error, etc.)[44][40]
- `edb_audit_tag` : Ajoute une étiquette personnalisée à tous les logs d'audit[43]
- `edb_audit_directory` : Spécifie l'emplacement des fichiers d'audit[40]
- `edb_audit_rotation_day` : Configure la rotation quotidienne des fichiers d'audit[40]

**Formats de fichiers d'audit**

EDB supporte trois formats de sortie pour les logs d'audit :[46][47]

**CSV** : Format tabulaire avec colonnes délimitées, facile à importer dans des outils d'analyse.[46]

**XML** : Format structuré avec éléments et attributs XML, offrant une hiérarchie claire des données d'audit.[46]

**JSON** : Format moderne et structuré, optimal pour l'intégration avec des systèmes de monitoring et d'analyse modernes.[46]

Tous les formats incluent des informations complètes : horodatage, utilisateur, base de données, process ID, hôte distant, ID de session, requête SQL, type de commande, sévérité d'erreur, et tag d'audit.[46]

**Fonctionnalités avancées**

EDB Audit offre des capacités spécifiques absentes de la version communautaire PostgreSQL :[42][48][40]

- Audit au niveau des objets (tables, vues, fonctions, triggers)
- Redaction automatique des mots de passe dans les logs d'audit[49]
- Audit spécifique par base de données et par rôle[40]
- Filtrage par codes d'erreur SQL[41]
- Filtrage par command tags[41]
- Archivage automatique des logs d'audit[41]

**Postgres Enterprise Manager (PEM)**

PEM est l'outil de gestion d'EDB qui simplifie la configuration de l'audit via une interface graphique. Il permet de : configurer les attributs de logging, définir la fréquence de collecte des logs, spécifier les types d'activités à inclure, gérer la rotation des fichiers, et analyser les logs via un tableau de bord avec filtrage par timestamp, base de données, utilisateur et type de commande.[50]

## Percona Distribution for PostgreSQL

Percona propose une distribution PostgreSQL packagée avec des composants enterprise-grade pré-testés, incluant pgAudit comme solution d'audit principale.[51][52][53]

**Composants d'audit inclus**

La distribution Percona intègre plusieurs outils d'audit et de monitoring :[52][53][54][51]

**pgAudit** : Extension standard d'audit offrant un logging détaillé au niveau session ou objet.[54][51]

**pgAudit set_user** : Extension complémentaire fournissant une couche supplémentaire de logging et de contrôle lorsque des utilisateurs non privilégiés doivent s'élever temporairement à des rôles superuser ou propriétaires d'objets pour des tâches de maintenance.[51]

**pg_stat_monitor** : Alternative avancée à pg_stat_statements, collectant et agrégeant des statistiques PostgreSQL avec des informations d'histogramme pour une meilleure analyse de performance.[54][51]

**pgBadger** : Outil d'analyse de logs PostgreSQL non inclus par défaut mais recommandé et supporté.[53]

**pg_gather** : Script de collecte d'informations pour le diagnostic et le dépannage.[53]

**Avantages de la distribution Percona**

Percona teste tous les composants ensemble pour garantir leur compatibilité. La distribution est entièrement open source et gratuite, sans lock-in commercial. Elle offre un support communautaire robuste, avec des services de support professionnel optionnels couvrant PostgreSQL, MySQL, MongoDB et MariaDB depuis une source unique.[55][53]

**Configuration flexible**

Percona supporte la configuration dynamique directement depuis SQL via le fichier auto.conf (/var/lib/postgresql/16/main/postgresql.auto.conf), permettant des ajustements d'audit sans redémarrage du serveur dans de nombreux cas. Cependant, il faut éviter de mélanger les configurations entre ce fichier et le postgresql.conf principal.[56]

## Comparaison des solutions

**PostgreSQL communautaire vs EDB vs Percona**

Les trois versions offrent des capacités d'audit, mais avec des différences significatives :[42][55][53]

| Aspect | PostgreSQL Community | EDB Postgres Advanced Server | Percona Distribution |
|--------|---------------------|------------------------------|---------------------|
| Audit natif | Logging de base (log_statement, log_connections) | EDB Audit intégré (csv, xml, json) | Logging de base + pgAudit pré-packagé |
| Extension d'audit | pgAudit (installation manuelle) | EDB Audit (natif) + pgAudit compatible | pgAudit + set_user (pré-testé) |
| Formats de sortie | stderr, csvlog | CSV, XML, JSON | stderr, csvlog via pgAudit |
| Audit par objet | Via pgAudit | Natif + via pgAudit | Via pgAudit |
| Redaction de mots de passe | Via pgAudit (limité) | Natif avec redaction automatique | Via pgAudit (limité) |
| Interface de gestion | Ligne de commande | PEM (Postgres Enterprise Manager) | Ligne de commande + PMM (monitoring) |
| Coût | Gratuit | Commercial (licence) | Gratuit |
| Support | Communauté | Commercial 24/7 | Communauté + support commercial optionnel |
| Compatibilité Oracle | Non | Oui (PL/SQL natif) | Non |

**Comparaison pgAudit vs EDB Audit**

Les deux solutions offrent des capacités d'audit avancées mais diffèrent dans leur approche :[48][57][19][40]

**pgAudit** est une extension communautaire open source, disponible pour toutes les versions PostgreSQL, offrant un audit de session et d'objets, avec un format de log préfixé "AUDIT:" intégré au log PostgreSQL standard.[18][17][26]

**EDB Audit** est intégré nativement à EPAS, offrant trois formats de sortie (CSV, XML, JSON), avec des fichiers d'audit séparés, une redaction automatique des mots de passe, et des options de filtrage plus granulaires (par code d'erreur, command tag).[41][40][46]

Les deux solutions peuvent générer un volume important de logs selon la configuration et introduisent un overhead de performance variable selon la charge.[28][29][17]

## Gestion et bonnes pratiques

**Rotation et rétention des logs**

PostgreSQL offre des mécanismes intégrés de rotation de logs via plusieurs paramètres :[58][59]

- `logging_collector` : Active le collecteur de logs en arrière-plan[58]
- `log_rotation_age` : Définit la durée avant création d'un nouveau fichier de log[58]
- `log_rotation_size` : Définit la taille maximale avant rotation[59]
- `log_truncate_on_rotation` : Détermine si les anciens logs sont tronqués ou préservés lors de la rotation[58]

Pour les logs d'audit, il est recommandé d'implémenter des politiques de rétention claires basées sur les exigences réglementaires (souvent 12 mois minimum pour HIPAA, jusqu'à 7 ans pour certaines normes). Des outils comme `pg_cron` peuvent automatiser la suppression ou l'archivage des anciens logs.[27][60][61]

**Impact sur les performances**

L'audit introduit inévitablement un overhead de performance. Les considérations clés incluent :[29][28]

- Le mode d'audit (synchrone vs asynchrone) : le mode asynchrone privilégie la performance au détriment de la complétude des logs[29]
- La granularité du logging : auditer toutes les opérations SELECT génère beaucoup plus de données que les seuls DDL[20][28]
- Le volume de transactions : dans les environnements à fort trafic, l'impact peut être significatif[28]
- Le stockage : les logs d'audit peuvent rapidement consommer de l'espace disque[17][29][21]

Il est crucial de configurer l'audit pour n'enregistrer que ce qui est strictement nécessaire aux exigences de conformité.[17][28][21]

**Conformité réglementaire**

PostgreSQL et ses variantes peuvent satisfaire les exigences de plusieurs réglementations :[62][63][64][27]

**HIPAA** (Health Insurance Portability and Accountability Act) : Nécessite chiffrement des données au repos et en transit, contrôles d'accès stricts, logs d'audit complets avec détails des accès et modifications, et sauvegardes régulières.[27]

**GDPR** (General Data Protection Regulation) : Exige contrôles d'accès granulaires, capacité de suppression et anonymisation des données, traçabilité des accès aux données personnelles.[64][62]

**PCI DSS** (Payment Card Industry Data Security Standard) : Impose restriction d'accès aux données de cartes, audit trails complets, chiffrement, monitoring et tests de sécurité réguliers.[62][64]

pgAudit est particulièrement adapté pour la conformité HIPAA grâce à ses capacités de logging détaillé et de redaction des informations sensibles. Les trois formats de sortie d'EDB Audit facilitent l'intégration avec des systèmes de monitoring et de compliance externes.[16][27][46]

## Solutions tierces et complémentaires

**DataSunrise**

DataSunrise propose une solution d'audit proxy qui se positionne entre les applications et la base de données PostgreSQL/Percona. Cette approche offre : audit sans modification de la configuration PostgreSQL, contrôle d'accès centralisé, masquage de données dynamique, et monitoring en temps réel.[65][56]

**CYBERTEC PGEE (PostgreSQL Enterprise Edition)**

CYBERTEC offre une version enterprise avec des capacités d'audit étendues incluant : audit logging avancé, tracking des événements et changements, deep security tracking, et intégration de compliance. La solution supporte le logging dans différents contextes UNIX et est conçue pour fonctionner à grande échelle.[66]

**ClusterControl**

ClusterControl (de Severalnines) simplifie le déploiement de pgAudit via son interface utilisateur et CLI. L'outil peut activer pgAudit sur tous les nœuds d'un cluster PostgreSQL en une seule opération, gérant automatiquement l'installation, la configuration et le redémarrage nécessaire.[17][21]

## Recommandations

Pour choisir la solution d'audit appropriée, considérez les critères suivants :

**Pour les petites organisations ou projets sans contraintes réglementaires strictes** : Les mécanismes natifs PostgreSQL (log_statement, log_connections, log_disconnections) peuvent suffire. Activez pg_stat_statements pour l'analyse de performance.[9][5]

**Pour les organisations nécessitant une conformité réglementaire (HIPAA, GDPR, PCI-DSS)** : pgAudit est le choix recommandé pour PostgreSQL communautaire. Configurez-le en mode audit d'objets pour minimiser l'overhead tout en satisfaisant les exigences.[18][24][16][20][17]

**Pour les organisations avec budget et besoin de support commercial** : EDB Postgres Advanced Server offre l'audit le plus complet et le plus facile à gérer via PEM. Les formats d'audit multiples et la redaction automatique des mots de passe sont des avantages significatifs.[50][49][42][40][46]

**Pour les organisations recherchant un compromis open source avec composants pré-testés** : Percona Distribution for PostgreSQL offre pgAudit et d'autres outils d'audit pré-intégrés et testés ensemble, avec un support commercial optionnel.[51][53][54]

**Pour l'audit au niveau applicatif (modifications de données uniquement)** : Les triggers personnalisés offrent la plus grande flexibilité et peuvent être adaptés précisément aux besoins métier. Utilisez l'approche audit-trigger 91plus comme base.[36][30][31][32]

Dans tous les cas, définissez clairement vos exigences d'audit avant l'implémentation, testez l'impact sur les performances dans un environnement de pré-production, et mettez en place des processus automatisés de rotation et archivage des logs pour gérer le stockage à long terme.[60][17][21][58]

[1](https://www.postgresql.org/docs/current/runtime-config-logging.html)
[2](https://betterstack.com/community/guides/logging/how-to-start-logging-with-postgresql/)
[3](https://www.cybertec-postgresql.com/en/enhanced-security/)
[4](https://www.dash0.com/guides/postgresql-logs)
[5](https://satoricyber.com/postgres-security/postgres-audit/)
[6](https://postgresqlco.nf/doc/en/param/log_min_duration_statement/)
[7](https://postgrespro.com/list/thread-id/1315795)
[8](https://www.dbi-services.com/blog/the-log_duration-parameter-in-postgresql/)
[9](https://www.postgresql.org/docs/current/pgstatstatements.html)
[10](https://docs.yugabyte.com/stable/launch-and-manage/monitor-and-alert/query-tuning/pg-stat-statements/)
[11](https://udulabs.com/blog/postgresql-pg-stat-statements)
[12](https://www.squash.io/evaluating-active-connections-to-a-postgresql-query/)
[13](https://pganalyze.com/docs/connections)
[14](https://www.enterprisedb.com/postgres-tutorials/how-monitor-postgresql-connections)
[15](https://www.instaclustr.com/blog/mastering-pg-stat-activity-for-real-time-monitoring-in-postgresql/)
[16](https://www.tigerdata.com/learn/what-is-audit-logging-and-how-to-enable-it-in-postgresql)
[17](https://severalnines.com/blog/audit-logging-postgresql/)
[18](https://www.pgaudit.org)
[19](https://access.crunchydata.com/documentation/pgaudit/latest/)
[20](https://www.scaleway.com/en/docs/managed-databases-for-postgresql-and-mysql/api-cli/pg-audit/)
[21](https://severalnines.com/blog/how-to-audit-postgresql-database/)
[22](https://docs.cloud.google.com/sql/docs/postgres/pg-audit)
[23](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Appendix.PostgreSQL.CommonDBATasks.pgaudit.auditing.html)
[24](https://severalnines.com/blog/postgresql-audit-logging-best-practices/)
[25](https://www.pythian.com/blog/12-essential-steps-for-a-comprehensive-postgresql-audit)
[26](https://neon.com/blog/postgres-logging-vs-pgaudit)
[27](https://www.linkedin.com/pulse/your-guide-hipaa-compliant-postgresql-databases-thecloudfleet-evb9c)
[28](https://www.datasunrise.com/knowledge-center/postgres-auditing/)
[29](https://aws.amazon.com/blogs/database/part-1-audit-aurora-postgresql-databases-using-database-activity-streams-and-pgaudit/)
[30](https://www.enterprisedb.com/postgres-tutorials/working-postgres-audit-triggers)
[31](https://vladmihalcea.com/postgresql-audit-logging-triggers/)
[32](https://github.com/2ndQuadrant/audit-trigger/blob/master/audit.sql)
[33](https://emmer.dev/blog/automatic-audit-logging-with-postgresql-triggers/)
[34](https://www.cybertec-postgresql.com/en/performance-differences-between-normal-and-generic-audit-triggers/)
[35](https://supabase.com/blog/postgres-audit)
[36](https://wiki.postgresql.org/wiki/Audit_trigger_91plus)
[37](https://github.com/2ndQuadrant/audit-trigger)
[38](https://www.enterprisedb.com/postgres-tutorials/how-use-event-triggers-postgresql)
[39](https://stackoverflow.com/questions/39160723/postgresql-event-trigger-for-auditing)
[40](https://www.enterprisedb.com/docs/epas/latest/epas_security_guide/05_edb_audit_logging/03_enabling_audit_logging/)
[41](https://www.enterprisedb.com/docs/epas/latest/epas_security_guide/05_edb_audit_logging/)
[42](https://info.enterprisedb.com/rs/069-ALB-339/images/a_comparison_of_the_edb_postgres_platform_to_self_supported_postgresql.pdf)
[43](https://www.dbi-services.com/blog/auditing-with-edb-postgre-enterprise/)
[44](https://www.enterprisedb.com/docs/epas/latest/reference/database_administrator_reference/01_audit_logging_configuration_parameters/)
[45](https://www.enterprisedb.com/docs/epas/latest/database_administration/01_configuration_parameters/03_configuration_parameters_by_functionality/07_auditing_settings/01_edb_audit/)
[46](https://www.enterprisedb.com/docs/epas/latest/reference/database_administrator_reference/04_audit_log_file/)
[47](https://last9.io/blog/postgres-logs-101/)
[48](https://www.enterprisedb.com/docs/edb-postgres-ai/databases/advanced_security/)
[49](https://www.youtube.com/watch?v=-AIQRp0GRlw)
[50](https://www.enterprisedb.com/docs/pem/latest/monitoring_performance/audit_manager/)
[51](https://www.percona.com/postgresql/software/postgresql-distribution)
[52](https://docs.percona.com/postgresql/13/extensions.html)
[53](https://www.percona.com/wp-content/uploads/2024/02/Percona-for-PostgreSQL-Feature-Value-Comparison-0424.pdf)
[54](https://severalnines.com/blog/how-deploy-percona-distribution-postgresql-high-availability/)
[55](https://www.percona.com/compare-mysql-mongodb-postgresql-mariadb)
[56](https://www.datasunrise.com/knowledge-center/percona-audit-trail/)
[57](https://proventa.de/en/auditing-in-postgresql-part-1/)
[58](https://www.mydbops.com/blog/mastering-postgresql-log-management)
[59](https://www.postgresql.org/docs/current/logfile-maintenance.html)
[60](https://dataegret.com/2025/05/data-archiving-and-retention-in-postgresql-best-practices-for-large-datasets/)
[61](https://blog.sequinstream.com/time-based-retention-strategies-in-postgres/)
[62](https://www.postgresql.eu/events/pgconfeu2025/sessions/session/7185-from-chaos-to-compliance-how-postgresql-makes-regulations-work-for-you/)
[63](https://www.liquibase.com/blog/postgresql-data-compliance-guide)
[64](https://www.enterprisedb.com/data-security-compliance-postgresql-enterprises)
[65](https://www.datasunrise.com/knowledge-center/data-audit-in-postgresql/)
[66](https://www.cybertec-postgresql.com/wp-content/uploads/2025/03/PGEE_-Extended-Enterprise-Audit-Logging.pdf)
[67](https://www.percona.com/blog/postgresql-extensions-for-an-enterprise-grade-system/)
[68](https://cubeapm.com/blog/best-postgresql-monitoring-tools/)
[69](https://docs-cybersec.thalesgroup.com/bundle/onboarding-databases-to-sonar-reference-guide/page/EnterpriseDB-Postgres-Advanced-Server-Onboarding-Steps_48367463.html)
[70](https://www.crunchydata.com/blog/postgres-logging-for-performance-optimization)
[71](https://www.tenable.com/audits/items/DISA_STIG_EDB_PostgreSQL_Advanced_Server_v9.6_v2r3_OS_Linux.audit:f83dc5757e60066986ce3f6ed0622939)
[72](https://severalnines.com/blog/using-percona-audit-log-plugin-database-security/)
[73](https://www.bytebase.com/blog/postgres-audit-logging/)
[74](https://www.dnsstuff.com/enterprisedb-vs-postgresql)
[75](https://www.postgresql.org/docs/9.3/pgstatstatements.html)
[76](https://docs.aws.amazon.com/fr_fr/AmazonRDS/latest/UserGuide/Appendix.PostgreSQL.CommonDBATasks.pgaudit.basic-setup.html)
[77](https://pgaudit.org)
[78](https://doc.scalingo.com/databases/postgresql/guides/monitoring)
[79](https://supabase.com/docs/guides/database/extensions/pgaudit)
[80](https://opensource-db.com/configuring-pgaudit-for-effective-database-auditing/)
[81](https://github.com/pgaudit/pgaudit)
[82](https://supabase.com/docs/guides/database/extensions/pg_stat_statements)
[83](https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/security-audit)
[84](https://www.postgresql.fastware.com/postgresql-insider-sec-threat)
[85](https://postgresqlco.nf/doc/en/param/log_disconnections/)
[86](https://www.enterprisedb.com/docs/epas/13/epas_guide/03_database_administration/05_edb_audit_logging/)
[87](https://stackoverflow.com/questions/72436352/disable-disconnection-logging-on-postgressql)
[88](https://postgresqlco.nf/doc/fr/param/log_disconnections/)
[89](https://postgresqlco.nf/doc/en/param/log_connections/)
[90](https://www.youtube.com/watch?v=Ufr1YkZ22cA)
[91](https://stackoverflow.com/questions/70002649/log-the-authenticated-user-in-the-postgres-logs)
[92](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_LogAccess.Concepts.PostgreSQL.Query_Logging.html)
[93](https://www.postgresql.org/docs/8.1/client-authentication.html)
[94](https://www.tenable.com/audits/DISA_STIG_EDB_PostgreSQL_Advanced_Server_v11_Windows_v2r4_OS)
[95](https://stackoverflow.com/questions/22031197/windows-postgresql-logs-indicate-many-short-time-sessions)
[96](https://stackoverflow.com/questions/41107991/audit-table-with-postgresql)
[97](https://wiki.postgresql.org/wiki/Audit_trigger)
[98](https://www.youtube.com/watch?v=-NWH56fuxkw)
[99](https://gist.github.com/djheru/d128ab296a03ed9ea19b)
[100](https://www.heap.io/blog/how-postgres-audit-tables-saved-us-from-taking-down-production)
[101](https://ttu.github.io/postgres-simple-audit-trail/)
[102](https://pganalyze.com/blog/5mins-postgres-auditing-pgaudit-supabase-supa-audit)
[103](https://wiki.postgresql.ac.cn/wiki/Audit_trigger_91plus)
[104](https://blog.bemi.io/the-ultimate-guide-to-postgresql-data-change-tracking/)
[105](https://docs.postgresql.fr/13/plpgsql-trigger.html)
[106](https://wahlstrand.dev/posts/2022-02-27-audit-logs-in-postgres/)
[107](https://www.enterprisedb.com/blog/comparing-edb-postgres-platform-and-postgresql)
[108](https://www.postgresql.org/message-id/b9b13a91a763dd54f01af7209693247fa48184fc.camel@cybertec.at)
[109](https://postgrespro.ru/list/thread-id/2549503)
[110](https://www.peerspot.com/products/comparisons/percona-server_vs_postgresql)
[111](https://www.enterprisedb.com/postgres-database-provider-comparative-analysis)
[112](https://www.percona.com/blog/percona-distribution-for-postgresql-the-best-enterprise-level-components-from-one-source/)
[113](https://reintech.io/blog/postgresql-audit-logging-compliance-security)
[114](https://www.trustradius.com/compare-products/edb-postgres-advanced-server-vs-postgresql)
[115](https://percona.community/postgresql/)
[116](https://postgresqlco.nf/doc/en/param/log_duration/)
[117](https://www.tenable.com/audits/DISA_STIG_EDB_PostgreSQL_Advanced_Server_v11_Windows_v2r2_Database)
[118](https://stackoverflow.com/questions/66329769/postgresql-how-to-change-log-min-duration-statement-so-that-the-change-takes-ef)
[119](https://dev.to/scalegrid/auditing-postgresql-using-pgaudit-1ggc)
[120](https://dev.to/dm8ry/postgresql-parameter-logmindurationstatement-1j27)
[121](https://stackoverflow.com/questions/78616006/postgres-parameter-log-min-duration-statement)
[122](https://edbjapan.com/manual/edbmanual/EPAS_Guide_E_Set_v11/)
[123](https://www.postgresql.org/docs/current/runtime-config-wal.html)
[124](https://www.postgresql.org/docs/current/wal-intro.html)
[125](https://www.artie.com/blogs/postgres-write-ahead-logs)
[126](https://stackoverflow.com/questions/27435839/how-to-list-active-connections-on-postgresql)
[127](https://www.architecture-weekly.com/p/the-write-ahead-log-a-foundation)
[128](https://hevodata.com/learn/working-with-postgres-wal/)
[129](https://graphicsunplugged.com/2022/01/15/getting-a-count-of-active-connections-in-postgresql/)
[130](https://docs.postgresql.fr/16/wal-intro.html)
[131](https://www.postgresql.fastware.com/blog/understanding-postgresql-write-ahead-logging-wal)
[132](https://www.postgresql.org/docs/current/monitoring-stats.html)
[133](https://www.percona.com/blog/percona-audit-log-plugin-and-the-percona-monitoring-and-management-security-threat-tool/)
[134](https://docs.yugabyte.com/stable/secure/audit-logging/audit-logging-ysql/)
[135](https://www.cybertec-postgresql.com/en/row-change-auditing-options-for-postgresql/)
[136](https://www.openlogic.com/blog/enterprisedb-vs-postgres)
[137](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Appendix.PostgreSQL.CommonDBATasks.pgaudit.exclude-user-db.html)
[138](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_LogAccess.Concepts.PostgreSQL.overview.parameter-groups.html)
[139](https://sonra.io/sql-parsing-for-postgresql-table-and-column-audit-logging/)
[140](https://www.reddit.com/r/PostgreSQL/comments/3qo9nc/whats_a_best_practice_for_storing_log_data_in/)
[141](https://help.splunk.com/en/splunk-soar/soar-on-premises/administer-soar-on-premises/6.3.0/configure-product-settings-for-your-splunk-soar-on-premises-instance/manage-your-postgresql-database-with-data-retention-strategies)
[142](https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/security-compliance)
[143](https://www.linkedin.com/pulse/auditing-database-applications-ensuring-data-integrity-joey-wang-h8vie)