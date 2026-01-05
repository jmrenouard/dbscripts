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
    Client[Client / App] -->|Port 3306| LB[HAProxy LB: 10.6.0.100]
    LB -->|Health Check / R-R| G1[Galera Node 1: 10.6.0.11]
    LB -->|Health Check / R-R| G2[Galera Node 2: 10.6.0.12]
    LB -->|Health Check / R-R| G3[Galera Node 3: 10.6.0.13]
    
    subgraph Galera_Cluster [Réseau Interne 10.6.0.x]
        G1 <-->|Port 4567, 4568, 4444| G2
        G2 <-->|Port 4567, 4568, 4444| G3
        G3 <-->|Port 4567, 4568, 4444| G1
    end
```

### Ports d'Accès

| Nœud | Port MariaDB | Port SSH |
| :--- | :--- | :--- | :--- |
| Nœud 1 | 3511 | 22001 |
| Nœud 2 | 3512 | 24002 |
| Nœud 3 | 3513 | 24003 |
| HAProxy | 3306 | N/A |

---

## 🔄 2. Architecture du Cluster de Réplication

Le cluster de réplication utilise une topologie classique Maître/Esclave avec GTID.

### Topologie Réseau

- **Sous-réseau** : `10.5.0.0/24`
- **Répartiteur de charge (LB)** : `10.5.0.100` (HAProxy)

### Schéma

```mermaid
graph TD
    Client_W[Client Écriture] -->|Port 3406| LB[HAProxy LB: 10.5.0.100]
    Client_R[Client Lecture] -->|Port 3407| LB
    
    LB -->|Écritures| M1[Maître : 10.5.0.11]
    LB -->|Lecture RR| S1[Esclave 1 : 10.5.0.12]
    LB -->|Lecture RR| S2[Esclave 2 : 10.5.0.13]
    
    subgraph Replication_Flow [Réseau Interne 10.5.0.x]
        M1 --"Asynchrone (GTID)"--> S1
        M1 --"Asynchrone (GTID)"--> S2
    end
```

### Ports d'Accès

| Nœud | Port MariaDB | Port SSH | Rôle |
| :--- | :--- | :--- | :--- |
| Nœud 1 | 3411 | 23001 | Maître |
| Nœud 2 | 3412 | 23002 | Esclave 1 |
| Nœud 3 | 3413 | 23003 | Esclave 2 |
| HAProxy (W) | 3406 | N/A | Point d'entrée -> Maître |
| HAProxy (R) | 3407 | N/A | Point d'entrée -> Esclaves (LB) |
