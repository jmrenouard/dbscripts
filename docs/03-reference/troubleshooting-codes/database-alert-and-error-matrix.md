# Database Alert and Error Matrix

Diagnostics, status conditions, exit codes, and runbook links.

| Code / Alert | Severity | Observed Condition / Cause | Remediation Runbook |
|---|---|---|---|
| `GAL-001` (`QuorumLost`) | Critical | `wsrep_cluster_status != Primary` or `safe_to_bootstrap: 0` in `grastate.dat`. | [Recover Galera Quorum](../../02-how-to-guides/incident-response/recover-galera-quorum-and-pitr.md) |
| `GAL-002` (`NodeNotReady`) | Warning | `wsrep_ready=OFF` or stale `galera.cache` / `gvwstate.dat`. | [Deploy Galera Cluster](../../02-how-to-guides/deployment/deploy-mariadb-galera-cluster.md) |
| `PITR-001` (`BinlogGTIDMissing`) | Critical | `maria-pitr-restore.sh` exits `1` (GTID missing in binlogs). | [Recover Galera Quorum](../../02-how-to-guides/incident-response/recover-galera-quorum-and-pitr.md) |
| `BCK-001` (`GaleraActiveRestore`) | Warning | `mbrestore.sh` (`RC=1`) or `lgrestore.sh` (`RC=2`) blocked (`wsrep_on=on`). | [Backup, Restore & TLS](../../02-how-to-guides/operations/backup-restore-and-ssl-rotation.md) |
| `BCK-002` (`ChecksumMismatch`) | Critical | `sha256sum -c` fails on `.xbstream.gz.sha256sum`. | [Backup, Restore & TLS](../../02-how-to-guides/operations/backup-restore-and-ssl-rotation.md) |
| `SSL-001` (`CertNearExpiry`) | Warning | `test_galera.sh` flags `server-cert.pem` expiry within 30 days. | [Backup, Restore & TLS](../../02-how-to-guides/operations/backup-restore-and-ssl-rotation.md) |
| `SEC-001` (`PortOrACLRejected`) | Warning | Ports `4567`/`4568`/`4444` blocked or Redis ACL `PONG` fails. | [Harden Firewall & ACLs](../../02-how-to-guides/security/harden-firewall-tls-and-redis-acl.md) |

Related: [Scripts & CLI](../cli-and-scripts/scripts-and-cli-reference.md) | [Parameters & Ports](../configuration/automation-parameters-and-ports.md)
