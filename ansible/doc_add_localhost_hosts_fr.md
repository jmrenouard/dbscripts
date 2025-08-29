# Playbook: Ajouter des hôtes localhost

Ce playbook ajoute des entrées au fichier `/etc/hosts` sur la machine locale.

## Tâches

- **Ajouter des entrées dans /etc/hosts**: Cette tâche utilise le module `lineinfile` pour ajouter les lignes spécifiées au fichier `/etc/hosts`. Il crée une sauvegarde du fichier avant de le modifier.

## Variables

Ce playbook n'utilise aucune variable.

## Exemple d'utilisation

Pour exécuter ce playbook, utilisez la commande suivante:

```bash
ansible-playbook add_localhost_hosts.yaml
```
