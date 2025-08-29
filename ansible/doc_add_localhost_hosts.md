# Playbook: Add localhost hosts

This playbook adds entries to the `/etc/hosts` file on the local machine.

## Tasks

- **Add entries to /etc/hosts**: This task uses the `lineinfile` module to add the specified lines to the `/etc/hosts` file. It creates a backup of the file before modifying it.

## Variables

This playbook does not use any variables.

## Example Usage

To run this playbook, use the following command:

```bash
ansible-playbook add_localhost_hosts.yaml
```
