# **Analyse Comparative : PgPool-II vs Patroni**

Cette analyse explore les différences fondamentales entre deux solutions majeures pour la haute disponibilité (HA) et la gestion de clusters PostgreSQL. Bien que leurs objectifs convergent, leurs approches architecturales divergent radicalement.

## **🏗️ Architecture et Topologie des Clusters**

La différence majeure réside dans la structure même du système : un modèle à deux clusters séparés contre un modèle de cluster unifié.

### **PgPool-II : L'Architecture à Double Cluster (Decoupled)**

PgPool-II fonctionne selon une topologie **Middleware**. On distingue deux entités séparées :

1. **Le Cluster PgPool-II** : Un ensemble de nœuds "Proxy" (souvent 2 ou 3\) qui communiquent entre eux via le protocole *Watchdog*.  
2. **Le Cluster PostgreSQL** : Un ensemble de serveurs de bases de données (Primary/Standbys) qui existent indépendamment de PgPool.  
* **Relation** : Les deux clusters sont découplés. PgPool-II "regarde" le cluster PostgreSQL de l'extérieur.

### **Patroni : L'Architecture Unifiée (Symbiotic)**

Patroni fonctionne selon une topologie de **Cluster Distribué Unifié**.

* **Le Nœud Patroni** : Sur chaque machine, Patroni et PostgreSQL vivent ensemble. Patroni est le parent du processus PostgreSQL.  
* **Unicité** : Il n'y a qu'un seul cluster. Chaque membre du cluster est un duo indissociable {Patroni \+ PostgreSQL}. L'état global est coordonné par le DCS (etcd/Consul).

## **✅ Avantages et ❌ Inconvénients**

### **PgPool-II**

| Aspect | ✅ Avantages | ❌ Inconvénients |
| :---- | :---- | :---- |
| **Performance** | Cache de requêtes intégré. | **Latence induite** : Doit décoder/analyser le protocole PostgreSQL (parsing SQL) pour chaque requête. |
| **Fiabilité HA** | — | **Risque Scripting** : Repose sur des scripts shell externes (failover\_command) fragiles et complexes. |
| **Reprise (Healing)** | — | **Aucune reprise automatique** : Ne sait pas ré-intégrer un ancien primaire sans intervention manuelle. |
| **Topologie** | Les proxys peuvent être mis à jour sans toucher aux bases de données. | Gestion de **deux clusters distincts** (Watchdog \+ Réplication), doublant la complexité d'administration. |
| **Routage** | Séparation Lectures/Écritures native. | Souvent limité au **nœud primaire seul** pour des raisons de sécurité (éviter les stale reads). |

### **Patroni**

| Aspect | ✅ Avantages | ❌ Inconvénients |
| :---- | :---- | :---- |
| **Fiabilité HA** | **Logique intégrée** : Le basculement est codé en dur (Python). Pas de scripts shell instables. | Nécessite une infrastructure de consensus (Cluster etcd ou Consul). |
| **Performance** | **Zéro latence** : Patroni n'est pas un proxy ; l'application parle directement à Postgres (ou via un routage L4). | — |
| **Gestion de Cycle** | **Auto-healing complet** : Automatise le pg\_rewind et la reconstruction des replicas. | Ne gère pas le pooling de connexions nativement. |
| **Topologie** | **Cluster unifié** : Un seul objet à gérer. La base et son gardien sont toujours synchronisés. | Si Patroni s'arrête brutalement, il peut arrêter Postgres par sécurité (Demise). |

## **📈 Architecture de Flux et Structure (Mermaid)**
```mermaid
graph TD  
    subgraph "Modèle PgPool-II (Cluster de Proxys \+ Cluster de Bases)"  
        subgraph "Cluster Proxys (Watchdog)"  
            P1[PgPool Node 1] <--> P2[PgPool Node 2]  
        end  
        subgraph "Cluster Data (Replication)"  
            M[Postgres Primary] <--- S1[Postgres Standby]  
        end  
        App [Application] --> P1  
        P1 -- "Analyse & Décodage SQL" --> P1  
        P1 -- "Flux vers" --> M  
        P1 -- "Scripts Shell" -.-> Scripts[failover.sh]  
    end

    subgraph "Modèle Patroni (Cluster Unifié)"  
        subgraph "DCS (Quorum)"  
            E[(etcd / Consul)]  
        end  
        subgraph "Nœud 1"  
            Pat1[Patroni] --- DB1[(Postgres)]  
        end  
        subgraph "Nœud 2"  
            Pat2[Patroni] --- DB2[(Postgres)]  
        end  
        Pat1 <--> E  
        Pat2 <--> E  
        App2[Application] -- "Direct / L4 Proxy" --> DB1  
    end
```
## **⚙️ Paramètres Clés de Configuration**

### **Pour PgPool-II (Extraits de pgpool.conf)**

* failover\_command : **⚠️ Point critique** : Chemin vers un script shell externe. C'est ici que les erreurs de personnalisation surviennent.  
* load\_balance\_mode : Souvent mis à off pour router uniquement vers le primaire par sécurité.

### **Pour Patroni (Extraits de patroni.yml)**

* use\_pg\_rewind : true. Utilise la logique interne pour ré-intégrer un nœud sans scripts.  
* loop\_wait : Intervalle de la machine à états interne (pas de script, logique native).

## **💻 Comparaison Opérationnelle**

### **La problématique des Scripts Shell (PgPool-II)**

Dans PgPool-II, le comportement en cas de panne est défini par l'utilisateur via des scripts. Ces scripts doivent gérer le SSH, le changement d'IP, et la promotion. Une simple erreur de "if/else" dans le script shell peut rendre le cluster indisponible ou provoquer un **Split Brain**.

### **La robustesse du Code Intégré (Patroni)**

Patroni remplace les scripts par une **State Machine** (machine à états). Le comportement est prédictible : si le verrou (leader key) expire dans etcd, Patroni sait exactement quoi faire selon son code source standardisé. Il n'y a pas de place pour une "customisation" hasardeuse de la logique de base du failover.

## **📊 Résumé Décisionnel**

| Critère | Choisir PgPool-II si... | Choisir Patroni si... |
| :---- | :---- | :---- |
| **Structure** | Vous gérez deux entités séparées (Proxy vs Database). | Vous gérez un ensemble de nœuds autonomes et intelligents. |
| **Stabilité** | Vous avez des experts en scripting Shell/Système. | Vous voulez une logique HA robuste et "codée" (Python). |
| **Latence** | L'overhead du décodage SQL est acceptable pour vous. | Vous voulez une performance maximale (Direct Path). |
| **Maintenance** | Basculement et ré-intégration manuelle acceptables. | Vous exigez du Self-healing (reprise auto après failover). |

**Sources :**

* *PgPool-II Documentation (v4.5), 2024\.*  
* *Patroni Documentation \- Zalando Open Source, 2024\.*  
* *PostgreSQL High Availability: The Case Against Manual Scripting.*
