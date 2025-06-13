# -*- coding: utf-8 -*-
import subprocess
import json
import os
from datetime import datetime
import re # Pour les expressions régulières
import html # Pour échapper les caractères spéciaux HTML

# --- Configuration ---
# Commande pour se connecter à MongoDB shell (assumant une connexion sans authentification par défaut pour les tests).
# Pour une utilisation en production, il est recommandé de configurer l'authentification
# via un fichier de configuration sécurisé (ex: ~/.mongoshrc.js ou variables d'environnement)
# ou en ajustant cette commande avec les options --username et --password.
# --quiet pour réduire le bruit, --eval pour exécuter du JavaScript.
MONGODB_SHELL_CMD = "mongosh --quiet --eval" 
# Chemin par défaut pour le fichier de configuration mongod sur Linux.
# Adaptez si votre fichier de configuration est ailleurs ou si vous êtes sur Windows.
MONGOD_CONFIG_PATH = "/etc/mongod.conf" 

# --- Structure des Recommandations (Adaptée pour MongoDB 7.0) ---
# Basée sur le document "CIS MongoDB 7.0 Benchmark v1.0.0"
RECOMMENDATIONS_DATA = [
    # Catégorie 1: Installation et Patching
    {"category": "1 Installation et Patching", "number": "1.1", "name": "S'assurer que la version/les correctifs appropriés de MongoDB sont installés", "type": "Manual",
     "test_procedure": f"Exécuter '{MONGODB_SHELL_CMD} \"print(db.version())\"' OU 'mongod --version'. Vérifier manuellement les dernières versions/correctifs sur le site de MongoDB.",
     "expected_output": None, 
     "remediation": "Sauvegarder les données, télécharger les binaires de la dernière version de MongoDB, arrêter l'instance, remplacer les binaires, redémarrer l'instance."},

    # Catégorie 2: Authentification
    {"category": "2 Authentification", "number": "2.1", "name": "S'assurer que l'authentification est configurée", "type": "Automated",
     "test_procedure": f"cat {MONGOD_CONFIG_PATH} | grep \"authorization\"",
     "expected_output": {"type": "stdout_regex_match", "pattern": r"authorization:\s*\"?enabled\"?"},
     "remediation": "Démarrer l'instance sans authentification, créer un utilisateur administrateur, configurer 'security.authorization: enabled' dans le fichier de configuration et redémarrer."},
    {"category": "2 Authentification", "number": "2.2", "name": "S'assurer que MongoDB ne contourne pas l'authentification via l'exception localhost", "type": "Automated",
     "test_procedure": f"cat {MONGOD_CONFIG_PATH} | grep \"enableLocalhostAuthBypass\"",
     "expected_output": {"type": "stdout_regex_match", "pattern": r"enableLocalhostAuthBypass:\s*false"},
     "remediation": "Définir 'setParameter.enableLocalhostAuthBypass: false' dans le fichier de configuration ou exécuter 'mongod --setParameter enableLocalhostAuthBypass=0'."},
    {"category": "2 Authentification", "number": "2.3", "name": "S'assurer que l'authentification est activée dans le cluster sharded", "type": "Automated",
     # Ce test vérifie la présence de plusieurs paramètres dans le fichier de configuration pour un cluster sharded sécurisé.
     "test_procedure": f"cat {MONGOD_CONFIG_PATH} | grep \"PEMKeyFile\" && cat {MONGOD_CONFIG_PATH} | grep \"CAFile\" && cat {MONGOD_CONFIG_PATH} | grep \"clusterFile\" && cat {MONGOD_CONFIG_PATH} | grep \"clusterAuthMode\" && cat {MONGOD_CONFIG_PATH} | grep \"authenticationMechanisms:\"",
     "expected_output": {"type": "all_lines_match_regex", "patterns": [r"PEMKeyFile:", r"CAFile:", r"clusterFile:", r"clusterAuthMode:\s*x509", r"authenticationMechanisms:\s*MONGODB-X509"]},
     "remediation": "Configurer 'net.tls.mode: requireSSL', 'net.tls.PEMKeyFile', 'net.tls.CAFile', 'net.tls.clusterFile', 'security.authorization: enabled', et 'security.clusterAuthMode: x509' dans le fichier de configuration et redémarrer. Ou utiliser 'keyFile' pour le développement."},

    # Catégorie 3: Authorization
    {"category": "3 Authorization", "number": "3.1", "name": "S'assurer du moindre privilège pour les comptes de base de données", "type": "Manual",
     "test_procedure": f"Exécuter '{MONGODB_SHELL_CMD} \"printjson(db.system.users.find({{\\\"roles.role\\\": {\\\"$in\\\": [\\\"dbOwner\\\", \\\"userAdmin\\\", \\\"userAdminAnyDatabase\\\"]},\\\"roles.db\\\": \\\"admin\\\" }}).toArray())\"' et analyser manuellement la sortie.",
     "expected_output": None, 
     "remediation": "Supprimer les comptes listés avec des rôles à privilèges élevés dans la base de données 'admin'."},
    {"category": "3 Authorization", "number": "3.2", "name": "S'assurer que le contrôle d'accès basé sur les rôles est activé et configuré correctement", "type": "Manual",
     "test_procedure": f"Exécuter '{MONGODB_SHELL_CMD} \"printjson(db.getUser())\"' et '{MONGODB_SHELL_CMD} \"printjson(db.getRole())\"'. Vérifier manuellement les rôles et privilèges.",
     "expected_output": None, 
     "remediation": "Établir des rôles, assigner des privilèges appropriés aux rôles, assigner des utilisateurs aux rôles, supprimer les privilèges individuels superflus."},
    {"category": "3 Authorization", "number": "3.3", "name": "S'assurer que MongoDB est exécuté en utilisant un compte de service dédié et non privilégié", "type": "Manual",
     "test_procedure": "Exécuter 'ps -ef | grep -E \"mongos | mongod\"' et vérifier l'utilisateur sous lequel les processus s'exécutent (doit être un utilisateur non-root dédié comme 'mongodb').",
     "expected_output": None, 
     "remediation": "Créer un utilisateur dédié (ex: 'mongodb'), définir les permissions des fichiers de données, des fichiers de clés et des fichiers de log pour n'être lisibles/écrivables que par cet utilisateur."},
    {"category": "3 Authorization", "number": "3.4", "name": "S'assurer que chaque rôle pour chaque base de données MongoDB est nécessaire et n'accorde que les privilèges nécessaires", "type": "Manual",
     "test_procedure": f"Exécuter '{MONGODB_SHELL_CMD} \"printjson(db.runCommand( {{rolesInfo: 1, showPrivileges: true, showBuiltinRoles: true}} ))\"' et analyser manuellement les rôles et privilèges.",
     "expected_output": None, 
     "remediation": "Révoquer les privilèges spécifiés des rôles définis par l'utilisateur s'ils ne sont plus nécessaires."},
    {"category": "3 Authorization", "number": "3.5", "name": "Réviser les rôles de superutilisateur/administrateur", "type": "Manual",
     "test_procedure": f"Exécuter '{MONGODB_SHELL_CMD} \"printjson(db.runCommand( {{rolesInfo: \\\"dbowner\\\"}} ))\"' et des commandes similaires pour 'userAdmin', 'userAdminAnyDatabase', 'root', 'readWriteAnyDatabase', 'dbAdminAnyDatabase', 'clusterAdmin', 'hostManager'. Analyser manuellement les sorties.",
     "expected_output": None, 
     "remediation": "Retirer les utilisateurs des rôles de superutilisateur/administrateur s'ils n'en ont pas besoin."},

    # Catégorie 4: Data Encryption
    {"category": "4 Data Encryption", "number": "4.1", "name": "S'assurer que les protocoles TLS hérités sont désactivés", "type": "Automated",
     "test_procedure": f"cat {MONGOD_CONFIG_PATH} | grep \"disabledProtocols\"",
     "expected_output": {"type": "stdout_regex_match", "pattern": r"disabledProtocols:\s*\[?[\"']?TLS1_0[\"']?.*[\"']?TLS1_1[\"']?\]?"}, # Gère les formats de liste et de chaîne
     "remediation": "Définir 'net.tls.disabledProtocols: [TLS1_0, TLS1_1]' (ou équivalent) dans le fichier de configuration et redémarrer."},
    {"category": "4 Data Encryption", "number": "4.2", "name": "S'assurer que les protocoles faibles sont désactivés", "type": "Automated",
     "test_procedure": f"cat {MONGOD_CONFIG_PATH} | grep \"disabledProtocols\"",
     "expected_output": {"type": "stdout_regex_match", "pattern": r"disabledProtocols:\s*\[?[\"']?TLS1_0[\"']?.*[\"']?TLS1_1[\"']?\]?"}, # Similaire à 4.1 selon le PDF
     "remediation": "Définir 'net.ssl.disabledProtocols: TLS1_0, TLS1_1' dans le fichier de configuration et redémarrer."},
    {"category": "4 Data Encryption", "number": "4.3", "name": "S'assurer du chiffrement des données en transit TLS ou SSL (chiffrement de transport)", "type": "Automated",
     "test_procedure": f"cat {MONGOD_CONFIG_PATH} | grep -A20 'net' | grep -A10 'tls' | grep 'mode'",
     "expected_output": {"type": "stdout_regex_match", "pattern": r"mode:\s*requireTLS"},
     "remediation": "Définir 'net.tls.mode: requireTLS', 'net.tls.certificateKeyFile', 'net.tls.CAFile' dans le fichier de configuration et redémarrer."},
    {"category": "4 Data Encryption", "number": "4.4", "name": "S'assurer que la norme FIPS (Federal Information Processing Standard) est activée", "type": "Automated",
     "test_procedure": f"cat {MONGOD_CONFIG_PATH} | grep \"FIPSMode\"",
     "expected_output": {"type": "stdout_regex_match", "pattern": r"FIPSMode:\s*true"},
     "remediation": "Définir 'net.tls.FIPSMode: true' dans le fichier de configuration et redémarrer."},
    {"category": "4 Data Encryption", "number": "4.5", "name": "S'assurer du chiffrement des données au repos", "type": "Manual",
     "test_procedure": f"cat {MONGOD_CONFIG_PATH} | grep \"enableEncryption\" | grep \"encryptionKeyFile\". (Fonctionnalité MongoDB Enterprise uniquement)",
     "expected_output": None, 
     "remediation": "Activer le chiffrement des données au repos (MongoDB Enterprise uniquement) en configurant 'storage.engine: wiredTiger' et les options 'encryption'."},

    # Catégorie 5: Audit Logging
    {"category": "5 Audit Logging", "number": "5.1", "name": "S'assurer que l'activité du système est auditée", "type": "Automated",
     "test_procedure": f"cat {MONGOD_CONFIG_PATH} | grep -A4 \"auditLog\" | grep \"destination\"",
     "expected_output": {"type": "stdout_regex_match", "pattern": r"destination:\s*\"?(syslog|console|file)\"?"}, # Toute destination valide est un succès
     "remediation": "Définir 'auditLog.destination' sur 'syslog', 'console' ou 'file' dans le fichier de configuration."},
    {"category": "5 Audit Logging", "number": "5.2", "name": "S'assurer que les filtres d'audit sont configurés correctement", "type": "Manual",
     "test_procedure": f"cat {MONGOD_CONFIG_PATH} | grep -A10 \"auditLog\" | grep \"filter\". (Fonctionnalité MongoDB Enterprise uniquement)",
     "expected_output": None, 
     "remediation": "Définir les filtres d'audit en fonction des exigences de l'organisation (MongoDB Enterprise uniquement)."},
    {"category": "5 Audit Logging", "number": "5.3", "name": "S'assurer que la journalisation capture autant d'informations que possible", "type": "Automated",
     "test_procedure": f"cat {MONGOD_CONFIG_PATH} | grep \"quiet\"",
     "expected_output": {"type": "stdout_regex_match", "pattern": r"quiet:\s*false"},
     "remediation": "Définir 'systemLog.quiet: false' dans le fichier de configuration."},
    {"category": "5 Audit Logging", "number": "5.4", "name": "S'assurer que les nouvelles entrées sont ajoutées à la fin du fichier journal", "type": "Automated",
     "test_procedure": f"cat {MONGOD_CONFIG_PATH} | grep \"logAppend\"",
     "expected_output": {"type": "stdout_regex_match", "pattern": r"logAppend:\s*true"},
     "remediation": "Définir 'systemLog.logAppend: true' dans le fichier de configuration."},

    # Catégorie 6: Operating System Hardening
    {"category": "6 Operating System Hardening", "number": "6.1", "name": "S'assurer que MongoDB utilise un port non-standard", "type": "Automated",
     "test_procedure": f"cat {MONGOD_CONFIG_PATH} | grep \"port\"",
     "expected_output": {"type": "stdout_not_contains", "value": "27017"}, # S'assurer que ce n'est pas le port par défaut 27017
     "remediation": "Changer le port 'net.port' dans le fichier de configuration pour un numéro autre que 27017."},
    {"category": "6 Operating System Hardening", "number": "6.2", "name": "S'assurer que les limites de ressources du système d'exploitation sont définies pour MongoDB", "type": "Manual",
     "test_procedure": "Exécuter 'ps -ef | grep mongod' pour obtenir le PID, puis 'cat /proc/<PID>/limits' (remplacer <PID> par le PID réel). Vérifier les limites 'f' (file size), 't' (cpu time), 'v' (virtual memory), 'n' (open files), 'm' (memory size), 'u' (processes/threads).",
     "expected_output": None, 
     "remediation": "Ajuster les ulimits du système d'exploitation (f, t, v, n, m, u) et redémarrer les instances mongod/mongos."},
    {"category": "6 Operating System Hardening", "number": "6.3", "name": "S'assurer que le script côté serveur est désactivé si non nécessaire", "type": "Manual", # Le PDF indique Manuel, malgré la vérification grep
     "test_procedure": f"cat {MONGOD_CONFIG_PATH} | grep -A10 \"security\" | grep \"javascriptEnabled\"",
     "expected_output": None, 
     "remediation": "Définir 'security.javascriptEnabled: false' dans le fichier de configuration si le script côté serveur n'est pas nécessaire."},

    # Catégorie 7: File Permissions
    {"category": "7 File Permissions", "number": "7.1", "name": "S'assurer que les permissions appropriées du fichier de clés sont définies", "type": "Manual",
     "test_procedure": f"Exécuter 'cat {MONGOD_CONFIG_PATH} | grep \"keyFile:\" || cat {MONGOD_CONFIG_PATH} | grep \"PEMKeyFile:\" || cat {MONGOD_CONFIG_PATH} | grep \"CAFile:\"' pour trouver les chemins. Puis 'ls -l <chemin_fichier_clé/certificat>' et vérifier les permissions (doit être 600 et propriétaire 'mongodb:mongodb').",
     "expected_output": None, 
     "remediation": "Définir les permissions du fichier de clés/certificats à 600 et le propriétaire à 'mongodb:mongodb'."},
    {"category": "7 File Permissions", "number": "7.2", "name": "S'assurer que les permissions appropriées du fichier de base de données sont définies", "type": "Manual",
     "test_procedure": f"Exécuter 'cat {MONGOD_CONFIG_PATH} | grep \"dbpath\" || cat {MONGOD_CONFIG_PATH} | grep \"dbPath\"' pour trouver le chemin. Puis 'stat -c '%a' <chemin_base_de_données>' et vérifier les permissions (doit être 770 ou plus restrictif pour 'mongodb:mongodb').",
     "expected_output": None, 
     "remediation": "Définir les permissions du répertoire de base de données à 770 et le propriétaire à 'mongodb:mongodb'."},
]

