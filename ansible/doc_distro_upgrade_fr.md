# Playbook: Mettre à jour la distribution Ubuntu

Ce playbook met à jour la distribution Ubuntu sur les hôtes cibles.

## Tâches

- **Redémarrer avant la mise à niveau de la distribution**: Cette tâche redémarre la machine avant de commencer la mise à niveau de la distribution.
- **Mise à niveau de la version de la distribution**: Cette tâche exécute la commande `do-release-upgrade` pour effectuer la mise à niveau de la distribution.
- **Redémarrer après la mise à niveau de la distribution**: Cette tâche redémarre la machine une fois la mise à niveau de la distribution terminée.

## Variables

- `target`: L'hôte ou les hôtes cibles à mettre à niveau. La valeur par défaut est `all`.

## Exemple d'utilisation

Pour exécuter ce playbook, utilisez la commande suivante:

```bash
ansible-playbook distro_upgrade.yml -e "target=your_target_host"
```
