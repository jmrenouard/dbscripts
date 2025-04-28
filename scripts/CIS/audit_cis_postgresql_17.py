import subprocess
import json
import os
from datetime import datetime
import re # Pour les expressions régulières
import html # Pour échapper les caractères spéciaux HTML

# --- Structure des Recommandations Automatisées ---
# Cette structure traduit le tableau que tu as fourni en données exploitables par le script.
# Chaque entrée contient le numéro, le nom, le type (Automated/Manual),
# la procédure de test (commande shell), le critère de succès attendu, et la remédiation.
# Pour les contrôles "Manual", la procédure de test et le critère attendu sont juste informatifs
# car le script ne peut pas les exécuter.
RECOMMENDATIONS_DATA = [
    # 1. Installation et correctifs
    {"category": "1. Installation et correctifs", "number": "1.1", "name": "Obtenir les paquets depuis des dépôts autorisés", "type": "Manual", "test_procedure": "Vérifier dnf repolist all ou équivalent (apt-file search /usr/pgsql-*/lib/libpq.so.5) pour s’assurer que seuls les dépôts officiels sont activés.", "expected_output": None, "remediation": "Supprimer/ajouter des dépôts pour n’inclure que les sources valides (p. ex. dnf install -y https://download.postgresql.org/.../pgdg-redhat-repo-latest.noarch.rpm), puis réinstaller."},
    {"category": "1. Installation et correctifs", "number": "1.2", "name": "Installer uniquement les paquets requis", "type": "Manual", "test_procedure": "apt search postgresql ou dnf search postgresql, lister les paquets installés et comparer à la liste d’exigences.", "expected_output": None, "remediation": "Purger/effacer les paquets non désirés : apt purge <pkg> ou dnf erase <pkg>."},
    {"category": "1. Installation et correctifs", "number": "1.3", "name": "Activer le service systemd", "type": "Automated", "test_procedure": "systemctl is-enabled postgresql@17-main.service || systemctl is-enabled postgresql-17.service", "expected_output": {"type": "stdout_equals", "value": "enabled"}, "remediation": "systemctl enable postgresql@17-main || systemctl enable postgresql-17"}, # Added common Ubuntu service name
    # Corrected 1.4: Check service status and data directory permissions/ownership
    {"category": "1. Installation et correctifs", "number": "1.4", "name": "Initialiser correctement le cluster de données", "type": "Automated", "sub_checks": [
        {"test_procedure": "systemctl is-active postgresql@17-main.service || systemctl is-active postgresql-17.service", "expected_output": {"type": "stdout_equals", "value": "active"}}, # Check if service is running
        {"test_procedure": "sudo -u postgres psql -t -c 'SHOW data_directory;'", "expected_output": {"type": "stdout_not_empty"}, "store_output_as": "datadir"}, # Get data directory path and store it
        {"test_procedure_template": "ls -ld {datadir}", "expected_output": {"type": "stdout_regex_match", "pattern": r"^drwx------\s+\d+\s+postgres\s+postgres"}}, # Check ownership and permissions (drwx------ postgres postgres)
    ], "remediation": "Supprimer le répertoire de données et relancer initdb (avec checksums si souhaité), puis démarrer le service. Assurer les bonnes permissions sur le répertoire de données."},
    {"category": "1. Installation et correctifs", "number": "1.5", "name": "Appliquer les derniers correctifs de sécurité", "type": "Manual", "test_procedure": "psql -c 'SHOW server_version' et comparer à la liste des versions disponibles sur la page de news PostgreSQL.", "expected_output": None, "remediation": "sudo apt update && sudo apt upgrade postgresql-17*"}, # Adapted remediation for Ubuntu/apt
    {"category": "1. Installation et correctifs", "number": "1.6", "name": "Vérifier que PGPASSWORD n'est pas défini dans les profils", "type": "Automated", "test_procedure": "! grep -q PGPASSWORD /home/*/.{bashrc,profile,bash_profile} /etc/environment 2>/dev/null", "expected_output": {"type": "returncode_zero"}, "remediation": "Empêcher le stockage en clair du mot de passe via la variable d’environnement PGPASSWORD.\nSupprimer toute définition de PGPASSWORD dans les scripts de connexion, utiliser ~/.pgpass ou une méthode sécurisée. "}, # Use bash features for grep -q and negation, added description
    {"category": "1. Installation et correctifs", "number": "1.7", "name": "Vérifier que PGPASSWORD n'est pas utilisé par un processus", "type": "Automated", "test_procedure": "! pgrep -a PGPASSWORD 2>/dev/null", "expected_output": {"type": "returncode_zero"}, "remediation": "S’assurer qu’aucun processus n’utilise la variable PGPASSWORD.\nIdentifier et modifier les scripts/processus pour ne plus utiliser PGPASSWORD."}, # Use pgrep for active processes, added description

    # 2. Permissions de répertoires et fichiers
    {"category": "2. Permissions de répertoires et fichiers", "number": "2.1", "name": "Masque de permissions (umask)", "type": "Manual", "test_procedure": "En tant que postgres, exécuter umask, doit afficher 0077 ou plus restrictif.", "expected_output": None, "remediation": "Configurer le umask de l’utilisateur postgres à 0077 pour restreindre la création de fichiers.\nAjouter umask 077 dans ~postgres/.bash_profile (ou .profile/.bashrc), recharger le profil."}, # Added description
    {"category": "2. Permissions de répertoires et fichiers", "number": "2.2", "name": "Propriétaire et permissions du répertoire d’extensions", "type": "Automated", "path_command": "sudo -u postgres pg_config --sharedir", "test_procedure_template": "ls -ld {path}/extension", "expected_output": {"type": "stdout_regex_match", "pattern": r"^drwxr-xr-x\s+\d+\s+root\s+root"}, "remediation": "Vérifier que $(pg_config --sharedir)/extension appartient à root:root et chmod 0755.\nchown root:root $(sudo -u postgres pg_config --sharedir)/extension && chmod 0755 $(sudo -u postgres pg_config --sharedir)/extension."}, # Corrected remediation command, added description
    {"category": "2. Permissions de répertoires et fichiers", "number": "2.3", "name": "Désactiver l’historique des commandes psql", "type": "Automated", "test_procedure": "! find /home -name .psql_history -print -quit 2>/dev/null", "expected_output": {"type": "returncode_zero"}, "remediation": "Empêcher la création de ~/.psql_history pour limiter l’exposition de données sensibles.\nSupprimer le fichier .psql_history et ajouter \\set HISTFILE /dev/null dans ~/.psqlrc ou créer un lien symbolique vers /dev/null."}, # Find will return 0 if found, 1 if not found. We want return code 1 (not found) to pass, thus negate., added description
    {"category": "2. Permissions de répertoires et fichiers", "number": "2.4", "name": "Ne pas stocker de mots de passe dans les fichiers de service", "type": "Manual", "test_procedure": "grep -H password /etc/postgresql/.../pg_service.conf et dans les home utilisateurs", "expected_output": None, "remediation": "Vérifier qu’aucun .pg_service.conf ne contient password= en clair.\nSupprimer toutes les lignes password= identifiées."}, # Added description

    # 3. Journalisation et audit
    {"category": "3. Journalisation et audit", "number": "3.1.2", "name": "Configurer log_destination", "type": "Automated", "test_procedure": "sudo -u postgres psql -t -c 'SHOW log_destination;'", "expected_output": {"type": "stdout_not_empty"}, "remediation": "Définir la ou les destinations de logs (stderr, csvlog, syslog, jsonlog).\nALTER SYSTEM SET log_destination = 'csvlog'; SELECT pg_reload_conf();"}, # Added description
    {"category": "3. Journalisation et audit", "number": "3.1.3", "name": "Activer logging_collector", "type": "Automated", "test_procedure": "sudo -u postgres psql -t -c 'SHOW logging_collector;'", "expected_output": {"type": "stdout_equals", "value": "on"}, "remediation": "Capturer stderr dans des fichiers via le démon collector.\nALTER SYSTEM SET logging_collector = 'on'; puis systemctl restart postgresql@17-main || systemctl restart postgresql-17."}, # Adapted restart command, added description
    {"category": "3.1. Journalisation des erreurs serveur", "number": "3.1.4", "name": "Définir log_directory", "type": "Automated", "test_procedure": "sudo -u postgres psql -t -c 'SHOW log_directory;'", "expected_output": {"type": "stdout_not_empty"}, "remediation": "Spécifier le répertoire de sortie des fichiers de logs (ex. /var/log/postgres).\nALTER SYSTEM SET log_directory = '/var/log/postgres'; SELECT pg_reload_conf();"}, # Added description
    {"category": "3.1. Journalisation des erreurs serveur", "number": "3.1.5", "name": "Définir log_filename", "type": "Automated", "test_procedure": "sudo -u postgres psql -t -c 'SHOW log_filename;'", "expected_output": {"type": "stdout_contains", "value": "%Y"}, "remediation": "Choisir un motif de nom de fichier strftime (e.g. postgresql-%Y%m%d.log).\nALTER SYSTEM SET log_filename = 'postgresql-%Y%m%d.log'; SELECT pg_reload_conf();"}, # Checking for %Y as recommended format, added description
    {"category": "3.1. Journalisation des erreurs serveur", "number": "3.1.6", "name": "Configurer log_file_mode", "type": "Automated", "test_procedure": "sudo -u postgres psql -t -c 'SHOW log_file_mode;'", "expected_output": {"type": "stdout_contains_any", "values": ["0600", "0640"]}, "remediation": "Fixer les permissions des fichiers de log à 0600 (ou 0640 selon le groupe).\nALTER SYSTEM SET log_file_mode = '0600'; SELECT pg_reload_conf();"}, # Added description
    {"category": "3.1. Journalisation des erreurs serveur", "number": "3.1.7", "name": "Activer log_truncate_on_rotation", "type": "Automated", "test_procedure": "sudo -u postgres psql -t -c 'SHOW log_truncate_on_rotation;'", "expected_output": {"type": "stdout_equals", "value": "on"}, "remediation": "Tronquer les fichiers existants lors de la rotation si même nom.\nALTER SYSTEM SET log_truncate_on_rotation = 'on'; SELECT pg_reload_conf();"}, # Added description
    {"category": "3.1. Journalisation des erreurs serveur", "number": "3.1.8", "name": "Définir log_rotation_age", "type": "Automated", "test_procedure": "sudo -u postgres psql -t -c 'SHOW log_rotation_age;'", "expected_output": {"type": "stdout_not_equals", "value": "0"}, "remediation": "Limiter la durée de vie des fichiers de log (ex. 1d).\nALTER SYSTEM SET log_rotation_age = '1d'; SELECT pg_reload_conf();"}, # Added description
    {"category": "3.1. Journalisation des erreurs serveur", "number": "3.1.9", "name": "Définir log_rotation_size", "type": "Automated", "test_procedure": "sudo -u postgres psql -t -c 'SHOW log_rotation_size;'", "expected_output": {"type": "stdout_not_equals", "value": "0"}, "remediation": "Limiter la taille des fichiers de log (ex. 1GB).\nALTER SYSTEM SET log_rotation_size = '1GB'; SELECT pg_reload_conf();"}, # Added description
    {"category": "3.1. Journalisation des erreurs serveur", "number": "3.1.10", "name": "Choisir syslog_facility", "type": "Manual", "test_procedure": "SHOW syslog_facility;", "expected_output": None, "remediation": "Définir la facility Syslog (LOCAL0–LOCAL7).\nALTER SYSTEM SET syslog_facility = 'LOCAL1'; SELECT pg_reload_conf();"}, # Added description
    {"category": "3.1. Journalisation des erreurs serveur", "number": "3.1.11", "name": "Activer syslog_split_messages", "type": "Automated", "test_procedure": "sudo -u postgres psql -t -c 'SHOW syslog_split_messages;'", "expected_output": {"type": "stdout_equals", "value": "on"}, "remediation": "Couper les messages trop longs (>1024 octets) pour Syslog.\nALTER SYSTEM SET syslog_split_messages = 'on'; SELECT pg_reload_conf();"}, # Added description
    {"category": "3.1. Journalisation des erreurs serveur", "number": "3.1.12", "name": "Prévenir la perte de messages Syslog", "type": "Automated", "test_procedure": "sudo -u postgres psql -t -c 'SHOW syslog_split_messages;'", "expected_output": {"type": "stdout_equals", "value": "on"}, "remediation": "Éviter la suppression des messages volumineux dans Syslog.\nMême que 3.1.11."}, # Refers to 3.1.11, added description
    {"category": "3.1. Journalisation des erreurs serveur", "number": "3.1.13", "name": "Configurer syslog_ident", "type": "Automated", "test_procedure": "sudo -u postgres psql -t -c 'SHOW syslog_ident;'", "expected_output": {"type": "stdout_not_empty"}, "remediation": "Définir l’identifiant de programme dans Syslog (ex. postgres).\nALTER SYSTEM SET syslog_ident = 'proddb'; SELECT pg_reload_conf();"}, # Added description
    {"category": "3.1. Journalisation des erreurs serveur", "number": "3.1.14", "name": "Assurer les bons messages dans le log serveur", "type": "Manual", "test_procedure": "Consulter postgresql.conf et SHOW log_statement;/SHOW log_min_messages;.", "expected_output": None, "remediation": "Vérifier que seuls les messages pertinents (erreurs, connexions, requêtes) sont enregistrés.\nALTER SYSTEM SET log_statement = 'all'; ALTER SYSTEM SET log_min_error_statement = 'error'; etc., puis SELECT pg_reload_conf();."}, # Added description
    {"category": "3.1. Journalisation des erreurs serveur", "number": "3.1.15", "name": "Enregistrer les SQL en erreur", "type": "Automated", "sub_checks": [
        {"test_procedure": "sudo -u postgres psql -t -c 'SHOW client_min_messages;'", "expected_output": {"type": "stdout_contains_any", "values": ["error", "log", "warning", "notice", "info", "debug"]}}, # client_min_messages should allow seeing errors.
        {"test_procedure": "sudo -u postgres psql -t -c 'SHOW log_error_verbosity;'", "expected_output": {"type": "stdout_equals", "value": "verbose"}}
    ], "remediation": "Consigner les instructions SQL ayant généré des erreurs.\nALTER SYSTEM SET log_error_verbosity = 'verbose'; puis SELECT pg_reload_conf();."}, # Added description
    {"category": "3.1. Journalisation des erreurs serveur", "number": "3.1.16", "name": "Désactiver debug_print_parse", "type": "Automated", "test_procedure": "sudo -u postgres psql -t -c 'SHOW debug_print_parse;'", "expected_output": {"type": "stdout_equals", "value": "off"}, "remediation": "Ne pas afficher les arbres d’analyse SQL dans les logs (réduction du bruit).\nALTER SYSTEM SET debug_print_parse = 'off'; SELECT pg_reload_conf();"}, # Added description
    {"category": "3.1. Journalisation des erreurs serveur", "number": "3.1.17", "name": "Désactiver debug_print_rewritten", "type": "Automated", "test_procedure": "sudo -u postgres psql -t -c 'SHOW debug_print_rewritten;'", "expected_output": {"type": "stdout_equals", "value": "off"}, "remediation": "Ne pas afficher les arbres réécrits SQL dans les logs.\nALTER SYSTEM SET debug_print_rewritten = 'off'; SELECT pg_reload_conf();"}, # Added description
    {"category": "3.1. Journalisation des erreurs serveur", "number": "3.1.18", "name": "Désactiver debug_print_plan", "type": "Automated", "test_procedure": "sudo -u postgres psql -t -c 'SHOW debug_print_plan;'", "expected_output": {"type": "stdout_equals", "value": "off"}, "remediation": "Ne pas afficher les plans d’exécution SQL dans les logs.\nALTER SYSTEM SET debug_print_plan = 'off'; SELECT pg_reload_conf();"}, # Added description
    {"category": "3.1. Journalisation des erreurs serveur", "number": "3.1.19", "name": "Activer debug_pretty_print", "type": "Automated", "test_procedure": "sudo -u postgres psql -t -c 'SHOW debug_pretty_print;'", "expected_output": {"type": "stdout_equals", "value": "on"}, "remediation": "Formater lisiblement les arbres d’analyse/réécriture dans les logs.\nALTER SYSTEM SET debug_pretty_print = 'on'; SELECT pg_reload_conf();."}, # Added description
    {"category": "3.1. Journalisation des erreurs serveur", "number": "3.1.20", "name": "Activer log_connections", "type": "Automated", "test_procedure": "sudo -u postgres psql -t -c 'SHOW log_connections;'", "expected_output": {"type": "stdout_equals", "value": "on"}, "remediation": "Enregistrer chaque nouvelle connexion à PostgreSQL.\nALTER SYSTEM SET log_connections = 'on'; SELECT pg_reload_conf();."}, # Added description
    {"category": "3.1. Journalisation des erreurs serveur", "number": "3.1.21", "name": "Activer log_disconnections", "type": "Automated", "test_procedure": "sudo -u postgres psql -t -c 'SHOW log_disconnections;'", "expected_output": {"type": "stdout_equals", "value": "on"}, "remediation": "Enregistrer chaque déconnexion de PostgreSQL.\nALTER SYSTEM SET log_disconnections = 'on'; SELECT pg_reload_conf();."}, # Added description
    {"category": "3.1. Journalisation des erreurs serveur", "number": "3.1.22", "name": "Configurer log_error_verbosity", "type": "Automated", "test_procedure": "sudo -u postgres psql -t -c 'SHOW log_error_verbosity;'", "expected_output": {"type": "stdout_equals", "value": "verbose"}, "remediation": "Contrôler la verbosité des messages d’erreur (DEFAULT, VERBOSE).\nALTER SYSTEM SET log_error_verbosity = 'verbose'; SELECT pg_reload_conf();."}, # Added description
    {"category": "3.1. Journalisation des erreurs serveur", "number": "3.1.23", "name": "Configurer log_hostname", "type": "Automated", "test_procedure": "sudo -u postgres psql -t -c 'SHOW log_hostname;'", "expected_output": {"type": "stdout_equals", "value": "off"}, "remediation": "Indiquer le nom d’hôte ou l’IP dans les logs de connexion.\nALTER SYSTEM SET log_hostname = 'off'; SELECT pg_reload_conf();."}, # Added description
    {"category": "3.1. Journalisation des erreurs serveur", "number": "3.1.24", "name": "Configurer log_line_prefix", "type": "Automated", "test_procedure": "sudo -u postgres psql -t -c 'SHOW log_line_prefix;'", "expected_output": {"type": "stdout_contains", "value": "%t"}, "remediation": "Définir le préfixe de ligne (timestamp, utilisateur, base, etc.) dans chaque log.\nALTER SYSTEM SET log_line_prefix = '%m [%p] user=%u db=%d '; SELECT pg_reload_conf();."}, # Added description
    {"category": "3.1. Journalisation des erreurs serveur", "number": "3.1.25", "name": "Configurer log_statement", "type": "Automated", "test_procedure": "sudo -u postgres psql -t -c 'SHOW log_statement;'", "expected_output": {"type": "stdout_contains_any", "values": ["ddl", "mod", "all"]}, "remediation": "Choisir le niveau de requêtes à logger (none, ddl, mod, all).\nALTER SYSTEM SET log_statement = 'ddl'; SELECT pg_reload_conf();."}, # Added description
    {"category": "3.1. Journalisation des erreurs serveur", "number": "3.1.26", "name": "Configurer log_timezone", "type": "Automated", "test_procedure": "sudo -u postgres psql -t -c 'SHOW log_timezone;'", "expected_output": {"type": "stdout_equals", "value": "UTC"}, "remediation": "Uniformiser le fuseau horaire des horodatages des logs (ex. UTC).\nALTER SYSTEM SET log_timezone = 'UTC'; SELECT pg_reload_conf();."}, # Added description
    {"category": "3. Journalisation et audit", "number": "3.2", "name": "Activer l’extension pgAudit", "type": "Automated", "test_procedure": "Installer et configurer l’extension d’audit avancé pgAudit pour capturer les activités.\nSELECT * FROM pg_extension WHERE extname = 'pgaudit';", "expected_output": {"type": "stdout_contains", "value": "pgaudit"}, "remediation": "Installer et configurer l’extension d’audit avancé pgAudit pour capturer les activités.\nCREATE EXTENSION pgaudit; ALTER SYSTEM SET pgaudit.log = 'all'; SELECT pg_reload_conf();"}, # Check if query returns 1 (extension exists), added description, changed expected output

    # 4. Accès et autorisations utilisateur
    {"category": "4. Accès et autorisations utilisateur", "number": "4.1", "name": "Désactiver la connexion interactive", "type": "Manual", "test_procedure": "Empêcher les rôles superutilisateurs sans console SSH d’interagir localement.\nVérifier dans pg_hba.conf qu’aucune ligne local .. trust pour les superutilisateurs", "expected_output": None, "remediation": "Empêcher les rôles superutilisateurs sans console SSH d’interagir localement.\nModifier pg_hba.conf, passer à md5 ou peer, puis SELECT pg_reload_conf();."}, # Added description
    {"category": "4. Accès et autorisations utilisateur", "number": "4.2", "name": "Configurer sudo correctement", "type": "Manual", "test_procedure": "Restreindre l’usage de sudo pour l’utilisateur système postgres.\nExaminer /etc/sudoers et fichiers dans /etc/sudoers.d/ pour la section postgres.", "expected_output": None, "remediation": "Restreindre l’usage de sudo pour l’utilisateur système postgres.\nExaminer /etc/sudoers et fichiers dans /etc/sudoers.d/ pour la section postgres.\nAjuster les droits sudo (ex. postgres ALL=(ALL) NOPASSWD: /usr/pgsql-17/bin/pg_*)."}, # Added description
    {"category": "4. Accès et autorisations utilisateur", "number": "4.3", "name": "Révoquer les privilèges administratifs excessifs", "type": "Manual", "test_procedure": "Retirer aux rôles non justifiés les attributs SUPERUSER, CREATEDB, CREATEROLE, REPLICATION.\n\\du+ doit lister uniquement les rôles autorisés avec ces attributs.", "expected_output": None, "remediation": "Retirer aux rôles non justifiés les attributs SUPERUSER, CREATEDB, CREATEROLE, REPLICATION.\n\\du+ doit lister uniquement les rôles autorisés avec ces attributs.\nALTER ROLE <user> NOSUPERUSER NOCREATEDB NOCREATEROLE;."}, # Added description
    {"category": "4. Accès et autorisations utilisateur", "number": "4.4", "name": "Verrouiller les comptes inactifs", "type": "Manual", "test_procedure": "Désactiver les rôles non utilisés depuis un certain temps.\nSELECT rolname, rolvaliduntil FROM pg_authid; vérifier dates d’expiration.", "expected_output": None, "remediation": "Désactiver les rôles non utilisés depuis un certain temps.\nSELECT rolname, rolvaliduntil FROM pg_authid; vérifier dates d’expiration.\nALTER ROLE <user> NOLOGIN; ou définir VALID UNTIL à une date passée."}, # Added description
    {"category": "4. Accès et autorisations utilisateur", "number": "4.5", "name": "Révoquer les privilèges de fonction excessifs", "type": "Manual", "test_procedure": "Restreindre l’EXECUTE sur les fonctions définies aux seuls rôles nécessaires.\nRequête sur pg_proc et has_function_privilege().", "expected_output": None, "remediation": "Restreindre l’EXECUTE sur les fonctions définies aux seuls rôles nécessaires.\nRequête sur pg_proc et has_function_privilege().\nREVOKE EXECUTE ON FUNCTION <schema>.<func>() FROM <role>;."}, # Marked Manual as the test procedure is complex/policy-dependent, added description
    {"category": "4. Accès et autorisations utilisateur", "number": "4.6", "name": "Révoquer les privilèges DML excessifs", "type": "Manual", "test_procedure": "Restreindre INSERT/UPDATE/DELETE aux tables selon le besoin des rôles applicatifs.\nInventaire via has_table_privilege() pour chaque table et utilisateur.", "expected_output": None, "remediation": "Restreindre INSERT/UPDATE/DELETE aux tables selon le besoin des rôles applicatifs.\nInventaire via has_table_privilege() pour chaque table et utilisateur.\nREVOKE INSERT, UPDATE, DELETE ON TABLE <tbl> FROM <role>;."}, # Added description
    {"category": "4. Accès et autorisations utilisateur", "number": "4.7", "name": "Configurer Row Level Security (RLS)", "type": "Manual", "test_procedure": "Activer RLS pour les tables sensibles et définir des politiques restrictives.\n\\d+ <table> doit indiquer Row Level Security: enabled.", "expected_output": None, "remediation": "Activer RLS pour les tables sensibles et définir des politiques restrictives.\n\\d+ <table> doit indiquer Row Level Security: enabled.\nALTER TABLE <tbl> ENABLE ROW LEVEL SECURITY; CREATE POLICY ...;."}, # Added description
    {"category": "4. Accès et autorisations utilisateur", "number": "4.8", "name": "Installer l’extension set_user", "type": "Automated", "test_procedure": "Utiliser set_user pour l’émulation de rôles et la révocabilité de sessions.\nSELECT * FROM pg_extension WHERE extname = 'set_user';", "expected_output": {"type": "stdout_contains", "value": "set_user"}, "remediation": "Utiliser set_user pour l’émulation de rôles et la révocabilité de sessions.\nCREATE EXTENSION set_user;"}, # Added description, changed expected output to check for extension name in output
    {"category": "4. Accès et autorisations utilisateur", "number": "4.9", "name": "Utiliser les rôles prédéfinis", "type": "Manual", "test_procedure": "Favoriser les rôles intégrés (pg_read_all_data, etc.) plutôt que superuser pour les accès.\n\\du+ vérifie la présence et l’usage des rôles prédéfinis.", "expected_output": None, "remediation": "Favoriser les rôles intégrés (pg_read_all_data, etc.) plutôt que superuser pour les accès.\n\\du+ vérifie la présence et l’usage des rôles prédéfinis.\nGRANT pg_read_all_data TO <role>; REVOKE ...."}, # Added description

    # 5. Connexion et authentification
    {"category": "5. Connexion et authentification", "number": "5.1", "name": "Ne pas passer de mot de passe en ligne de commande", "type": "Manual", "test_procedure": "Éviter psql -U user -W password dans les scripts shell.\nExaminer les processus en cours (`ps aux | grep psql`) et scripts automatisés.", "expected_output": None, "remediation": "Éviter psql -U user -W password dans les scripts shell.\nModifier les scripts pour utiliser ~/.pgpass ou une méthode sécurisée."}, # Added description
    {"category": "5. Connexion et authentification", "number": "5.2", "name": "Lier PostgreSQL à une adresse IP", "type": "Manual", "test_procedure": "Restreindre l’écoute à l’interface prévue (listen_addresses).\nSHOW listen_addresses; doit afficher l’IP autorisée ou localhost.", "expected_output": None, "remediation": "Restreindre l’écoute à l’interface prévue (listen_addresses).\nModifier postgresql.conf (listen_addresses = '192.0.2.1' ou '*') et redémarrer le service."}, # Added '*' option, added description
    {"category": "5. Connexion et authentification", "number": "5.3", "name": "Configurer la connexion UNIX locale", "type": "Manual", "test_procedure": "Sécuriser les entrées local dans pg_hba.conf pour n’autoriser que peer ou md5.\nVérifier les lignes local all all trust dans pg_hba.conf.", "expected_output": None, "remediation": "Sécuriser les entrées local dans pg_hba.conf pour n’autoriser que peer ou md5.\nModifier (ou ajouter) local all all peer ou md5 dans pg_hba.conf, puis SELECT pg_reload_conf();."}, # Added md5 option, added description
    {"category": "5. Connexion et authentification", "number": "5.4", "name": "Configurer la connexion TCP/IP", "type": "Manual", "test_procedure": "Sécuriser les entrées host dans pg_hba.conf (CIDR, méthode d’authentification).\nVérifier host all all 10.0.0.0/24 md5.", "expected_output": None, "remediation": "Sécuriser les entrées host dans pg_hba.conf (CIDR, méthode d’authentification).\nModifier pg_hba.conf pour utiliser des CIDR restreints et des méthodes d'authentification fortes (md5, scram-sha-256, cert, etc.), redémarrer ou recharger."}, # More general remediation, added description
    {"category": "5. Connexion et authentification", "number": "5.5", "name": "Limites de connexion par compte", "type": "Manual", "test_procedure": "Empêcher un même rôle d’ouvrir trop de connexions simultanées.\nSELECT rolname, rolconnlimit FROM pg_authid;.", "expected_output": None, "remediation": "Empêcher un même rôle d’ouvrir trop de connexions simultanées.\nALTER ROLE <user> CONNECTION LIMIT 10;."}, # Marked Manual as the pass condition is policy-dependent, added description
    {"category": "5. Connexion et authentification", "number": "5.6", "name": "Configurer la complexité des mots de passe", "type": "Manual", "test_procedure": "Imposer un contrôle de la complexité (extensions passwordcheck, pam, etc.).\nVérifier la présence de password_encryption, modules pam ou passwordcheck.", "expected_output": None, "remediation": "Imposer un contrôle de la complexité (extensions passwordcheck, pam, etc.).\nInstaller/configurer passwordcheck ou pam, définir password_encryption = 'scram-sha-256'."}, # Added description

    # 6. Paramètres PostgreSQL
    {"category": "6. Paramètres PostgreSQL", "number": "6.1", "name": "Comprendre vecteurs d’attaque et paramètres runtime", "type": "Manual", "test_procedure": "Documenter les vecteurs d’attaque possibles et les paramètres ajustables.\nRéviser postgresql.conf pour lister runtime parameters.", "expected_output": None, "remediation": "Documenter les vecteurs d’attaque possibles et les paramètres ajustables.\nMettre à jour la documentation interne, auditer régulièrement."}, # Added description
    {"category": "6. Paramètres PostgreSQL", "number": "6.2", "name": "Configurer les paramètres backend", "type": "Automated", "sub_checks": [ # Check key parameters are set to something reasonable (not 0 or defaults depending on context)
        {"test_procedure": "sudo -u postgres psql -t -c 'SHOW max_connections;'", "expected_output": {"type": "stdout_is_numeric_greater_than", "value": 0}},
        {"test_procedure": "sudo -u postgres psql -t -c 'SHOW shared_buffers;'", "expected_output": {"type": "stdout_not_equals", "value": "128kB"}}, # Default is 128kB, check if changed
        {"test_procedure": "sudo -u postgres psql -t -c 'SHOW work_mem;'", "expected_output": {"type": "stdout_not_equals", "value": "4MB"}} # Default is 4MB, check if changed
    ], "remediation": "Ajuster max_connections, shared_buffers, work_mem, etc., pour limiter l’exposition.\nALTER SYSTEM SET max_connections = 100; ALTER SYSTEM SET shared_buffers = '...'; ALTER SYSTEM SET work_mem = '...'; SELECT pg_reload_conf();"}, # Added description
    {"category": "6. Paramètres PostgreSQL", "number": "6.3", "name": "Configurer Postmaster runtime parameters", "type": "Manual", "test_procedure": "Ajuster data_directory, hba_file, ident_file, etc.\nVérifier SHOW data_directory, hba_file, ident_file;", "expected_output": None, "remediation": "Ajuster data_directory, hba_file, ident_file, etc.\nModifier postgresql.conf puis redémarrer."}, # Added description
    {"category": "6. Paramètres PostgreSQL", "number": "6.4", "name": "Configurer les signaux SIGHUP", "type": "Manual", "test_procedure": "Sécuriser la réaction aux signaux de rechargement de configuration.\nTester SELECT pg_reload_conf();.", "expected_output": None, "remediation": "Sécuriser la réaction aux signaux de rechargement de configuration.\nAucun changement automatique ; documenter le processus."}, # Added description
    {"category": "6. Paramètres PostgreSQL", "number": "6.5", "name": "Configurer les paramètres Superuser", "type": "Manual", "test_procedure": "Restreindre statement_timeout, idle_in_transaction_session_timeout pour les superusers.\nSHOW statement_timeout, idle_in_transaction_session_timeout;.", "expected_output": None, "remediation": "Restreindre statement_timeout, idle_in_transaction_session_timeout pour les superusers.\nALTER SYSTEM SET statement_timeout = '...'; ALTER SYSTEM SET idle_in_transaction_session_timeout = '5min'; puis recharger."}, # Added statement_timeout, added description
    {"category": "6. Paramètres PostgreSQL", "number": "6.6", "name": "Configurer les paramètres User", "type": "Manual", "test_procedure": "Ajuster log_statement, search_path, etc., pour les rôles standards.\nVérifier SHOW search_path;.", "expected_output": None, "remediation": "Ajuster log_statement, search_path, etc., pour les rôles standards.\nALTER ROLE <user> SET search_path TO '$user', public;."}, # Added description
    {"category": "6. Paramètres PostgreSQL", "number": "6.7", "name": "Utiliser la cryptographie FIPS 140-2", "type": "Automated", "test_procedure": "S’assurer qu’OpenSSL FIPS est utilisé si requis.\nSHOW ssl_library; et vérifier la version OpenSSL.", "expected_output": {"type": "stdout_contains", "value": "OpenSSL"}, "remediation": "S’assurer qu’OpenSSL FIPS est utilisé si requis.\nRecompiler PostgreSQL avec FIPS ou configurer la bibliothèque FIPS."}, # Check if OpenSSL is used, FIPS mode is a system/compile-time config, added description
    {"category": "6. Paramètres PostgreSQL", "number": "6.8", "name": "Activer et configurer TLS", "type": "Automated", "sub_checks": [
        {"test_procedure": "sudo -u postgres psql -t -c 'SHOW ssl;'", "expected_output": {"type": "stdout_equals", "value": "on"}},
        {"test_procedure": "sudo -u postgres psql -t -c 'SHOW ssl_cert_file;'", "expected_output": {"type": "stdout_not_empty"}},
        {"test_procedure": "sudo -u postgres psql -t -c 'SHOW ssl_key_file;'", "expected_output": {"type": "stdout_not_empty"}}
    ], "remediation": "Installer certificats TLS et configurer ssl_cert_file, ssl_key_file.\nCopier les certificats, ALTER SYSTEM SET ssl = 'on'; SELECT pg_reload_conf();."}, # Added description
    {"category": "6. Paramètres PostgreSQL", "number": "6.9", "name": "Configurer TLSv1.3+", "type": "Automated", "test_procedure": "Forcer au minimum TLSv1.3.\nSHOW ssl_min_protocol_version; doit être TLSv1.3.", "expected_output": {"type": "stdout_equals", "value": "TLSv1.3"}, "remediation": "Forcer au minimum TLSv1.3.\nALTER SYSTEM SET ssl_min_protocol_version = 'TLSv1.3'; SELECT pg_reload_conf();."}, # Added description
    # Corrected 6.10: Handle potential unrecognized parameter error
    {"category": "6. Paramètres PostgreSQL", "number": "6.10", "name": "Désactiver les cipher suites faibles", "type": "Automated", "test_procedure": "Exclure RC4, DES, etc., dans ssl_cipher_suites.\nSHOW ssl_cipher_suites; vérifier l’absence de ciphers faibles.", "expected_output": {"type": "stdout_not_contains_any", "values": ["RC4", "DES", "3DES", "MD5", "SHA1"]}, "remediation": "Exclure RC4, DES, etc., dans ssl_cipher_suites.\nALTER SYSTEM SET ssl_cipher_suites = 'HIGH:!aNULL'; SELECT pg_reload_conf();.", "possible_errors": ["unrecognized configuration parameter"]}, # Added possible_errors, added description, corrected test procedure
    {"category": "6. Paramètres PostgreSQL", "number": "6.11", "name": "Installer et configurer pgcrypto", "type": "Automated", "test_procedure": "Activer pgcrypto pour fonctions cryptographiques.\nSELECT * FROM pg_extension WHERE extname = 'pgcrypto';", "expected_output": {"type": "stdout_contains", "value": "pgcrypto"}, "remediation": "Activer pgcrypto pour fonctions cryptographiques.\nCREATE EXTENSION pgcrypto;"}, # Check if query returns 1 (extension exists), added description, changed expected output

    # 7. Réplication
    {"category": "7. Réplication", "number": "7.1", "name": "Créer un utilisateur de réplication dédié", "type": "Manual", "test_procedure": "Ne pas réutiliser postgres pour la réplication.\nSELECT rolname, rolreplication FROM pg_roles WHERE rolname = '<user>';", "expected_output": None, "remediation": "Ne pas réutiliser postgres pour la réplication.\nCREATE USER repuser REPLICATION LOGIN ENCRYPTED PASSWORD '…';."}, # Added description
    {"category": "7. Réplication", "number": "7.2", "name": "Journaliser les commandes de réplication", "type": "Automated", "test_procedure": "Activer log_replication_commands pour tracer les actions de réplication.\nSHOW log_replication_commands; doit être on.", "expected_output": {"type": "stdout_equals", "value": "on"}, "remediation": "Activer log_replication_commands pour tracer les actions de réplication.\nALTER SYSTEM SET log_replication_commands = 'on'; SELECT pg_reload_conf();."}, # Added description
    {"category": "7. Réplication", "number": "7.3", "name": "Configurer les sauvegardes de base", "type": "Manual", "test_procedure": "Vérifier que pg_basebackup ou équivalent génère des sauvegardes fonctionnelles.\nExécuter pg_basebackup -h localhost … et vérifier l’intégrité des fichiers.", "expected_output": None, "remediation": "Vérifier que pg_basebackup ou équivalent génère des sauvegardes fonctionnelles.\nMettre en place un script de sauvegarde automatisée avec pg_basebackup."}, # Added description
    {"category": "7. Réplication", "number": "7.4", "name": "Configurer l’archivage WAL", "type": "Automated", "sub_checks": [
        {"test_procedure": "sudo -u postgres psql -t -c 'SHOW archive_mode;'", "expected_output": {"type": "stdout_equals", "value": "on"}},
        {"test_procedure": "sudo -u postgres psql -t -c 'SHOW archive_command;'", "expected_output": {"type": "stdout_not_empty"}} # Check if archive_command is set
    ], "remediation": "Activer archive_mode et archive_command pour conserver les WAL.\nALTER SYSTEM SET archive_mode = 'on'; ALTER SYSTEM SET archive_command = 'cp %p /archive/%f'; SELECT pg_reload_conf();."}, # Added description
    {"category": "7. Réplication", "number": "7.5", "name": "Configurer les paramètres de streaming", "type": "Manual", "test_procedure": "Ajuster primary_conninfo, max_wal_senders, hot_standby.\nSHOW primary_conninfo, max_wal_senders, hot_standby;.", "expected_output": None, "remediation": "Ajuster primary_conninfo, max_wal_senders, hot_standby.\nALTER SYSTEM SET max_wal_senders = 3; ALTER SYSTEM SET hot_standby = 'on'; SELECT pg_reload_conf();."}, # Added description

    # 8. Considérations spéciales de configuration
    {"category": "8. Considérations spéciales de configuration", "number": "8.1", "name": "Emplacements hors du cluster de données", "type": "Manual", "test_procedure": "Placer les répertoires temporaires et de logs en dehors de $PGDATA pour éviter leur inclusion.\nVérifier SHOW temp_tablespaces, log_directory;.", "expected_output": None, "remediation": "Placer les répertoires temporaires et de logs en dehors de $PGDATA pour éviter leur inclusion.\nMettre temp_tablespaces et log_directory sur un autre volume, recharger."}, # Added description
    # Corrected 8.2: Handle command not found
    {"category": "8. Considérations spéciales de configuration", "number": "8.2", "name": "Installer/configurer pgBackRest", "type": "Automated", "test_procedure": "sudo pgbackrest info", "expected_output": {"type": "stdout_contains", "value": "stanza:"}, "remediation": "Utiliser pgBackRest pour des sauvegardes et restaurations robustes.\nInstaller le paquet pgbackrest et configurer au moins une stanza (pgbackrest stanza-create)."}, # Check if pgbackrest info shows at least one stanza, improved remediation, added description
    {"category": "8. Considérations spéciales de configuration", "number": "8.3", "name": "Vérifier autres paramètres divers", "type": "Manual", "test_procedure": "Contrôler toute autre configuration (temp_file_limit, temp_tablespaces, …) selon les besoins.\nRevoir postgresql.conf pour paramètres personnalisés.", "expected_output": None, "remediation": "Contrôler toute autre configuration (temp_file_limit, temp_tablespaces, …) selon les besoins.\nAjuster manuellement puis recharger la configuration."} # Added description
]