# --- Modèle HTML pour le rapport ---
HTML_TEMPLATE = """
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport CIS MongoDB 7.0 Benchmark</title>
    <link href="https://cdn.jsdelivr.net/npm/tailwindcss@2.2.19/dist/tailwind.min.css" rel="stylesheet">
    <script src="https://cdn.jsdelivr.net/npm/chart.js@3.7.1/dist/chart.min.js"></script>
    <style>
        /* Styles personnalisés pour le rapport */
        .status-pass { color: #10B981; } /* green-500 */
        .status-fail { color: #EF4444; } /* red-500 */
        .status-manual { color: #F59E0B; } /* yellow-500 */
        .status-error { color: #6B7280; } /* gray-500 */
        .status-na { color: #9CA3AF; } /* gray-400 */
        pre { white-space: pre-wrap; word-wrap: break-word; background-color: #f3f4f6; padding: 0.5rem; border-radius: 0.25rem; font-size: 0.875rem;}
        table { table-layout: fixed; width: 100%; } /* Ajouté pour un meilleur contrôle de la largeur des colonnes */
        td, th { word-break: break-word; } /* Permettre la coupure des mots longs */
        .chart-container { width: 300px; height: 300px; margin: 20px auto; } /* Style pour le conteneur du graphique */
        .category-chart-container { width: 80%; margin: 20px auto; } /* Style pour le conteneur du graphique par catégorie */
        code { background-color: #e5e7eb; padding: 0.1rem 0.3rem; border-radius: 0.25rem; font-family: monospace;}
    </style>
</head>
<body class="font-sans bg-gray-100 text-gray-800 p-6">
    <div class="container mx-auto bg-white p-8 rounded-lg shadow-lg">
        <h1 class="text-3xl font-bold mb-6 text-gray-900">Rapport CIS MongoDB 7.0 Benchmark</h1>
        <p class="text-gray-600 mb-4">Date du rapport : {report_date}</p>
        <p class="text-gray-600 mb-8">Généré par un script basé sur le document CIS MongoDB 7.0 Benchmark (Version 1.0 du 11 Novembre 2023 par CIS).</p>

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
        // Données pour le graphique global en camembert
        const overallChartData = {{
            labels: ['Réussi', 'Échoué', 'Erreur', 'N/A'],
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

        // Options de configuration pour le graphique global en camembert
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

        // Rendu du graphique global
        const overallScoreChartCtx = document.getElementById('overallScoreChart');
        if (overallScoreChartCtx) {{
            new Chart(overallScoreChartCtx, overallChartConfig);
        }}


        // Données et configuration pour les graphiques à barres par catégorie
        const categoryChartData = {{
            labels: {category_labels}, // Liste des noms de catégories
            datasets: [
                {{
                    label: 'Réussi',
                    data: {category_pass_counts},
                    backgroundColor: '#10B981', // green-500
                }},
                {{
                    label: 'Échoué',
                    data: {category_fail_counts},
                    backgroundColor: '#EF4444', // red-500
                }},
                {{
                    label: 'Erreur',
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
                maintainAspectRatio: false, // Permettre au graphique de se redimensionner verticalement
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

        // Rendu du graphique à barres par catégorie
        const categoryScoreChartCtx = document.getElementById('categoryChart');
        if (categoryScoreChartCtx) {{
            new Chart(categoryScoreChartCtx, categoryChartConfig);
        }}

    </script>
</body>
</html>
"""

