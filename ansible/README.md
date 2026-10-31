# Ansible Automation & Cluster Playbooks

Ansible playbooks and roles for multi-node database automation, MySQL InnoDB Cluster orchestration, remote script execution with artifact extraction, S3-to-RDS migration, and Redis Cluster ACL management.

## Directory Layout

```text
ansible/
├── roles/                  # common, mysql-server, mysql_servers, mysql_cluster, rundeck
├── group_vars/             # Host group variable definitions
└── *.yaml / *.yml          # Database and cluster automation playbooks (see table below)
```

## Playbook Inventory Matrix

| Playbook | Target / Role | Key Variables & Defaults | Command Example |
|---|---|---|---|
| `add_localhost_hosts.yaml` | `localhost` | None (backs up `/etc/hosts`) | `ansible-playbook add_localhost_hosts.yaml` |
| `add_user.yml` | `{{ target }}` | `target`, `muser`, `mgroup` (`muser`) | `ansible-playbook add_user.yml -e "target=node1 muser=deployer"` |
| `distro_upgrade.yml` | `{{ target }}` (`all`) | `target` (default `all`) | `ansible-playbook distro_upgrade.yml -e "target=ubuntu-node"` |
| `import_s3_dump_rds_executor.yml` | `{{ target }}` (`mysql-servers`) | `target`, `dbname`, `rds_mysql_*`, `s3_shared_bucket`, `rds_executor` | `ansible-playbook import_s3_dump_rds_executor.yml -e "rds_mysql_hostname=rds s3_shared_bucket=b rds_executor=h"` |
| `install_goss.yaml` | `all` | None (installs Goss binary) | `ansible-playbook install_goss.yaml` |
| `install_packages.yml` | `{{ target }}` | `target` (`net-tools`, `htop`, `pigz`) | `ansible-playbook install_packages.yml -e "target=web"` |
| `install_rundeck.yaml` | `{{ target }}` (`admin-vm`) | Roles: `mysql-server`, `rundeck` | `ansible-playbook install_rundeck.yaml -e "target=ops"` |
| `install_scripts.yaml` | `{{ target }}` (`all`) | `target`, `muser`, `mgroup`, `basedir` | `ansible-playbook install_scripts.yaml -e "target=all muser=admin"` |
| `playbook_innodb_cluster_group.yml` | `all` | Roles: `common`, `mysql_servers`, `mysql_cluster` | `ansible-playbook playbook_innodb_cluster_group.yml` |
| `run_script.yaml` | `{{ target }}` (`mysql`) | `target`, `script`, `outputdir` (`result`), `tmpdir`, `max_time` (`180`) | `ansible-playbook run_script.yaml -e "target=db script=scripts/bin/show_cql_grants.py"` |
| `update_apt_distribution.yaml` | `{{ target }}` (`all`) | `target`, `type` (`yes`/`dist`), `reboot` (`no`) | `ansible-playbook update_apt_distribution.yaml -e "target=servers type=dist"` |
| `update_rh_distribution.yaml` | `{{ target }}` (`all`) | `target` (default `all`) | `ansible-playbook update_rh_distribution.yaml -e "target=servers"` |
| `add_redis_user.yaml` | `redis` | `user`, `email`, `profile` (`READ_ONLY`, `READ_WRITE`, `ADMIN`) | `ansible-playbook add_redis_user.yaml -e "user=u email=e profile=READ_ONLY"` |
| `change_redis_user_password.yaml` | `redis` | `user`, `password` | `ansible-playbook change_redis_user_password.yaml -e "user=u password=p"` |
| `delete_redis_user.yaml` | `redis` | `user` | `ansible-playbook delete_redis_user.yaml -e "user=u"` |

## Key Workflows

### 1. MySQL InnoDB Cluster Deployment (`playbook_innodb_cluster_group.yml`)
Deploys a 3-node MySQL 8.0 InnoDB Cluster with Group Replication:
1. `common`: Prepares OS prerequisites, sysctl parameters, and firewall rules.
2. `mysql_servers`: Installs MySQL Server 8.0, configures GTID consistency, and starts mysqld.
3. `mysql_cluster`: Deploys MySQL Shell, bootstraps primary cluster node, and joins secondary members.
`ansible-playbook -i inventory.ini playbook_innodb_cluster_group.yml`

### 2. Remote Script Execution with Artifact Collection (`run_script.yaml`)
Stages, executes, and extracts artifacts from remote hosts:
1. Cleans local output directory (`outputdir`, default `result/`).
2. Stages target script to `/var/tmp/generic` and enforces timeout (`max_time: 180`).
3. Fetches generated logs and result files back to the control node.
`ansible-playbook run_script.yaml -e "target=db script=scripts/bin/show_cql_grants.py"`

### 3. S3 to Amazon RDS Database Import (`import_s3_dump_rds_executor.yml`)
Automates database migration from AWS S3 dumps into Amazon RDS MySQL with verification:
1. Validates RDS connectivity and retrieves dump files from `s3_shared_bucket`.
2. Imports database dumps through the designated `rds_executor` host.
3. Asserts import integrity by comparing created table counts and row counts against dump metadata.
`ansible-playbook import_s3_dump_rds_executor.yml -e "rds_mysql_hostname=rds s3_shared_bucket=dumps rds_executor=h"`

### 4. Redis Cluster ACL Management
Manages Redis 6+ Access Control Lists across multi-node cluster instances (ports 7000–7005):
- Profiles: `READ_ONLY` (`-@all +@read +@list +@string +@hash +@bitmap +@pubsub +PING ~*`), `READ_WRITE`, `ADMIN`.
- Add user: `ansible-playbook add_redis_user.yaml -e "user=u email=e profile=READ_ONLY"`
- Rotate password: `ansible-playbook change_redis_user_password.yaml -e "user=u password=secret"`
- Delete user: `ansible-playbook delete_redis_user.yaml -e "user=u"`

## Testing & Validation

```bash
python -m unittest tests/test_ansible_structure.py -v
python -m unittest discover -s tests -v
```