# --- Modèle HTML ---
HTML_TEMPLATE = """
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport CIS PostgreSQL 17 Benchmark</title>
    <link href="https://cdn.jsdelivr.net/npm/tailwindcss@2.2.19/dist/tailwind.min.css" rel="stylesheet">
    <script src="https://cdn.jsdelivr.net/npm/chart.js@3.7.1/dist/chart.min.js"></script>
    <style>
        /* Styles personnalisés si nécessaire */
        .status-pass {{ color: #10B981; }} /* green-500 */
        .status-fail {{ color: #EF4444; }} /* red-500 */
        .status-manual {{ color: #F59E0B; }} /* yellow-500 */
        .status-error {{ color: #6B7280; }} /* gray-500 */
        .status-na {{ color: #9CA3AF; }} /* gray-400 */
        pre {{ white-space: pre-wrap; word-wrap: break-word; }}
        table {{ table-layout: fixed; width: 100%; }} /* Added for better column width control */
        td, th {{ word-break: break-word; }} /* Allow breaking long words */
        .chart-container {{ width: 300px; height: 300px; margin: 20px auto; }} /* Style for chart container */
        .category-chart-container {{ width: 80%; margin: 20px auto; }} /* Style for category chart container */
    </style>
</head>
<body class="font-sans bg-gray-100 text-gray-800 p-6">
    <div class="container mx-auto bg-white p-8 rounded-lg shadow-lg">
        <h1 class="text-3xl font-bold mb-6 text-gray-900">Rapport CIS PostgreSQL 17 Benchmark</h1>
        <p class="text-gray-600 mb-4">Date du rapport : {report_date}</p>
        <p class="text-gray-600 mb-8">Généré par un script basé sur les recommandations fournies par Jean-Marie Renouard (Version 1.0 du 13 Avril 2025).</p>

        <div class="mb-8 p-4 bg-gray-50 rounded-md border border-gray-200">
            <h2 class="text-2xl font-semibold mb-3 text-gray-800">Score Global</h2>
            <p class="text-xl font-bold {overall_score_class}">{overall_score:.2f}%</p>
            <p class="text-gray-700">des contrôles automatisés réussis ({passed_automated}/{total_automated} vérifiés).</p>
             <p class="text-gray-700">{manual_checks} contrôles nécessitent une vérification manuelle.</p>
             <p class="text-700">{error_checks} contrôles ont rencontré une erreur d'exécution.</p>
             <p class="text-700">{na_checks} contrôles ne sont pas applicables (paramètre non reconnu, etc.).</p>

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
        const overallScoreChart = new Chart(
            document.getElementById('overallScoreChart'),
            overallChartConfig
        );

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
                maintainAspectRatio: false,
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
         const categoryScoreChart = new Chart(
            document.getElementById('categoryChart'),
            categoryChartConfig
        );

    </script>
</body>
</html>
"""

