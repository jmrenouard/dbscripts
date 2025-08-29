# Playbook: Mettre à jour la distribution de type RedHat

Ce playbook met à jour une distribution de type Red Hat.

## Tâches

- **Mettre à jour le cache et mise à jour complète du système**: Met à jour le cache des paquets et effectue une mise à niveau complète du système.
- **Redémarrer après la mise à jour**: Redémarre la machine après la mise à jour.

## Variables

- `target`: L'hôte ou les hôtes cibles. La valeur par défaut est `all`.

## Exemple d'utilisation

Pour exécuter ce playbook, utilisez la commande suivante:

```bash
ansible-playbook update_rh_distribution.yaml -e "target=your_target_host"
```
