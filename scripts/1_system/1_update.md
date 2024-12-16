---

### Script Documentation: System Update and Firewall Installation

#### Overview
This script is designed to automate the process of updating the package list, upgrading installed packages, and installing necessary software (including Python, Perl, Firewalld, and Net-tools) on a Linux system. It supports both Red Hat-based systems (using `yum`) and Debian-based systems (using `apt`).

#### Pre-requisites
- The script assumes the existence of a utility script (`utils.sh`) that provides functions for logging and command execution. It checks both system-wide and current directory paths for this file.
- Ensure that the necessary utilities (`utils.sh`) are available before running the script.
  
#### Key Features
1. **Package Manager Detection**:  
   - The script automatically detects the package manager (`yum` for Red Hat systems or `apt` for Debian systems) based on the operating system type.
   
2. **System Update and Upgrade**:  
   - It updates the package list and upgrades installed packages to the latest versions using the detected package manager.

3. **Software Installation**:  
   - Installs `python3`, `perl`, `firewalld`, and `net-tools`, essential for various system operations and firewall management.

4. **Error Handling**:  
   - The script captures the return codes of each command and accumulates the results to return a final exit status. Any error during the process increments the return code counter.

#### Logging
- The script includes logging mechanisms to indicate the start and end of execution, as well as the status of individual operations (such as updates and installations).

#### Exit Status
- A final exit code (`lRC`) is returned. It will be `0` if all commands execute successfully or a non-zero value if any command fails.

#### Notes
- This script is designed for environments with root or sudo privileges.
- Ensure that Firewalld and the associated tools are compatible with the system before running the script.

---