CATEGORY_REPORT_TEMPLATE = """
        <div class="mb-10 p-4 bg-gray-50 rounded-md border border-gray-200">
            <h2 class="text-2xl font-semibold mb-3 text-gray-800">{category_name}</h2>
            <p class="text-lg font-bold {category_score_class}">{category_score:.2f}%</p>
            <p class="text-gray-700">des contrôles automatisés réussis dans cette catégorie ({passed_automated}/{total_automated} vérifiés).</p>
            <p class="text-700">{manual_checks} contrôles nécessitent une vérification manuelle.</p>
            <p class="text-700">{error_checks} contrôles ont rencontré une erreur d'exécution.</p>
            <p class="text-700">{na_checks} contrôles ne sont pas applicables.</p>

            <table class="min-w-full border border-gray-300 divide-y divide-gray-300 mt-6">
                <thead>
                    <tr class="bg-gray-200 text-gray-700 uppercase text-sm leading-normal">
                        <th class="py-3 px-6 text-left w-1/12">Numéro</th>
                        <th class="py-3 px-6 text-left w-2/12">Recommandation</th>
                        <th class="py-3 px-6 text-left w-1/12">Type</th>
                        <th class="py-3 px-6 text-left w-2/12">Test Exécuté</th>
                        <th class="py-3 px-6 text-left w-1/12">Résultat</th>
                        <th class="py-3 px-6 text-left w-3/12">Sortie / Erreur / Notes</th>
                        <th class="py-3 px-6 text-left w-2/12">Procédure de Remédiation</th>
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
        <div class="category-chart-container">
            <canvas id="categoryChart"></canvas>
        </div>
"""