# Modèle pour le rapport par catégorie
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

# Nouveau modèle pour le canvas du graphique par catégorie
CATEGORY_CHART_CANVAS_TEMPLATE = """
        <div class="category-chart-container" style="height: 400px;"> {/* Hauteur augmentée */}
            <canvas id="categoryChart"></canvas>
        </div>
"""


# Modèle pour une ligne de vérification individuelle
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

# --- Fonctions d'exécution et d'évaluation ---

def run_command(command):
    """
    Exécute une commande shell et retourne stdout, stderr, et le code de retour.
    Gère les timeouts et les commandes introuvables.
    """
    try:
        # Utilise shell=True pour permettre les pipelines et les redirections.
        # Attention : shell=True est moins sécurisé si la commande vient d'une source non fiable.
        # Ici, les commandes sont définies dans le script.
        # Ajout de `timeout` pour éviter les blocages potentiels (ex: attente de mot de passe).
        process = subprocess.run(command, shell=True, check=False, capture_output=True, text=True, executable='/bin/bash', timeout=30) # Timeout de 30s
        return process.stdout.strip(), process.stderr.strip(), process.returncode
    except subprocess.TimeoutExpired:
        return "", f"Erreur : La commande a dépassé le délai d'exécution ({30}s).", 124 # Code pour timeout
    except FileNotFoundError:
        cmd_name = command.split()[0] if command else "N/A"
        return "", f"Erreur : Commande '{cmd_name}' introuvable.", 127 # Code 127 pour command not found
    except Exception as e:
        return "", f"Erreur d'exécution inattendue : {e}", 1 # Code générique pour autres erreurs

