# Overview of Audit and Traceability Solutions for PostgreSQL

Audit and traceability solutions for PostgreSQL come in several approaches, each suited to specific needs in terms of compliance, security, and operation monitoring. This overview covers different versions of PostgreSQL (open source community), EnterpriseDB (EDB Postgres Advanced Server), and Percona Distribution for PostgreSQL.

## Native PostgreSQL Audit Solutions

PostgreSQL offers several integrated traceability mechanisms that form the basis of any audit system.

**Connection and Disconnection Logging**
The parameters `log_connections` and `log_disconnections` track all connections to the PostgreSQL server. When activated, they provide details on receipt, authentication method, and authorization (user, DB, application), including client IP and the `pg_hba.conf` file responsible for the decision.

**SQL Query Logging**
The `log_statement` parameter controls which SQL instruction categories are recorded: `none`, `ddl` (schema changes), `mod` (storage changes), or `all`.

**Duration-based Logging**
The `log_min_duration_statement` parameter records queries exceeding a certain execution time threshold, which is useful for identifying unoptimized queries without excessive log volume.

**pg_stat_statements**
This integrated extension collects execution statistics for all SQL queries, including execution counts, total/min/max/average times, and affected rows.

**pg_stat_activity**
A system view providing real-time visibility into active connections, including state and query duration.

## pgAudit: The Community Standard Extension

pgAudit is the most used open-source extension for PostgreSQL auditing, providing a much higher level of detail and granularity than native mechanisms.

**Key Features**

- **Session Audit:** Tracks SQL operations categorized as READ, WRITE, FUNCTION, ROLE, DDL, and MISC.
- **Object Audit:** Provides fine control by auditing only operations on specific objects using a dedicated audit role.

**Configuration**
Key parameters include `pgaudit.log`, `pgaudit.log_catalog`, `pgaudit.log_parameter`, and `pgaudit.role`.

## Custom Solutions with Triggers

PostgreSQL triggers allow for custom audit solutions to track data modifications at the row level. This approach is flexible for capturing BEFORE/AFTER states but cannot audit SELECT operations or DDL changes.

## EDB Postgres Advanced Server: Integrated Enterprise Audit

EnterpriseDB (EDB) provides EPAS, an enterprise edition with native advanced audit capabilities (EDB Audit).

- Format support: CSV, XML, JSON.
- Features: Automatic password redaction, object-level auditing, and simplified management via PEM (Postgres Enterprise Manager).

## Percona Distribution for PostgreSQL

Percona includes pre-tested enterprise-grade components, including pgAudit and `pg_stat_monitor` (an advanced alternative to `pg_stat_statements`), providing a robust open-source alternative.

## Conclusion and Recommendations

- **Small Projects:** Use native logging.
- **Regulatory Compliance (HIPAA, GDPR, PCI-DSS):** Use pgAudit.
- **Enterprise-grade Managed Audit:** Use EDB Postgres Advanced Server.
- **Data Change Tracking:** Use custom triggers.