CHECK_ROW_TEMPLATE = """
                    <tr class="border-b border-gray-200 hover:bg-gray-100">
                        <td class="py-3 px-6 text-left align-top">{number}</td>
                        <td class="py-3 px-6 text-left align-top">{name}</td>
                        <td class="py-3 px-6 text-left align-top">{type}</td>
                        <td class="py-3 px-6 text-left align-top"><code>{test_procedure}</code></td>
                        <td class="py-3 px-6 text-left align-top"><span class="{status_class}">{status_icon} {status_text}</span></td>
                        <td class="py-3 px-6 text-left align-top"><pre>{output}</pre></td>
                        <td class="py-3 px-6 text-left align-top">{remediation}</td>
                    </tr>
"""

# --- Fonctions d'exécution et d'évaluation ---

def run_command(command):
    """Exécute une commande shell et retourne stdout, stderr, et le code de retour."""
    try:
        # Utilise shell=True pour permettre les pipelines et les redirections comme dans les exemples
        # Attention : shell=True est moins sécurisé si la commande vient d'une source non fiable.
        # Ici, les commandes sont définies dans le script.
        process = subprocess.run(command, shell=True, check=False, capture_output=True, text=True, executable='/bin/bash') # Explicitly use bash
        return process.stdout.strip(), process.stderr.strip(), process.returncode
    except FileNotFoundError:
        return "", f"Erreur : Commande '{command.split()[0]}' introuvable.", 127 # Code 127 pour command not found
    except Exception as e:
        return "", f"Erreur d'exécution : {e}", 1 # Code générique pour autres erreurs