def evaluate_condition(condition, stdout, stderr, returncode):
    """
    Évalue si le résultat de la commande correspond à la condition attendue.
    """
    if not condition:
        return False # Aucune condition définie

    condition_type = condition.get("type")
    expected_value = condition.get("value")
    expected_values = condition.get("values")
    regex_pattern = condition.get("pattern")
    regex_patterns = condition.get("patterns") # Nouveau pour all_lines_match_regex

    if condition_type == "returncode_zero":
        return returncode == 0
    elif condition_type == "returncode_equals":
        return returncode == expected_value
    elif condition_type == "stdout_equals":
        # L'output peut contenir des espaces/retours à la ligne supplémentaires, on le nettoie.
        return stdout.strip() == str(expected_value) # Convertir l'attendu en chaîne pour comparaison
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
    elif condition_type == "all_lines_match_regex": # Nouveau type de condition
        if regex_patterns is None: return False
        lines = stdout.splitlines()
        # Pour que cela réussisse, tous les motifs donnés doivent trouver une correspondance quelque part dans la sortie.
        # C'est un ET logique pour tous les motifs.
        for pattern in regex_patterns:
            found_match_for_pattern = False
            for line in lines:
                if re.search(pattern, line):
                    found_match_for_pattern = True
                    break
            if not found_match_for_pattern:
                return False # Si un motif n'est trouvé dans aucune ligne, cela échoue
        return True # Tous les motifs ont été trouvés
    elif condition_type == "stdout_is_numeric_greater_than":
        try:
            numeric_value_match = re.match(r'^(\d+)', stdout)
            if numeric_value_match:
                numeric_value = int(numeric_value_match.group(1))
                return numeric_value > expected_value
            return False
        except (ValueError, TypeError):
            return False
    elif condition_type == "stdout_is_numeric_less_equal":
        try:
            numeric_value_match = re.match(r'^(\d+)', stdout)
            if numeric_value_match:
                numeric_value = int(numeric_value_match.group(1))
                # Gérer le cas où '0' signifie une durée de vie infinie, qui est considérée > 365
                if numeric_value == 0:
                    return False # 0 (infini) n'est pas <= 365
                return numeric_value <= expected_value
            return False
        except (ValueError, TypeError):
            return False

    # Cas par défaut : type de condition inconnu
    print(f"ATTENTION : Type de condition inconnu '{condition_type}'")
    return False

