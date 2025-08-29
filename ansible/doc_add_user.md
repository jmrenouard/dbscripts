# Playbook: Create Unix user

This playbook creates a new Unix user on a target host.

## Tasks

- **Add the user**: This task uses the `ansible.builtin.user` module to create a new user with a specific UID and primary group.

## Variables

- `target`: The target host(s) where the user will be created.
- `muser`: The name of the user to create.
- `mgroup`: The primary group for the user. Defaults to the value of `muser`.

## Example Usage

To run this playbook, use the following command, providing the required variables:

```bash
ansible-playbook add_user.yml -e "target=your_target_host muser=newuser"
```
