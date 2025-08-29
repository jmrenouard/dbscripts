# Playbook: Mettre à jour la distribution Ubuntu

Ce playbook met à jour une distribution Ubuntu.

## Tâches

- **Mettre à jour le cache et mise à jour complète du système**: Met à jour le cache des paquets et effectue une mise à niveau complète du système.
- **/bin/bash par défaut**: Définit `/bin/bash` comme shell par défaut.
- **Redémarrer après la mise à niveau**: Redémarre la machine après la mise à niveau.

## Variables

- `target`: L'hôte ou les hôtes cibles. La valeur par défaut est `all`.
- `type`: Le type de mise à niveau à effectuer (`yes`, `no`, `dist`). La valeur par défaut est `yes`.
- `reboot`: Indique s'il faut redémarrer après la mise à niveau. La valeur par défaut est `no`.

## Exemple d'utilisation

Pour exécuter ce playbook, utilisez la commande suivante:

```bash
ansible-playbook update_apt_distribution.yaml -e "target=your_target_host"
```