def perform_checks(recommendations):
    """
    Exécute tous les contrôles définis dans les recommandations et stocke les résultats.
    """
    results = {}
    # Initialise les résultats par catégorie en respectant l'ordre de définition
    category_order = list(dict.fromkeys(rec["category"] for rec in RECOMMENDATIONS_DATA))
    for category in category_order:
        results[category] = []

    for rec in recommendations:
        category = rec["category"]
        check_number = rec.get("number", "N/A")

        check_result = {
            "number": check_number,
            "name": rec["name"],
            "type": rec["type"],
            "test_procedure": rec.get("test_procedure", ""),
            "remediation": rec.get("remediation", ""),
            "status": "Not Applicable", # Statut par défaut (sera modifié pour les automatisés)
            "output": "",
            "error": ""
        }

        if rec["type"] == "Manual":
            check_result["status"] = "Manual"
            check_result["output"] = "Ce contrôle nécessite une vérification manuelle."
            # Ajoute la description de la procédure de test manuelle pour l'affichage
            check_result["output"] += f"\n\nProcédure suggérée:\n{rec.get('test_procedure', 'N/A')}"
        elif rec["type"] == "Automated":
            cmd_to_run = None
            command_executed_display = "N/A"
            stdout, stderr, returncode = "", "", -1 # Initialise les résultats d'exécution

            try:
                # Gérer les contrôles qui nécessitent d'obtenir d'abord un chemin dynamique (non utilisé pour MongoDB ici, mais conservé)
                if "path_command" in rec:
                    path_cmd = rec["path_command"]
                    path_stdout, path_stderr, path_returncode = run_command(path_cmd)

                    if path_returncode != 0 or not path_stdout:
                        check_result["status"] = "Error"
                        check_result["output"] = f"Erreur lors de l'obtention du chemin via:\n`{path_cmd}`\nStdout:\n{path_stdout}\nStderr:\n{path_stderr}"
                        check_result["error"] = path_stderr
                        results[category].append(check_result)
                        continue # Passer à la recommandation suivante

                    dynamic_path = path_stdout.strip()

                    if "test_procedure_template" in rec:
                        cmd_to_run = rec["test_procedure_template"].format(path=dynamic_path)
                        command_executed_display = cmd_to_run # Stocke la commande formatée
                    else:
                        # Si seul path_command est défini sans template, c'est une erreur de configuration du test.
                        check_result["status"] = "Error"
                        check_result["output"] = f"Configuration d'audit invalide: 'path_command' défini mais pas 'test_procedure_template' pour {check_number}."
                        results[category].append(check_result)
                        continue
                elif "test_procedure" in rec:
                    cmd_to_run = rec["test_procedure"]
                    command_executed_display = cmd_to_run
                else:
                    # Ni 'test_procedure' ni 'path_command' définis, erreur de configuration.
                    check_result["status"] = "Error"
                    check_result["output"] = f"Configuration d'audit invalide: Ni 'test_procedure' ni 'path_command' définis pour {check_number}."
                    results[category].append(check_result)
                    continue

                # Exécuter la commande
                stdout, stderr, returncode = run_command(cmd_to_run)
                check_result["output"] = f"Stdout:\n{stdout}\nStderr:\n{stderr}\nReturn Code: {returncode}"
                check_result["error"] = stderr
                check_result["test_procedure"] = command_executed_display # Met à jour avec la commande réellement exécutée

                # --- Évaluation ---
                condition = rec.get("expected_output")

                # Gérer les conditions d'erreur spécifiques avant d'évaluer le succès
                if returncode == 127: # Commande introuvable
                    check_result["status"] = "Error"
                    check_result["output"] = f"Erreur : Commande introuvable.\n{check_result['output']}"
                elif returncode == 124: # Timeout
                    check_result["status"] = "Error"
                    check_result["output"] = f"Erreur : Timeout.\n{check_result['output']}"
                elif "command not found" in stderr.lower(): # Une autre façon de détecter une commande introuvable
                    check_result["status"] = "Error"
                    check_result["output"] = f"Erreur : Commande introuvable (détecté dans stderr).\n{check_result['output']}"
                elif "Error: command failed" in stderr or "Failed to connect to" in stderr: # Erreurs MongoDB (connexion/commande)
                     check_result["status"] = "Error"
                     check_result["output"] = f"Erreur d'exécution de la commande MongoDB. Vérifiez la disponibilité/configuration du serveur/client.\n{check_result['output']}"
                elif returncode != 0 and stderr and not condition:
                    # Si la commande a échoué avec stderr, et aucune condition spécifique à vérifier, marquer comme Erreur
                    check_result["status"] = "Error"
                    check_result["output"] = f"Erreur d'exécution (code {returncode}).\n{check_result['output']}"
                elif condition:
                    # Évaluer la condition seulement si aucune erreur critique n'est survenue ci-dessus
                    if evaluate_condition(condition, stdout, stderr, returncode):
                        check_result["status"] = "Pass"
                    else:
                        # La condition n'est pas remplie, mais la commande a été exécutée (potentiellement avec des erreurs non fatales)
                        check_result["status"] = "Fail"
                        check_result["output"] += "\n\nCondition de succès non remplie."
                elif returncode == 0 and not condition:
                    # La commande a réussi mais aucune condition à vérifier ? Marquer comme Succès (par exemple, commandes informatives)
                    check_result["status"] = "Pass"
                    check_result["output"] += "\n\nNote : Commande exécutée avec succès, mais aucune condition de succès n'était définie pour ce test automatisé."
                # else: Le statut reste 'Not Applicable' ou 'Error' si défini précédemment


            except Exception as e:
                check_result["status"] = "Error"
                check_result["output"] = f"Erreur interne du script lors de l'exécution du contrôle {check_number}: {e}\nCommande tentée: {command_executed_display}"
                check_result["error"] = str(e)


        # Ajouter le résultat final de cette vérification
        results[category].append(check_result)

    return results

