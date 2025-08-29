# Playbook: Installer GOSS

Ce playbook installe l'outil de validation de serveur GOSS.

## Tâches

- **Installer GOSS depuis l'URL**: Télécharge le binaire GOSS depuis le dépôt GitHub officiel.
- **Créer le répertoire de configuration**: Crée le répertoire de configuration pour GOSS.
- **Vérifier l'exécution du binaire GOSS**: Vérifie que le binaire GOSS peut être exécuté.
- **Vérifier la sortie du binaire GOSS**: Vérifie la sortie de la commande de version de GOSS.

## Variables

Ce playbook n'utilise aucune variable fournie par l'utilisateur.

## Exemple d'utilisation

Pour exécuter ce playbook, utilisez la commande suivante:

```bash
ansible-playbook install_goss.yaml
```