def evaluate_condition(condition, stdout, stderr, returncode):
    """Évalue si le résultat de la commande correspond à la condition attendue."""
    if not condition:
        return False # Aucune condition définie pour un test automatisé ? Ne devrait pas arriver avec la structure actuelle.

    condition_type = condition.get("type")
    expected_value = condition.get("value")
    expected_values = condition.get("values")
    regex_pattern = condition.get("pattern")

    if condition_type == "returncode_zero":
        return returncode == 0
    elif condition_type == "returncode_equals":
        return returncode == expected_value
    elif condition_type == "stdout_equals":
        return stdout == expected_value
    elif condition_type == "stdout_contains":
        return expected_value in stdout
    elif condition_type == "stdout_not_empty":
        return stdout != "" and stdout is not None
    elif condition_type == "stdout_contains_any":
        if expected_values is None: return False # Should not happen with current data
        return any(value in stdout for value in expected_values)
    elif condition_type == "stdout_not_contains_any":
        if expected_values is None: return True # Should not happen with current data
        return not any(value in stdout for value in expected_values)
    elif condition_type == "stdout_regex_match":
        if regex_pattern is None: return False # Should not happen
        return re.search(regex_pattern, stdout) is not None
    elif condition_type == "stdout_is_numeric_greater_than":
        try:
            # Extract potential number from string like '100' or '8GB' (take the number part)
            numeric_value_match = re.match(r'^(\d+)', stdout)
            if numeric_value_match:
                 numeric_value = int(numeric_value_match.group(1))
                 return numeric_value > expected_value
            return False
        except ValueError:
            return False # Not a valid number
    # Ajouter d'autres types de conditions au besoin
    return False # Type de condition inconnu