def calculate_scores(results):
    """
    Calcule les scores globaux et par catégorie.
    """
    overall = {"total_automated": 0, "passed_automated": 0, "failed_automated": 0, "manual": 0, "error": 0, "na": 0}
    categories_scores = {}
    # Initialiser les compteurs par catégorie en respectant l'ordre de RECOMMENDATIONS_DATA
    category_order = list(dict.fromkeys(rec["category"] for rec in RECOMMENDATIONS_DATA))
    for category in category_order:
        categories_scores[category] = {
            "score": 0,
            "total_automated": 0, # Total tenté (Pass + Fail)
            "passed_automated": 0,
            "failed_automated": 0,
            "manual_checks": 0,
            "error_checks": 0,
            "na_checks": 0,
            "pass_count": 0, # Compteurs pour les graphiques
            "fail_count": 0,
            "error_count": 0,
            "na_count": 0
        }


    for category, checks in results.items():
        if category not in categories_scores:
            print(f"ATTENTION : Catégorie '{category}' trouvée dans les résultats mais non pré-initialisée. Ignorée.")
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
                elif check["status"] == "Not Applicable": # Ce cas est peu probable pour les automatisés avec la logique actuelle
                    overall["na"] += 1
                    cat_stats["na_checks"] += 1
                    cat_stats["na_count"] += 1
            elif check["type"] == "Manual":
                overall["manual"] += 1
                cat_stats["manual_checks"] += 1

    # Calculer les scores
    overall_attempted_automated = overall["passed_automated"] + overall["failed_automated"]
    overall_score = (overall["passed_automated"] / overall_attempted_automated * 100) if overall_attempted_automated > 0 else 0

    for category in category_order:
        cat_stats = categories_scores[category]
        cat_attempted_automated = cat_stats["passed_automated"] + cat_stats["failed_automated"]
        cat_stats["total_automated"] = cat_attempted_automated # Stocker le nombre de tentatives
        cat_stats["score"] = (cat_stats["passed_automated"] / cat_attempted_automated * 100) if cat_attempted_automated > 0 else 0

    # Préparer les données pour le graphique à barres par catégorie (en utilisant l'ordre original)
    category_labels = json.dumps(category_order)
    category_pass_counts = json.dumps([categories_scores[cat]["pass_count"] for cat in category_order])
    category_fail_counts = json.dumps([categories_scores[cat]["fail_count"] for cat in category_order])
    category_error_counts = json.dumps([categories_scores[cat]["error_count"] for cat in category_order])
    category_na_counts = json.dumps([categories_scores[cat]["na_count"] for cat in category_order])


    # Retourner le score global, les détails par catégorie, les totaux globaux et les données des graphiques
    return (overall_score, categories_scores,
            overall["manual"], overall["error"], overall["na"],
            overall["passed_automated"], overall["failed_automated"], overall["error"], overall["na"], # Compteurs pour le graphique global
            category_labels, category_pass_counts, category_fail_counts, category_error_counts, category_na_counts) # Données pour le graphique par catégorie

