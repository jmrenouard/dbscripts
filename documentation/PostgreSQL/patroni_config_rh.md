# Patroni: Configuration on Red Hat (RHEL 7/8)

## Table of contents
- [Procedure Objective](#procedure-objective)
- [Prerequisites](#prerequisites)
- [Systemd Service Configuration](#systemd-service-configuration)
- [Patroni Parameters (YAML File)](#patroni-parameters-(yaml-file))
- [Automation Script Example](#automation-script-example)
- [RHEL 7 vs RHEL 8 Differences](#rhel-7-vs-rhel-8-differences)

> This document describes the Patroni configuration based on Etcd for Red Hat Enterprise Linux 7 and 8 environments.

## Procedure Objective

Perform the complete configuration of Patroni to orchestrate PostgreSQL high availability using an Etcd cluster as the Distributed Configuration Store (DCS).

## Prerequisites

- Root access to the Linux server.
- Functional Etcd cluster already installed.
- PostgreSQL installed on the nodes.

## Systemd Service Configuration

A single systemd service is used to manage the Patroni instance.

**File:** `/etc/systemd/system/patroni.service`

```ini
[Unit]
Description=Runners to orchestrate a high-availability PostgreSQL
After=syslog.target network.target

[Service]
Type=simple
User=postgres
Group=postgres
# Ensure the path to python3 or patroni is correct
ExecStart=/usr/local/bin/patroni /etc/patroni.yaml
KillMode=process
TimeoutSec=30
Restart=no

[Install]
WantedBy=multi-user.target
```

## Patroni Parameters (YAML File)

The configuration file defines network interfaces, Etcd connection, and PostgreSQL parameters.

**File:** `/etc/patroni.yaml`

```yaml
scope: postgres_cluster
namespace: /db/
name: pg-node1

restapi:
  listen: 0.0.0.0:8008
  connect_address: 192.168.36.15:8008

etcd:
  host: 192.168.36.22:2379

bootstrap:
  dcs:
    ttl: 100
    loop_wait: 10
    retry_timeout: 10
    maximum_lag_on_failover: 1048576
    postgresql:
      use_pg_rewind: true
      use_slots: true
      parameters:
        wal_level: replica
        hot_standby: "on"
        wal_keep_segments: 8
        max_wal_senders: 5
        max_replication_slots: 5
        checkpoint_timeout: 30

postgresql:
  listen: 0.0.0.0:5432
  connect_address: 192.168.36.15:5432
  data_dir: /var/lib/pgsql/data
  bin_dir: /usr/pgsql-16/bin  # Adjust based on version
  authentication:
    replication:
      username: replication
      password: MyPassword123
    superuser:
      username: postgres
      password: postgres

tags:
  nofailover: false
  noloadbalance: false
  clonefrom: true

log:
  dir: /var/log/patroni
  level: INFO
```

## Automation Script Example

This script generates the YAML configuration and starts the systemd service.

```bash
#!/bin/sh
# Usage: ./config_patroni.sh <port>

port=${1:-"5432"}
api_port=$(($port + 2000))
SELF_IP=$(hostname -I | awk '{print $1}')
SUID=$(hostname -s)

# 1. Cleanup and stop
systemctl stop patroni 2>/dev/null

# 2. YAML file generation
cat <<EOF > /etc/patroni.yaml
scope: pg_cluster
namespace: /db/
name: pg-${SUID}

restapi:
  listen: ${SELF_IP}:${api_port}
  connect_address: ${SELF_IP}:${api_port}

etcd:
  host: 192.168.36.22:2379

bootstrap:
  dcs:
    ttl: 30
    loop_wait: 10
    retry_timeout: 10
    postgresql:
      use_pg_rewind: true
      parameters:
        wal_level: replica
        hot_standby: "on"

postgresql:
  listen: 0.0.0.0:${port}
  connect_address: ${SELF_IP}:${port}
  data_dir: /var/lib/pgsql/data
  bin_dir: /usr/pgsql-16/bin
  authentication:
    replication: {username: replication, password: rep_password}
    superuser: {username: postgres, password: postgres_password}
EOF

# 3. Activation and start
chown postgres. /etc/patroni.yaml
systemctl daemon-reload
systemctl enable patroni
systemctl start patroni

echo "Patroni configured. Follow logs: tail -f /var/log/patroni/patroni.log"
```

## RHEL 7 vs RHEL 8 Differences

| Element | RHEL 7 | RHEL 8 |
|:---|:---|:---|
| Package Manager | `yum` | `dnf` |
| Python | Python 2.7 / 3.6 | Python 3.6 / 3.9 |
| PostgreSQL | Often < 12 | Often >= 12 |
| Firewall | `firewalld` (iptables backend) | `firewalld` (nftables backend) |

---
Source: Patroni operating procedures on Red Hat distributions.
