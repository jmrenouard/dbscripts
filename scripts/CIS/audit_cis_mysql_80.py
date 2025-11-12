# -*- coding: utf-8 -*-
import subprocess
import json
import os
from datetime import datetime
import re # Pour les expressions régulières
import html # Pour échapper les caractères spéciaux HTML

# --- Configuration ---
# Adapte cette commande si nécessaire pour te connecter à MySQL
# Par exemple, ajoute -u <user> -p<password> ou utilise mysql_config_editor
# Pour l'instant, on suppose que la connexion fonctionne sans mot de passe
# ou via un fichier de configuration (ex: /root/.my.cnf)
MYSQL_CMD = "mysql -N -B" # -N: skip headers, -B: batch mode (tab separated)

# --- Structure des Recommandations (Adaptée pour MySQL 8.0) ---
# Basée sur le PDF "CIS MySQL 8.0 Benchmark – Tableau récapitulatif complet.pdf"
RECOMMENDATIONS_DATA = [
    # Catégorie 1: Configuration Système d'exploitation
    {"category": "1. Configuration Système d'exploitation", "number": "1.1", "name": "Placer les bases de données sur des partitions non-système", "type": "Manual", "test_procedure": f"{MYSQL_CMD} -e \"SELECT @@datadir;\" puis vérifier avec df -h <datadir>", "expected_output": None, "remediation": "Sauvegarder la base, déplacer les fichiers de données, mettre à jour datadir dans la configuration MySQL, redémarrer le service."},
    {"category": "1. Configuration Système d'exploitation", "number": "1.2", "name": "Utiliser un compte dédié et privilégié minimal pour MySQL", "type": "Automated", "test_procedure": "ps -ef | grep mysqld | grep -v grep | awk '{print $1}'", "expected_output": {"type": "stdout_equals", "value": "mysql"}, "remediation": "Configurer le service MySQL pour qu'il s'exécute sous un utilisateur dédié (ex: 'mysql') avec les privilèges minimaux."},
    {"category": "1. Configuration Système d'exploitation", "number": "1.3", "name": "Désactiver l'historique des commandes MySQL", "type": "Automated", "test_procedure": "! find /home /root -name .mysql_history -print -quit 2>/dev/null", "expected_output": {"type": "returncode_zero"}, "remediation": "Supprimer les fichiers d'historique, créer un lien symbolique vers /dev/null, ou configurer MYSQL_HISTFILE."},
    {"category": "1. Configuration Système d'exploitation", "number": "1.4", "name": "Vérifier que MYSQL_PWD n'est pas utilisé", "type": "Automated", "test_procedure": "! grep -qs MYSQL_PWD /proc/*/environ", "expected_output": {"type": "returncode_zero"}, "remediation": "Modifier les scripts/utilisateurs pour éviter MYSQL_PWD, utiliser mysql_config_editor ou authentification certifiée."},
    {"category": "1. Configuration Système d'exploitation", "number": "1.5", "name": "Désactiver l'accès interactif pour l'utilisateur MySQL", "type": "Automated", "test_procedure": "getent passwd mysql | cut -d: -f7", "expected_output": {"type": "stdout_contains_any", "values": ["/bin/false", "/sbin/nologin"]}, "remediation": "Modifier le shell de l'utilisateur mysql pour utiliser /bin/false ou /sbin/nologin (ex: usermod -s /sbin/nologin mysql)."},
    {"category": "1. Configuration Système d'exploitation", "number": "1.6", "name": "Vérifier que MYSQL_PWD n'est pas dans les profils utilisateurs", "type": "Automated", "test_procedure": "! grep -qs MYSQL_PWD /home/*/.{bashrc,profile,bash_profile} /root/.{bashrc,profile,bash_profile} /etc/environment 2>/dev/null", "expected_output": {"type": "returncode_zero"}, "remediation": "Nettoyer les fichiers de login des utilisateurs pour supprimer MYSQL_PWD."},
    {"category": "1. Configuration Système d'exploitation", "number": "1.7", "name": "Exécuter MySQL dans un environnement sandbox", "type": "Manual", "test_procedure": "Vérifier si chroot, unité systemd spécifique, ou conteneurs Docker sont utilisés.", "expected_output": None, "remediation": "Configurer chroot, utiliser un service systemd avec un utilisateur spécifique, ou déployer MySQL sous Docker."},

    # Catégorie 2: Installation et Planification
    {"category": "2. Installation et Planification", "number": "2.1.1", "name": "Politique de sauvegarde en place", "type": "Manual", "test_procedure": "Vérifier crontab -l, les scripts de sauvegarde, ou la documentation interne.", "expected_output": None, "remediation": "Créer une politique de sauvegarde et planifier des sauvegardes automatiques."},
    {"category": "2. Installation et Planification", "number": "2.1.2", "name": "Validation des sauvegardes", "type": "Manual", "test_procedure": "Analyser les rapports de tests de restauration.", "expected_output": None, "remediation": "Planifier et documenter les tests de restauration périodiques."},
    {"category": "2. Installation et Planification", "number": "2.1.3", "name": "Sécuriser les identifiants de sauvegarde", "type": "Manual", "test_procedure": "Inspecter les permissions des fichiers contenant les credentials de sauvegarde.", "expected_output": None, "remediation": "Restreindre les droits fichiers, utiliser des keystores ou du chiffrement."},
    {"category": "2. Installation et Planification", "number": "2.1.4", "name": "Sécuriser les fichiers de sauvegarde", "type": "Manual", "test_procedure": "Examiner les permissions et la présence de chiffrement sur les fichiers de sauvegarde.", "expected_output": None, "remediation": "Utiliser l'option --encrypt-password de MySQL Enterprise Backup ou une méthode de chiffrement équivalente."},
    {"category": "2. Installation et Planification", "number": "2.1.5", "name": "Point-in-Time Recovery", "type": "Automated", "test_procedure": f"{MYSQL_CMD} -e \"SELECT @@log_bin;\"", "expected_output": {"type": "stdout_equals", "value": "1"}, "remediation": "Activer log_bin (log-bin=mysql-bin dans my.cnf), configurer l'expiration (expire_logs_days ou binlog_expire_logs_seconds), tester les restaurations PITR."},
    {"category": "2. Installation et Planification", "number": "2.1.6", "name": "Plan de reprise d'activité (DR)", "type": "Manual", "test_procedure": "Vérifier l'existence et la validité du plan DR.", "expected_output": None, "remediation": "Documenter et tester un plan DR incluant réplication, backups offsite."},
    {"category": "2. Installation et Planification", "number": "2.1.7", "name": "Sauvegarde des fichiers de configuration", "type": "Manual", "test_procedure": "Contrôler la liste des fichiers inclus dans la sauvegarde (my.cnf, clés SSL, etc.).", "expected_output": None, "remediation": "Ajouter tous les fichiers essentiels à la stratégie de sauvegarde."},

    # Catégorie 3: Permissions Fichiers
    {"category": "3. Permissions Fichiers", "number": "3.1", "name": "Permissions adéquates sur 'datadir'", "type": "Automated", "path_command": f"{MYSQL_CMD} -e \"SELECT @@datadir;\"", "test_procedure_template": "stat -c '%U:%G %a' {path}", "expected_output": {"type": "stdout_regex_match", "pattern": r"^mysql:mysql\s+700$"}, "remediation": "chown -R mysql:mysql <datadir> && chmod 700 <datadir>"},
    {"category": "3. Permissions Fichiers", "number": "3.2", "name": "Permissions sur les fichiers 'log_bin_basename'", "type": "Manual", "test_procedure": f"{MYSQL_CMD} -e \"SELECT @@log_bin_basename;\" puis ls -l <log_bin_basename>*", "expected_output": None, "remediation": "Appliquer chmod 600 sur les fichiers binaires."}, # Manual car dépend du nom et de l'emplacement
    {"category": "3. Permissions Fichiers", "number": "3.3", "name": "Permissions sur 'log_error'", "type": "Manual", "test_procedure": f"{MYSQL_CMD} -e \"SELECT @@log_error;\" puis ls -l <log_error>", "expected_output": None, "remediation": "Appliquer des permissions restrictives (ex: 640 ou 600)."}, # Manual car dépend du nom et de l'emplacement
    {"category": "3. Permissions Fichiers", "number": "3.4", "name": "Permissions sur 'slow_query_log'", "type": "Manual", "test_procedure": f"{MYSQL_CMD} -e \"SELECT @@slow_query_log_file;\" puis ls -l <slow_query_log_file>", "expected_output": None, "remediation": "Limiter l'accès aux utilisateurs autorisés (ex: 640 ou 600)."}, # Manual car dépend du nom et de l'emplacement
    {"category": "3. Permissions Fichiers", "number": "3.5", "name": "Permissions sur 'relay_log_basename'", "type": "Manual", "test_procedure": f"{MYSQL_CMD} -e \"SELECT @@relay_log_basename;\" puis ls -l <relay_log_basename>*", "expected_output": None, "remediation": "Appliquer chmod 600."}, # Manual car dépend du nom et de l'emplacement
    {"category": "3. Permissions Fichiers", "number": "3.6", "name": "Permissions sur 'general_log_file'", "type": "Manual", "test_procedure": f"{MYSQL_CMD} -e \"SELECT @@general_log_file;\" puis ls -l <general_log_file>", "expected_output": None, "remediation": "Restreindre les droits d'accès (ex: 640 ou 600)."}, # Manual car dépend du nom et de l'emplacement
    {"category": "3. Permissions Fichiers", "number": "3.7", "name": "Permissions sur les fichiers de clés SSL", "type": "Manual", "test_procedure": "Identifier les chemins des fichiers ssl_key, ssl_cert, ssl_ca dans my.cnf ou via SHOW VARIABLES, puis vérifier les permissions avec ls -l.", "expected_output": None, "remediation": "Restreindre l'accès aux clés privées (ex: chmod 600) et s'assurer que le propriétaire est mysql."},
    {"category": "3. Permissions Fichiers", "number": "3.8", "name": "Permissions sur le répertoire des plugins", "type": "Automated", "path_command": f"{MYSQL_CMD} -e \"SELECT @@plugin_dir;\"", "test_procedure_template": "stat -c '%U:%G %a' {path}", "expected_output": {"type": "stdout_regex_match", "pattern": r"^mysql:mysql\s+755$"}, "remediation": "chown -R mysql:mysql <plugin_dir> && chmod 755 <plugin_dir>"}, # 755 est courant pour les plugins
    {"category": "3. Permissions Fichiers", "number": "3.9", "name": "Permissions sur 'audit_log_file'", "type": "Manual", "test_procedure": f"{MYSQL_CMD} -e \"SELECT @@audit_log_file;\" puis ls -l <audit_log_file>", "expected_output": None, "remediation": "Appliquer des permissions restrictives (ex: 640 ou 600)."}, # Manual car dépend du nom et de l'emplacement
    {"category": "3. Permissions Fichiers", "number": "3.10", "name": "Sécuriser le Keyring MySQL", "type": "Manual", "test_procedure": "Vérifier les permissions du fichier keyring (si type 'file').", "expected_output": None, "remediation": "Chiffrer et restreindre l'accès au fichier keyring."},

    # Catégorie 4: Général
    {"category": "4. Général", "number": "4.1", "name": "Ensure the Latest Security Patches are Applied", "type": "Manual", "test_procedure": f"{MYSQL_CMD} -e \"SELECT @@version;\" puis comparer aux annonces Oracle/OS.", "expected_output": None, "remediation": "Installez les derniers correctifs pour votre version ou mettez à niveau vers la dernière version."},
    {"category": "4. Général", "number": "4.2", "name": "Ensure Example or Test Databases are Not Installed on Production Servers", "type": "Automated", "test_procedure": f"{MYSQL_CMD} -e \"SELECT SCHEMA_NAME FROM information_schema.SCHEMATA WHERE SCHEMA_NAME IN ('employees', 'world', 'world_x', 'sakila', 'airportdb', 'menagerie');\"", "expected_output": {"type": "stdout_is_empty"}, "remediation": "Exécutez DROP DATABASE <database name>; pour supprimer une base de données d'exemple."},
    {"category": "4. Général", "number": "4.3", "name": "Ensure 'allow-suspicious-udfs' is Set to 'OFF'", "type": "Automated", "test_procedure": "my_print_defaults mysqld | grep -q 'allow-suspicious-udfs' && echo 'FOUND' || echo 'NOT FOUND'", "expected_output": {"type": "stdout_equals", "value": "NOT FOUND"}, "remediation": "Supprimer --allow-suspicious-udfs de la ligne de commande ou du fichier de configuration."},
    {"category": "4. Général", "number": "4.4", "name": "Harden Usage for 'local_infile' on MySQL Clients", "type": "Automated", "test_procedure": f"{MYSQL_CMD} -e \"SELECT @@local_infile;\"", "expected_output": {"type": "stdout_equals", "value": "0"}, "remediation": "Ajouter local-infile=0 à la section [mysqld] et [mysql] du fichier de configuration MySQL et redémarrer le service. Si nécessaire, utiliser --load-data-local-dir et TLS."},
    {"category": "4. Général", "number": "4.5", "name": "Ensure 'mysqld' is Not Started With '--skip-grant-tables'", "type": "Automated", "test_procedure": "ps -ef | grep mysqld | grep -v grep | grep -q 'skip-grant-tables' && echo 'FOUND' || echo 'NOT FOUND'", "expected_output": {"type": "stdout_equals", "value": "NOT FOUND"}, "remediation": "Supprimer l'option --skip-grant-tables de la ligne de commande ou du fichier de configuration."},
    {"category": "4. Général", "number": "4.6", "name": "Ensure Symbolic Links are Disabled", "type": "Automated", "test_procedure": f"{MYSQL_CMD} -e \"SELECT @@have_symlink;\"", "expected_output": {"type": "stdout_equals", "value": "DISABLED"}, "remediation": "Ajouter skip-symbolic-links dans la section [mysqld] du fichier my.cnf."},
    {"category": "4. Général", "number": "4.7", "name": "Ensure the 'daemon_memcached' Plugin is Disabled", "type": "Automated", "test_procedure": f"{MYSQL_CMD} -e \"SELECT PLUGIN_STATUS FROM information_schema.plugins WHERE PLUGIN_NAME = 'daemon_memcached';\"", "expected_output": {"type": "stdout_not_equals", "value": "ACTIVE"}, "remediation": "Exécutez UNINSTALL PLUGIN daemon_memcached;"},
    {"category": "4. Général", "number": "4.8", "name": "Ensure the 'secure_file_priv' is Configured Correctly", "type": "Automated", "test_procedure": f"{MYSQL_CMD} -e \"SELECT @@secure_file_priv;\"", "expected_output": {"type": "stdout_not_empty"}, "remediation": "Définir secure_file_priv sur NULL (pour désactiver) ou sur un chemin spécifique dans my.cnf."}, # Check if NOT empty string
    {"category": "4. Général", "number": "4.9", "name": "Ensure 'sql_mode' Contains 'STRICT_ALL_TABLES'", "type": "Automated", "test_procedure": f"{MYSQL_CMD} -e \"SELECT @@sql_mode;\"", "expected_output": {"type": "stdout_contains", "value": "STRICT_ALL_TABLES"}, "remediation": "Ajouter STRICT_ALL_TABLES au paramètre sql_mode dans my.cnf."},
    {"category": "4. Général", "number": "4.10", "name": "Use MySQL TDE for At-Rest Data Encryption", "type": "Manual", "test_procedure": f"{MYSQL_CMD} -e \"SELECT TABLE_SCHEMA, TABLE_NAME, CREATE_OPTIONS FROM information_schema.TABLES WHERE CREATE_OPTIONS NOT LIKE '%ENCRYPTION=\"Y\"%' AND TABLE_SCHEMA NOT IN ('mysql', 'information_schema', 'performance_schema', 'sys');\"", "expected_output": None, "remediation": "Activer le chiffrement pour les tables/tablespaces nécessaires via ALTER TABLE ... ENCRYPTION='Y';. Configurer le chiffrement pour les logs (binlog, redo, undo) et l'audit log si nécessaire."},

    # Catégorie 5 - Gestion des privilèges
    {"category": "5. Gestion des privilèges", "number": "5.1", "name": "Limiter l'accès complet à mysql.* aux seuls administrateurs", "type": "Manual", "test_procedure": f"{MYSQL_CMD} -e \"SELECT user, host FROM mysql.db WHERE db='mysql' AND (Select_priv='Y' OR Insert_priv='Y' OR Update_priv='Y' OR Delete_priv='Y' OR Create_priv='Y' OR Drop_priv='Y' OR Alter_priv='Y');\"", "expected_output": None, "remediation": "Révoquer les privilèges excessifs sur la base 'mysql' pour les utilisateurs non-administrateurs."},
    {"category": "5. Gestion des privilèges", "number": "5.2", "name": "Retirer le droit FILE aux non-admins", "type": "Automated", "test_procedure": f"{MYSQL_CMD} -e \"SELECT user, host FROM mysql.user WHERE File_priv = 'Y';\"", "expected_output": {"type": "stdout_is_empty"}, "remediation": "REVOKE FILE ON *.* FROM '<user>'@'<host>';"}, # Assume only admins should have it, check if any user has it
    {"category": "5. Gestion des privilèges", "number": "5.3", "name": "Retirer le droit PROCESS aux non-admins", "type": "Automated", "test_procedure": f"{MYSQL_CMD} -e \"SELECT user, host FROM mysql.user WHERE Process_priv = 'Y';\"", "expected_output": {"type": "stdout_is_empty"}, "remediation": "REVOKE PROCESS ON *.* FROM '<user>'@'<host>';"}, # Assume only admins should have it
    {"category": "5. Gestion des privilèges", "number": "5.4", "name": "Retirer le droit SUPER (prérogative obsolète)", "type": "Automated", "test_procedure": f"{MYSQL_CMD} -e \"SELECT user, host FROM mysql.user WHERE Super_priv = 'Y';\"", "expected_output": {"type": "stdout_is_empty"}, "remediation": "Migrer vers les droits dynamiques (ex: BACKUP_ADMIN, REPLICATION_SLAVE_ADMIN) puis REVOKE SUPER ON *.* FROM '<user>'@'<host>';"}, # Assume only admins should have it
    {"category": "5. Gestion des privilèges", "number": "5.5", "name": "Retirer le droit SHUTDOWN", "type": "Automated", "test_procedure": f"{MYSQL_CMD} -e \"SELECT user, host FROM mysql.user WHERE Shutdown_priv = 'Y';\"", "expected_output": {"type": "stdout_is_empty"}, "remediation": "REVOKE SHUTDOWN ON *.* FROM '<user>'@'<host>';"}, # Assume only admins should have it
    {"category": "5. Gestion des privilèges", "number": "5.6", "name": "Retirer CREATE USER aux non-admins", "type": "Automated", "test_procedure": f"{MYSQL_CMD} -e \"SELECT user, host FROM mysql.user WHERE Create_user_priv = 'Y';\"", "expected_output": {"type": "stdout_is_empty"}, "remediation": "REVOKE CREATE USER ON *.* FROM '<user>'@'<host>';"}, # Assume only admins should have it
    {"category": "5. Gestion des privilèges", "number": "5.7", "name": "Retirer GRANT OPTION aux non-admins", "type": "Automated", "test_procedure": f"{MYSQL_CMD} -e \"SELECT user, host FROM mysql.user WHERE Grant_priv = 'Y';\"", "expected_output": {"type": "stdout_is_empty"}, "remediation": "REVOKE GRANT OPTION ON *.* FROM '<user>'@'<host>';"}, # Assume only admins should have it
    {"category": "5. Gestion des privilèges", "number": "5.8", "name": "Limiter REPLICATION SLAVE aux comptes de réplication", "type": "Manual", "test_procedure": f"{MYSQL_CMD} -e \"SELECT user, host FROM mysql.user WHERE Repl_slave_priv = 'Y';\"", "expected_output": None, "remediation": "REVOKE REPLICATION SLAVE ON *.* FROM les comptes non dédiés à la réplication."},
    {"category": "5. Gestion des privilèges", "number": "5.9", "name": "Limiter les droits DML/DDL à des BD/comptes précis", "type": "Manual", "test_procedure": "Inspecter les privilèges via SHOW GRANTS FOR '<user>'@'<host>';", "expected_output": None, "remediation": "Révoquer les droits superflus par base de données/compte."},
    {"category": "5. Gestion des privilèges", "number": "5.10", "name": "Définir proprement DEFINER/INVOKER des SP/Functions", "type": "Manual", "test_procedure": f"{MYSQL_CMD} -e \"SELECT ROUTINE_SCHEMA, ROUTINE_NAME, DEFINER FROM information_schema.ROUTINES;\"", "expected_output": None, "remediation": "Recréer les routines avec un DEFINER minimal ou utiliser SQL SECURITY INVOKER."},
    {"category": "5. Gestion des privilèges", "number": "5.11", "name": "Restreindre le droit SET_ANY_DEFINER", "type": "Manual", "test_procedure": f"{MYSQL_CMD} -e \"SHOW GRANTS FOR '<user>'@'<host>';\" et vérifier la présence de SET_ANY_DEFINER.", "expected_output": None, "remediation": "REVOKE SET_ANY_DEFINER ON *.* FROM '<user>'@'<host>';"},
    {"category": "5. Gestion des privilèges", "number": "5.12", "name": "Restreindre ALLOW_NONEXISTENT_DEFINER", "type": "Manual", "test_procedure": f"{MYSQL_CMD} -e \"SHOW GRANTS FOR '<user>'@'<host>';\" et vérifier la présence de ALLOW_NONEXISTENT_DEFINER.", "expected_output": None, "remediation": "REVOKE ALLOW_NONEXISTENT_DEFINER ON *.* FROM '<user>'@'<host>';"},

    # Catégorie 6 - Audit & Journalisation
    {"category": "6. Audit & Journalisation", "number": "6.1", "name": "Configurer log_error", "type": "Automated", "test_procedure": f"{MYSQL_CMD} -e \"SELECT @@log_error;\"", "expected_output": {"type": "stdout_not_contains", "value": "/dev/stderr"}, "remediation": "Définir log-error=/chemin/vers/mysql.err dans my.cnf."}, # Check it's not stderr (default if not set)
    {"category": "6. Audit & Journalisation", "number": "6.2", "name": "Journal hors partition système", "type": "Manual", "test_procedure": f"{MYSQL_CMD} -e \"SELECT @@log_bin_basename, @@log_error;\" puis vérifier les chemins avec df -h.", "expected_output": None, "remediation": "Déplacer les répertoires des journaux (log-bin, log-error) hors des partitions système."},
    {"category": "6. Audit & Journalisation", "number": "6.3", "name": "log_error_verbosity=2", "type": "Automated", "test_procedure": f"{MYSQL_CMD} -e \"SELECT @@log_error_verbosity;\"", "expected_output": {"type": "stdout_equals", "value": "2"}, "remediation": "Ajouter log_error_verbosity=2 dans my.cnf."},
    {"category": "6. Audit & Journalisation", "number": "6.4", "name": "log-raw OFF", "type": "Manual", "test_procedure": "Vérifier la présence de 'log-raw' dans my.cnf.", "expected_output": None, "remediation": "S'assurer que 'log-raw' n'est pas activé ou est explicitement OFF dans my.cnf."}, # Difficile à vérifier automatiquement sans parser le fichier
    {"category": "6. Audit & Journalisation", "number": "6.5", "name": "Filtrer et journaliser les connexions", "type": "Manual", "test_procedure": "Vérifier la configuration du plugin d'audit (ex: audit_log) pour la journalisation des connexions.", "expected_output": None, "remediation": "Configurer le plugin d'audit pour journaliser les succès et échecs de connexion."},
    {"category": "6. Audit & Journalisation", "number": "6.6", "name": "Filtre << tout journaliser >>", "type": "Manual", "test_procedure": "Vérifier la configuration du plugin d'audit pour s'assurer qu'un filtre 'log_all' ou équivalent est appliqué.", "expected_output": None, "remediation": "Créer et appliquer un filtre d'audit pour journaliser toutes les actions."},
    {"category": "6. Audit & Journalisation", "number": "6.7", "name": "audit_log_strategy = (S)SYNC", "type": "Manual", "test_procedure": f"{MYSQL_CMD} -e \"SELECT @@audit_log_strategy;\"", "expected_output": None, "remediation": "Configurer audit_log_strategy='SEMISYNCHRONOUS' ou 'SYNCHRONOUS' via le plugin d'audit."}, # Variable spécifique au plugin
    {"category": "6. Audit & Journalisation", "number": "6.8", "name": "Interdire le déchargement du plugin audit", "type": "Manual", "test_procedure": "Vérifier si audit_log=FORCE_PLUS_PERMANENT est dans my.cnf.", "expected_output": None, "remediation": "Ajouter audit_log=FORCE_PLUS_PERMANENT dans my.cnf."},

    # Catégorie 7 - Authentification
    {"category": "7. Authentification", "number": "7.1", "name": "Plugin d'authentification sûr (caching_sha2_password)", "type": "Automated", "test_procedure": f"{MYSQL_CMD} -e \"SELECT @@default_authentication_plugin;\"", "expected_output": {"type": "stdout_equals", "value": "caching_sha2_password"}, "remediation": "Définir default_authentication_plugin=caching_sha2_password dans my.cnf et migrer les comptes existants."},
    {"category": "7. Authentification", "number": "7.2", "name": "Aucun mot de passe dans le my.cnf global", "type": "Manual", "test_procedure": "Inspecter les fichiers my.cnf globaux (/etc/my.cnf, /etc/mysql/my.cnf, etc.) pour des mots de passe en clair.", "expected_output": None, "remediation": "Utiliser mysql_config_editor ou des fichiers .my.cnf privés avec permissions restreintes."},
    {"category": "7. Authentification", "number": "7.3", "name": "Tous les comptes ont un mot de passe", "type": "Automated", "test_procedure": f"{MYSQL_CMD} -e \"SELECT user, host FROM mysql.user WHERE authentication_string = '' OR plugin='mysql_no_login';\"", "expected_output": {"type": "stdout_is_empty"}, "remediation": "ALTER USER '<user>'@'<host>' IDENTIFIED BY '<password>'; ou utiliser mysql_secure_installation."},
    {"category": "7. Authentification", "number": "7.4", "name": "Expiration annuelle des mots de passe", "type": "Automated", "test_procedure": f"{MYSQL_CMD} -e \"SELECT @@default_password_lifetime;\"", "expected_output": {"type": "stdout_is_numeric_less_equal", "value": 365}, "remediation": "SET PERSIST default_password_lifetime=365;"},
    {"category": "7. Authentification", "number": "7.5", "name": "Politique de complexité forte", "type": "Manual", "test_procedure": f"{MYSQL_CMD} -e \"SHOW VARIABLES LIKE 'validate_password%';\"", "expected_output": None, "remediation": "Installer et configurer component_validate_password avec une politique forte (ex: validate_password.policy=STRONG)."},
    {"category": "7. Authentification", "number": "7.6", "name": "Pas de wildcard '%' dans host", "type": "Automated", "test_procedure": f"{MYSQL_CMD} -e \"SELECT user, host FROM mysql.user WHERE host = '%';\"", "expected_output": {"type": "stdout_is_empty"}, "remediation": "ALTER USER '<user>'@'%' IDENTIFIED BY '...' RENAME TO '<user>'@'<specific_host>'; ou supprimer le compte."},
    {"category": "7. Authentification", "number": "7.7", "name": "Supprimer les comptes anonymes", "type": "Automated", "test_procedure": f"{MYSQL_CMD} -e \"SELECT user, host FROM mysql.user WHERE user = '';\"", "expected_output": {"type": "stdout_is_empty"}, "remediation": "DROP USER ''@'<host>'; ou utiliser mysql_secure_installation."},

    # Catégorie 8 - Sécurité réseau
    {"category": "8. Sécurité réseau", "number": "8.1", "name": "Forcer SSL/TLS (require_secure_transport=ON)", "type": "Automated", "test_procedure": f"{MYSQL_CMD} -e \"SELECT @@require_secure_transport;\"", "expected_output": {"type": "stdout_equals", "value": "1"}, "remediation": "Configurer les certificats SSL/TLS, puis ajouter require_secure_transport=ON dans my.cnf."},
    {"category": "8. Sécurité réseau", "number": "8.2", "name": "Exiger TLS côté utilisateur (ssl_type)", "type": "Manual", "test_procedure": f"{MYSQL_CMD} -e \"SELECT user, host, ssl_type FROM mysql.user WHERE host NOT IN ('localhost', '127.0.0.1', '::1');\"", "expected_output": None, "remediation": "ALTER USER '<user>'@'<host>' REQUIRE SSL; ou REQUIRE X509;"},
    {"category": "8. Sécurité réseau", "number": "8.3", "name": "Limiter le nombre de connexions", "type": "Manual", "test_procedure": f"{MYSQL_CMD} -e \"SHOW VARIABLES LIKE 'max_connections'; SHOW VARIABLES LIKE 'max_user_connections';\"", "expected_output": None, "remediation": "Ajuster max_connections et max_user_connections dans my.cnf selon les besoins."},

    # Catégorie 9 - Réplication
    {"category": "9. Réplication", "number": "9.1", "name": "Chiffrer le trafic de réplication", "type": "Manual", "test_procedure": "Vérifier si la réplication utilise TLS (SOURCE_SSL=1) ou un tunnel VPN/SSH.", "expected_output": None, "remediation": "Configurer TLS pour la réplication (SOURCE_SSL=1, SOURCE_SSL_CA, etc.) ou utiliser un tunnel sécurisé."},
    {"category": "9. Réplication", "number": "9.2", "name": "SOURCE_SSL_VERIFY_SERVER_CERT = 1", "type": "Manual", "test_procedure": "Si TLS est utilisé, exécuter SHOW REPLICA STATUS\\G et vérifier la valeur de Master_SSL_Verify_Server_Cert.", "expected_output": None, "remediation": "Exécuter CHANGE REPLICATION SOURCE TO SOURCE_SSL_VERIFY_SERVER_CERT = 1;"},
    {"category": "9. Réplication", "number": "9.3", "name": "master_info_repository TABLE", "type": "Automated", "test_procedure": f"{MYSQL_CMD} -e \"SELECT @@master_info_repository;\"", "expected_output": {"type": "stdout_equals", "value": "TABLE"}, "remediation": "Configurer master_info_repository=TABLE dans my.cnf."},
    {"category": "9. Réplication", "number": "9.4", "name": "Retirer SUPER aux comptes de réplication", "type": "Manual", "test_procedure": "SHOW GRANTS FOR '<repl_user>'@'<repl_host>'; vérifier l'absence de SUPER.", "expected_output": None, "remediation": "REVOKE SUPER ON *.* FROM '<repl_user>'@'<repl_host>'; et accorder les privilèges dynamiques nécessaires (ex: REPLICATION_SLAVE_ADMIN)."},

    # Catégorie 10 - InnoDB Cluster / Group Replication
    {"category": "10. InnoDB Cluster / Group Replication", "number": "10.1", "name": "Chiffrer le trafic Group Replication", "type": "Automated", "test_procedure": f"{MYSQL_CMD} -e \"SELECT @@group_replication_ssl_mode;\"", "expected_output": {"type": "stdout_not_equals", "value": "DISABLED"}, "remediation": "Configurer group_replication_ssl_mode à REQUIRED, VERIFY_CA, ou VERIFY_IDENTITY dans my.cnf."},
    {"category": "10. InnoDB Cluster / Group Replication", "number": "10.2", "name": "Définir une allow-list de nœuds", "type": "Automated", "test_procedure": f"{MYSQL_CMD} -e \"SELECT @@group_replication_ip_allowlist;\"", "expected_output": {"type": "stdout_not_empty"}, "remediation": "Configurer group_replication_ip_allowlist avec les adresses IP/CIDR des nœuds autorisés."},
]

