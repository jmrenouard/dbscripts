---

### Script Documentation: Port Configuration for Galera Cluster (MariaDB)

#### Overview
This script configures the firewall settings to allow necessary traffic for a Galera Cluster setup with MariaDB. It supports both `iptables` and `firewalld`, depending on the system's operating system and version. The ports configured include those required for MySQL/MariaDB clients, Galera replication, synchronization, monitoring agents (Zabbix and NRPE), and additional services.

#### Pre-requisites
- The script assumes the existence of a utility script (`utils.sh`) that provides logging and command execution functions. The script checks both system-wide and current directory paths for this file.
- Ensure that the necessary utilities (`utils.sh`) are available before running the script.

#### Key Features
1. **Firewall Selection**:  
   - Depending on the operating system and version, the script either configures firewall rules using `iptables` or `firewalld`:
     - `iptables` is used for CentOS systems that are not version 7.
     - `firewalld` is used for Debian-based systems and CentOS 7.

2. **Port Configuration**:  
   - The script opens the following ports based on the service requirements:
     - **Port 3306 (TCP)**: Allows MySQL/MariaDB client connections.
     - **Ports 4567 (TCP/UDP)**: Allows Galera replication traffic.
     - **Port 4568 (TCP)**: Allows Galera Incremental State Transfer (IST) synchronization.
     - **Port 4444 (TCP)**: Allows Galera State Snapshot Transfer (SST) synchronization.
     - **Port 10050 (TCP/UDP)**: Allows Zabbix monitoring agent traffic.
     - **Port 5666 (TCP/UDP)**: Allows NRPE (Nagios Remote Plugin Executor) monitoring agent traffic.
     - **Port 9200 (TCP/UDP)**: Opens port 9200 for custom use, typically for monitoring or logging services.

3. **Error Handling**:  
   - The script checks the success of each command and accumulates the results in a return code variable (`lRC`). Any command failure increments this variable, which is returned as the script's final exit status.

4. **Firewall Configuration Persistence**:  
   - For systems using `firewalld`, ports are added permanently to ensure that they remain open after a system reboot. A firewall reload and listing of all current rules are also included to validate the changes.

#### Logging
- Logging mechanisms are included to indicate the start and end of the script, along with detailed logging of the individual operations performed (such as allowing traffic on specific ports).

#### Exit Status
- The script returns a final exit code (`lRC`), which will be `0` if all commands are executed successfully, or a non-zero value if any command encounters an error.

#### Notes
- Root or sudo privileges are required to execute this script, as it modifies firewall settings.
- The firewall rules are specific to the needs of a Galera Cluster setup and related monitoring agents (Zabbix, NRPE). Ensure that these services are configured and running on the system before executing the script.

---
