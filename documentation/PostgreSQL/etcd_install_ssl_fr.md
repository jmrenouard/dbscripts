# Etcd v3.6 : Installation et Configuration SSL sur RHEL 8

## Table des matières
- [Objectif de la procédure](#objectif-de-la-procédure)
- [1. Installation des binaires Etcd v3.6](#1.-installation-des-binaires-etcd-v3.6)
- [2. Génération des certificats SSL/TLS](#2.-génération-des-certificats-ssl/tls)
- [Architecture des fichiers](#architecture-des-fichiers)
- [3. Configuration du service Systemd (etcd3)](#3.-configuration-du-service-systemd-(etcd3))
- [4. Contrôle du cluster (API v3)](#4.-contrôle-du-cluster-(api-v3))
- [5. Authentification et Sécurité v3](#5.-authentification-et-sécurité-v3)
- [Activation de l'authentification](#activation-de-l'authentification)
- [Gestion des utilisateurs (Script Expect)](#gestion-des-utilisateurs-(script-expect))
- [6. Manipulation des clés (API v3)](#6.-manipulation-des-clés-(api-v3))

> Ce document décrit le déploiement sécurisé d'un cluster Etcd v3.6 de 3 nœuds sur Red Hat Enterprise Linux 8 avec chiffrement SSL/TLS.

## Objectif de la procédure

Réaliser le déploiement d'un cluster Etcd hautement disponible et sécurisé pour servir de magasin de configuration (DCS) à Patroni.

## 1. Installation des binaires Etcd v3.6

Sur RHEL 8, il est recommandé d'installer Etcd via les binaires officiels pour garantir la version 3.6.

```bash
# Variables de version
ETCD_VER=v3.6.0
GOOGLE_URL=https://storage.googleapis.com/etcd
GITHUB_URL=https://github.com/etcd-io/etcd/releases/download
DOWNLOAD_URL=${GITHUB_URL}

# Téléchargement et extraction
curl -L ${DOWNLOAD_URL}/${ETCD_VER}/etcd-${ETCD_VER}-linux-amd64.tar.gz -o /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz
tar xzvf /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz -C /usr/local/bin --strip-components=1
rm -f /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz

# Vérification
etcd --version
etcdctl version
```

## 2. Génération des certificats SSL/TLS

La sécurité repose sur une Autorité de Certification (CA) interne. Utilisez `openssl` ou `cfssl`.

### Architecture des fichiers

- `/etc/etcd/ssl/ca.pem` : Certificat racine
- `/etc/etcd/ssl/server.pem` : Certificat pour l'API client
- `/etc/etcd/ssl/peer.pem` : Certificat pour la communication entre nœuds

```bash
mkdir -p /etc/etcd/ssl
# [Etape de génération de certificats omise pour la brièveté, utiliser les outils standards de l'entreprise]
chown -R etcd:etcd /etc/etcd/ssl
chmod 600 /etc/etcd/ssl/*.key
```

## 3. Configuration du service Systemd (etcd3)

Le service doit utiliser des URLs `https` et pointer vers les certificats générés.

**Fichier :** `/etc/systemd/system/etcd3.service`

```ini
[Unit]
Description=etcd
Documentation=https://github.com/coreos/etcd
Conflicts=etcd.service

[Service]
Type=notify
User=etcd
Group=etcd
Restart=always
RestartSec=10s
LimitNOFILE=40000
TimeoutStartSec=0

ExecStart=/usr/local/bin/etcd \
  --name etcd-${HOSTNAME} \
  --data-dir /var/lib/etcd \
  --auto-compaction-retention 3 \
  # Configuration Client (HTTPS)
  --listen-client-urls https://${SELF_IP}:2379,https://127.0.0.1:2379 \
  --advertise-client-urls https://${SELF_IP}:2379 \
  --client-cert-auth --trusted-ca-file=/etc/etcd/ssl/ca.pem \
  --cert-file=/etc/etcd/ssl/server.pem --key-file=/etc/etcd/ssl/server-key.pem \
  # Configuration Peer (HTTPS)
  --listen-peer-urls https://${SELF_IP}:2380 \
  --initial-advertise-peer-urls https://${SELF_IP}:2380 \
  --peer-client-cert-auth --peer-trusted-ca-file=/etc/etcd/ssl/ca.pem \
  --peer-cert-file=/etc/etcd/ssl/peer.pem --peer-key-file=/etc/etcd/ssl/peer-key.pem \
  # Cluster settings
  --initial-cluster etcd-node1=https://${NODE1}:2380,etcd-node2=https://${NODE2}:2380,etcd-node3=https://${NODE3}:2380 \
  --initial-cluster-token my-etcd-token \
  --initial-cluster-state new

[Install]
WantedBy=multi-user.target
```

## 4. Contrôle du cluster (API v3)

Avec SSL, `etcdctl` nécessite les certificats pour communiquer.

```bash
export ETCDCTL_API=3
export ETCDCTL_CACERT=/etc/etcd/ssl/ca.pem
export ETCDCTL_CERT=/etc/etcd/ssl/server.pem
export ETCDCTL_KEY=/etc/etcd/ssl/server-key.pem
export ETCDCTL_ENDPOINTS=https://127.0.0.1:2379

# État du cluster
etcdctl endpoint health
etcdctl member list
```

## 5. Authentification et Sécurité v3

L'API v2 est dépréciée dans la v3.6, focalisez-vous sur l'API v3.

### Activation de l'authentification

```bash
# 1. Créer le rôle root et l'utilisateur root
etcdctl user add root
etcdctl role add root
etcdctl user grant-role root root

# 2. Activer l'authentification
etcdctl auth enable
```

### Gestion des utilisateurs (Script Expect)

```perl
use Expect;
my $user = $ARGV[0];
my $pass = $ARGV[1];
my $exp = Expect->spawn("etcdctl user add $user");
$exp->expect(30, [ 'Password:' => sub { $exp->send("$pass\n"); exp_continue; } ]);
$exp->soft_close();
```

## 6. Manipulation des clés (API v3)

```bash
# Ajouter une clé
etcdctl put /db/postgres/leader "node1"

# Récupérer récursivement
etcdctl get /db --prefix

# Supprimer
etcdctl del /db/postgres/leader
```

---
Source: Guide d'installation Etcd v3.6 sécurisé sur RHEL 8