# --- Modèle HTML (Adapté pour MySQL) ---
HTML_TEMPLATE = """
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport CIS MySQL 8.0 Benchmark</title>
    <link href="https://cdn.jsdelivr.net/npm/tailwindcss@2.2.19/dist/tailwind.min.css" rel="stylesheet">
    <script src="https://cdn.jsdelivr.net/npm/chart.js@3.7.1/dist/chart.min.js"></script>
    <style>
        /* Styles personnalisés si nécessaire */
        .status-pass {{ color: #10B981; }} /* green-500 */
        .status-fail {{ color: #EF4444; }} /* red-500 */
        .status-manual {{ color: #F59E0B; }} /* yellow-500 */
        .status-error {{ color: #6B7280; }} /* gray-500 */
        .status-na {{ color: #9CA3AF; }} /* gray-400 */
        pre {{ white-space: pre-wrap; word-wrap: break-word; background-color: #f3f4f6; padding: 0.5rem; border-radius: 0.25rem; font-size: 0.875rem;}}
        table {{ table-layout: fixed; width: 100%; }} /* Added for better column width control */
        td, th {{ word-break: break-word; }} /* Allow breaking long words */
        .chart-container {{ width: 300px; height: 300px; margin: 20px auto; }} /* Style for chart container */
        .category-chart-container {{ width: 80%; margin: 20px auto; }} /* Style for category chart container */
        code {{ background-color: #e5e7eb; padding: 0.1rem 0.3rem; border-radius: 0.25rem; font-family: monospace;}}
    </style>
</head>
<body class="font-sans bg-gray-100 text-gray-800 p-6">
    <div class="container mx-auto bg-white p-8 rounded-lg shadow-lg">
        <h1 class="text-3xl font-bold mb-6 text-gray-900">Rapport CIS MySQL 8.0 Benchmark</h1>
        <p class="text-gray-600 mb-4">Date du rapport : {report_date}</p>
        <p class="text-gray-600 mb-8">Généré par un script basé sur le document CIS MySQL 8.0 Benchmark (Version 1.0 du 13 Avril 2025 par Jean-Marie Renouard).</p>

        <div class="mb-8 p-4 bg-gray-50 rounded-md border border-gray-200">
            <h2 class="text-2xl font-semibold mb-3 text-gray-800">Score Global</h2>
            <p class="text-xl font-bold {overall_score_class}">{overall_score:.2f}%</p>
            <p class="text-gray-700">des contrôles automatisés réussis ({passed_automated}/{total_automated} vérifiés).</p>
             <p class="text-gray-700">{manual_checks} contrôles nécessitent une vérification manuelle.</p>
             <p class="text-gray-700">{error_checks} contrôles ont rencontré une erreur d'exécution.</p>
             <p class="text-gray-700">{na_checks} contrôles ne sont pas applicables (ex: plugin non installé, commande introuvable).</p>

             <div class="chart-container">
                 <canvas id="overallScoreChart"></canvas>
             </div>
        </div>

        {categories_reports}

    </div>

    <script>
        // Data for the overall pie chart
        const overallChartData = {{
            labels: ['Pass', 'Fail', 'Error', 'N/A'],
            datasets: [{{
                label: 'Résultats des contrôles automatisés',
                data: [{passed_automated_count}, {failed_automated_count}, {error_automated_count}, {na_automated_count}],
                backgroundColor: [
                    '#10B981', // green-500
                    '#EF4444', // red-500
                    '#6B7280', // gray-500
                    '#9CA3AF'  // gray-400
                ],
                hoverOffset: 4
            }}]
        }};

        // Configuration options for the overall pie chart
        const overallChartConfig = {{
            type: 'pie',
            data: overallChartData,
            options: {{
                responsive: true,
                maintainAspectRatio: false,
                plugins: {{
                    legend: {{
                        position: 'top',
                    }},
                    title: {{
                        display: true,
                        text: 'Répartition des contrôles automatisés (Global)'
                    }}
                }}
            }}
        }};

        // Render the overall chart
        const overallScoreChartCtx = document.getElementById('overallScoreChart');
        if (overallScoreChartCtx) {{
             new Chart(overallScoreChartCtx, overallChartConfig);
        }}


        // Data and configuration for category bar charts
        const categoryChartData = {{
            labels: {category_labels}, // List of category names
            datasets: [
                {{
                    label: 'Pass',
                    data: {category_pass_counts},
                    backgroundColor: '#10B981', // green-500
                }},
                {{
                    label: 'Fail',
                    data: {category_fail_counts},
                    backgroundColor: '#EF4444', // red-500
                }},
                {{
                    label: 'Error',
                    data: {category_error_counts},
                    backgroundColor: '#6B7280', // gray-500
                }},
                 {{
                    label: 'N/A',
                    data: {category_na_counts},
                    backgroundColor: '#9CA3AF', // gray-400
                }}
            ]
        }};

        const categoryChartConfig = {{
            type: 'bar',
            data: categoryChartData,
            options: {{
                responsive: true,
                maintainAspectRatio: false, // Allow chart to resize vertically
                plugins: {{
                    legend: {{
                        position: 'top',
                    }},
                    title: {{
                        display: true,
                        text: 'Répartition des contrôles automatisés par catégorie'
                    }}
                }},
                scales: {{
                    x: {{
                        stacked: true,
                    }},
                    y: {{
                        stacked: true,
                        beginAtZero: true,
                        title: {{
                            display: true,
                            text: 'Nombre de contrôles'
                        }}
                    }}
                }}
            }}
        }};

        // Render the category bar chart
         const categoryScoreChartCtx = document.getElementById('categoryChart');
         if (categoryScoreChartCtx) {{
              new Chart(categoryScoreChartCtx, categoryChartConfig);
         }}

    </script>
</body>
</html>
"""

