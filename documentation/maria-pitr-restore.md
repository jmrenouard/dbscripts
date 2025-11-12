# Technical Documentation - Point-In-Time Recovery (PITR) with MariaDB Binlogs

## 1. Introduction
Point-In-Time Recovery (**PITR**) allows restoring a MariaDB database to a specific point in time using **binary logs (binlogs)**. This method is crucial for recovering data after accidental deletions or corruption.

This document describes how a Bash script automates binlog-based recovery and provides a step-by-step procedure for performing a PITR operation.

---
## 2. Script Functionality

### 2.1 Objective
The **Restore Binlog GTID** script restores MariaDB binlog events from a **specific GTID** up to a defined date and time.

### 2.2 Script Steps
1. **Retrieve the current GTID position.**
2. **Identify the binlog file containing this GTID.**
3. **Select subsequent binlog files for recovery.**
4. **Execute `mariadb-binlog` to replay transactions up to the specified date.**

### 2.3 Script Parameters
| Parameter | Description |
|-----------|-------------|
| `$1` | Path to the directory containing binlog files |
| `$2` | End date for recovery (format: YYYY-MM-DD) |
| `$3` | End time for recovery (format: HH:MM:SS) |

### 2.4 Script Execution
```bash
./script.sh /var/lib/mysql/binlogs 2025-03-12 09:30:00
```

---
## 3. PITR Procedure with MariaDB Binlogs

### 3.1 Prerequisites
- **CommVault** must be available for restoring snapshots and binlogs.
- A full database backup must be available before the incident.
- Binlog must be enabled (`log_bin` must be active in MariaDB).
- A MariaDB user with the necessary privileges is required.

### 3.2 Recovery Steps

#### **Step 1: Restore the Database via CommVault Snapshot**
First, restore a **full snapshot** of the database to a point before the incident.
Once the snapshot restoration is complete, ensure that the MariaDB server is operational.

#### **Step 2: Restore Binlogs via CommVault**
The required binlog files must be restored from CommVault into a specific directory.
Ensure that the restored binlogs are complete and available in the designated path.

Example:
```bash
ls -lah /path/to/restored-binlogs/
```

#### **Step 3: Identify the Last Known GTID**
If GTID is enabled, find the last known GTID after the snapshot restoration:
```sql
SHOW VARIABLES LIKE 'gtid_current_pos';
```

#### **Step 4: Locate the Binlog Files to Use**
Binlogs contain transactions after the last known GTID. Identify which binlog contains your GTID:
```bash
ls -lah /path/to/restored-binlogs/
```

#### **Step 5: Execute the Recovery Script**
Run the script to apply binlogs up to the target date and time:
```bash
./script.sh /path/to/restored-binlogs 2025-03-12 09:30:00
```
This will replay all changes from the binlogs up to the specified point in time.

#### **Step 6: Verify Data Integrity**
After recovery, check that the data is correct:
```sql
SELECT * FROM affected_table WHERE ...;
```

#### **Step 7: Restart MariaDB and Validate**
Once the recovery is completed, restart MariaDB if necessary:
```bash
systemctl restart mariadb
```
Test the application to confirm proper functionality.

---
## 4. Conclusion
Using **CommVault snapshots** combined with **MariaDB binlogs** allows precise and efficient PITR. This approach simplifies the recovery process and ensures better backup management. PITR is crucial for mitigating accidental deletions or partial data corruption. It is recommended to automate these steps and conduct regular recovery tests to ensure a fast response in case of an incident.

---
## 5. References
- [Official MariaDB Documentation on Binlogs](https://mariadb.com/kb/en/binary-log/)
- [Point-in-Time Recovery Guide](https://mariadb.com/kb/en/point-in-time-recovery/)
- [CommVault Documentation](https://documentation.commvault.com/