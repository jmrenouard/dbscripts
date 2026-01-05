# Test Cases & Results 🧪

This document describes the automated test suites available to validate the clusters.

## 🌐 1. Galera Test Suite (`test_galera.sh`)

### Test Cases

1. **Connectivity & Status**: Verifies all 3 nodes are UP, `wsrep_ready=ON`, and cluster size is 3.
2. **Synchronous Replication**:
   - Write on Node 1 -> Read on Node 2 and Node 3.
   - Write on Node 3 -> Read on Node 1.
3. **Auto-increment Consistency**: Ensures each node uses a different offset to avoid ID collisions.
4. **Certification Conflict (Optimistic Locking)**: Simulates simultaneous updates on the same row across different nodes to trigger a deadlock/certification failure.
5. **DDL Replication**: Runs `ALTER TABLE` on one node and verifies schema changes on others.
6. **Unique Key Constraint**: Verifies that duplicate entry errors are correctly propagated and handled.

### Typical Results

```text
✅ Node at port 3511 is UP (Ready: ON, Cluster Size: 3, State: Synced, SSL: TLS_AES_128_GCM_SHA256, GTID: 1)
✅ Node 2 received data correctly
✅ Node 1: Column 'new_col' exists
✅ Node 2 correctly rejected duplicate entry
```

---

## 🔄 2. Replication Test Suite (`test_repli.sh`)

### Test Cases

1. **Connectivity & SSL**: Checks if Master and both Slaves are reachable and reports SSL status.
2. **Topology Verification**: Displays `SHOW MASTER STATUS` and `SHOW SLAVE STATUS` (IO/SQL threads).
3. **Data Replication**:
   - Create DB/Table on Master.
   - Write sample data on Master.
   - Verify data presence on Slave 1 and Slave 2 after a short delay.

### Typical Results

```text
✅ Port 3411 is UP (SSL: TLS_AES_128_GCM_SHA256)
✅ Slave 1 received: Hello from Master at Mon Jan  5 08:30:00 UTC 2026
```

---

## 🏎️ 3. Performance Tests (Sysbench)

Executed via `test_perf_galera.sh` or `test_perf_repli.sh`.

- **Output**: Generates a high-quality HTML report (e.g., `test_perf_galera.html`).
- **Metrics**: TPS (Transactions Per Second), Latency (95th percentile), and Error rates.