CATEGORY_REPORT_TEMPLATE = """
        <div class="mb-10 p-4 bg-gray-50 rounded-md border border-gray-200">
            <h2 class="text-2xl font-semibold mb-3 text-gray-800">{category_name}</h2>
            <p class="text-lg font-bold {category_score_class}">{category_score:.2f}%</p>
            <p class="text-gray-700">des contrôles automatisés réussis dans cette catégorie ({passed_automated}/{total_automated} vérifiés).</p>
            <p class="text-gray-700">{manual_checks} contrôles nécessitent une vérification manuelle.</p>
            <p class="text-gray-700">{error_checks} contrôles ont rencontré une erreur d'exécution.</p>
            <p class="text-gray-700">{na_checks} contrôles ne sont pas applicables.</p>

            <table class="min-w-full border border-gray-300 divide-y divide-gray-300 mt-6">
                <thead>
                    <tr class="bg-gray-200 text-gray-700 uppercase text-sm leading-normal">
                        <th class="py-3 px-4 text-left w-1/12">Numéro</th>
                        <th class="py-3 px-4 text-left w-3/12">Recommandation</th>
                        <th class="py-3 px-4 text-left w-1/12">Type</th>
                        <th class="py-3 px-4 text-left w-2/12">Test Exécuté</th>
                        <th class="py-3 px-4 text-left w-1/12">Résultat</th>
                        <th class="py-3 px-4 text-left w-2/12">Sortie / Erreur / Notes</th>
                        <th class="py-3 px-4 text-left w-2/12">Procédure de Remédiation</th>
                    </tr>
                </thead>
                <tbody class="text-gray-600 text-sm font-light divide-y divide-gray-200">
                    {checks_rows}
                </tbody>
            </table>
        </div>
"""