def get_score_class(score):
    """Retourne la classe CSS pour la couleur du score."""
    if score >= 80:
        return "text-green-600"
    elif score >= 50:
        return "text-yellow-600"
    else:
        return "text-red-600"

def get_status_info(status):
    """Retourne l'icône, le texte et la classe CSS pour un statut."""
    if status == "Pass":
        return "✅", "Réussi", "status-pass"
    elif status == "Fail":
        return "❌", "Échoué", "status-fail"
    elif status == "Manual":
        return "⚠️", "Manuel", "status-manual"
    elif status == "Error":
        return "❓", "Erreur", "status-error"
    elif status == "Not Applicable":
        return "➖", "N/A", "status-na"
    else:
        return "❓", status, "status-error" # Fallback

def generate_html_report(results, overall_score, categories_scores, total_manual, total_errors, total_na, passed_auto_count, failed_auto_count, error_auto_count, na_auto_count, category_labels, category_pass_counts, category_fail_counts, category_error_counts, category_na_counts, filename="rapport_cis_mongodb_7.html"):
    """
    Génère le rapport HTML.
    """
    report_date = datetime.now().strftime("%d/%m/%Y %H:%M:%S")
    overall_score_class = get_score_class(overall_score)
    categories_html = ""
    category_order = list(dict.fromkeys(rec["category"] for rec in RECOMMENDATIONS_DATA)) # Obtenir l'ordre des données

    for category in category_order:
        checks = results.get(category, [])
        cat_info = categories_scores.get(category, {})
        category_score = cat_info.get("score", 0)
        cat_score_class = get_score_class(category_score)
        cat_total_automated = cat_info.get("total_automated", 0) # Tenté
        cat_passed_automated = cat_info.get("passed_automated", 0)
        cat_manual_checks = cat_info.get("manual_checks", 0)
        cat_error_checks = cat_info.get("error_checks", 0)
        cat_na_checks = cat_info.get("na_checks", 0)

        checks_rows_html = ""
        # Trier les vérifications au sein de la catégorie par numéro (gérer les parties non numériques potentielles)
        def sort_key(check):
            parts = re.split(r'[._-]', check['number'])
            return [int(p) if p.isdigit() else p for p in parts]

        try:
            sorted_checks = sorted(checks, key=sort_key)
        except Exception as e:
            print(f"ATTENTION : Impossible de trier les vérifications pour la catégorie '{category}'. Erreur : {e}")
            sorted_checks = checks # Garder l'ordre original si le tri échoue

        for check in sorted_checks:
            status_icon, status_text, status_class = get_status_info(check["status"])

            # Échapper les caractères spéciaux HTML
            escaped_name = html.escape(check["name"])
            # Note: Pour les procédures de test contenant des guillemets (ex: dans les commandes mongosh),
            # l'échappement HTML peut les remplacer par &quot;. L'affichage dans <code> devrait être correct.
            escaped_test_procedure = html.escape(check["test_procedure"]) 
            # L'output et la remédiation sont déjà échappés par `perform_checks`
            output_display = html.escape(check["output"]) # Assurer l'échappement même si déjà fait.
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
            total_automated=cat_total_automated, # Afficher le nombre de tentatives
            manual_checks=cat_manual_checks,
            error_checks=cat_error_checks,
            na_checks=cat_na_checks,
            checks_rows=checks_rows_html
        )

    # Ajouter le canvas du graphique par catégorie après tous les rapports de catégorie
    categories_html += CATEGORY_CHART_CANVAS_TEMPLATE

    html_output = HTML_TEMPLATE.format(
        report_date=report_date,
        overall_score=overall_score,
        overall_score_class=overall_score_class,
        passed_automated=passed_auto_count, # Utiliser les compteurs réels pour l'affichage
        total_automated=passed_auto_count + failed_auto_count, # Total tenté pour l'affichage
        manual_checks=total_manual,
        error_checks=total_errors, # Utiliser le compte d'erreurs global
        na_checks=total_na,        # Utiliser le compte N/A global
        categories_reports=categories_html,
        # Passer les compteurs pour le graphique global
        passed_automated_count=passed_auto_count,
        failed_automated_count=failed_auto_count,
        error_automated_count=error_auto_count, # Passer le compte d'erreurs global pour le graphique
        na_automated_count=na_auto_count,      # Passer le compte N/A global pour le graphique
        # Passer les données pour le graphique à barres par catégorie
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
    print("🚀 Démarrage de l'audit CIS MongoDB 7.0 Benchmark ...")
    print(f"ℹ️ Vérification des configurations dans: '{MONGOD_CONFIG_PATH}'")
    print(f"ℹ️ Utilisation du client MongoDB: '{MONGODB_SHELL_CMD}' (Assurez-vous que la connexion est configurée)")

    # Exécuter les contrôles
    check_results = perform_checks(RECOMMENDATIONS_DATA)

    # Calculer les scores et obtenir les compteurs pour les graphiques
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
                             "rapport_cis_mongodb_7.html")

        print("✅ Audit terminé.")
        print(f"Score Global (contrôles automatisés tentés) : {overall_score:.2f}%.")
        print(f"Contrôles manuels : {total_manual}.")
        print(f"Contrôles en erreur : {total_errors}.")
        print(f"Contrôles non applicables : {total_na}.")
        print("Consultez le fichier rapport_cis_mongodb_7.html pour les détails.")

    except Exception as e:
        print(f"\n❌ Une erreur s'est produite lors du calcul des scores ou de la génération du rapport :")
        print(e)
        import traceback
        traceback.print_exc()
