# **Guide de Migration : PostgreSQL 15 (PGPool) vers PostgreSQL 17 (Patroni)**

Ce document détaille les stratégies de migration pour basculer d'un cluster PostgreSQL 15 géré par PGPool vers un cluster PostgreSQL 17 orchestré par Patroni.

## **Architecture de Cible (Patroni)**

L'architecture cible repose sur Patroni pour la gestion du cycle de vie des instances et un outil de consensus (DCS) comme Etcd ou Consul pour l'élection du leader.
```mermaid
graph TD  
    subgraph "Nouveau Cluster Patroni (v17)"  
        N1\[Patroni Node 1 \- Leader\]  
        N2\[Patroni Node 2 \- Replica\]  
        DCS\[(Etcd / Consul)\]  
        N1 \<--\> DCS  
        N2 \<--\> DCS  
        N1 \-- Streaming Replication \--\> N2  
    end  
    subgraph "Ancien Cluster PGPool (v15)"  
        PG1\[PG 15 Primary\]  
        PG2\[PG 15 Standby\]  
        PP\[PGPool-II\]  
        PP \--\> PG1  
        PP \--\> PG2  
    end  
    LB\[Load Balancer / VIP\] \--\> N1
```
## **Étude des Scénarios de Migration**

Le choix de la méthode dépend principalement de la volumétrie des données et de la fenêtre d'indisponibilité (SLA) acceptable.

| Méthode | Temps d'indisponibilité | Complexité | Risque | Cas d'usage |
| :---- | :---- | :---- | :---- | :---- |
| **pg\_dump / pg\_restore** | Élevé | Faible | Faible | Bases \< 500 Go |
| **pgbackrest \+ pg\_upgrade** | Modéré (minutes) | Moyenne | Moyen | Grosses bases, même OS |
| **Réplication Logique Native** | Quasi-nul | Moyenne | Moyen | Migration 24/7 standard |
| **Bucardo** | Quasi-nul | Élevée | Moyen | Multi-maître / Versions disparates |
| **Debezium (CDC)** | Quasi-nul | Très élevée | Élevé | Migration avec transformation / Microservices |

## **1\. Méthode : Dump & Restore (via pg\_dump)**

### **✅ Avantages**

* Nettoyage complet du "bloat".  
* Vérification de l'intégrité des données.

### **❌ Inconvénients**

* Indisponibilité totale durant l'import/export.  
* Consommation importante de ressources IO.

## **2\. Méthode : pgbackrest & pg\_upgrade**

### **✅ Avantages**

* Le plus rapide pour les très gros volumes grâce au mode \--link.

### **❌ Inconvénients**

* Nécessite une version de Glibc/ICU identique entre source et cible.

## **3\. Méthode : Bucardo (Réplication par Triggers)**

Bucardo est une solution de réplication asynchrone qui utilise des triggers pour capturer les changements.

### **⚙️ Prérequis**

* **Perl** installé sur le serveur de contrôle.  
* L'extension **plperl** activée sur PostgreSQL.  
* Accès **Superuser** sur les deux clusters.  
* Les tables doivent idéalement posséder une clé primaire (PK).

### **✅ Avantages**

* **Multi-maître** : Permet d'écrire sur les deux clusters simultanément durant la transition.  
* **Flexibilité** : Peut synchroniser des bases avec des structures de tables légèrement différentes.  
* **Versions** : Très robuste pour migrer depuis de très vieilles versions vers PG 17\.

### **❌ Inconvénients**

* **Performance** : Les triggers ajoutent une surcharge (overhead) sur chaque écriture (INSERT/UPDATE/DELETE).  
* **Maintenance** : Gestion complexe des conflits si les deux côtés sont modifiés.

### **💻 Étapes de réalisation**

1. Installer Bucardo et créer sa base de contrôle.  
2. Ajouter les bases : bucardo add db source\_pg15 dbname=..., bucardo add db target\_pg17 dbname=....  
3. Ajouter les tables : bucardo add all tables.  
4. Créer la synchronisation : bucardo add sync migration\_sync relgroup=... dbs=source\_pg15:source,target\_pg17:target.

## **4\. Méthode : Debezium (Change Data Capture \- CDC)**

Debezium capture les changements directement dans les WAL (Write Ahead Logs) et les diffuse via Kafka.

### **⚙️ Prérequis**

* Infrastructure **Apache Kafka** et **Kafka Connect** opérationnelle.  
* wal\_level \= logical sur le cluster source (PG 15).  
* Plugin de décodage logique (ex: pgoutput) disponible.  
* Slot de réplication dédié.

### **✅ Avantages**

* **Découplage total** : La source et la cible ne communiquent pas directement.  
* **Transformation** : Possibilité de transformer les données à la volée (via Kafka Connect SMT).  
* **Audit** : Conserve un historique des événements de changement dans les topics Kafka.

### **❌ Inconvénients**

* **Infrastructure lourde** : Demande une expertise Kafka en plus de PostgreSQL.  
* **Complexité de monitoring** : Il faut surveiller le lag Kafka, le lag du connecteur et le lag de la base cible.

### **💻 Étapes de réalisation**

1. Configurer le connecteur source Debezium pour lire les WAL du PG 15\.  
2. Les changements sont publiés dans des topics Kafka (un par table).  
3. Configurer un connecteur "Sink" (ex: JDBC Sink ou Debezium Sink) pour appliquer les messages sur le cluster PG 17\.  
4. Basculer l'application une fois que le "Lag" Kafka est proche de zéro.

### **📈 Architecture Debezium**

graph LR  
    PG15\[(PG 15 Source)\] \-- WAL \--\> DBZ\[Debezium Connector\]  
    DBZ \-- JSON Events \--\> K\[Kafka Cluster\]  
    K \-- Stream \--\> SNK\[Sink Connector\]  
    SNK \-- SQL \--\> PG17\[(PG 17 Cible)\]

## **⚠️ Risques de Sécurité et Continuité**

| Nature du Risque | Outil | Description | Mitigation |
| :---- | :---- | :---- | :---- |
| **Surcharge Source** | **Bucardo** | Les triggers ralentissent les transactions applicatives. | Benchmarker l'impact sur une pré-prod. |
| **Rétention WAL** | **Debezium** | Si Kafka s'arrête, les WAL s'accumulent sur le PG 15\. | Alerter sur l'espace pg\_wal et le lag du slot. |
| **Incohérence** | **Bucardo** | Conflits de mise à jour si l'app écrit des deux côtés. | Privilégier un mode Read-Only sur la source au moment du switch. |
| **Fuite de données** | **Debezium** | Données sensibles transitant en clair dans Kafka. | Chiffrer les topics Kafka et sécuriser les accès TLS. |

## **Synthèse des prérequis Patroni**

Pour l'une ou l'autre de ces méthodes, l'intégration finale dans Patroni nécessite :

1. Un **DCS** (Etcd/Consul) configuré pour la v17.  
2. Une validation du paramètre max\_worker\_processes pour supporter les flux de réplication supplémentaires.  
3. Un script de bascule (Switchover) testé pour rediriger le trafic applicatif vers le nouveau Leader Patroni.

Sources consultées :

* Documentation Bucardo 5.6.  
* Debezium Documentation (PostgreSQL Connector).  
* Patroni Core Documentation v4.0.
