# Patroni: HA Behavior Test Cases

## Table of contents
- [Procedure Objective](#procedure-objective)
- [Log Analysis /var/log/patroni/patroni.log](#log-analysis-/var/log/patroni/patroni.log)
- [Standby Server Tests (Stop/Reboot/Kill)](#standby-server-tests-(stop/reboot/kill))
- [Primary Server Tests (Stop/Reboot/Kill)](#primary-server-tests-(stop/reboot/kill))
- [Standby Node Isolation Tests (TCP Blocking)](#standby-node-isolation-tests-(tcp-blocking))
- [Primary Node Isolation Tests (TCP Blocking)](#primary-node-isolation-tests-(tcp-blocking))

> This document describes the test procedures to validate the High Availability (HA) behavior of a PostgreSQL cluster managed by Patroni.

## Procedure Objective

Perform usage and resilience tests on the Patroni/PostgreSQL platform across various failure scenarios.

## Log Analysis /var/log/patroni/patroni.log

An important point is the appearance of a Python *stack trace* when HaProxy servers test the `/read-write` URL on standby nodes (non-leaders). This is normal and indicates an abrupt client disconnection.

**Log Example:**

```text
2026-01-26 14:02:35,835 WARNING: Traceback (most recent call last):
  File "/usr/lib64/python3.9/socketserver.py", line 654, in process_request_thread
    self.finish_request(request, client_address)
  ...
ConnectionResetError: [Errno 104] Connection reset by peer
```

## Standby Server Tests (Stop/Reboot/Kill)

| ID | Test Scenario | Commands | Observations |
|:---|:---|:---|:---|
| 1 | Kill PostgreSQL process | `ps -edf\|grep '[/]usr/pgsql-16/bin/postgres' \| awk '{ print $2}' \| xargs kill -9` | Patroni automatically restarts the PostgreSQL server. Service remains operational. |
| 2 | Stop PostgreSQL server | `pg_ctl stop -D /var/lib/pgsql/data` | Patroni automatically restarts the PostgreSQL server. |
| 3 | Linux Server Reboot | `# reboot` | If Patroni service is `enabled`, it starts PostgreSQL on boot. No global service loss. |
| 4 | Stop Patroni service | `# systemctl stop patroni` | The PostgreSQL server is stopped at the same time. No failover as primary is healthy. |

## Primary Server Tests (Stop/Reboot/Kill)

| ID | Test Scenario | Commands | Observations |
|:---|:---|:---|:---|
| 1 | Kill PostgreSQL process | `kill -9 <POSTGRES_PID>` | Patroni restarts PostgreSQL. Server remains Primary. No failover as Patroni daemon is still active. |
| 2 | Stop PostgreSQL server | `pg_ctl stop -D /var/lib/pgsql/data` | Patroni automatically restarts PostgreSQL. Node remains Primary. |
| 3 | Linux Server Reboot | `# reboot` | A standby node is re-elected as Primary. Service maintained by the new leader. |
| 4 | Stop Patroni service | `# systemctl stop patroni` | PostgreSQL is stopped. Another node is automatically elected as Primary. Service continuity ensured. |
| 5 | Stop 2 Patroni servers | (Stop on Standby + Primary) | Automatic failover works. The last operational server remains active. |

## Standby Node Isolation Tests (TCP Blocking)

| ID | Test Scenario | Commands | Observations |
|:---|:---|:---|:---|
| 1 | Isolate PG port (5432) - DROP | `iptables -A INPUT -p tcp --dport 5432 -j DROP` | Server disappears from `patronictl list`. Blacklisted by Load Balancer. |
| 1B | Switchover attempt | `patronictl switchover` | Switchover operations from other nodes work normally. |
| 1C | Unlock / Flush | `iptables --flush` | Returns to normal after a few minutes to rejoin the cluster. |
| 2 | Isolate Patroni port (8008) - DROP | `iptables -A INPUT -p tcp --dport 8008 -j DROP` | Blacklisted by HAProxy. `patronictl list` does not immediately detect loss. |
| 2B | Failover to blocked server | `patronictl switchover --candidate=isolated_node` | Switchover fails (Code 412): no valid candidate found. |
| 2C | Failover to healthy server | `patronictl switchover --candidate=healthy_node` | Failover works. The isolated node is marked as `stopped/unknown`. |
| 3 | Isolate PG port (5432) - REJECT | `iptables -A INPUT -p tcp --dport 5432 -j REJECT` | Similar behavior to DROP. Detection after a few minutes. |
| 4 | Isolate Patroni port (8008) - REJECT | `iptables -A INPUT -p tcp --dport 8008 -j REJECT` | Similar behavior to DROP. Switchover to healthy node possible. |

## Primary Node Isolation Tests (TCP Blocking)

| ID | Test Scenario | Commands | Observations |
|:---|:---|:---|:---|
| 1 | Isolate PG port (5432) - DROP | `iptables -A INPUT -p tcp --dport 5432 -j DROP` | Leader lost. A re-election is triggered. New leader promoted. |
| 5 | Isolate PG port (5432) on Primary | `iptables -A INPUT -p tcp --dport 5432 -j DROP` | Processes don't stop, but API stops responding. New leader elected after TTL. |
| 6 | Isolate Patroni port (8008) on Primary | `iptables -A INPUT -p tcp --dport 8008 -j DROP` | **Warning**: No immediate automatic failover as Patroni doesn't see itself as failing! |
| 7 | Isolate PG port (5432) - REJECT | `iptables -A INPUT -p tcp --dport 5432 -j REJECT` | New leader re-elected due to PostgreSQL inaccessibility. |
| 8 | Isolate Patroni port (8008) - REJECT | `iptables -A INPUT -p tcp --dport 8008 -j REJECT` | No automatic leader failover. Isolation at Proxy level only. |

---
Source: Internal Procedures - PostgreSQL/Patroni HA Behavior Tests