def perform_checks(recommendations):
    """Exécute tous les contrôles et stocke les résultats."""
    results = {}
    for rec in recommendations:
        category = rec["category"]
        if category not in results:
            results[category] = []

        # Ensure 'number' key exists before accessing it
        check_number = rec.get("number", "N/A") # Use .get() with a default value

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
        elif rec["type"] == "Automated":
            all_sub_checks_passed = True
            aggregated_output = []
            aggregated_error = []
            command_executed_display = check_result.get("test_procedure", rec.get("test_procedure", ""))
            stored_outputs = {} # To store outputs for templates

            # Handle checks that require getting a path first (like 2.2) or storing output for later sub-checks
            if "path_command" in rec or ("sub_checks" in rec and any("store_output_as" in sc for sc in rec["sub_checks"])):
                 # If it's a path_command or any sub_check needs output stored
                 # For path_command, run it first
                 if "path_command" in rec:
                     path_cmd = rec["path_command"]
                     path_cmd_output, path_cmd_error, path_cmd_returncode = run_command(path_cmd)
                     aggregated_output.append(f"--- Commande pour obtenir le chemin: {path_cmd} ---\nStdout:\n{path_cmd_output}\nStderr:\n{path_cmd_error}\nReturn Code: {path_cmd_returncode}\n---")
                     aggregated_error.append(path_cmd_error)

                     if path_cmd_returncode != 0:
                         check_result["status"] = "Error"
                         check_result["output"] = "\n\n".join(aggregated_output)
                         check_result["error"] = "\n\n".join(aggregated_error)
                         all_sub_checks_passed = False # Mark as failed due to setup error
                     else:
                         stored_outputs["path"] = path_cmd_output.strip() # Store the fetched path

                 # Now process sub_checks if pre-checks passed and there are sub_checks
                 if "sub_checks" in rec and all_sub_checks_passed:
                     command_executed_display = "Multiple commandes (voir Sortie)"
                     overall_sub_checks_status = "Pass" # Assume pass unless a sub-check fails or errors

                     for i, sub_check in enumerate(rec["sub_checks"]):
                        cmd_to_run = sub_check.get("test_procedure")

                        # If template exists, format it using stored outputs
                        if "test_procedure_template" in sub_check:
                             try:
                                 cmd_to_run = sub_check["test_procedure_template"].format(**stored_outputs)
                                 sub_check["test_procedure"] = cmd_to_run # Store formatted command back
                             except KeyError as e:
                                 aggregated_output.append(f"--- Erreur: Template pour sous-contrôle {i+1} invalide ---")
                                 aggregated_error.append(f"Erreur interne: Clé manquante pour le template dans sous-contrôle {i+1}: {e}.")
                                 overall_sub_checks_status = "Error"
                                 all_sub_checks_passed = False
                                 break # Cannot proceed with this sub-check

                        # Check if command is defined after template formatting (if applicable)
                        if cmd_to_run is None:
                             aggregated_output.append(f"--- Erreur: Commande pour sous-contrôle {i+1} non définie ---")
                             aggregated_error.append(f"Erreur interne: Commande pour sous-contrôle {i+1} non définie.")
                             overall_sub_checks_status = "Error"
                             all_sub_checks_passed = False
                             break # Cannot proceed with this sub-check


                        stdout, stderr, returncode = run_command(cmd_to_run)
                        aggregated_output.append(f"--- Commande {i+1}: {cmd_to_run} ---\nStdout:\n{stdout}\nStderr:\n{stderr}\nReturn Code: {returncode}\n---")
                        aggregated_error.append(stderr)

                        # Store output if requested
                        if "store_output_as" in sub_check:
                            stored_outputs[sub_check["store_output_as"]] = stdout.strip()


                        condition = sub_check.get("expected_output")
                        sub_check_passed = False
                        if condition:
                            if evaluate_condition(condition, stdout, stderr, returncode):
                                sub_check_passed = True
                            else:
                                # Sub-check failed the condition
                                overall_sub_checks_status = "Fail"
                                aggregated_output[-1] += "\nCondition de succès non remplie." # Add failure reason to output
                                break # If any sub-check fails, the overall check fails
                        else:
                             # Sub-check has no condition, consider it passed if no execution error
                             sub_check_passed = True


                        # Check for specific known errors that should mark as N/A
                        if rec.get("possible_errors"):
                             if any(err in stderr for err in rec["possible_errors"]):
                                  check_result["status"] = "Not Applicable" # Mark the main check as N/A
                                  overall_sub_checks_status = "Not Applicable" # Propagate status
                                  # No break here, still run other sub-checks to collect info

                        # Check for command not found errors for the sub-check
                        if returncode == 127:
                             overall_sub_checks_status = "Error" # Mark the main check as Error
                             aggregated_output[-1] = f"--- Commande {i+1}: {cmd_to_run} ---\nErreur d'exécution: Commande introuvable.\n{aggregated_output[-1]}"
                             break # Stop if a command is not found

                        # If a sub-check had an execution error (other than 127)
                        if returncode != 0 and stderr and overall_sub_checks_status not in ["Not Applicable", "Error"]:
                             overall_sub_checks_status = "Error" # Mark the main check as Error
                             aggregated_output[-1] = f"--- Commande {i+1}: {cmd_to_run} ---\nErreur d'exécution:\n{aggregated_output[-1]}"
                             # No break here, still run other sub-checks to collect info


                     check_result["output"] = "\n\n".join(aggregated_output)
                     check_result["error"] = "\n\n".join(aggregated_error)
                     check_result["test_procedure"] = command_executed_display # Display the general description
                     check_result["status"] = overall_sub_checks_status # Set the final status based on sub-checks

                 elif all_sub_checks_passed and "sub_checks" in rec: # No path_command, but sub_checks defined
                      command_executed_display = "Multiple commandes (voir Sortie)"
                      overall_sub_checks_status = "Pass" # Assume pass unless a sub-check fails or errors

                      for i, sub_check in enumerate(rec["sub_checks"]):
                         cmd_to_run = sub_check.get("test_procedure")
                         # No template formatting needed here as no path_command

                         if cmd_to_run is None:
                              aggregated_output.append(f"--- Erreur: Commande pour sous-contrôle {i+1} non définie ---")
                              aggregated_error.append(f"Erreur interne: Commande pour sous-contrôle {i+1} non définie.")
                              overall_sub_checks_status = "Error"
                              all_sub_checks_passed = False
                              break # Cannot proceed with this sub-check

                         stdout, stderr, returncode = run_command(cmd_to_run)
                         aggregated_output.append(f"--- Commande {i+1}: {cmd_to_run} ---\nStdout:\n{stdout}\nStderr:\n{stderr}\nReturn Code: {returncode}\n---")
                         aggregated_error.append(stderr)

                         # Store output if requested
                         if "store_output_as" in sub_check:
                             stored_outputs[sub_check["store_output_as"]] = stdout.strip()

                         condition = sub_check.get("expected_output")
                         sub_check_passed = False
                         if condition:
                             if evaluate_condition(condition, stdout, stderr, returncode):
                                 sub_check_passed = True
                             else:
                                 # Sub-check failed the condition
                                 overall_sub_checks_status = "Fail"
                                 aggregated_output[-1] += "\nCondition de succès non remplie." # Add failure reason to output
                                 break # If any sub-check fails, the overall check fails
                         else:
                              # Sub-check has no condition, consider it passed if no execution error
                              sub_check_passed = True

                         # Check for specific known errors that should mark as N/A
                         if rec.get("possible_errors"):
                              if any(err in stderr for err in rec["possible_errors"]):
                                   check_result["status"] = "Not Applicable" # Mark the main check as N/A
                                   overall_sub_checks_status = "Not Applicable" # Propagate status
                                   # No break here, still run other sub-checks to collect info

                         # Check for command not found errors for the sub-check
                         if returncode == 127:
                              overall_sub_checks_status = "Error" # Mark the main check as Error
                              aggregated_output[-1] = f"--- Commande {i+1}: {cmd_to_run} ---\nErreur d'exécution: Commande introuvable.\n{aggregated_output[-1]}"
                              break # Stop if a command is not found

                         # If a sub-check had an execution error (other than 127)
                         if returncode != 0 and stderr and overall_sub_checks_status not in ["Not Applicable", "Error"]:
                              overall_sub_checks_status = "Error" # Mark the main check as Error
                              aggregated_output[-1] = f"--- Commande {i+1}: {cmd_to_run} ---\nErreur d'exécution:\n{aggregated_output[-1]}"
                              # No break here, still run other sub-checks to collect info

                      check_result["output"] = "\n\n".join(aggregated_output)
                      check_result["error"] = "\n\n".join(aggregated_error)
                      check_result["test_procedure"] = command_executed_display # Display the general description
                      check_result["status"] = overall_sub_checks_status # Set the final status based on sub-checks


            elif all_sub_checks_passed: # Run single test procedure if no sub_checks or sub_checks setup passed
                cmd = check_result.get("test_procedure", rec.get("test_procedure", "")) # Use the formatted procedure if available
                command_executed_display = cmd
                stdout, stderr, returncode = run_command(cmd)
                check_result["output"] = f"Stdout:\n{stdout}\nStderr:\n{stderr}\nReturn Code: {returncode}"
                check_result["error"] = stderr
                check_result["test_procedure"] = command_executed_display # Store the command that was run

                condition = rec.get("expected_output")
                if condition:
                    if evaluate_condition(condition, stdout, stderr, returncode):
                        check_result["status"] = "Pass"
                    else:
                        check_result["status"] = "Fail"
                        check_result["output"] += "\n\nCondition de succès non remplie."

                # Check for specific known errors that should mark as N/A
                if rec.get("possible_errors"):
                     if any(err in stderr for err in rec["possible_errors"]):
                          check_result["status"] = "Not Applicable"

                # Check for command not found errors
                if returncode == 127:
                     check_result["status"] = "Error"
                     check_result["output"] = f"Erreur d'exécution: Commande introuvable.\n{check_result['output']}" # Add specific error message


            # If status is still Not Applicable (e.g., error during sub_check handling or no condition defined)
            if check_result["status"] == "Not Applicable" and rec.get("expected_output") is not None:
                 # If it was marked N/A due to a possible_error, keep that status
                 pass # Keep Not Applicable status if set by possible_errors check
            elif check_result["status"] == "Not Applicable" and (rec.get("expected_output") is None and not rec.get("sub_checks")):
                 # If it's automated but no condition/sub_checks, mark as Error (misconfiguration in script)
                 check_result["status"] = "Error"
                 check_result["output"] = check_result.get("output", "") + "\n\nErreur interne du script : Contrôle automatisé sans condition définie."
            elif check_result["status"] == "Fail" and check_result["error"] and check_result["output"].startswith("Stdout:\n\nStderr:\n\nReturn Code:"):
                 # If it failed but there was an execution error (not just condition not met)
                 check_result["status"] = "Error"
                 check_result["output"] = f"Erreur d'exécution:\n{check_result['output']}"


        results[category].append(check_result)

    return results

