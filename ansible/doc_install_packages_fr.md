# Playbook: Installer des paquets

Ce playbook installe une liste de paquets courants sur un hôte cible.

## Tâches

- **Installer la dernière version de certains paquets**: Cette tâche utilise le module `ansible.builtin.package` pour installer la dernière version de `net-tools`, `htop`, `pigz` et `socat`.

## Variables

- `target`: L'hôte ou les hôtes cibles où les paquets seront installés.

## Exemple d'utilisation

Pour exécuter ce playbook, utilisez la commande suivante, en fournissant les variables requises:

```bash
ansible-playbook install_packages.yml -e "target=your_target_host"
```