# New template for the category bar chart canvas
CATEGORY_CHART_CANVAS_TEMPLATE = """
        <div class="category-chart-container" style="height: 400px;"> {/* Increased height */}
            <canvas id="categoryChart"></canvas>
        </div>
"""


CHECK_ROW_TEMPLATE = """
                    <tr class="border-b border-gray-200 hover:bg-gray-100">
                        <td class="py-3 px-4 text-left align-top">{number}</td>
                        <td class="py-3 px-4 text-left align-top">{name}</td>
                        <td class="py-3 px-4 text-left align-top">{type}</td>
                        <td class="py-3 px-4 text-left align-top"><code>{test_procedure}</code></td>
                        <td class="py-3 px-4 text-left align-top"><span class="{status_class} font-semibold">{status_icon} {status_text}</span></td>
                        <td class="py-3 px-4 text-left align-top"><pre>{output}</pre></td>
                        <td class="py-3 px-4 text-left align-top">{remediation}</td>
                    </tr>
"""

# --- Fonctions d'exécution et d'évaluation (Légèrement adaptées) ---

def run_command(command):
    """Exécute une commande shell et retourne stdout, stderr, et le code de retour."""
    # print(f"DEBUG: Running command: {command}") # Ligne de débogage
    try:
        # Utilise shell=True pour permettre les pipelines et les redirections comme dans les exemples
        # Attention : shell=True est moins sécurisé si la commande vient d'une source non fiable.
        # Ici, les commandes sont définies dans le script.
        # Ajout de `timeout` pour éviter les blocages potentiels (ex: attente de mot de passe)
        process = subprocess.run(command, shell=True, check=False, capture_output=True, text=True, executable='/bin/bash', timeout=30) # Timeout de 30s
        # print(f"DEBUG: stdout: {process.stdout.strip()}") # Ligne de débogage
        # print(f"DEBUG: stderr: {process.stderr.strip()}") # Ligne de débogage
        # print(f"DEBUG: returncode: {process.returncode}") # Ligne de débogage
        return process.stdout.strip(), process.stderr.strip(), process.returncode
    except subprocess.TimeoutExpired:
        return "", f"Erreur : La commande a dépassé le délai d'exécution ({30}s).", 124 # Code pour timeout
    except FileNotFoundError:
        cmd_name = command.split()[0] if command else "N/A"
        return "", f"Erreur : Commande '{cmd_name}' introuvable.", 127 # Code 127 pour command not found
    except Exception as e:
        return "", f"Erreur d'exécution : {e}", 1 # Code générique pour autres erreurs

