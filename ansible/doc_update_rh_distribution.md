# Playbook: Update RedHat Like Distro

This playbook updates a Red Hat-like distribution.

## Tasks

- **Update cache & Full system update**: Updates the package cache and performs a full system upgrade.
- **Reboot After update**: Reboots the machine after the update.

## Variables

- `target`: The target host(s). Defaults to `all`.

## Example Usage

To run this playbook, use the following command:

```bash
ansible-playbook update_rh_distribution.yaml -e "target=your_target_host"
```
