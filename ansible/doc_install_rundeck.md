# Playbook: Install Rundeck

This playbook installs Rundeck and a MySQL server.

## Roles

- **mysql-server**: This role installs and configures a MySQL server.
- **rundeck**: This role installs and configures Rundeck.

## Variables

- `target`: The target host(s) where Rundeck will be installed. Defaults to `admin-vm`.

## Example Usage

To run this playbook, use the following command:

```bash
ansible-playbook install_rundeck.yaml -e "target=your_target_host"
```
