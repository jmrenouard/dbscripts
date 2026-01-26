# Patroni: Configuration sur Red Hat (RHEL 7/8)

## Table des matières
- [Patroni: Configuration sur Red Hat (RHEL 7/8)](#patroni-configuration-sur-red-hat-rhel-78)
  - [Table des matières](#table-des-matières)
  - [Objectif de la procédure](#objectif-de-la-procédure)
  - [Prérequis](#prérequis)
  - [Configuration du service Systemd](#configuration-du-service-systemd)
  - [Paramétrage de Patroni (Fichier YAML)](#paramétrage-de-patroni-fichier-yaml)
  - [Exemple de script d'automatisation](#exemple-de-script-dautomatisation)
  - [Différences RHEL 7 vs RHEL 8](#différences-rhel-7-vs-rhel-8)

> Ce document décrit le paramétrage de Patroni basé sur Etcd pour les environnements Red Hat Enterprise Linux 7 et 8.

## Objectif de la procédure

Réaliser le paramétrage complet de Patroni pour orchestrer la haute disponibilité PostgreSQL en s'appuyant sur un cluster Etcd comme magasin de configuration distribuée (DCS).

## Prérequis

- Accès root au serveur Linux.
- Cluster Etcd déjà installé et fonctionnel.
- PostgreSQL installé sur les nœuds.

## Configuration du service Systemd

Un seul service systemd est utilisé pour gérer l'instance Patroni.

**Fichier :** `/etc/systemd/system/patroni.service`

```ini
[Unit]
Description=Runners to orchestrate a high-availability PostgreSQL
After=syslog.target network.target

[Service]
Type=simple
User=postgres
Group=postgres
# Assurez-vous que le chemin vers python3 ou patroni est correct
ExecStart=/usr/local/bin/patroni /etc/patroni.yaml
KillMode=process
TimeoutSec=30
Restart=no

[Install]
WantedBy=multi-user.target
```

## Paramétrage de Patroni (Fichier YAML)

Le fichier de configuration définit les interfaces réseau, la connexion Etcd, et les paramètres PostgreSQL.

**Fichier :** `/etc/patroni.yaml`

```yaml
scope: postgres_cluster
namespace: /db/
name: pg-node1

restapi:
  listen: 0.0.0.0:8008
  connect_address: 192.168.36.15:8008

etcd:
  host: 192.168.36.22:2379
  # username: patroni
  # password: patroni

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
  bin_dir: /usr/pgsql-16/bin  # Adapter selon la version
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

## Exemple de script d'automatisation

Ce script génère la configuration YAML et démarre le service systemd.

```bash
#!/bin/sh
# Usage: ./config_patroni.sh <port>

port=${1:-"5432"}
api_port=$(($port + 2000))
SELF_IP=$(hostname -I | awk '{print $1}')
SUID=$(hostname -s)

# 1. Nettoyage et arrêt
systemctl stop patroni 2>/dev/null
systemctl disable patroni 2>/dev/null

# 2. Génération du fichier YAML
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

# 3. Activation et démarrage
chown postgres. /etc/patroni.yaml
systemctl daemon-reload
systemctl enable patroni
systemctl start patroni

echo "Patroni configuré. Suivi des logs : tail -f /var/log/patroni/patroni.log"
```

## Différences RHEL 7 vs RHEL 8

| Élément | RHEL 7 | RHEL 8 |
|:---|:---|:---|
| Gestionnaire | `yum` | `dnf` |
| Python | Python 2.7 / 3.6 | Python 3.6 / 3.9 |
| PostgreSQL | Souvent < 12 | Souvent >= 12 |
| Pare-feu | `firewalld` (iptables backend) | `firewalld` (nftables backend) |

---
Source: Procédures d'exploitation Patroni sur distribution Red Hat.
