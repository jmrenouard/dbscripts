# Patroni: Configuration sur Red Hat (RHEL 7/8)

## Table des matières
- [Objectif de la procédure](#objectif-de-la-procédure)
- [Prérequis](#prérequis)
- [Configuration du service Systemd](#configuration-du-service-systemd)
- [Paramétrage de Patroni (Fichier YAML)](#paramétrage-de-patroni-(fichier-yaml))
- [Exemple de script d'automatisation](#exemple-de-script-d'automatisation)
- [Différences RHEL 7 vs RHEL 8](#différences-rhel-7-vs-rhel-8)

> Ce document décrit le paramétrage de Patroni basé sur Etcd pour les environnements Red Hat Enterprise Linux 7 et 8.

## Objectif de la procédure

Réaliser le paramétrage complet de Patroni pour orchestrer la haute disponibilité PostgreSQL en s'appuyant sur un cluster Etcd comme magasin de configuration distribuée (DCS).

## Prérequis

- Accès root au serveur Linux.
- Cluster Etcd déjà installé et fonctionnel.
- PostgreSQL installé sur les nœuds.

## Configuration du service Systemd

L'utilisation d'un template systemd permet de gérer plusieurs instances sur le même serveur si nécessaire.

**Fichier :** `/etc/systemd/system/patroni@.service`

```ini
[Unit]
Description=Runners to orchestrate a high-availability PostgreSQL %I
After=syslog.target network.target

[Service]
Type=simple
User=postgres
Group=postgres
# Sur RHEL 8, assurez-vous que le chemin vers python3 ou patroni est correct
ExecStart=/usr/local/bin/patroni /admin/etc/patroni_%I.yaml
KillMode=process
TimeoutSec=30
Restart=no

[Install]
WantedBy=multi-user.target
```

## Paramétrage de Patroni (Fichier YAML)

Le fichier de configuration définit les interfaces réseau, la connexion Etcd, et les paramètres PostgreSQL appliqués par le DCS.

**Fichier type :** `/admin/etc/patroni_tarif.yaml`

```yaml
scope: tarif_cluster
namespace: /tarif/
name: tarif-node1

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
  listen: 0.0.0.0:6003
  connect_address: 192.168.36.15:6003
  data_dir: /base/tarif
  config_dir: /base/tarif
  bin_dir: /usr/pgsql-11/bin  # Adapter selon la version (ex: /usr/pgsql-13/bin sur RHEL 8)
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

Ce script génère dynamiquement la configuration YAML et le service systemd pour une instance donnée.

```bash
#!/bin/sh
# Usage: ./config_patroni.sh <instance_name> <port>

instance=${1:-"tarif"}
port=${2:-"6003"}
api_port=$(($port + 2000))
SELF_IP=$(hostname -I | awk '{print $1}')
SUID=$(hostname -s)

# 1. Nettoyage et arrêt
systemctl stop patroni@${instance} 2>/dev/null
systemctl disable patroni@${instance} 2>/dev/null

# 2. Génération du fichier YAML
cat <<EOF > /admin/etc/patroni_${instance}.yaml
scope: ${instance}_cluster
namespace: /${instance}/
name: ${instance}-${SUID}

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
  data_dir: /base/${instance}
  bin_dir: /usr/pgsql-11/bin
  authentication:
    replication: {username: replication, password: rep_password}
    superuser: {username: postgres, password: postgres_password}
EOF

# 3. Activation et démarrage
chown postgres. /admin/etc/patroni_${instance}.yaml
systemctl daemon-reload
systemctl enable patroni@${instance}
systemctl start patroni@${instance}

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
