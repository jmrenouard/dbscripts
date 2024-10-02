---

### Script Documentation: Time Synchronization and Timezone Setup

#### Overview
This script automates the installation and configuration of time synchronization services (`ntp` or `chrony`) and sets the system timezone to a specified value. It supports both Red Hat-based systems (CentOS 7/8) and Debian-based systems (Ubuntu), adjusting the package installation and time synchronization commands accordingly.

#### Pre-requisites
- The script assumes the existence of a utility script (`utils.sh`) that provides logging and command execution functions. The script checks both system-wide and current directory paths for this file.
- Ensure that the necessary utilities (`utils.sh`) are available before running the script.

#### Key Features
1. **OS Detection and Package Management**:  
   - The script detects the operating system using the `/etc/os-release` file and adjusts the package management commands based on the system type:
     - **CentOS 7/Red Hat 7**: Installs and configures `ntpdate`.
     - **CentOS 8/Red Hat 8**: Installs `chrony` and `ntpstat`.
     - **Ubuntu/Debian**: Installs `ntp` and `ntpstat`.

2. **Service Management**:  
   - Depending on the operating system version, the script ensures that the appropriate time synchronization service is enabled and restarted:
     - **CentOS**: Restarts the `chronyd` service.
     - **Ubuntu/Debian**: Enables and restarts the `ntp` service.

3. **Timezone Configuration**:  
   - The script sets the system's timezone to **Europe/Paris** using the `timedatectl` command.

4. **Time Synchronization Check**:  
   - After setting up the time synchronization service, the script checks the status of the time sources:
     - **CentOS 8/Red Hat 8**: Uses `chronyc sources` to display the synchronization sources.
     - **CentOS 7/Red Hat 7 / Ubuntu/Debian**: Uses `ntpq -p` to list the NTP peers.
   - The command `ntpstat` is used to verify the synchronization status.

5. **Error Handling**:  
   - Each command's success is evaluated, and any failure increments the return code counter (`lRC`). This ensures that the final exit code reflects the overall success or failure of the script.

#### Logging
- The script includes logging mechanisms to indicate the start and end of the script, as well as details on the specific operations performed (installation, synchronization status checks, etc.).

#### Exit Status
- The final exit code (`lRC`) is returned as `0` if all commands are successful or a non-zero value if any errors are encountered during the execution.

#### Notes
- This script requires root or sudo privileges to install packages and manage system services.
- The default timezone is set to **Europe/Paris**, but this can be modified by adjusting the `TIMEZONE` variable.
- Time synchronization is essential for systems in clustered or distributed environments where accurate timekeeping is critical.

---
