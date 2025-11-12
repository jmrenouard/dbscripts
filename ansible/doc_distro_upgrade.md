# Playbook: Update Ubuntu Distro

This playbook upgrades the Ubuntu distribution on the target hosts.

## Tasks

- **Reboot Before Distribution upgrade**: This task reboots the machine before starting the distribution upgrade.
- **Distribution Release upgrade**: This task runs the `do-release-upgrade` command to perform the distribution upgrade.
- **Reboot After Distribution upgrade**: This task reboots the machine after the distribution upgrade is complete.

## Variables

- `target`: The target host(s) to upgrade. Defaults to `all`.

## Example Usage

To run this playbook, use the following command:

```bash
ansible-playbook distro_upgrade.yml -e "target=your_target_host"
```