def evaluate_condition(condition, stdout, stderr, returncode):
    """Évalue si le résultat de la commande correspond à la condition attendue."""
    if not condition:
        return False # Aucune condition définie

    condition_type = condition.get("type")
    expected_value = condition.get("value")
    expected_values = condition.get("values")
    regex_pattern = condition.get("pattern")

    # Handle potential MySQL errors that don't necessarily mean failure of the check's intent
    # Example: Access denied might mean the check passed (e.g., user doesn't have SUPER priv)
    # This needs careful consideration per check, but for now, focus on direct evaluation.

    if condition_type == "returncode_zero":
        return returncode == 0
    elif condition_type == "returncode_equals":
         return returncode == expected_value
    elif condition_type == "stdout_equals":
        # MySQL output might have extra whitespace/newlines
        return stdout.strip() == str(expected_value) # Convert expected to string for comparison
    elif condition_type == "stdout_contains":
        return str(expected_value) in stdout
    elif condition_type == "stdout_not_contains":
        return str(expected_value) not in stdout
    elif condition_type == "stdout_not_empty":
        return stdout != "" and stdout is not None
    elif condition_type == "stdout_is_empty":
        return stdout == "" or stdout is None
    elif condition_type == "stdout_contains_any":
        if expected_values is None: return False
        return any(str(value) in stdout for value in expected_values)
    elif condition_type == "stdout_not_contains_any":
        if expected_values is None: return True
        return not any(str(value) in stdout for value in expected_values)
    elif condition_type == "stdout_regex_match":
        if regex_pattern is None: return False
        return re.search(regex_pattern, stdout) is not None
    elif condition_type == "stdout_is_numeric_greater_than":
        try:
            numeric_value_match = re.match(r'^(\d+)', stdout)
            if numeric_value_match:
                 numeric_value = int(numeric_value_match.group(1))
                 return numeric_value > expected_value
            return False
        except (ValueError, TypeError):
            return False
    elif condition_type == "stdout_is_numeric_less_equal": # Nouvelle condition pour 7.4
         try:
             numeric_value_match = re.match(r'^(\d+)', stdout)
             if numeric_value_match:
                  numeric_value = int(numeric_value_match.group(1))
                  # Handle potential '0' which means infinite lifetime, considered > 365
                  if numeric_value == 0:
                      return False # 0 (infinite) is not <= 365
                  return numeric_value <= expected_value
             return False
         except (ValueError, TypeError):
             return False

    # Default case: unknown condition type
    print(f"WARN: Unknown condition type '{condition_type}'")
    return False

