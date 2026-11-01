# Technical Documentation Index

Canonical technical documentation, standard operation sheets, and architectural references for database automation and Linux systems.

## General Documentation
- [Documentation Index Generator](generate_doc_description.md)
- [User Guide: Understanding Script Documentation](user_guide.md)

## Cassandra
- [DataStax Search (DSE Solr) Architecture](Cassandra/dse_solr.md)

## Linux System Administration
- [NFS Scripts for Database Backups](LinuxSystem/7_nfs.md)
- [SSHFS Remote Filesystem Mounting Guide](LinuxSystem/README_SSHFS.md)
- [Stunnel Encrypted Tunnel Setup](LinuxSystem/README_STUNNEL.md)

## MariaDB & Galera Cluster
- [Standard Operations: System Updates](MariaDB/1_update.md)
- [MariaDB Server Installation on CentOS/RHEL](MariaDB/1a_install_mariadb_centos.md)
- [Deploy Management Utilities and Scripts](MariaDB/1bis_deploy_scripts.md)
- [Firewall Configuration with firewalld and iptables](MariaDB/2_firewall.md)
- [MariaDB Resource-Based Server Configuration](MariaDB/3_config_start.md)
- [Galera Cluster Bootstrap Procedure](MariaDB/5_bootstrap_node.md)
- [Adding New Members to Galera Cluster](MariaDB/6_start_new_node.md)
- [Point-In-Time Recovery (PITR) with MariaDB Binlogs](MariaDB/maria-pitr-restore.md)

## MongoDB
- [Installing MongoDB Community with Docker](MongoDB/install_mongodb_docker.md)
- [MongoDB Audit and Traceability Study](MongoDB/mongodb_audit_study.md)
- [MongoDB CRUD Operations Reference](MongoDB/mongodb_crud_operations.md)

## PostgreSQL & Patroni HA
- [Overview of PostgreSQL Audit and Traceability](PostgreSQL/audit_study.md)
- [Physical Backup and Recovery Procedures](PostgreSQL/backup_physique.md)
- [Etcd v3.6 SSL Installation and Configuration](PostgreSQL/etcd_install_ssl.md)
- [Patroni Configuration on Red Hat Enterprise Linux](PostgreSQL/patroni_config_rh.md)
- [Patroni High Availability Test Cases](PostgreSQL/patroni_ha_tests.md)
- [Patroni Health and Metrics Monitoring](PostgreSQL/patroni_monitoring.md)
- [Patroni REST API Reference](PostgreSQL/patroni_rest_api.md)
- [PostgreSQL WAL Disk Performance Optimization](PostgreSQL/perfromance_wal_disk.md)
- [Specification: PostgreSQL Multi-Database Synchronization](PostgreSQL/spec_sync_pg_databases.md)
