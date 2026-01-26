# Overview of MongoDB Audit and Traceability Solutions

## Table of contents
- [Audit Availability by Version](#audit-availability-by-version)
- [MongoDB Community Edition](#mongodb-community-edition)
- [MongoDB Enterprise Edition](#mongodb-enterprise-edition)
- [MongoDB Atlas](#mongodb-atlas)
- [Percona Server for MongoDB](#percona-server-for-mongodb)
- [Audit Architecture and Configuration](#audit-architecture-and-configuration)
- [Audit Log Destinations](#audit-log-destinations)
- [Log Formats](#log-formats)
- [Essential Configuration Parameters](#essential-configuration-parameters)
- [Audited Events and Filters](#audited-events-and-filters)
- [Event Categories](#event-categories)
- [Advanced Audit Filters](#advanced-audit-filters)
- [Audit Log Rotation](#audit-log-rotation)
- [Complementary Monitoring and Traceability Tools](#complementary-monitoring-and-traceability-tools)
- [MongoDB Profiler vs Audit Log](#mongodb-profiler-vs-audit-log)
- [Atlas Query Profiler](#atlas-query-profiler)
- [Third-Party Audit Solutions](#third-party-audit-solutions)
- [Performance Impact](#performance-impact)
- [Factors Determining Performance Impact](#factors-determining-performance-impact)
- [Performance Optimization Strategies](#performance-optimization-strategies)
- [Performance Comparison by Configuration](#performance-comparison-by-configuration)
- [⚠️ Points of Vigilance](#⚠️-points-of-vigilance)

Audit and traceability solutions differ considerably between MongoDB versions. The Community version lacks any native audit functionality, while MongoDB Enterprise, MongoDB Atlas, and Percona Server for MongoDB offer complete audit capabilities with notable differences in terms of cost and features.

## Audit Availability by Version

### MongoDB Community Edition

MongoDB Community Edition offers **no native audit functionality**. This free open-source version, distributed under the Server Side Public License (SSPL), is primarily suitable for development and test environments without strict regulatory requirements. For Community version users requiring auditing, the only alternatives are using third-party tools like mongoaudit for point-in-time security audits or migrating to a version that supports auditing.

### MongoDB Enterprise Edition

MongoDB Enterprise Edition integrates a **complete and robust audit system** available for `mongod` and `mongos` instances. This commercial version offers the widest range of audit features, including support for multiple formats (JSON, BSON) and log destinations, as well as advanced filters allowing for precise targeting of events to record.

Enterprise audit systematically captures schema operations (DDL), actions on replica sets and sharded clusters, authentication and authorization, as well as CRUD operations when the `auditAuthorizationSuccess` parameter is enabled. Since MongoDB 5.0, audit filter configuration can be modified at runtime without server restart, providing significant operational flexibility.

MongoDB 8.0 introduces support for the **OCSF (Open Cybersecurity Schema Framework)** schema for audit messages, facilitating integration with modern SIEM platforms and standardized log processing tools.

### MongoDB Atlas

MongoDB Atlas, MongoDB's Database-as-a-Service solution, offers auditing for **M10 clusters and above**. Enabling auditing is done via the Atlas user interface or REST API, offering granular control over audited events.

For organizations using Atlas without an Enterprise or Platinum subscription, enabling audit results in a **10% surcharge on the hourly rate for all dedicated clusters** in the project. For example, an M10 cluster costing approximately $57 per month would see its cost increase to about $63 with audit enabled. Enterprise and Platinum customers benefit from audit at no additional charge.

Atlas automatically generates audit logs in JSON format and stores them in the cloud infrastructure. These logs can be viewed via the Atlas interface or exported to external systems for in-depth analysis. Log rotation is managed automatically by the platform.

### Percona Server for MongoDB

Percona Server for MongoDB represents a **free and open-source alternative** to MongoDB Enterprise, including audit features without license costs. Distributed under the GPL license, Percona Server is based on MongoDB Community Edition but enriched with enterprise-level features.

Percona audit differs slightly from MongoDB Enterprise: it supports only **JSON** format (no BSON), and filtering syntax has some differences. Unlike MongoDB Enterprise, Percona does not offer runtime audit configuration; any modification requires a server restart.

Percona also provides more selective filtering by default, recording mainly major commands rather than all events, which can reduce log volume and performance impact.

## Audit Architecture and Configuration

### Audit Log Destinations

MongoDB Enterprise and Percona offer three primary destinations for audit logs:

**File**: Audit events are written to a file on the local file system. This destination is the standard choice for production, allowing for persistent storage and controlled log rotation. The file path is specified via the `auditLog.path` parameter.

**Syslog**: Events are sent to the operating system's syslog daemon, facilitating integration with centralized log management systems and SIEM platforms like Splunk or ELK. This destination is particularly suitable for distributed architectures requiring centralized collection.

**Console**: Audit events are written to standard output (stdout). This destination is **strongly discouraged in production** due to its high performance impact, but can be useful for debugging in development environments.

### Log Formats

MongoDB Enterprise supports two main formats for recording audit events:

**JSON**: Readable text format, facilitating manual analysis and integration with many log processing tools. However, this format generates a **higher performance impact** than BSON format, particularly under high load.

**BSON**: MongoDB's native binary format, offering better write performance with a reduced impact of 5-10% compared to JSON. BSON logs require the `bsondump` utility to be converted into readable format.

To view BSON logs, the following command converts the file to readable JSON format:

```bash
bsondump /var/lib/mongodb/auditLog.bson
```

### Essential Configuration Parameters

MongoDB audit configuration relies on several key parameters in the `mongod.conf` file or via command line:

**auditLog.destination**: Defines where to send events (file, syslog, console).

**auditLog.format**: Specifies the log format (JSON or BSON).

**auditLog.path**: Full path to the log file (required if destination = file).

**auditLog.filter**: JSON filtering expression to select which events to audit.

**auditLog.schema**: Since MongoDB 8.0, allows choosing between the `mongo` schema (default) and `OCSF` for standardized compatibility.

**auditAuthorizationSuccess**: Crucial parameter enabling auditing of CRUD operations (read/write). Defaulting to `false`, this parameter must be explicitly enabled via `setParameter` to record authorization successes.

Basic configuration example in `mongod.conf`:

```yaml
auditLog:
  destination: file
  format: BSON
  path: /var/log/mongodb/auditLog.bson
  filter: '{ atype: { $in: ["authenticate", "createCollection", "dropCollection"] } }'
```

## Audited Events and Filters

### Event Categories

MongoDB can audit a wide range of operations divided into several categories:

**Schema (DDL)**: Data definition operations including `createCollection`, `dropCollection`, `createDatabase`, `dropDatabase`, `createIndex`, `dropIndex`, and `renameCollection`. These events have a **low performance impact** as they are relatively infrequent.

**Authentication**: `authenticate` event type recording successful and failed login attempts, allowing for detection of unauthorized access. Authentication auditing represents a fundamental security practice with minimal performance impact.

**Authorization**: `authCheck` type capturing privilege checks for all operations. When `auditAuthorizationSuccess` is disabled (default), only **authorization failures** are recorded, limiting performance impact.

**CRUD (Read/Write)**: Data operations including `find`, `insert`, `update`, `delete`, `findandmodify`, `aggregate`, `count`, and `distinct`. These operations strictly require enabling `auditAuthorizationSuccess: true` and generate a **significant performance impact** (15-30%) due to their high frequency.

**User and Role Management**: Events like `createUser`, `dropUser`, `updateUser`, `createRole`, `grantRolesToUser`, `revokeRolesFromUser`. These administrative operations have minimal impact as they are infrequent.

**Replica Set and Sharding**: Cluster management operations including `replSetReconfig`, `replSetStateChange`, `addShard`, `removeShard`, `enableSharding`.

### Advanced Audit Filters

Audit filters allow for drastically reducing log volume and performance impact by precisely targeting relevant events. Filtering syntax uses JSON expressions similar to MongoDB queries.

**Filter by action type**: Audit only deletion operations:

```json
{ "atype": { "$in": ["dropIndex", "dropCollection", "dropDatabase"] } }
```

**Filter by user**: Record actions from specific users:

```yaml
auditLog:
  destination: file
  format: JSON
  path: /var/log/mongodb/auditLog.json
  filter: '{ "users.user": /^prod_app/ }'
```

**Filter by database or collection**: Audit only a specific database:

```json
{ "param.ns": /^production\./ }
```

**Filter CRUD operations by command**: Record only certain read/write operations:

```yaml
auditLog:
  destination: file
  format: BSON
  path: /var/log/mongodb/auditLog.bson
  filter: '{ 
    "atype": "authCheck", 
    "param.command": { "$in": ["find", "insert", "delete", "update"] },
    "param.ns": /^test\\./ 
  }'
setParameter: 
  auditAuthorizationSuccess: true
```

**Filter by role**: Audit actions of users with a specific role:

```json
{ 
  "roles": { "role": "readWrite", "db": "production" } 
}
```

Since MongoDB 5.0, filters can be modified at runtime via the `setAuditConfig` command without requiring a restart, offering considerable operational agility:

```javascript
db.adminCommand({
  setAuditConfig: 1,
  filter: { "atype": { "$in": ["authenticate", "createUser"] } },
  auditAuthorizationSuccess: false
})
```

### Audit Log Rotation

Audit log rotation is essential to avoid file system saturation. MongoDB does not automatically rotate audit logs; this operation must be triggered manually or via external tools.

**Manual rotation via command**: From the `mongosh` interface connected to the `admin` database:

```javascript
// Rotate server log only
db.adminCommand({ logRotate: "server" })

// Rotate audit log only
db.adminCommand({ logRotate: "audit", comment: "Scheduled Rotation" })

// Rotate both logs simultaneously
db.adminCommand({ logRotate: 1 })
```

**Rotation via system signal**: Sending the SIGUSR1 signal to the `mongod` process:

```bash
kill -SIGUSR1 $(pidof mongod)
```

**Integration with logrotate**: Recommended configuration for automating rotation:

```bash
# /etc/logrotate.d/mongodb-audit
/var/log/mongodb/auditLog*.json {
  daily
  rotate 15
  compress
  delaycompress
  missingok
  notifempty
  create 644 mongod mongod
  postrotate
    /bin/kill -SIGUSR1 $(pidof mongod) 2>/dev/null || true
  endscript
}
```

Rotation behavior is controlled by the `systemLog.logRotate` parameter:

- **rename** (default): MongoDB renames the current file by adding a UTC timestamp and creates a new file.
- **reopen**: MongoDB closes and reopens the file, expecting an external tool (like logrotate) to have already renamed it.

## Complementary Monitoring and Traceability Tools

### MongoDB Profiler vs Audit Log

The **Database Profiler** and **Audit Log** are two distinct mechanisms addressing different needs:

**Database Profiler**: Performance diagnostic tool recording operation execution metrics in the `system.profile` collection. It focuses on analyzing slow queries (slowms) and provides detailed statistics like execution time, documents examined, and index usage. The profiler can be enabled per database with three levels (0: disabled, 1: slow queries only, 2: all operations). It is **performance-oriented** rather than security-oriented.

**Audit Log**: Security and compliance-oriented traceability system, recording **who** did **what** and **when**. Unlike the profiler, the audit log does not focus on performance but on accountability and security anomaly detection.

### Atlas Query Profiler

MongoDB Atlas offers the **Query Profiler**, an integrated monitoring tool available on M10+ clusters. This profiler automatically identifies slow queries based on log data from `mongod` instances, with an adaptive threshold managed by Atlas based on average execution time.

The Atlas Query Profiler displays interactive visualizations (scatterplots) of slow operations and provides optimization recommendations, including index suggestions. It differs from the classic Database Profiler as it does not require profiling level configuration and does not impact performance.

### Third-Party Audit Solutions

**DataSunrise**: Third-party platform offering advanced audit capabilities for MongoDB with a "Sniffer" mode generating **negligible performance impact**. DataSunrise captures the full activity history, integrates with Elasticsearch and Kibana, and uses artificial intelligence for audit trace analysis.

**ELK Stack (Elasticsearch, Logstash, Kibana)**: Popular solution for centralized analysis of MongoDB audit logs. JSON or BSON (converted) logs can be ingested by Logstash and visualized in Kibana, offering advanced search and analysis capabilities.

**Splunk and other SIEM**: Professional SIEM platforms allowing for real-time aggregation and analysis of MongoDB audit events via syslog integration or file ingestion.

## Performance Impact

Enabling audit invariably generates an impact on MongoDB server performance, the extent of which depends on several factors.

### Factors Determining Performance Impact

**auditAuthorizationSuccess Parameter**: Enabling this parameter to audit CRUD operations represents the **most impactful factor**. With `auditAuthorizationSuccess: false` (default), only authorization failures are recorded, generating a 5-10% impact. With `auditAuthorizationSuccess: true`, auditing all read and write operations can degrade performance by **15-30% or more** depending on load.

**Audited Event Volume**: The higher the number of captured events, the greater the impact. Unfiltered auditing of all CRUD operations can cause a degradation of **30-50%+** in high-concurrency environments.

**Log Format**: BSON format offers **better performance** with a reduced impact of 5 to 10% compared to JSON. MongoDB recommends BSON for production and reserves JSON for cases requiring immediate readability.

**Log Destination**: Writing to a local file generates the lowest impact. Using syslog introduces a variable depending on network latency and syslog server load. Console destination is the **most penalizing** and must be avoided in production.

**Storage System**: Using a dedicated disk for audit logs, separate from MongoDB data storage, can significantly reduce impact by avoiding I/O contention.

**File System Configuration**: The DataSunrise "Sniffer" mode demonstrates that a non-intrusive approach can reduce impact to a **negligible** level. Conversely, a poorly optimized configuration can amplify the impact.

### Performance Optimization Strategies

**Selective Filtering**: Using precise audit filters constitutes the most effective optimization strategy. Instead of auditing all operations, targeting only critical events (authentication, schema modifications, privileged user operations) can drastically reduce volume and impact.

**Asynchronous Audit via Memory Buffer**: Although not directly documented for MongoDB, some audit implementations (like Percona MySQL) use memory buffers to reduce write impact. MongoDB writes audit events to a memory buffer before periodic disk persistence.

**Limitation to DDL and Authentication Events**: For most production environments, auditing limited to DDL (schema) and authentication operations offers an **excellent compromise** with a performance impact below 5%. This configuration satisfies many compliance requirements (GDPR, SOC2, PCI-DSS) without significantly degrading performance.

**Avoiding CRUD Audit in Production**: Unless strictly necessary (forensic investigations, strict HIPAA compliance), CRUD operations auditing should be avoided in production or limited to specific time windows.

**Regular Rotation and Compression**: Frequent audit log rotation with immediate compression reduces file size and improves write performance.

### Performance Comparison by Configuration

DDL Audit only (authentication, schema): **< 5% impact** - Recommended configuration for standard compliance.

Authentication + Authorization Audit (without CRUD): **5-10% impact** - Good security/performance balance.

CRUD Audit with precise filters: **15-20% impact** - Acceptable for targeted investigations.

CRUD Audit without filter: **30-50%+ impact** - To be absolutely avoided in production.

BSON vs JSON Format: **5-10% improvement** with BSON.

Percona vs MongoDB Enterprise: Comparable impact, although Percona selectively records fewer events by default, which can slightly improve performance.

## ⚠️ Points of Vigilance

**Service Continuity**: Enabling audit requires a MongoDB server restart (except for MongoDB 5.0+ with runtime configuration). In production environments, this operation must be carefully planned, following the appropriate sequence in replica sets (secondaries first, then primary).

**Storage and Disk Saturation**: Audit logs can grow very quickly, particularly with `auditAuthorizationSuccess: true`. A high-activity cluster can generate several gigabytes of logs daily. Implementing a rotation and retention strategy is **imperative** to avoid file system saturation, which could lead to MongoDB server shutdown.

**CRUD Performance Degradation**: Enabling `auditAuthorizationSuccess` significantly degrades read/write operation performance. This degradation can affect application response times and require infrastructure rightsizing. Official MongoDB documentation explicitly warns against this impact.

**Filtering Syntax Complexity**: Audit filter syntax, while powerful, presents a significant learning curve. Poorly designed filters can either let critical events through or generate an excessive volume of logs. Filters should be carefully tested in a pre-production environment.

**Percona vs MongoDB Enterprise Differences**: Organizations considering a migration between Percona and MongoDB Enterprise (or vice-versa) should note differences in filtering syntax and supported formats. Percona only supports JSON and does not offer runtime configuration, necessitating adaptation of operational procedures.

**MongoDB Atlas Cost**: The 10% surcharge for Atlas audit can represent a significant expense for organizations with many clusters or large configurations. An M40 cluster at $1.13/hour (about $815/month) would see its cost increase by $81/month with audit enabled.

**Audit Guarantee**: MongoDB guarantees that all audit events are written to disk before the corresponding operation is added to the journal. This guarantee ensures that no operation modifying database state can be performed without a corresponding audit trace. However, this synchronization reinforces the performance impact of write operations.

**Regulatory Compliance**: The absence of audit in MongoDB Community Edition makes this version **unsuitable** for environments subject to strict regulatory requirements (PCI-DSS, HIPAA, SOC2, GDPR in sensitive contexts). Organizations in these sectors must use MongoDB Enterprise, Atlas, or Percona Server.

**Audit Access and Privileges**: For runtime audit configuration (MongoDB 5.0+), users must have the `auditConfigure` privilege. Incorrect management of these privileges can create security vulnerabilities or prevent proper audit configuration.

**SIEM Integration**: While SIEM integration via syslog is possible, it introduces an additional dependency and potential points of failure. Loss of connectivity with the syslog server can lead to loss of audit events or buffer accumulation in MongoDB.

---
Source: Internal Study - Audit Solutions for MongoDB
