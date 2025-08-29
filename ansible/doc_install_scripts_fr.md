# Playbook: Installer des scripts

Ce playbook copie des scripts utilitaires sur la machine cible.

## Tâches

- **Copier les fonctions utilitaires**: Copie les fonctions shell utilitaires dans `/etc/profile.d`.
- **Créer le répertoire des scripts**: Crée les répertoires `/opt/local` et `/opt/local/bin`.
- **Copier les scripts**: Copie les scripts dans `/opt/local/bin`.
- **Vérifier la copie**: Vérifie que les fichiers ont été copiés correctement.

## Variables

- `target`: L'hôte ou les hôtes cibles. La valeur par défaut est `all`.
- `muser`: L'utilisateur pour lequel les scripts sont installés.
- `mgroup`: Le groupe de l'utilisateur. La valeur par défaut est la valeur de `muser`.
- `basedir`: Le répertoire de base où se trouvent les scripts. La valeur par défaut est `../scripts`.

## Exemple d'utilisation

Pour exécuter ce playbook, utilisez la commande suivante:

```bash
ansible-playbook install_scripts.yaml -e "target=your_target_host muser=your_user"
```
