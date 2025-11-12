# Playbook: Update Ubuntu Distro

This playbook updates an Ubuntu distribution.

## Tasks

- **Update cache & Full system update**: Updates the package cache and performs a full system upgrade.
- **/bin/bash by default**: Sets `/bin/bash` as the default shell.
- **Reboot After upgrade**: Reboots the machine after the upgrade.

## Variables

- `target`: The target host(s). Defaults to `all`.
- `type`: The type of upgrade to perform (`yes`, `no`, `dist`). Defaults to `yes`.
- `reboot`: Whether to reboot after the upgrade. Defaults to `no`.

## Example Usage

To run this playbook, use the following command:

```bash
ansible-playbook update_apt_distribution.yaml -e "target=your_target_host"
```
