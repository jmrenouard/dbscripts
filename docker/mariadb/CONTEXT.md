# **SPÉCIFICATIONS DU CONTEXTE IA & ÉTAT D'AVANCEMENT DU PROJET**

**Avis à l'Agent :** Ce document constitue la source de vérité unique et absolue du projet. Sa consultation préalable est impérative avant toute intervention technique.

## **1\. OBJECTIF OPÉRATIONNEL (Mise à jour manuelle requise)**

Statut : \[EN COURS\]  
Tâche Prioritaire : \> Exemple : Optimiser le script de sauvegarde make backup-galera pour inclure la date dans le nom du fichier.  
Critères de Validation :

* Les environnements Docker (Galera et Réplication) doivent démarrer et s'arrêter proprement via make.  
* Les scripts Bash doivent être robustes (set \-e) et portables.  
* La maintenance (Backup/Restore) doit être fonctionnelle sur les volumes persistants.

## **2\. ARCHITECTURE & COMPOSANTS CRITIQUES**

**Pile Technologique :**

* **Langage :** Bash (Scripts Shell), Makefile  
* **SGBD :** MariaDB 11.8 (Images Docker personnalisées)  
* **Orchestration :** Docker, Docker Compose  
* **Proxy :** HAProxy (Load Balancing Galera/Réplication)

**Cartographie des Composants (Modification interdite sans requête explicite) :**

| Fichier/Dossier | Fonctionnalité | Niveau de Criticité |
| :---- | :---- | :---- |
| Makefile | Orchestrateur principal des commandes (Up, Down, Test, Backup) | 🔴 ÉLEVÉ |
| docker-compose.yaml | Définition de l'infrastructure (Réseaux, Volumes, Services) | 🔴 ÉLEVÉ |
| scripts/ | Scripts de maintenance (Backup, Restore, Setup, Healthcheck) | 🟡 MOYEN |
| config/ | Fichiers de configuration MariaDB (my.cnf, galera.cnf) | 🟡 MOYEN |
| documentation/ | Documentation technique Markdown | 🟢 FAIBLE |

## **3\. PROTOCOLES D'INTERVENTION ET MESURES DE SÉCURITÉ**

**Le respect rigoureux des directives suivantes est exigé :**

### **Prohibitions Formelles**

1. **PRINCIPE DE NON-RÉGRESSION :** La suppression de code existant est formellement interdite sans un déplacement préalable ou une mise en commentaire explicite.  
2. **MINIMALISME DES DÉPENDANCES :** Le principe de parcimonie s'applique strictement. L'ajout de dépendances (outils installés dans les conteneurs) est proscrit sauf nécessité absolue.  
3. **SILENCE OPÉRATIONNEL (Zéro Verbiage) :** Les explications textuelles, justifications pédagogiques et commentaires narratifs sont proscrits dans la réponse. Seuls les blocs de code, les commandes et les résultats techniques sont attendus.

### **Règles Désactivées (Tolérance Contexte Dev/Test)**

1. \~\~**SÉCURITÉ DES DONNÉES :** L'inclusion de données sensibles (mots de passe, IP) en dur est strictement interdite.\~\~**Note :** Règle désactivée pour cet environnement de laboratoire. L'usage de mots de passe par défaut (ex: rootpass) documentés dans le README est autorisé.

### **Cycle de Développement Exigé**

1. **PHASE D'ANALYSE D'IMPACT (Réflexion) :** Avant toute génération de code, une analyse silencieuse de la cohérence systémique (Impact sur le Makefile, les volumes Docker) est requise.  
2. **VALIDATION PAR LA PREUVE (Tests) :**  
   * Tout changement fonctionnel doit être vérifiable via une commande make test-\*.  
   * L'exécution des tests est obligatoire après modification pour valider la non-régression.  
3. **COHÉRENCE DOCUMENTAIRE :** Toute modification de code entraînant un changement de comportement doit inclure la mise à jour synchrone de la documentation associée (documentation/\*.md).  
4. **ROBUSTESSE BASH (Adaptation Typage) :**  
   * **Syntaxe Stricte :** Absence de typage fort compensée par une rigueur syntaxique (Usage de set \-euo pipefail).  
   * **Protection des variables :** Utilisation systématique des guillemets ("$VAR").  
   * **Nomenclature :** Variables explicites et majuscules pour les globales/env.  
   * **Vérification Critique :** Pour les opérations sensibles (dump, restore, stop, docker exec), **le résultat de la commande doit être testé explicitement** (if \! commande; then ... fi) pour garantir une gestion d'erreur précise et un message de sortie utile.
