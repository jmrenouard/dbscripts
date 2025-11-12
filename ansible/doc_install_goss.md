# Playbook: Install GOSS

This playbook installs the GOSS server validation tool.

## Tasks

- **Install GOSS from URL**: Downloads the GOSS binary from the official GitHub repository.
- **Create Configuration directory**: Creates the configuration directory for GOSS.
- **Check GOSS Binary execution**: Checks that the GOSS binary can be executed.
- **Check GOSS Binary Output**: Checks the output of the GOSS version command.

## Variables

This playbook does not use any user-provided variables.

## Example Usage

To run this playbook, use the following command:

```bash
ansible-playbook install_goss.yaml
```