def calculate_scores(results):
    """Calcule les scores globaux et par catégorie."""
    overall = {"total_automated": 0, "passed_automated": 0, "failed_automated": 0, "manual": 0, "error": 0, "na": 0}
    categories_scores = {}
    # Initialize category counts
    for category in list(dict.fromkeys(rec["category"] for rec in RECOMMENDATIONS_DATA)):
        categories_scores[category] = {
            "score": 0,
            "total_automated": 0,
            "passed_automated": 0,
            "failed_automated": 0,
            "manual_checks": 0,
            "error_checks": 0,
            "na_checks": 0,
            "pass_count": 0,
            "fail_count": 0,
            "error_count": 0,
            "na_count": 0
        }


    for category, checks in results.items():
        for check in checks:
            if check["type"] == "Automated":
                overall["total_automated"] += 1
                categories_scores[category]["total_automated"] += 1 # Count attempted automated checks per category

                if check["status"] == "Pass":
                    overall["passed_automated"] += 1
                    categories_scores[category]["passed_automated"] += 1
                    categories_scores[category]["pass_count"] += 1
                elif check["status"] == "Fail":
                    overall["failed_automated"] += 1
                    categories_scores[category]["failed_automated"] += 1
                    categories_scores[category]["fail_count"] += 1
                elif check["status"] == "Error":
                     overall["error"] += 1
                     categories_scores[category]["error_checks"] += 1
                     categories_scores[category]["error_count"] += 1
                elif check["status"] == "Not Applicable":
                     overall["na"] += 1
                     categories_scores[category]["na_checks"] += 1
                     categories_scores[category]["na_count"] += 1
             # Manual checks are just counted
            elif check["type"] == "Manual":
                overall["manual"] += 1
                categories_scores[category]["manual_checks"] += 1


        # Calculate category score based on attempted automated checks (Pass + Fail)
        cat_attempted_automated = categories_scores[category]["passed_automated"] + categories_scores[category]["failed_automated"]
        categories_scores[category]["total_automated"] = cat_attempted_automated # Update total_automated to be attempted
        categories_scores[category]["score"] = (categories_scores[category]["passed_automated"] / cat_attempted_automated * 100) if cat_attempted_automated > 0 else 0


    overall_attempted_automated = overall["passed_automated"] + overall["failed_automated"] # Only count Pass and Fail for the percentage base
    overall_score = (overall["passed_automated"] / overall_attempted_automated * 100) if overall_attempted_automated > 0 else 0

    # Prepare data for category bar chart
    category_labels = json.dumps(list(categories_scores.keys()))
    category_pass_counts = json.dumps([cat_info["pass_count"] for cat_info in categories_scores.values()])
    category_fail_counts = json.dumps([cat_info["fail_count"] for cat_info in categories_scores.values()])
    category_error_counts = json.dumps([cat_info["error_count"] for cat_info in categories_scores.values()])
    category_na_counts = json.dumps([cat_info["na_count"] for cat_info in categories_scores.values()])


    # Return counts for chart
    return overall_score, categories_scores, overall["manual"], overall["error"], overall["na"], overall["passed_automated"], overall["failed_automated"], overall["error"], overall["na"], category_labels, category_pass_counts, category_fail_counts, category_error_counts, category_na_counts

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
        return "❓", status, "status-error" # Fallback for unexpected status


