# Playbook: Deploy and configure MySQL InnoDB Cluster

This playbook deploys and configures a MySQL InnoDB cluster.

## Roles

- **common**: Prepares the base servers.
- **mysql_server**: Installs MySQL Server.
- **mysql_cluster**: Configures and initializes the InnoDB Cluster.

## Variables

This playbook does not use any user-provided variables directly, but the included roles might.

## Example Usage

To run this playbook, use the following command:

```bash
ansible-playbook playbook_innodb_cluster_group.yml
```
