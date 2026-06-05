# Playbook: Déployer et configurer le cluster MySQL InnoDB

Ce playbook déploie et configure un cluster MySQL InnoDB.

## Rôles

- **common**: Prépare les serveurs de base.
- **mysql_server**: Installe le serveur MySQL.
- **mysql_cluster**: Configure et initialise le cluster InnoDB.

## Variables

Ce playbook n'utilise aucune variable fournie par l'utilisateur directement, mais les rôles inclus peuvent en utiliser.

## Exemple d'utilisation

Pour exécuter ce playbook, utilisez la commande suivante:

```bash
ansible-playbook playbook_innodb_cluster_group.yml
```
