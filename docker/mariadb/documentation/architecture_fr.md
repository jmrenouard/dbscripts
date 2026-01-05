# Architecture Globale 🏗️

Ce document décrit la topologie réseau et serveur de l'environnement Docker MariaDB.

## 🌐 1. Architecture du Cluster Galera

Le cluster Galera fournit une réplication multi-maître synchrone.

### Topologie Réseau

- **Sous-réseau** : `10.6.0.0/24`
- **Répartiteur de charge (LB)** : `10.6.0.100` (HAProxy)

### Schéma

```mermaid
graph TD
    Client[Client / App] -->|Port 3306| LB[HAProxy LB<br/>10.6.0.100]
    
    subgraph Galera_Cluster [Cluster Galera : 10.6.0.0/24]
        LB -->|LB / Health Check| G1[mariadb-g1<br/>10.6.0.11]
        LB -->|LB / Health Check| G2[mariadb-g2<br/>10.6.0.12]
        LB -->|LB / Health Check| G3[mariadb-g3<br/>10.6.0.13]
        
        G1 <-->|Sync : 4567, 4568, 4444| G2
        G2 <-->|Sync : 4567, 4568, 4444| G3
        G3 <-->|Sync : 4567, 4568, 4444| G1
    end
```

### Access Ports

| Nom Logique | Nœud | Adresse IP | Port MariaDB | Port SSH |
| :--- | :--- | :--- | :--- | :--- |
| `mariadb-g1` | Nœud 1 | `10.6.0.11` | 3511 | 22001 |
| `mariadb-g2` | Nœud 2 | `10.6.0.12` | 3512 | 24002 |
| `mariadb-g3` | Nœud 3 | `10.6.0.13` | 3513 | 24003 |
| `haproxy_galera` | Load Balancer | `10.6.0.100` | 3306 | N/A |

---

## 🔄 2. Architecture du Cluster de Réplication

Le cluster de réplication utilise une topologie classique Maître/Esclave avec GTID.

### Topologie Réseau

- **Sous-réseau** : `10.5.0.0/24`
- **Répartiteur de charge (LB)** : `10.5.0.100` (HAProxy)

### Schéma

```mermaid
graph TD
    Client_W[Client Écriture] -->|Port 3406| LB[HAProxy LB<br/>10.5.0.100]
    Client_R[Client Lecture] -->|Port 3407| LB
    
| Nœud 2 | 3412 | 23002 | Esclave 1 |
| Nœud 3 | 3413 | 23003 | Esclave 2 |
| HAProxy (W) | 3406 | N/A | Point d'entrée -> Maître |
| HAProxy (R) | 3407 | N/A | Point d'entrée -> Esclaves (LB) |