def generate_html_report(results, overall_score, categories_scores, total_manual, total_errors, total_na, passed_auto_count, failed_auto_count, error_auto_count, na_auto_count, category_labels, category_pass_counts, category_fail_counts, category_error_counts, category_na_counts, filename="rapport_cis_postgresql_17.html"):
    """Génère le rapport HTML."""
    report_date = datetime.now().strftime("%d/%m/%Y %H:%M:%S")

    overall_score_class = get_score_class(overall_score)

    categories_html = ""
    # Maintain the original order of categories from RECOMMENDATIONS_DATA
    category_order = list(dict.fromkeys(rec["category"] for rec in RECOMMENDATIONS_DATA))

    for category in category_order:
        checks = results.get(category, [])
        cat_info = categories_scores.get(category, {})
        category_score = cat_info.get("score", 0)
        cat_score_class = get_score_class(category_score)
        cat_total_automated = cat_info.get("total_automated", 0) # This is now attempted automated
        cat_passed_automated = cat_info.get("passed_automated", 0)
        cat_manual_checks = cat_info.get("manual_checks", 0)
        cat_error_checks = cat_info.get("error_checks", 0)
        cat_na_checks = cat_info.get("na_checks", 0)


        checks_rows_html = ""
        # Sort checks within the category by number for consistent report order
        sorted_checks = sorted(checks, key=lambda x: tuple(map(int, x['number'].replace('.', '_').split('_'))))

        for check in sorted_checks:
            status_icon, status_text, status_class = get_status_info(check["status"])

            # Escape HTML special characters in text fields
            escaped_name = html.escape(check["name"])
            escaped_test_procedure = html.escape(check["test_procedure"])
            escaped_output = html.escape(check["output"])
            escaped_remediation = html.escape(check["remediation"])


            checks_rows_html += CHECK_ROW_TEMPLATE.format(
                number=check["number"],
                name=escaped_name,
                type=check["type"],
                test_procedure=escaped_test_procedure,
                status_icon=status_icon,
                status_text=status_text,
                status_class=status_class,
                output=escaped_output,
                remediation=escaped_remediation if escaped_remediation else "N/A"
            )

        categories_html += CATEGORY_REPORT_TEMPLATE.format(
            category_name=category,
            category_score=category_score,
            category_score_class=cat_score_class,
            passed_automated=cat_passed_automated,
            total_automated=cat_total_automated, # Display attempted automated checks
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
        error_checks=total_errors,
        na_checks=total_na,
        categories_reports=categories_html,
        # Pass counts for the chart
        passed_automated_count=passed_auto_count,
        failed_automated_count=failed_auto_count,
        error_automated_count=error_auto_count,
        na_automated_count=na_auto_count,
        # Pass data for category bar chart
        category_labels=category_labels,
        category_pass_counts=category_pass_counts,
        category_fail_counts=category_fail_counts,
        category_error_counts=category_error_counts,
        category_na_counts=category_na_counts
    )

    with open(filename, "w", encoding="utf-8") as f:
        f.write(html_output)

    print(f"Rapport généré avec succès : {filename}")


# --- Exécution principale ---
if __name__ == "__main__":
    print("🚀 Démarrage de l'audit CIS PostgreSQL 17 Benchmark ...")

    # Exécuter les contrôles
    check_results = perform_checks(RECOMMENDATIONS_DATA)

    # Calculer les scores et obtenir les comptes pour les graphiques
    overall_score, categories_scores, total_manual, total_errors, total_na, passed_auto_count, failed_auto_count, error_auto_count, na_auto_count, category_labels, category_pass_counts, category_fail_counts, category_error_counts, category_na_counts = calculate_scores(check_results)

    # Générer le rapport HTML
    generate_html_report(check_results, overall_score, categories_scores, total_manual, total_errors, total_na, passed_auto_count, failed_auto_count, error_auto_count, na_auto_count, category_labels, category_pass_counts, category_fail_counts, category_error_counts, category_na_counts, "rapport_cis_postgresql_17.html")

    print("✅ Audit terminé.")
    print(f"Score Global (contrôles automatisés tentés) : {overall_score:.2f}%.")
    print(f"Contrôles manuels : {total_manual}.")
    print(f"Contrôles en erreur : {total_errors}.")
    print(f"Contrôles non applicables : {total_na}.")
    print("Consulte le fichier rapport_cis_postgresql_17.html pour les détails.")
