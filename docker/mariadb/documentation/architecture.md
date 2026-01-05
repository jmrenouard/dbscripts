# Global Architecture 🏗️

This document describes the network and server topology of the MariaDB Docker environment.

## 🌐 1. Galera Cluster Architecture

The Galera cluster provides synchronous multi-master replication.

### Network Topology

- **Subnet**: `10.6.0.0/24`
- **Load Balancer**: `10.6.0.100` (HAProxy)

### Diagram

```mermaid
graph TD
    Client[Client / App] -->|Port 3306| LB[HAProxy LB: 10.6.0.100]
    LB -->|Health Check / R-R| G1[Galera Node 1: 10.6.0.11]
    LB -->|Health Check / R-R| G2[Galera Node 2: 10.6.0.12]
    LB -->|Health Check / R-R| G3[Galera Node 3: 10.6.0.13]
    
    subgraph Galera_Cluster [Internal Network 10.6.0.x]
        G1 <-->|Port 4567, 4568, 4444| G2
        G2 <-->|Port 4567, 4568, 4444| G3
        G3 <-->|Port 4567, 4568, 4444| G1
    end
```

### Access Ports

| Node | MariaDB Port | SSH Port |
| :--- | :--- | :--- |
| Node 1 | 3511 | 22001 |
| Node 2 | 3512 | 24002 |
| Node 3 | 3513 | 24003 |
| HAProxy | 3306 | N/A |

---

## 🔄 2. Replication Cluster Architecture

The replication cluster uses a classic Master/Slave topology with GTID.

### Network Topology

- **Subnet**: `10.5.0.0/24`
- **Load Balancer**: `10.5.0.100` (HAProxy)

### Diagram

```mermaid
graph TD
    Client_W[Write Client] -->|Port 3406| LB[HAProxy LB: 10.5.0.100]
    Client_R[Read Client] -->|Port 3407| LB
    
    LB -->|Writes| M1[Master: 10.5.0.11]
    LB -->|Read RR| S1[Slave 1: 10.5.0.12]
    LB -->|Read RR| S2[Slave 2: 10.5.0.13]
    
    subgraph Replication_Flow [Internal Network 10.5.0.x]
        M1 --"Asynchronous (GTID)"--> S1
        M1 --"Asynchronous (GTID)"--> S2
    end
```

### Access Ports

| Node | MariaDB Port | SSH Port | Role |
| :--- | :--- | :--- | :--- |
| Node 1 | 3411 | 23001 | Master |
| Node 2 | 3412 | 23002 | Slave 1 |
| Node 3 | 3413 | 23003 | Slave 2 |
| HAProxy (W) | 3406 | N/A | Entry Point -> Master |
| HAProxy (R) | 3407 | N/A | Entry Point -> Slaves (LB) |