def perform_checks(recommendations):
    """Exécute tous les contrôles et stocke les résultats."""
    results = {}
    stored_outputs = {} # Store outputs globally for potential cross-check references (if needed later)

    for rec in recommendations:
        category = rec["category"]
        if category not in results:
            results[category] = []

        check_number = rec.get("number", "N/A")

        check_result = {
            "number": check_number,
            "name": rec["name"],
            "type": rec["type"],
            "test_procedure": rec.get("test_procedure", ""),
            "remediation": rec.get("remediation", ""),
            "status": "Not Applicable", # Default status
            "output": "",
            "error": ""
        }

        if rec["type"] == "Manual":
            check_result["status"] = "Manual"
            check_result["output"] = "Ce contrôle nécessite une vérification manuelle."
            # Store manual test procedure description for display
            check_result["output"] += f"\n\nProcédure suggérée:\n{rec.get('test_procedure', 'N/A')}"
        elif rec["type"] == "Automated":
            cmd_to_run = None
            command_executed_display = "N/A"
            stdout, stderr, returncode = "", "", -1 # Initialize execution results

            try:
                # Handle checks that require getting a dynamic path first
                if "path_command" in rec:
                    path_cmd = rec["path_command"]
                    path_stdout, path_stderr, path_returncode = run_command(path_cmd)

                    if path_returncode != 0 or not path_stdout:
                        check_result["status"] = "Error"
                        check_result["output"] = f"Erreur lors de l'obtention du chemin via:\n`{path_cmd}`\nStdout:\n{path_stdout}\nStderr:\n{path_stderr}"
                        check_result["error"] = path_stderr
                        results[category].append(check_result)
                        continue # Skip to next recommendation

                    dynamic_path = path_stdout.strip()
                    stored_outputs[check_number + "_path"] = dynamic_path # Store path specific to this check number

                    if "test_procedure_template" in rec:
                        cmd_to_run = rec["test_procedure_template"].format(path=dynamic_path)
                        command_executed_display = cmd_to_run # Store the formatted command
                    else:
                        # If only path_command is defined, maybe the check is just getting the path?
                        # Or maybe test_procedure should have been a template? Assume error for now.
                         check_result["status"] = "Error"
                         check_result["output"] = f"Configuration d'audit invalide: 'path_command' défini mais pas 'test_procedure_template' pour {check_number}."
                         results[category].append(check_result)
                         continue
                elif "test_procedure" in rec:
                    cmd_to_run = rec["test_procedure"]
                    command_executed_display = cmd_to_run
                else:
                     check_result["status"] = "Error"
                     check_result["output"] = f"Configuration d'audit invalide: Ni 'test_procedure' ni 'path_command' définis pour {check_number}."
                     results[category].append(check_result)
                     continue

                # Execute the command
                stdout, stderr, returncode = run_command(cmd_to_run)
                check_result["output"] = f"Stdout:\n{stdout}\nStderr:\n{stderr}\nReturn Code: {returncode}"
                check_result["error"] = stderr
                check_result["test_procedure"] = command_executed_display # Update with actual command run

                # --- Evaluation ---
                condition = rec.get("expected_output")

                # Handle specific error conditions before evaluating success
                if returncode == 127: # Command not found
                    check_result["status"] = "Error"
                    check_result["output"] = f"Erreur: Commande introuvable.\n{check_result['output']}"
                elif returncode == 124: # Timeout
                    check_result["status"] = "Error"
                    check_result["output"] = f"Erreur: Timeout.\n{check_result['output']}"
                elif "command not found" in stderr.lower(): # Another way to catch command not found
                     check_result["status"] = "Error"
                     check_result["output"] = f"Erreur: Commande introuvable (détecté dans stderr).\n{check_result['output']}"
                elif "ERROR 1045 (28000): Access denied" in stderr:
                     # Access denied might be a PASS for some privilege checks (e.g., trying to use a revoked priv)
                     # Or a FAIL if the script needs access. For now, mark as Error needing review.
                     # A more sophisticated approach could check 'rec' for expected errors.
                     check_result["status"] = "Error"
                     check_result["output"] = f"Erreur: Accès refusé. Vérifiez les identifiants/privilèges MySQL.\n{check_result['output']}"
                elif returncode != 0 and stderr and not condition:
                     # If command failed with stderr, and no specific condition to check, mark as Error
                     check_result["status"] = "Error"
                     check_result["output"] = f"Erreur d'exécution (code {returncode}).\n{check_result['output']}"
                elif condition:
                    # Evaluate the condition only if no critical error occurred above
                    if evaluate_condition(condition, stdout, stderr, returncode):
                        check_result["status"] = "Pass"
                    else:
                        # Condition not met, but command ran (potentially with non-fatal errors)
                        check_result["status"] = "Fail"
                        check_result["output"] += "\n\nCondition de succès non remplie."
                elif returncode == 0 and not condition:
                     # Command succeeded but no condition to check? Mark as Pass (e.g., informational commands)
                     check_result["status"] = "Pass" # Or maybe Manual/NA? Let's assume Pass if rc=0.
                     check_result["output"] += "\n\nNote: Commande exécutée avec succès, mais aucune condition de succès n'était définie pour ce test automatisé."
                # else: Status remains 'Not Applicable' or 'Error' if set previously


            except Exception as e:
                 check_result["status"] = "Error"
                 check_result["output"] = f"Erreur interne du script lors de l'exécution du contrôle {check_number}: {e}\nCommande tentée: {command_executed_display}"
                 check_result["error"] = str(e)


        # Append the final result for this check
        results[category].append(check_result)

    return results

