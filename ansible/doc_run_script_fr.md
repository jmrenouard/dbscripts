# Playbook: Exécuter un script

Ce playbook exécute un script sur un hôte distant et récupère les résultats.

## Tâches

- **Nettoyage local**: Nettoie le répertoire de sortie sur la machine locale.
- **Installer les dépendances**: Installe les dépendances pour le script sur l'hôte distant.
- **Nettoyage à distance**: Nettoie le répertoire temporaire sur l'hôte distant.
- **Copier le script**: Copie le script sur l'hôte distant.
- **Exécuter à distance**: Exécute le script sur l'hôte distant.
- **Collecter la liste des fichiers**: Collecte la liste des fichiers à récupérer depuis l'hôte distant.
- **ansible copie le résultat du distant au local**: Récupère les fichiers de résultats de l'hôte distant.
- **Nettoyage local**: Affiche le contenu des fichiers récupérés.

## Variables

- `target`: L'hôte ou les hôtes cibles. La valeur par défaut est `mysql`.
- `outputdir`: Le répertoire de sortie sur la machine locale. La valeur par défaut est `result`.
- `script`: Le script à exécuter. La valeur par défaut est `scripts/export_info.py`.
- `tmpdir`: Le répertoire temporaire sur l'hôte distant. La valeur par défaut est `/var/tmp/generic`.
- `http_proxy`: Le proxy HTTP à utiliser. La valeur par défaut est `http://myproxy.local:3128`.
- `max_time`: Le temps d'exécution maximum pour le script. La valeur par défaut est `180`.
- `params`: Les paramètres à passer au script. La valeur par défaut est `''`.
- `dependencies`: Indique s'il faut installer les dépendances. La valeur par défaut est `False`.

## Exemple d'utilisation

Pour exécuter ce playbook, utilisez la commande suivante:

```bash
ansible-playbook run_script.yaml -e "target=your_target_host script=your_script.py"
```
