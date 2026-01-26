# Etcd v3.6: SSL Installation and Configuration on RHEL 8

## Table of contents
- [Procedure Objective](#procedure-objective)
- [1. Etcd v3.6 Binary Installation](#1.-etcd-v3.6-binary-installation)
- [2. SSL/TLS Certificate Generation](#2.-ssl/tls-certificate-generation)
- [File Architecture](#file-architecture)
- [3. Systemd Service Configuration (etcd3)](#3.-systemd-service-configuration-(etcd3))
- [4. Cluster Control (API v3)](#4.-cluster-control-(api-v3))
- [5. Security and Authentication (v3)](#5.-security-and-authentication-(v3))
- [Enable Authentication](#enable-authentication)
- [User Management (Expect Script)](#user-management-(expect-script))
- [6. Key/Value Operations (API v3)](#6.-key/value-operations-(api-v3))

> This document describes the secure deployment of a 3-node Etcd v3.6 cluster on Red Hat Enterprise Linux 8 with SSL/TLS encryption.

## Procedure Objective

Deploy a highly available and secure Etcd cluster to act as the Distributed Configuration Store (DCS) for Patroni.

## 1. Etcd v3.6 Binary Installation

On RHEL 8, it is recommended to install Etcd using official binaries to ensure version 3.6 consistency.

```bash
# Version Variables
ETCD_VER=v3.6.0
GITHUB_URL=https://github.com/etcd-io/etcd/releases/download
DOWNLOAD_URL=${GITHUB_URL}

# Download and Extract
curl -L ${DOWNLOAD_URL}/${ETCD_VER}/etcd-${ETCD_VER}-linux-amd64.tar.gz -o /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz
tar xzvf /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz -C /usr/local/bin --strip-components=1
rm -f /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz

# Verification
etcd --version
etcdctl version
```

## 2. SSL/TLS Certificate Generation

Security is based on an internal Certificate Authority (CA). Use `openssl` or `cfssl`.

### File Architecture

- `/etc/etcd/ssl/ca.pem`: Root CA certificate
- `/etc/etcd/ssl/server.pem`: Server certificate for Client API
- `/etc/etcd/ssl/peer.pem`: Peer certificate for node-to-node communication

```bash
mkdir -p /etc/etcd/ssl
# [Certificate generation steps omitted, use corporate standard tools]
chown -R etcd:etcd /etc/etcd/ssl
chmod 600 /etc/etcd/ssl/*.key
```

## 3. Systemd Service Configuration (etcd3)

The service must use `https` URLs and point to the generated certificates.

**File:** `/etc/systemd/system/etcd3.service`

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
  # Client Configuration (HTTPS)
  --listen-client-urls https://${SELF_IP}:2379,https://127.0.0.1:2379 \
  --advertise-client-urls https://${SELF_IP}:2379 \
  --client-cert-auth --trusted-ca-file=/etc/etcd/ssl/ca.pem \
  --cert-file=/etc/etcd/ssl/server.pem --key-file=/etc/etcd/ssl/server-key.pem \
  # Peer Configuration (HTTPS)
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

## 4. Cluster Control (API v3)

With SSL, `etcdctl` requires certificates to communicate.

```bash
export ETCDCTL_API=3
export ETCDCTL_CACERT=/etc/etcd/ssl/ca.pem
export ETCDCTL_CERT=/etc/etcd/ssl/server.pem
export ETCDCTL_KEY=/etc/etcd/ssl/server-key.pem
export ETCDCTL_ENDPOINTS=https://127.0.0.1:2379

# Cluster Status
etcdctl endpoint health
etcdctl member list
```

## 5. Security and Authentication (v3)

API v2 is deprecated in v3.6; focus strictly on API v3.

### Enable Authentication

```bash
# 1. Create root role and root user
etcdctl user add root
etcdctl role add root
etcdctl user grant-role root root

# 2. Enable auth
etcdctl auth enable
```

### User Management (Expect Script)

```perl
use Expect;
my $user = $ARGV[0];
my $pass = $ARGV[1];
my $exp = Expect->spawn("etcdctl user add $user");
$exp->expect(30, [ 'Password:' => sub { $exp->send("$pass\n"); exp_continue; } ]);
$exp->soft_close();
```

## 6. Key/Value Operations (API v3)

```bash
# Add a key
etcdctl put /db/postgres/leader "node1"

# Recursive get
etcdctl get /db --prefix

# Delete
etcdctl del /db/postgres/leader
```

---
Source: Secure Etcd v3.6 Installation Guide for RHEL 8
