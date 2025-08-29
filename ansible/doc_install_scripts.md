# Playbook: Install scripts

This playbook copies utility scripts to the target machine.

## Tasks

- **Copy utilities functions**: Copies utility shell functions to `/etc/profile.d`.
- **Create script directory**: Creates the `/opt/local` and `/opt/local/bin` directories.
- **Copy scripts**: Copies scripts to `/opt/local/bin`.
- **Check copy**: Verifies that the files were copied correctly.

## Variables

- `target`: The target host(s). Defaults to `all`.
- `muser`: The user for which the scripts are being installed.
- `mgroup`: The group for the user. Defaults to the value of `muser`.
- `basedir`: The base directory where the scripts are located. Defaults to `../scripts`.

## Example Usage

To run this playbook, use the following command:

```bash
ansible-playbook install_scripts.yaml -e "target=your_target_host muser=your_user"
```
