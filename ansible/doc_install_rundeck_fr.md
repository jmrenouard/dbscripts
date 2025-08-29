# Playbook: Installer Rundeck

Ce playbook installe Rundeck et un serveur MySQL.

## Rôles

- **mysql-server**: Ce rôle installe et configure un serveur MySQL.
- **rundeck**: Ce rôle installe et configure Rundeck.

## Variables

- `target`: L'hôte ou les hôtes cibles où Rundeck sera installé. La valeur par défaut est `admin-vm`.

## Exemple d'utilisation

Pour exécuter ce playbook, utilisez la commande suivante:

```bash
ansible-playbook install_rundeck.yaml -e "target=your_target_host"
```
