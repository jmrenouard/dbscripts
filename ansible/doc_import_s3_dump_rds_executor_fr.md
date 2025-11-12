# Playbook: Importer un dump S3 vers RDS

Ce playbook importe un dump de base de données d'un bucket S3 vers une instance Amazon RDS.

## Tâches

- **Générer le fichier d'informations d'identification RDS**: Crée un fichier temporaire avec les informations d'identification RDS.
- **Tester l'accès RDS**: Teste la connexion à l'instance RDS.
- **Obtenir la liste des bases de données S3**: Récupère la liste des bases de données à importer depuis le bucket S3.
- **Importer le dump S3**: Importe le dump de la base de données de S3 vers l'instance RDS.
- **Vérifier l'importation depuis S3 - Nombre de tables**: Compare le nombre de tables dans la base de données importée avec le dump d'origine.
- **Vérifier l'importation depuis S3 - Nombre de lignes**: Compare le nombre de lignes dans chaque table de la base de données importée avec le dump d'origine.

## Variables

- `target`: L'hôte ou les hôtes cibles sur lesquels exécuter le playbook. La valeur par défaut est `mysql-servers`.
- `dbname`: Le nom de la base de données à importer. La valeur par défaut est `all`.
- `rds_mysql_hostname`: Le nom d'hôte de l'instance RDS.
- `rds_mysql_username`: Le nom d'utilisateur de l'instance RDS.
- `rds_mysql_password`: Le mot de passe de l'instance RDS.
- `s3_shared_bucket`: Le nom du bucket S3 où sont stockés les dumps.
- `rds_executor`: L'hôte qui exécutera les tâches liées à RDS.

## Exemple d'utilisation

Pour exécuter ce playbook, utilisez la commande suivante, en fournissant les variables requises:

```bash
ansible-playbook import_s3_dump_rds_executor.yml -e "rds_mysql_hostname=your_rds_hostname rds_mysql_username=your_rds_username rds_mysql_password=your_rds_password s3_shared_bucket=your_s3_bucket rds_executor=your_executor_host"
```