5. **MISE À JOUR DES TESTS :** Toute modification de la configuration ou du comportement doit impérativement être intégrée dans les scripts de tests (`test_*.sh`) pour assurer une validation automatique et pérenne des changements effectués.
6. **COMMIT IMMÉDIAT :** Une fois les tests validés avec succès (`make test-*`), les modifications doivent être commitées immédiatement afin de garantir la traçabilité et l'intégrité de l'environnement de développement.
7. **CONVENTIONAL COMMITS :** Les messages de commit doivent respecter la norme *Conventional Commits* (ex: `feat:`, `fix:`, `chore:`, `docs:`) pour faciliter la génération automatique de changelogs techniques.
8. **SINGLE BRANCH APPROACH :** Le développement s'effectue directement sur la branche principale (`main`) afin de simplifier le cycle de développement et de déploiement, en s'appuyant sur des commits atomiques et des tests systématiques avant chaque validation.

### **Format de Restitution**

1. **RESTITUTION STRICTEMENT TECHNIQUE :**  
   * Pas de phrases d'introduction ou de conclusion.  
   * Uniquement les blocs de code (Format search\_block / replace\_block pour fichiers \> 50 lignes).  
2. **PROSPECTIVE TECHNIQUE (Obligatoire) :** Chaque intervention doit se conclure impérativement par la proposition de **3 pistes d'évolution technique** pertinentes pour améliorer la robustesse ou la performance de l'ensemble.

### **Maintien de la Cohérence Contextuelle (CRITIQUE)**

1. **PROCÉDURE DE MISE À JOUR :** À l'issue de chaque intervention, la mise à jour de la section **4\. HISTORIQUE DES OPÉRATIONS RÉCENTES** est obligatoire.  
2. **CONSULTATION GIT :** En présence d'un répertoire .git, consulter les logs (git log \-n 5\) pour synchroniser le contexte avec la réalité du dépôt.  
3. **ROTATION FIFO (Max 200 lignes) :** Purger les anciennes entrées de l'historique pour maintenir la fenêtre de contexte optimale.

## **4\. HISTORIQUE DES OPÉRATIONS RÉCENTES (Mémoire tampon \- Max 200 lignes)**

**Instructions :** Ajouter les nouvelles entrées en tête. Supprimer les plus anciennes au-delà de 200 lignes.

* [2026-01-08] Evolution du test HAProxy : ajout du benchmarking de performance (latence), détection du mode de persistance et simulation de panne (failover) avec arrêt/redémarrage réel d'un conteneur.
* [2026-01-08] Intégration de la surveillance de l'expiration SSL (30 jours) et de l'audit des "Best Practices" Galera dans `test_galera.sh`.
* [2026-01-08] Implémentation de la rotation SSL à chaud (`make renew-ssl`) avec rechargement via `FLUSH SSL`.
* [2026-01-08] Refonte de l'affichage des Provider Options Galera : passage d'un test unitaire à un bloc d'information dédié dans les rapports.
* [2026-01-08] Optimisation du script `gen_ssl.sh` : ajout d'une vérification de validité existante pour éviter les régénérations inutiles.
* [2026-01-08] Résolution des erreurs "Aborted connection" dans les logs MariaDB : passage du health check HAProxy de `tcp-check` à `mysql-check` avec un utilisateur dédié `haproxy_check`.
* [2026-01-08] Intégration de la validation formatée des variables `wsrep_provider_options` dans les rapports de tests Galera (`test_galera.sh`).
* [2026-01-07] Intégration de diagrammes d'architecture dynamiques (Mermaid.js) dans les rapports HTML de Galera et Réplication.
* [2026-01-07] Correction des commandes de logs dans le Makefile : séparation entre lecture statique (`logs-*`) et flux dynamique (`follow-*`).
* [2026-01-07] Ajout des cibles `make logs-error-*` et `make logs-slow-*` dans le Makefile pour le diagnostic des conteneurs.
* [2026-01-07] Refactorisation des fichiers `gcustom_*.cnf` et `custom_*.cnf` : structuration par thématiques et documentation des paramètres en anglais.
* [2026-01-07] Correction automatique des permissions de `id_rsa` (600) dans `gen_profiles.sh` pour l'accès SSH.
* [2026-01-07] Ajout des alias SSH (`ssh-g*`, `ssh-m*`) dans les profils de shell pour faciliter l'accès aux conteneurs.
* [2026-01-07] Transition vers une approche "Single Branch" sur `main` pour simplifier le flux de développement.
* [2026-01-07] Intégration des règles "Conventional Commits" et "Branches de Feature" dans le cycle de développement.
* [2026-01-07] Validation de la règle de commit immédiat et archivage Git des changements (PFS/SlowQuery).
* [2026-01-07] Ajout de la règle de mise à jour des tests dans CONTEXT.md et intégration de la vérification PFS/SlowQuery dans `test_galera.sh`.
* [2026-01-07] Vérification et application de la configuration Galera (PFS et Slow Query Log). Redémarrage du cluster effectué avec succès.
* [2026-01-07] Renforcement des règles de robustesse Bash (Ajout de la vérification explicite des commandes critiques).  
* [2025-01-01] Initialisation du contexte IA pour l'environnement Docker MariaDB (Galera/Réplication).