def calculate_scores(results):
    """Calcule les scores globaux et par catégorie."""
    overall = {"total_automated": 0, "passed_automated": 0, "failed_automated": 0, "manual": 0, "error": 0, "na": 0}
    categories_scores = {}
    # Initialize category counts using the order from RECOMMENDATIONS_DATA
    category_order = list(dict.fromkeys(rec["category"] for rec in RECOMMENDATIONS_DATA))
    for category in category_order:
        categories_scores[category] = {
            "score": 0,
            "total_automated": 0, # Total attempted (Pass + Fail)
            "passed_automated": 0,
            "failed_automated": 0,
            "manual_checks": 0,
            "error_checks": 0,
            "na_checks": 0,
            "pass_count": 0, # Counts for charts
            "fail_count": 0,
            "error_count": 0,
            "na_count": 0
        }


    for category, checks in results.items():
        if category not in categories_scores:
             print(f"WARN: Category '{category}' found in results but not pre-initialized. Skipping.")
             continue
        for check in checks:
            cat_stats = categories_scores[category]
            if check["type"] == "Automated":
                if check["status"] == "Pass":
                    overall["passed_automated"] += 1
                    cat_stats["passed_automated"] += 1
                    cat_stats["pass_count"] += 1
                elif check["status"] == "Fail":
                    overall["failed_automated"] += 1
                    cat_stats["failed_automated"] += 1
                    cat_stats["fail_count"] += 1
                elif check["status"] == "Error":
                    overall["error"] += 1
                    cat_stats["error_checks"] += 1
                    cat_stats["error_count"] += 1
                elif check["status"] == "Not Applicable":
                    overall["na"] += 1
                    cat_stats["na_checks"] += 1
                    cat_stats["na_count"] += 1
            elif check["type"] == "Manual":
                overall["manual"] += 1
                cat_stats["manual_checks"] += 1

    # Calculate scores
    overall_attempted_automated = overall["passed_automated"] + overall["failed_automated"]
    overall_score = (overall["passed_automated"] / overall_attempted_automated * 100) if overall_attempted_automated > 0 else 0

    for category in category_order:
         cat_stats = categories_scores[category]
         cat_attempted_automated = cat_stats["passed_automated"] + cat_stats["failed_automated"]
         cat_stats["total_automated"] = cat_attempted_automated # Store attempted count
         cat_stats["score"] = (cat_stats["passed_automated"] / cat_attempted_automated * 100) if cat_attempted_automated > 0 else 0

    # Prepare data for category bar chart (using the original order)
    category_labels = json.dumps(category_order)
    category_pass_counts = json.dumps([categories_scores[cat]["pass_count"] for cat in category_order])
    category_fail_counts = json.dumps([categories_scores[cat]["fail_count"] for cat in category_order])
    category_error_counts = json.dumps([categories_scores[cat]["error_count"] for cat in category_order])
    category_na_counts = json.dumps([categories_scores[cat]["na_count"] for cat in category_order])


    # Return overall score, category details, overall counts, and chart data
    return (overall_score, categories_scores,
            overall["manual"], overall["error"], overall["na"],
            overall["passed_automated"], overall["failed_automated"], overall["error"], overall["na"], # Counts for overall chart
            category_labels, category_pass_counts, category_fail_counts, category_error_counts, category_na_counts) # Data for category chart

