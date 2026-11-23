# How-To: Harden Firewall, TLS, and Redis Cluster ACLs

See [Automation Parameters and Ports](../../03-reference/configuration/automation-parameters-and-ports.md) first.

## Preconditions

1. Confirm root or `sudo` access on database hosts.
2. Confirm `openssl` and `firewalld` (or `iptables`) exist.
3. Confirm Ansible inventory defines group `redis` and `redis_auth_password`.

## Safety Instructions

**CAUTION:** `2_iptables.sh` flushes chains on CentOS 7 hosts. Verify SSH access before execution.

## Procedure

1. Open Galera, MySQL, Zabbix, and NRPE ports:

```bash
bash scripts/1_system/2_iptables.sh
```

2. Generate server and SST TLS certificates:

```bash
bash scripts/3_database/4a_mysql_server_ssl_access.sh /etc/mysql/ssl
```

3. Create a least-privilege Redis ACL user:

```bash
ansible-playbook ansible/add_redis_user.yaml -e "user=app_ro email=ops@example.com profile=READ_ONLY"
```

4. Rotate an active Redis ACL password:

```bash
ansible-playbook ansible/change_redis_user_password.yaml -e "redis_username=app_ro redis_password=<new-secret>"
```

## Verification Check

1. Run `firewall-cmd --list-all` and confirm ports `3306`, `4444`, `4567`, and `4568`.
2. Run `openssl verify -CAfile /etc/mysql/ssl/ca-cert.pem /etc/mysql/ssl/server-cert.pem`.
3. Confirm `ansible/add_redis_user.yaml` prints `PONG`.

## Rollback

1. Delete the Redis ACL user via `ansible-playbook ansible/delete_redis_user.yaml -e "user=app_ro"`.
2. Restore prior firewall rules or remove added `firewall-cmd` ports.

Related: [Parameters and Ports](../../03-reference/configuration/automation-parameters-and-ports.md) | [Architecture](../../04-explanation/architecture-overview/multi-db-automation-architecture.md)
