# Tutorial: MySQL Docker CLI Sandbox

> **Learning Goal:** Provision, inspect, stop, and remove a single-container MySQL sandbox using `docker/mysql_docker.py`.
> **Environment Warning:** Run this sandbox only on a local Docker workstation.

## Prerequisites

- Running Docker daemon and Python `docker` SDK (`pip install docker`)
- Free local TCP port allocated dynamically by `find_free_port()`

## Step 1: Start a MySQL Sandbox Container

Launch a container named `mysql-lab` with MySQL `8.0`:

```bash
python docker/mysql_docker.py start mysql-lab --db_type mysql --version 8.0
```

Expected output prints `Container mysql v8.0 launched successfully!`, the allocated `Access port`, and writes `mysql-lab.my.cnf` (`0600`) plus `mysql.bashrc`.

## Step 2: List Active Containers

Display managed MySQL, MariaDB, and Percona containers:

```bash
python docker/mysql_docker.py list --status running
```

Expected output prints a table with columns `Name`, `Image`, `HostPort`, and `Status`.

## Step 3: Stop and Remove the Sandbox

Stop the container, then remove the container, `mysql-lab.my.cnf`, and aliases:

```bash
python docker/mysql_docker.py stop mysql-lab
python docker/mysql_docker.py rm mysql-lab
```

Expected output confirms `Container mysql-lab removed successfully` without deleting the base `mysql:8.0` image.

## Next Steps

- Execute production runbooks: [How-To Guides](../02-how-to-guides/index.md)
- Look up CLI flags: [Scripts and CLI Reference](../03-reference/cli-and-scripts/scripts-and-cli-reference.md)
- Review architecture: [Explanation](../04-explanation/index.md)
