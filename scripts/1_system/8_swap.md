---

### Script Documentation: Swap File Creation and Management

#### Overview
This script is designed to create, format, and activate a swap file on a Linux system. It removes any existing swap file configurations, generates a new swap file with a specified size, and ensures that it is persistently enabled by adding it to `/etc/fstab`. The script also adjusts permissions and verifies the swap status.

#### Pre-requisites
- The script assumes the existence of a utility script (`utils.sh`) that provides logging and command execution functions. The script checks both system-wide and current directory paths for this file.
- Ensure that the necessary utilities (`utils.sh`) are available before running the script.

#### Key Features
1. **Swap File Removal**:  
   - The script starts by disabling and removing any existing swap file located at `/swapfile` to ensure that a clean swap file is created.

2. **Swap File Creation**:  
   - A new swap file is created using `fallocate` with a size defined by the `swapsize` variable (default is **2G**). Alternatively, the file is initialized using `dd` by writing zeros (`/dev/zero`) into the swap file, using `swapitemsize` and `swapcount` to define the size and block count.

3. **Permissions Management**:  
   - Permissions for the swap file are set to **600** to ensure that it is only accessible by root, securing the file from unauthorized access.

4. **Swap File Formatting and Activation**:  
   - The script formats the new file as swap space using `mkswap` and activates it with the `swapon` command. 

5. **Persistent Swap File Configuration**:  
   - Any old references to `/swapfile` in `/etc/fstab` are removed to avoid conflicts, and a new entry is added for the newly created swap file. This ensures the swap file is automatically enabled on boot.

6. **Status Verification**:  
   - The script checks the swap status with `swapon --show` and displays the system’s memory usage with `free -h` to confirm that the swap file has been successfully created and is active.

#### Error Handling
- The script tracks the success of each operation by updating a return code variable (`lRC`). If a command fails, the return code is incremented, allowing the final exit status to reflect the overall success or failure of the script.

#### Logging
- Logging is integrated throughout the script to document the start and end of the process, as well as each individual operation (e.g., creating the swap file, setting permissions, activating the swap file).

#### Exit Status
- The final exit code (`lRC`) is returned as `0` if all commands are executed successfully, or a non-zero value if any errors occur.

#### Notes
- Root or sudo privileges are required to create and manage the swap file.
- The default swap file size is set to **2G**, but this can be adjusted by modifying the `swapsize` variable.
- The script ensures that the swap file is persistent across reboots by updating `/etc/fstab`.

---