def get_score_class(score):
    """Retourne la classe CSS pour la couleur du score."""
    if score >= 80:
        return "text-green-600"
    elif score >= 50:
        return "text-yellow-600"
    else:
        return "text-red-600"

def get_status_info(status):
    """Retourne l'icône et le texte pour un statut."""
    if status == "Pass":
        return "✅", "Pass", "status-pass"
    elif status == "Fail":
        return "❌", "Fail", "status-fail"
    elif status == "Manual":
        return "⚠️", "Manuel", "status-manual"
    elif status == "Error":
        return "❓", "Erreur", "status-error"
    elif status == "Not Applicable":
        return "➖", "N/A", "status-na"
    else:
        return "❓", status, "status-error" # Fallback

def generate_html_report(results, overall_score, categories_scores, total_manual, total_errors, total_na, passed_auto_count, failed_auto_count, error_auto_count, na_auto_count, category_labels, category_pass_counts, category_fail_counts, category_error_counts, category_na_counts, filename="rapport_cis_mysql_8.html"):
    """Génère le rapport HTML."""
    report_date = datetime.now().strftime("%d/%m/%Y %H:%M:%S")
    overall_score_class = get_score_class(overall_score)
    categories_html = ""
    category_order = list(dict.fromkeys(rec["category"] for rec in RECOMMENDATIONS_DATA)) # Get order from data

    for category in category_order:
        checks = results.get(category, [])
        cat_info = categories_scores.get(category, {})
        category_score = cat_info.get("score", 0)
        cat_score_class = get_score_class(category_score)
        cat_total_automated = cat_info.get("total_automated", 0) # Attempted
        cat_passed_automated = cat_info.get("passed_automated", 0)
        cat_manual_checks = cat_info.get("manual_checks", 0)
        cat_error_checks = cat_info.get("error_checks", 0)
        cat_na_checks = cat_info.get("na_checks", 0)

        checks_rows_html = ""
        # Sort checks within the category by number (handle potential non-numeric parts)
        def sort_key(check):
            parts = re.split(r'[._-]', check['number'])
            return [int(p) if p.isdigit() else p for p in parts]

        try:
             sorted_checks = sorted(checks, key=sort_key)
        except Exception as e:
             print(f"WARN: Could not sort checks for category '{category}'. Error: {e}")
             sorted_checks = checks # Keep original order if sorting fails

        for check in sorted_checks:
            status_icon, status_text, status_class = get_status_info(check["status"])

            # Escape HTML special characters
            escaped_name = html.escape(check["name"])
            escaped_test_procedure = html.escape(check["test_procedure"])
            # Don't escape output/remediation to allow pre/code formatting
            output_display = html.escape(check["output"])
            remediation_display = html.escape(check["remediation"]) if check["remediation"] else "N/A"

            checks_rows_html += CHECK_ROW_TEMPLATE.format(
                number=check["number"],
                name=escaped_name,
                type=check["type"],
                test_procedure=escaped_test_procedure,
                status_icon=status_icon,
                status_text=status_text,
                status_class=status_class,
                output=output_display,
                remediation=remediation_display
            )

        categories_html += CATEGORY_REPORT_TEMPLATE.format(
            category_name=html.escape(category),
            category_score=category_score,
            category_score_class=cat_score_class,
            passed_automated=cat_passed_automated,
            total_automated=cat_total_automated, # Display attempted
            manual_checks=cat_manual_checks,
            error_checks=cat_error_checks,
            na_checks=cat_na_checks,
            checks_rows=checks_rows_html
        )

    # Add the category chart canvas after all category reports
    categories_html += CATEGORY_CHART_CANVAS_TEMPLATE

    html_output = HTML_TEMPLATE.format(
        report_date=report_date,
        overall_score=overall_score,
        overall_score_class=overall_score_class,
        passed_automated=passed_auto_count, # Use the actual counts for display
        total_automated=passed_auto_count + failed_auto_count, # Total attempted for display
        manual_checks=total_manual,
        error_checks=total_errors, # Use overall error count
        na_checks=total_na,       # Use overall NA count
        categories_reports=categories_html,
        # Pass counts for the overall chart
        passed_automated_count=passed_auto_count,
        failed_automated_count=failed_auto_count,
        error_automated_count=error_auto_count, # Pass overall error count for chart
        na_automated_count=na_auto_count,       # Pass overall NA count for chart
        # Pass data for category bar chart
        category_labels=category_labels,
        category_pass_counts=category_pass_counts,
        category_fail_counts=category_fail_counts,
        category_error_counts=category_error_counts,
        category_na_counts=category_na_counts
    )

    try:
        with open(filename, "w", encoding="utf-8") as f:
            f.write(html_output)
        print(f"Rapport généré avec succès : {filename}")
    except IOError as e:
        print(f"Erreur lors de l'écriture du fichier de rapport '{filename}': {e}")


# --- Exécution principale ---
if __name__ == "__main__":
    print("🚀 Démarrage de l'audit CIS MySQL 8.0 Benchmark ...")
    print(f"ℹ️ Utilisation de la commande MySQL: '{MYSQL_CMD}' (Assurez-vous que la connexion est configurée)")

    # Exécuter les contrôles
    check_results = perform_checks(RECOMMENDATIONS_DATA)

    # Calculer les scores et obtenir les comptes pour les graphiques
    try:
        (overall_score, categories_scores, total_manual, total_errors, total_na,
         passed_auto_count, failed_auto_count, error_auto_count, na_auto_count,
         category_labels, category_pass_counts, category_fail_counts, category_error_counts, category_na_counts
        ) = calculate_scores(check_results)

        # Générer le rapport HTML
        generate_html_report(check_results, overall_score, categories_scores,
                             total_manual, total_errors, total_na,
                             passed_auto_count, failed_auto_count, error_auto_count, na_auto_count,
                             category_labels, category_pass_counts, category_fail_counts, category_error_counts, category_na_counts,
                             "rapport_cis_mysql_8.html")

        print("✅ Audit terminé.")
        print(f"Score Global (contrôles automatisés tentés) : {overall_score:.2f}%.")
        print(f"Contrôles manuels : {total_manual}.")
        print(f"Contrôles en erreur : {total_errors}.")
        print(f"Contrôles non applicables : {total_na}.")
        print("Consulte le fichier rapport_cis_mysql_8.html pour les détails.")

    except Exception as e:
        print(f"\n❌ Une erreur s'est produite lors du calcul des scores ou de la génération du rapport:")
        print(e)
        import traceback
        traceback.print_exc()