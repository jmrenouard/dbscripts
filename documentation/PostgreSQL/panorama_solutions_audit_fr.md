# Panorama des solutions d'audit et de traçabilité pour PostgreSQL

## Table des matières
- [Solutions d'audit natives de PostgreSQL](#solutions-d'audit-natives-de-postgresql)
- [pgAudit : L'extension communautaire de référence](#pgaudit-:-l'extension-communautaire-de-référence)
- [Solutions personnalisées avec triggers](#solutions-personnalisées-avec-triggers)
- [EDB Postgres Advanced Server : Audit intégré de niveau entreprise](#edb-postgres-advanced-server-:-audit-intégré-de-niveau-entreprise)
- [Percona Distribution for PostgreSQL](#percona-distribution-for-postgresql)
- [Comparaison des solutions](#comparaison-des-solutions)
- [Gestion et bonnes pratiques](#gestion-et-bonnes-pratiques)
- [Solutions tierces et complémentaires](#solutions-tierces-et-complémentaires)
- [Recommandations](#recommandations)

  - [Table des matières](#table-des-matières)
  - [Solutions d'audit natives de PostgreSQL](#solutions-daudit-natives-de-postgresql)
  - [pgAudit : L'extension communautaire de référence](#pgaudit--lextension-communautaire-de-référence)
  - [Solutions personnalisées avec triggers](#solutions-personnalisées-avec-triggers)
  - [EDB Postgres Advanced Server : Audit intégré de niveau entreprise](#edb-postgres-advanced-server--audit-intégré-de-niveau-entreprise)
  - [Percona Distribution for PostgreSQL](#percona-distribution-for-postgresql)
  - [Comparaison des solutions](#comparaison-des-solutions)
  - [Gestion et bonnes pratiques](#gestion-et-bonnes-pratiques)
  - [Solutions tierces et complémentaires](#solutions-tierces-et-complémentaires)
  - [Recommandations](#recommandations)

Les solutions d'audit et de traçabilité pour PostgreSQL se déclinent en plusieurs approches, chacune adaptée à des besoins spécifiques en matière de conformité, sécurité et surveillance des opérations. Ce panorama couvre les différentes versions de PostgreSQL (communauté open source), EnterpriseDB (EDB Postgres Advanced Server) et Percona Distribution for PostgreSQL.

## Solutions d'audit natives de PostgreSQL

PostgreSQL offre plusieurs mécanismes de traçabilité intégrés qui constituent la base de tout système d'audit.

**Logging des connexions et déconnexions**

Les paramètres `log_connections` et `log_disconnections` permettent de tracer l'ensemble des connexions au serveur PostgreSQL. Lorsque `log_connections` est activé, trois types d'événements peuvent être enregistrés selon la configuration : `receipt` (réception de la connexion), `authentication` (authentification avec la méthode utilisée comme md5, scram-sha-256 ou trust), et `authorization` (autorisation avec l'utilisateur, la base de données et l'application). Ces logs fournissent également l'adresse IP du client et le fichier pg_hba.conf responsable de la décision d'authentification, facilitant ainsi le débogage de la sécurité.

**Logging des requêtes SQL**

Le paramètre `log_statement` contrôle quelles catégories d'instructions SQL sont enregistrées. Les valeurs possibles sont :

- `none` : aucun logging (valeur par défaut)
- `ddl` : enregistre toutes les opérations de définition de données (CREATE, DROP, ALTER)
- `mod` : comme ddl, plus les opérations de modification (INSERT, UPDATE, DELETE)
- `all` : enregistre toutes les requêtes SQL

**Logging basé sur la durée d'exécution**

Le paramètre `log_min_duration_statement` permet de n'enregistrer que les requêtes dépassant un certain seuil de temps d'exécution. Cette approche est particulièrement utile pour identifier les requêtes non optimisées sans générer un volume excessif de logs. Une valeur de -1 désactive cette fonctionnalité, tandis qu'une valeur de 0 enregistre toutes les requêtes avec leur durée.

**pg_stat_statements**

Cette extension intégrée collecte des statistiques d'exécution pour toutes les requêtes SQL exécutées par le serveur. Elle fournit des informations détaillées incluant le nombre d'exécutions, le temps total d'exécution, les temps minimum, maximum et moyen, ainsi que le nombre de lignes affectées. Bien qu'elle ne soit pas strictement un outil d'audit, elle est précieuse pour l'analyse de performance et peut compléter une stratégie d'audit globale.

**pg_stat_activity**

Cette vue système offre une visibilité en temps réel sur toutes les connexions actives au serveur PostgreSQL. Elle permet de surveiller qui est connecté, quelles requêtes sont en cours d'exécution, l'état de chaque connexion (active, idle, idle in transaction), et depuis combien de temps. Cette vue est essentielle pour les audits de sécurité et la détection de patterns d'accès inattendus.

## pgAudit : L'extension communautaire de référence

pgAudit est l'extension open source la plus utilisée pour l'audit PostgreSQL, offrant un niveau de détail et de granularité bien supérieur aux mécanismes natifs.

**Fonctionnalités principales**

pgAudit fournit deux modes d'audit distincts :

**Audit de session** : Permet de tracer des catégories entières d'opérations SQL via le paramètre `pgaudit.log`. Les catégories disponibles incluent READ (SELECT et COPY), WRITE (INSERT, UPDATE, DELETE, TRUNCATE), FUNCTION (appels de fonctions), ROLE (opérations sur les rôles et privilèges), DDL (toutes les instructions de définition de données), et MISC (commandes diverses).

**Audit d'objets** : Offre un contrôle plus fin en auditant uniquement les opérations sur des objets spécifiques. Cette approche utilise le paramètre `pgaudit.role` pour désigner un rôle d'audit principal. Seules les opérations sur les objets pour lesquels ce rôle possède des privilèges sont enregistrées.

**Paramètres de configuration clés**

- `pgaudit.log` : Définit les catégories d'instructions à auditer
- `pgaudit.log_catalog` : Contrôle l'audit des opérations sur les tables système (pg_catalog)
- `pgaudit.log_client` : Détermine si les messages d'audit sont visibles pour le client (psql, etc.)
- `pgaudit.log_level` : Définit le niveau de sévérité des messages d'audit (log, notice, etc.)
- `pgaudit.log_parameter` : Active l'enregistrement des paramètres des requêtes
- `pgaudit.log_relation` : Enregistre les relations (tables) impliquées dans les requêtes DML
- `pgaudit.log_statement_once` : Évite la duplication des logs pour les requêtes complexes
- `pgaudit.role` : Spécifie le rôle d'audit pour l'audit d'objets

**Installation et activation**

pgAudit nécessite d'être ajouté à `shared_preload_libraries` dans postgresql.conf, puis installé via `CREATE EXTENSION pgaudit`. L'extension doit être créée avant de configurer `pgaudit.log` pour assurer le bon fonctionnement des event triggers qui enrichissent l'audit DDL avec les types et noms d'objets.

**Format des logs**

Les entrées d'audit générées par pgAudit sont préfixées par "AUDIT:" et incluent des métadonnées enrichies telles que le type d'audit (SESSION ou OBJECT), la classe de commande, et les détails de la requête. Ce format structuré facilite le parsing automatisé et l'indexation pour l'analyse.

**Avantages et limitations**

pgAudit offre plusieurs avantages significatifs : filtrage granulaire des événements, format de log structuré et cohérent, possibilité de redaction des informations sensibles (via `pgaudit.log_parameter`), et conformité avec les exigences réglementaires comme HIPAA, GDPR et PCI-DSS. Cependant, selon la configuration, pgAudit peut générer un volume considérable de données et introduire un overhead de performance, particulièrement dans les environnements à fort trafic.

## Solutions personnalisées avec triggers

Les triggers PostgreSQL permettent de créer des solutions d'audit sur mesure pour tracer les modifications de données au niveau des lignes.

**Principe de fonctionnement**

Un trigger d'audit typique utilise une fonction PL/pgSQL qui s'exécute AFTER INSERT, UPDATE ou DELETE sur une table cible. La fonction capture l'ancienne valeur (OLD), la nouvelle valeur (NEW), le type d'opération (TG_OP), l'utilisateur, et l'horodatage, puis insère ces informations dans une table d'audit dédiée.

**Approches d'implémentation**

Deux approches principales existent pour les tables d'audit :

**Tables d'audit explicites** : Chaque table auditée possède sa propre table d'audit avec les mêmes colonnes, plus des métadonnées d'audit. Cette approche offre de meilleures performances pour les requêtes complexes et élimine le besoin de syntaxe JSONB.

**Tables d'audit génériques** : Une seule table d'audit stocke les changements de toutes les tables auditées, utilisant JSONB pour stocker les données des lignes. Cette approche simplifie la gestion mais consomme environ deux fois plus d'espace et présente des performances inférieures pour les requêtes historiques fréquentes.

**Exemple de code**

La solution audit-trigger 91plus, disponible sur GitHub et documentée sur le wiki PostgreSQL, fournit un framework complet et réutilisable. Elle utilise le type de données hstore pour capturer efficacement les changements et offre des fonctions pour activer facilement l'audit sur n'importe quelle table.

**Limitations**

Les triggers ne peuvent pas auditer les opérations SELECT. De plus, ils ne capturent pas les instructions DDL ni les modifications sur les tables système. Pour ces cas d'usage, il faut combiner les triggers avec les event triggers (disponibles depuis PostgreSQL 9.3) ou avec pgAudit.

## EDB Postgres Advanced Server : Audit intégré de niveau entreprise

EnterpriseDB propose EDB Postgres Advanced Server (EPAS), une version commerciale enrichie de PostgreSQL incluant des fonctionnalités d'audit avancées natives.

**Fonctionnalités d'audit EDB**

EDB Audit Logging est directement intégré à EPAS, sans nécessiter l'installation d'extensions externes. Les capacités d'audit incluent :

**Paramètres de configuration**

- `edb_audit` : Active l'audit et définit le format (csv, xml, ou json)
- `edb_audit_connect` : Trace toutes les connexions (all, failed, none)
- `edb_audit_disconnect` : Trace toutes les déconnexions
- `edb_audit_statement` : Contrôle les catégories d'instructions SQL à auditer (ddl, dml, select, insert, update, delete, truncate, rollback, error, etc.)
- `edb_audit_tag` : Ajoute une étiquette personnalisée à tous les logs d'audit
- `edb_audit_directory` : Spécifie l'emplacement des fichiers d'audit
- `edb_audit_rotation_day` : Configure la rotation quotidienne des fichiers d'audit

**Formats de fichiers d'audit**

EDB supporte trois formats de sortie pour les logs d'audit :

**CSV** : Format tabulaire avec colonnes délimitées, facile à importer dans des outils d'analyse.

**XML** : Format structuré avec éléments et attributs XML, offrant une hiérarchie claire des données d'audit.

**JSON** : Format moderne et structuré, optimal pour l'intégration avec des systèmes de monitoring et d'analyse modernes.

Tous les formats incluent des informations complètes : horodatage, utilisateur, base de données, process ID, hôte distant, ID de session, requête SQL, type de commande, sévérité d'erreur, et tag d'audit.

**Fonctionnalités avancées**

EDB Audit offre des capacités spécifiques absentes de la version communautaire PostgreSQL :

- Audit au niveau des objets (tables, vues, fonctions, triggers)
- Redaction automatique des mots de passe dans les logs d'audit
- Audit spécifique par base de données et par rôle
- Filtrage par codes d'erreur SQL
- Filtrage par command tags
- Archivage automatique des logs d'audit

**Postgres Enterprise Manager (PEM)**

PEM est l'outil de gestion d'EDB qui simplifie la configuration de l'audit via une interface graphique. Il permet de : configurer les attributs de logging, définir la fréquence de collecte des logs, spécifier les types d'activités à inclure, gérer la rotation des fichiers, et analyser les logs via un tableau de bord avec filtrage par timestamp, base de données, utilisateur et type de commande.

## Percona Distribution for PostgreSQL

Percona propose une distribution PostgreSQL packagée avec des composants enterprise-grade pré-testés, incluant pgAudit comme solution d'audit principale.

**Composants d'audit inclus**

La distribution Percona intègre plusieurs outils d'audit et de monitoring :

**pgAudit** : Extension standard d'audit offrant un logging détaillé au niveau session ou objet.

**pgAudit set_user** : Extension complémentaire fournissant une couche supplémentaire de logging et de contrôle lorsque des utilisateurs non privilégiés doivent s'élever temporairement à des rôles superuser ou propriétaires d'objets pour des tâches de maintenance.

**pg_stat_monitor** : Alternative avancée à pg_stat_statements, collectant et agrégeant des statistiques PostgreSQL avec des informations d'histogramme pour une meilleure analyse de performance.

**pgBadger** : Outil d'analyse de logs PostgreSQL non inclus par défaut mais recommandé et supporté.

**pg_gather** : Script de collecte d'informations pour le diagnostic et le dépannage.

**Avantages de la distribution Percona**

Percona teste tous les composants ensemble pour garantir leur compatibilité. La distribution est entièrement open source et gratuite, sans lock-in commercial. Elle offre un support communautaire robuste, avec des services de support professionnel optionnels couvrant PostgreSQL, MySQL, MongoDB et MariaDB depuis une source unique.

**Configuration flexible**

Percona supporte la configuration dynamique directement depuis SQL via le fichier auto.conf (/var/lib/postgresql/16/main/postgresql.auto.conf), permettant des ajustements d'audit sans redémarrage du serveur dans de nombreux cas. Cependant, il faut éviter de mélanger les configurations entre ce fichier et le postgresql.conf principal.

## Comparaison des solutions

**PostgreSQL communautaire vs EDB vs Percona**

Les trois versions offrent des capacités d'audit, mais avec des différences significatives :

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

Les deux solutions offrent des capacités d'audit avancées mais diffèrent dans leur approche :

**pgAudit** est une extension communautaire open source, disponible pour toutes les versions PostgreSQL, offrant un audit de session et d'objets, avec un format de log préfixé "AUDIT:" intégré au log PostgreSQL standard.

**EDB Audit** est intégré nativement à EPAS, offrant trois formats de sortie (CSV, XML, JSON), avec des fichiers d'audit séparés, une redaction automatique des mots de passe, et des options de filtrage plus granulaires (par code d'erreur, command tag).

Les deux solutions peuvent générer un volume important de logs selon la configuration et introduisent un overhead de performance variable selon la charge.

## Gestion et bonnes pratiques

**Rotation et rétention des logs**

PostgreSQL offre des mécanismes intégrés de rotation de logs via plusieurs paramètres :

- `logging_collector` : Active le collecteur de logs en arrière-plan
- `log_rotation_age` : Définit la durée avant création d'un nouveau fichier de log
- `log_rotation_size` : Définit la taille maximale avant rotation
- `log_truncate_on_rotation` : Détermine si les anciens logs sont tronqués ou préservés lors de la rotation

Pour les logs d'audit, il est recommandé d'implémenter des politiques de rétention claires basées sur les exigences réglementaires (souvent 12 mois minimum pour HIPAA, jusqu'à 7 ans pour certaines normes). Des outils comme `pg_cron` peuvent automatiser la suppression ou l'archivage des anciens logs.

**Impact sur les performances**

L'audit introduit inévitablement un overhead de performance. Les considérations clés incluent :

- Le mode d'audit (synchrone vs asynchrone) : le mode asynchrone privilégie la performance au détriment de la complétude des logs
- La granularité du logging : auditer toutes les opérations SELECT génère beaucoup plus de données que les seuls DDL
- Le volume de transactions : dans les environnements à fort trafic, l'impact peut être significatif
- Le stockage : les logs d'audit peuvent rapidement consommer de l'espace disque

Il est crucial de configurer l'audit pour n'enregistrer que ce qui est strictement nécessaire aux exigences de conformité.

**Conformité réglementaire**

PostgreSQL et ses variantes peuvent satisfaire les exigences de plusieurs réglementations :

**HIPAA** (Health Insurance Portability and Accountability Act) : Nécessite chiffrement des données au repos et en transit, contrôles d'accès stricts, logs d'audit complets avec détails des accès et modifications, et sauvegardes régulières.

**GDPR** (General Data Protection Regulation) : Exige contrôles d'accès granulaires, capacité de suppression et anonymisation des données, traçabilité des accès aux données personnelles.

**PCI DSS** (Payment Card Industry Data Security Standard) : Impose restriction d'accès aux données de cartes, audit trails complets, chiffrement, monitoring et tests de sécurité réguliers.

pgAudit est particulièrement adapté pour la conformité HIPAA grâce à ses capacités de logging détaillé et de redaction des informations sensibles. Les trois formats de sortie d'EDB Audit facilitent l'intégration avec des systèmes de monitoring et de compliance externes.

## Solutions tierces et complémentaires

**DataSunrise**

DataSunrise propose une solution d'audit proxy qui se positionne entre les applications et la base de données PostgreSQL/Percona. Cette approche offre : audit sans modification de la configuration PostgreSQL, contrôle d'accès centralisé, masquage de données dynamique, et monitoring en temps réel.

**CYBERTEC PGEE (PostgreSQL Enterprise Edition)**

CYBERTEC offre une version enterprise avec des capacités d'audit étendues incluant : audit logging avancé, tracking des événements et changements, deep security tracking, et intégration de compliance. La solution supporte le logging dans différents contextes UNIX et est conçue pour fonctionner à grande échelle.

**ClusterControl**

ClusterControl (de Severalnines) simplifie le déploiement de pgAudit via son interface utilisateur et CLI. L'outil peut activer pgAudit sur tous les nœuds d'un cluster PostgreSQL en une seule opération, gérant automatiquement l'installation, la configuration et le redémarrage nécessaire.

## Recommandations

Pour choisir la solution d'audit appropriée, considérez les critères suivants :

**Pour les petites organisations ou projets sans contraintes réglementaires strictes** : Les mécanismes natifs PostgreSQL (log_statement, log_connections, log_disconnections) peuvent suffire. Activez pg_stat_statements pour l'analyse de performance.

**Pour les organisations nécessitant une conformité réglementaire (HIPAA, GDPR, PCI-DSS)** : pgAudit est le choix recommandé pour PostgreSQL communautaire. Configurez-le en mode audit d'objets pour minimiser l'overhead tout en satisfaisant les exigences.

**Pour les organisations avec budget et besoin de support commercial** : EDB Postgres Advanced Server offre l'audit le plus complet et le plus facile à gérer via PEM. Les formats d'audit multiples et la redaction automatique des mots de passe sont des avantages significatifs.

**Pour les organisations recherchant un compromis open source avec composants pré-testés** : Percona Distribution for PostgreSQL offre pgAudit et d'autres outils d'audit pré-intégrés et testés ensemble, avec un support commercial optionnel.

**Pour l'audit au niveau applicatif (modifications de données uniquement)** : Les triggers personnalisés offrent la plus grande flexibilité et peuvent être adaptés précisément aux besoins métier. Utilisez l'approche audit-trigger 91plus comme base.

Dans tous les cas, définissez clairement vos exigences d'audit avant l'implémentation, testez l'impact sur les performances dans un environnement de pré-production, et mettez en place des processus automatisés de rotation et archivage des logs pour gérer le stockage à long terme.
