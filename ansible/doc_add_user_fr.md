# Playbook: Créer un utilisateur Unix

Ce playbook crée un nouvel utilisateur Unix sur un hôte cible.

## Tâches

- **Ajouter l'utilisateur**: Cette tâche utilise le module `ansible.builtin.user` pour créer un nouvel utilisateur avec un UID et un groupe primaire spécifiques.

## Variables

- `target`: L'hôte ou les hôtes cibles où l'utilisateur sera créé.
- `muser`: Le nom de l'utilisateur à créer.
- `mgroup`: Le groupe primaire de l'utilisateur. La valeur par défaut est la valeur de `muser`.

## Exemple d'utilisation

Pour exécuter ce playbook, utilisez la commande suivante, en fournissant les variables requises:

```bash
ansible-playbook add_user.yml -e "target=your_target_host muser=newuser"
```
