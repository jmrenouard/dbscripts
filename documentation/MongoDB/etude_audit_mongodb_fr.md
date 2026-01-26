# Panorama des Solutions d'Audit et de Traçabilité MongoDB

## Table des matières
- [Disponibilité de l'Audit selon les Versions](#disponibilité-de-l'audit-selon-les-versions)
- [MongoDB Community Edition](#mongodb-community-edition)
- [MongoDB Enterprise Edition](#mongodb-enterprise-edition)
- [MongoDB Atlas](#mongodb-atlas)
- [Percona Server for MongoDB](#percona-server-for-mongodb)
- [Architecture et Configuration de l'Audit](#architecture-et-configuration-de-l'audit)
- [Destinations des Logs d'Audit](#destinations-des-logs-d'audit)
- [Formats de Logs](#formats-de-logs)
- [Paramètres de Configuration Essentiels](#paramètres-de-configuration-essentiels)
- [Événements Audités et Filtres](#Événements-audités-et-filtres)
- [Catégories d'Événements](#catégories-d'Événements)
- [Filtres d'Audit Avancés](#filtres-d'audit-avancés)
- [Rotation des Logs d'Audit](#rotation-des-logs-d'audit)
- [Outils Complémentaires de Monitoring et Traçabilité](#outils-complémentaires-de-monitoring-et-traçabilité)
- [Profiler MongoDB vs Audit Log](#profiler-mongodb-vs-audit-log)
- [Query Profiler Atlas](#query-profiler-atlas)
- [Solutions Tierces d'Audit](#solutions-tierces-d'audit)
- [Impact sur les Performances](#impact-sur-les-performances)
- [Facteurs Déterminant l'Impact Performance](#facteurs-déterminant-l'impact-performance)
- [Stratégies d'Optimisation des Performances](#stratégies-d'optimisation-des-performances)
- [Comparaison Performance selon Configuration](#comparaison-performance-selon-configuration)
- [⚠️ Points de Vigilance](#⚠️-points-de-vigilance)

Les solutions d'audit et de traçabilité diffèrent considérablement entre les versions de MongoDB. La version Community ne dispose d'aucune fonctionnalité d'audit native, tandis que MongoDB Enterprise, MongoDB Atlas et Percona Server for MongoDB offrent des capacités d'audit complètes avec des différences notables en termes de coût et de fonctionnalités.

## Disponibilité de l'Audit selon les Versions

### MongoDB Community Edition

MongoDB Community Edition ne propose **aucune fonctionnalité d'audit native**. Cette version open source gratuite, distribuée sous licence Server Side Public License (SSPL), convient principalement aux environnements de développement et de test sans exigences réglementaires strictes. Pour les utilisateurs de la version Community nécessitant un audit, les seules alternatives consistent à utiliser des outils tiers comme mongoaudit pour des audits ponctuels de sécurité, ou à migrer vers une version supportant l'audit.

### MongoDB Enterprise Edition

MongoDB Enterprise Edition intègre un **système d'audit complet et robuste** disponible pour les instances `mongod` et `mongos`. Cette version commerciale offre la palette la plus étendue de fonctionnalités d'audit, incluant le support de multiples formats (JSON, BSON) et destinations de logs, ainsi que des filtres avancés permettant de cibler précisément les événements à enregistrer.

L'audit Enterprise capture systématiquement les opérations de schéma (DDL), les actions sur les replica sets et clusters shardés, l'authentification et l'autorisation, ainsi que les opérations CRUD lorsque le paramètre `auditAuthorizationSuccess` est activé. Depuis MongoDB 5.0, la configuration des filtres d'audit peut être modifiée à l'exécution sans redémarrage du serveur, offrant ainsi une flexibilité opérationnelle significative.

MongoDB 8.0 introduit le support du schéma **OCSF (Open Cybersecurity Schema Framework)** pour les messages d'audit, facilitant l'intégration avec les plateformes SIEM modernes et les outils de traitement de logs standardisés.

### MongoDB Atlas

MongoDB Atlas, la solution Database-as-a-Service de MongoDB, propose l'audit pour les **clusters M10 et supérieurs**. L'activation de l'audit s'effectue via l'interface utilisateur Atlas ou l'API REST, offrant un contrôle granulaire sur les événements audités.

Pour les organisations utilisant Atlas sans abonnement Enterprise ou Platinum, l'activation de l'audit entraîne un **surcoût de 10% sur le tarif horaire de tous les clusters dédiés** du projet. Par exemple, un cluster M10 coûtant environ 57$ par mois verrait son coût augmenter à environ 63$ avec l'audit activé. Les clients Enterprise et Platinum bénéficient de l'audit sans frais supplémentaires.

Atlas génère automatiquement des logs d'audit au format JSON et les stocke dans l'infrastructure cloud. Ces logs peuvent être consultés via l'interface Atlas ou exportés vers des systèmes externes pour analyse approfondie. La rotation des logs est gérée automatiquement par la plateforme.

### Percona Server for MongoDB

Percona Server for MongoDB représente une **alternative gratuite et open source** à MongoDB Enterprise, incluant les fonctionnalités d'audit sans coût de licence. Distribué sous licence GPL, Percona Server est basé sur MongoDB Community Edition mais enrichi avec des fonctionnalités de niveau entreprise.

L'audit Percona diffère légèrement de celui de MongoDB Enterprise : il supporte uniquement le format **JSON** (pas BSON), et la syntaxe de filtrage présente quelques différences. Contrairement à MongoDB Enterprise, Percona n'offre pas la configuration d'audit en runtime ; toute modification nécessite un redémarrage du serveur.

Percona fournit également un filtrage plus sélectif par défaut, enregistrant principalement les commandes importantes plutôt que tous les événements, ce qui peut réduire le volume de logs et l'impact sur les performances.

## Architecture et Configuration de l'Audit

### Destinations des Logs d'Audit

MongoDB Enterprise et Percona offrent trois destinations principales pour les logs d'audit:

**File (Fichier)** : Les événements d'audit sont écrits dans un fichier sur le système de fichiers local. Cette destination constitue le choix standard pour la production, permettant un stockage persistant et une rotation contrôlée des logs. Le chemin du fichier est spécifié via le paramètre `auditLog.path`.

**Syslog** : Les événements sont envoyés au démon syslog du système d'exploitation, facilitant l'intégration avec des systèmes de gestion de logs centralisés et des plateformes SIEM comme Splunk ou ELK. Cette destination est particulièrement adaptée aux architectures distribuées nécessitant une collecte centralisée.

**Console** : Les événements d'audit sont écrits sur la sortie standard (stdout). Cette destination est **fortement déconseillée en production** en raison de son impact élevé sur les performances, mais peut être utile pour le débogage en environnement de développement.

### Formats de Logs

MongoDB Enterprise supporte deux formats principaux pour l'enregistrement des événements d'audit:

**JSON** : Format texte lisible, facilitant l'analyse manuelle et l'intégration avec de nombreux outils de traitement de logs. Cependant, ce format génère un **impact sur les performances supérieur** au format BSON, particulièrement lors d'une charge élevée.

**BSON** : Format binaire natif de MongoDB, offrant de meilleures performances d'écriture avec un impact réduit de 5 à 10% par rapport au JSON. Les logs BSON nécessitent l'utilitaire `bsondump` pour être convertis en format lisible.

Pour consulter des logs BSON, la commande suivante convertit le fichier en format JSON lisible:

```bash
bsondump /var/lib/mongodb/auditLog.bson
```

### Paramètres de Configuration Essentiels

La configuration de l'audit MongoDB repose sur plusieurs paramètres clés dans le fichier `mongod.conf` ou en ligne de commande:

**auditLog.destination** : Définit où envoyer les événements (file, syslog, console).

**auditLog.format** : Spécifie le format des logs (JSON ou BSON).

**auditLog.path** : Chemin complet vers le fichier de log (obligatoire si destination = file).

**auditLog.filter** : Expression de filtrage JSON pour sélectionner les événements à auditer.

**auditLog.schema** : Depuis MongoDB 8.0, permet de choisir entre le schéma `mongo` (par défaut) et `OCSF` pour une compatibilité standardisée.

**auditAuthorizationSuccess** : Paramètre crucial activant l'audit des opérations CRUD (read/write). Par défaut à `false`, ce paramètre doit être explicitement activé via `setParameter` pour enregistrer les succès d'autorisation.

Exemple de configuration basique dans `mongod.conf`:

```yaml
auditLog:
  destination: file
  format: BSON
  path: /var/log/mongodb/auditLog.bson
  filter: '{ atype: { $in: ["authenticate", "createCollection", "dropCollection"] } }'
```

## Événements Audités et Filtres

### Catégories d'Événements

MongoDB peut auditer un large éventail d'opérations réparties en plusieurs catégories:

**Schéma (DDL)** : Opérations de définition de données incluant `createCollection`, `dropCollection`, `createDatabase`, `dropDatabase`, `createIndex`, `dropIndex`, et `renameCollection`. Ces événements ont un **impact faible sur les performances** car ils sont relativement peu fréquents.

**Authentification** : Type d'événement `authenticate` enregistrant les tentatives de connexion réussies et échouées, permettant de détecter les accès non autorisés. L'audit d'authentification représente une pratique de sécurité fondamentale avec un impact performance minimal.

**Autorisation** : Type `authCheck` capturant les vérifications de privilèges pour toutes les opérations. Lorsque `auditAuthorizationSuccess` est désactivé (par défaut), seuls les **échecs d'autorisation** sont enregistrés, limitant l'impact performance.

**CRUD (Lecture/Écriture)** : Opérations de données incluant `find`, `insert`, `update`, `delete`, `findandmodify`, `aggregate`, `count`, et `distinct`. Ces opérations nécessitent obligatoirement l'activation de `auditAuthorizationSuccess: true` et génèrent un **impact performance significatif** (15-30%) en raison de leur haute fréquence.

**Gestion des utilisateurs et rôles** : Événements comme `createUser`, `dropUser`, `updateUser`, `createRole`, `grantRolesToUser`, `revokeRolesFromUser`. Ces opérations administratives ont un impact minimal car elles sont peu fréquentes.

**Replica Set et Sharding** : Opérations de gestion de cluster incluant `replSetReconfig`, `replSetStateChange`, `addShard`, `removeShard`, `enableSharding`.

### Filtres d'Audit Avancés

Les filtres d'audit permettent de réduire drastiquement le volume de logs et l'impact performance en ciblant précisément les événements pertinents. La syntaxe de filtrage utilise des expressions JSON similaires aux requêtes MongoDB.

**Filtrer par type d'action** : Auditer uniquement les opérations de suppression:

```json
{ "atype": { "$in": ["dropIndex", "dropCollection", "dropDatabase"] } }
```

**Filtrer par utilisateur** : Enregistrer les actions d'utilisateurs spécifiques:

```yaml
auditLog:
  destination: file
  format: JSON
  path: /var/log/mongodb/auditLog.json
  filter: '{ "users.user": /^prod_app/ }'
```

**Filtrer par base de données ou collection** : Auditer uniquement une base spécifique:

```json
{ "param.ns": /^production\./ }
```

**Filtrer les opérations CRUD par commande** : Enregistrer uniquement certaines opérations de lecture/écriture:

```yaml
auditLog:
  destination: file
  format: BSON
  path: /var/log/mongodb/auditLog.bson
  filter: '{ 
    "atype": "authCheck", 
    "param.command": { "$in": ["find", "insert", "delete", "update"] },
    "param.ns": /^test\\./ 
  }'
setParameter: 
  auditAuthorizationSuccess: true
```

**Filtrer par rôle** : Auditer les actions des utilisateurs ayant un rôle particulier:

```json
{ 
  "roles": { "role": "readWrite", "db": "production" } 
}
```

Depuis MongoDB 5.0, les filtres peuvent être modifiés en runtime via la commande `setAuditConfig` sans nécessiter de redémarrage, offrant une agilité opérationnelle considérable:

```javascript
db.adminCommand({
  setAuditConfig: 1,
  filter: { "atype": { "$in": ["authenticate", "createUser"] } },
  auditAuthorizationSuccess: false
})
```

### Rotation des Logs d'Audit

La rotation des logs d'audit est essentielle pour éviter la saturation du système de fichiers. MongoDB ne rotation pas automatiquement les logs d'audit ; cette opération doit être déclenchée manuellement ou via des outils externes.

**Rotation manuelle via commande** : Depuis l'interface `mongosh` connectée à la base `admin`:

```javascript
// Rotation du log serveur uniquement
db.adminCommand({ logRotate: "server" })

// Rotation du log d'audit uniquement
db.adminCommand({ logRotate: "audit", comment: "Rotation programmée" })

// Rotation des deux logs simultanément
db.adminCommand({ logRotate: 1 })
```

**Rotation via signal système** : Envoi du signal SIGUSR1 au processus mongod:

```bash
kill -SIGUSR1 $(pidof mongod)
```

**Intégration avec logrotate** : Configuration recommandée pour automatiser la rotation:

```bash
# /etc/logrotate.d/mongodb-audit
/var/log/mongodb/auditLog*.json {
  daily
  rotate 15
  compress
  delaycompress
  missingok
  notifempty
  create 644 mongod mongod
  postrotate
    /bin/kill -SIGUSR1 $(pidof mongod) 2>/dev/null || true
  endscript
}
```

Le comportement de rotation est contrôlé par le paramètre `systemLog.logRotate`:

- **rename** (défaut) : MongoDB renomme le fichier actuel en ajoutant un timestamp UTC et crée un nouveau fichier
- **reopen** : MongoDB ferme et rouvre le fichier, s'attendant à ce qu'un outil externe (comme logrotate) l'ait déjà renommé

## Outils Complémentaires de Monitoring et Traçabilité

### Profiler MongoDB vs Audit Log

Le **Database Profiler** et l'**Audit Log** sont deux mécanismes distincts répondant à des besoins différents:

**Database Profiler** : Outil de diagnostic de performance enregistrant les métriques d'exécution des opérations dans la collection `system.profile`. Il se concentre sur l'analyse des requêtes lentes (slowms) et fournit des statistiques détaillées comme le temps d'exécution, les documents examinés, et l'utilisation des index. Le profiler peut être activé par base de données avec trois niveaux (0: désactivé, 1: requêtes lentes uniquement, 2: toutes les opérations). Il est **orienté performance** plutôt que sécurité.

**Audit Log** : Système de traçabilité orienté sécurité et conformité, enregistrant **qui** a fait **quoi** et **quand**. Contrairement au profiler, l'audit log ne se concentre pas sur les performances mais sur l'accountability et la détection d'anomalies de sécurité.

### Query Profiler Atlas

MongoDB Atlas propose le **Query Profiler**, un outil de monitoring intégré disponible sur les clusters M10+. Ce profiler identifie automatiquement les requêtes lentes basé sur les données de logs des instances `mongod`, avec un seuil adaptatif géré par Atlas en fonction du temps d'exécution moyen.

Le Query Profiler Atlas affiche des visualisations interactives (scatterplots) des opérations lentes et fournit des recommandations d'optimisation, incluant des suggestions d'index. Il diffère du Database Profiler classique car il ne nécessite pas de configuration du niveau de profiling et n'impacte pas les performances.

### Solutions Tierces d'Audit

**DataSunrise** : Plateforme tierce proposant des capacités d'audit avancées pour MongoDB avec un mode "Sniffer" générant un **impact négligeable sur les performances**. DataSunrise capture l'historique complet des activités, s'intègre avec Elasticsearch et Kibana, et utilise l'intelligence artificielle pour l'analyse des traces d'audit.

**ELK Stack (Elasticsearch, Logstash, Kibana)** : Solution populaire pour l'analyse centralisée des logs d'audit MongoDB. Les logs JSON ou BSON (convertis) peuvent être ingérés par Logstash et visualisés dans Kibana, offrant des capacités de recherche et d'analyse avancées.

**Splunk et autres SIEM** : Plateformes SIEM professionnelles permettant l'agrégation et l'analyse en temps réel des événements d'audit MongoDB via l'intégration syslog ou l'ingestion de fichiers.

## Impact sur les Performances

L'activation de l'audit génère invariablement un impact sur les performances du serveur MongoDB, dont l'ampleur dépend de plusieurs facteurs.

### Facteurs Déterminant l'Impact Performance

**Paramètre auditAuthorizationSuccess** : L'activation de ce paramètre pour auditer les opérations CRUD représente le **facteur le plus impactant**. Avec `auditAuthorizationSuccess: false` (par défaut), seuls les échecs d'autorisation sont enregistrés, générant un impact de 5-10%. Avec `auditAuthorizationSuccess: true`, l'audit de toutes les opérations de lecture et écriture peut dégrader les performances de **15-30% ou plus** selon la charge.

**Volume d'événements audités** : Plus le nombre d'événements capturés est élevé, plus l'impact est important. L'audit sans filtre de toutes les opérations CRUD peut engendrer une dégradation de **30-50%+** en environnement haute concurrence.

**Format de logs** : Le format BSON offre de **meilleures performances** avec un impact réduit de 5 à 10% comparé au JSON. MongoDB recommande BSON pour la production et réserve JSON pour les cas nécessitant une lisibilité immédiate.

**Destination des logs** : L'écriture vers un fichier local génère l'impact le plus faible. L'utilisation de syslog introduit une variable dépendant de la latence réseau et de la charge du serveur syslog. La destination console est la **plus pénalisante** et doit être évitée en production.

**Système de stockage** : L'utilisation d'un disque dédié pour les logs d'audit, distinct du stockage des données MongoDB, peut réduire significativement l'impact en évitant la contention I/O.

**Configuration du système de fichiers** : Le mode DataSunrise "Sniffer" démontre qu'une approche non intrusive peut réduire l'impact à un niveau **négligeable**. En revanche, une configuration mal optimisée peut amplifier l'impact.

### Stratégies d'Optimisation des Performances

**Filtrage sélectif** : L'utilisation de filtres d'audit précis constitue la stratégie d'optimisation la plus efficace. Plutôt que d'auditer toutes les opérations, cibler uniquement les événements critiques (authentification, modifications de schéma, opérations d'utilisateurs privilégiés) peut réduire drastiquement le volume et l'impact.

**Audit asynchrone via buffer mémoire** : Bien que non directement documenté pour MongoDB, certaines implémentations d'audit (comme celle de Percona MySQL) utilisent des buffers mémoire pour réduire l'impact d'écriture. MongoDB écrit les événements d'audit dans un buffer mémoire avant la persistance périodique sur disque.

**Limitation aux événements DDL et authentification** : Pour la plupart des environnements de production, l'audit limité aux opérations DDL (schéma) et authentification offre un **excellent compromis** avec un impact performance inférieur à 5%. Cette configuration satisfait de nombreuses exigences de conformité (RGPD, SOC2, PCI-DSS) sans dégrader significativement les performances.

**Éviter l'audit CRUD en production** : Sauf nécessité absolue (investigations forensiques, conformité HIPAA stricte), l'audit des opérations CRUD devrait être évité en production ou limité à des fenêtres temporelles spécifiques.

**Rotation et compression régulières** : La rotation fréquente des logs d'audit avec compression immédiate réduit la taille des fichiers et améliore les performances d'écriture.

### Comparaison Performance selon Configuration

Audit DDL uniquement (authentification, schéma) : **< 5% d'impact** - Configuration recommandée pour la conformité standard.

Audit authentification + autorisation (sans CRUD) : **5-10% d'impact** - Bon équilibre sécurité/performance.

Audit CRUD avec filtres précis : **15-20% d'impact** - Acceptable pour investigations ciblées.

Audit CRUD sans filtre : **30-50%+ d'impact** - À éviter absolument en production.

Format BSON vs JSON : **5-10% d'amélioration** avec BSON.

Percona vs MongoDB Enterprise : Impact comparable, bien que Percona enregistre sélectivement moins d'événements par défaut, pouvant légèrement améliorer les performances.

## ⚠️ Points de Vigilance

**Continuité de service** : L'activation de l'audit nécessite un redémarrage du serveur MongoDB (sauf pour MongoDB 5.0+ avec configuration runtime). Dans les environnements de production, cette opération doit être planifiée avec soin, en suivant la séquence appropriée dans les replica sets (secondaires d'abord, puis primaire).

**Stockage et saturation disque** : Les logs d'audit peuvent croître très rapidement, particulièrement avec `auditAuthorizationSuccess: true`. Un cluster haute activité peut générer plusieurs gigaoctets de logs quotidiennement. La mise en place d'une stratégie de rotation et rétention est **impérative** pour éviter la saturation du système de fichiers, qui pourrait entraîner l'arrêt du serveur MongoDB.

**Dégradation des performances CRUD** : L'activation de `auditAuthorizationSuccess` dégrade significativement les performances des opérations de lecture/écriture. Cette dégradation peut affecter les temps de réponse applicatifs et nécessiter un redimensionnement de l'infrastructure. La documentation officielle MongoDB met explicitement en garde contre cet impact.

**Complexité de la syntaxe de filtrage** : La syntaxe des filtres d'audit, bien que puissante, présente une courbe d'apprentissage significative. Des filtres mal conçus peuvent soit laisser passer des événements critiques, soit générer un volume excessif de logs. Les filtres doivent être soigneusement testés en environnement de pré-production.

**Différences Percona vs MongoDB Enterprise** : Les organisations envisageant une migration entre Percona et MongoDB Enterprise (ou inversement) doivent noter les différences dans la syntaxe de filtrage et les formats supportés. Percona ne supporte que JSON et n'offre pas la configuration runtime, nécessitant une adaptation des procédures opérationnelles.

**Coût MongoDB Atlas** : Le surcoût de 10% pour l'audit Atlas peut représenter une dépense significative pour les organisations avec de nombreux clusters ou des configurations de grande taille. Un cluster M40 à 1,13$/heure (environ 815$/mois) verrait son coût augmenter de 81$/mois avec l'audit activé.

**Garantie d'audit** : MongoDB garantit que tous les événements d'audit sont écrits sur disque avant l'ajout de l'opération correspondante au journal (journal). Cette garantie assure qu'aucune opération modifiant l'état de la base ne peut être effectuée sans trace d'audit correspondante. Cependant, cette synchronisation renforce l'impact performance des opérations d'écriture.

**Conformité réglementaire** : L'absence d'audit dans MongoDB Community Edition rend cette version **inadaptée** aux environnements soumis à des exigences réglementaires strictes (PCI-DSS, HIPAA, SOC2, RGPD en contexte sensible). Les organisations dans ces secteurs doivent obligatoirement utiliser MongoDB Enterprise, Atlas, ou Percona Server.

**Accès et privilèges audit** : Pour la configuration d'audit runtime (MongoDB 5.0+), les utilisateurs doivent disposer du privilège `auditConfigure`. La gestion incorrecte de ces privilèges peut créer des vulnérabilités de sécurité ou empêcher la configuration appropriée de l'audit.

**Intégration SIEM** : Bien que l'intégration avec des SIEM via syslog soit possible, elle introduit une dépendance supplémentaire et des points de défaillance potentiels. La perte de connectivité avec le serveur syslog peut entraîner la perte d'événements d'audit ou l'accumulation de buffers dans MongoDB.
