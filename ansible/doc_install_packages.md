# Playbook: Install packages

This playbook installs a list of common packages on a target host.

## Tasks

- **Install the latest version of some packages**: This task uses the `ansible.builtin.package` module to install the latest version of `net-tools`, `htop`, `pigz`, and `socat`.

## Variables

- `target`: The target host(s) where the packages will be installed.

## Example Usage

To run this playbook, use the following command, providing the required variables:

```bash
ansible-playbook install_packages.yml -e "target=your_target_host"
```
