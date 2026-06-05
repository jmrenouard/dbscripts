# 🛠️ Prompt : Création d'un script Bash de synchronisation et d'audit PostgreSQL
**Copie ce texte ci-dessous et colle-le dans ton IA préférée pour générer le script :**
**Rôle :**
Tu es un expert DevOps, Administrateur de Bases de Données PostgreSQL et développeur Bash chevronné. Tu produis des scripts robustes, lisibles, bien commentés et sécurisés, adaptés pour des environnements de production.
**Objectif :**
Écrire un script shell Bash (sync_pg_databases.sh) permettant de migrer, synchroniser et auditer des bases de données PostgreSQL d'une instance source vers une instance cible.
### 📋 1. Spécifications Fonctionnelles
Le script doit exécuter les étapes suivantes, numérotées dans l'ordre :
 1. **Copie des rôles/utilisateurs :** - Identifier les utilisateurs présents sur la source mais absents sur la cible.
   * Copier ces utilisateurs manquants ainsi que leurs privilèges globaux.
   * *Contrainte technique :* Utiliser un pipe shell (pg_dumpall -r | psql) pour éviter d'écrire un fichier sur le disque.
 2. **Copie des définitions (Structure) :**
   * Exporter et importer la structure des bases de données.
   * *Contrainte technique :* Utiliser impérativement un pipe shell (pg_dump -s ... | psql ...) sans fichier intermédiaire.
 3. **Copie des données :**
   * Exporter et restaurer les données.
   * *Contrainte technique :* Utiliser un pipe shell (pg_dump -a ... | psql ... ou via pg_restore en flux).
 4. **Réaffectation des propriétaires (Ownership) :**
   * Appliquer une règle stricte sur la cible : le propriétaire (owner) de la base de données doit devenir le propriétaire de **tous** les objets (tables, vues, séquences, schémas) contenus dans cette base.
 5. **Optimisation :**
   * Lancer un VACUUM ANALYZE sur les bases de données cibles migrées.
 6. **Audit et Validation (Diffs) :**
   * **Diff de comptage (Count) :** Comparer le nombre de lignes par table entre la source et la cible. Afficher les écarts éventuels.
   * **Diff de structure :** Comparer les schémas (tables, colonnes, types) entre la source et la cible pour s'assurer qu'ils sont strictement identiques.
### ⚙️ 2. Spécifications Techniques et Comportementales
 * **Affichage des commandes :** Avant chaque exécution technique majeure, le script doit afficher la commande exacte qui va être exécutée via les pipes.
 * **Formatage des Logs et Étapes :**
   * Utiliser des **icônes** dans les logs (ex: ℹ️, ⏳, ✅, ❌, 🚀).
   * **En-tête d'étape :** Chaque étape doit commencer par un bloc visuel clair contenant le numéro de l'étape et son titre (ex: === 🚀 Étape 1 : Copie des rôles/utilisateurs ===).
   * **Pied de page d'étape (Footer) :** Chaque étape doit se terminer par un bloc indiquant son état de réussite ou d'échec, ainsi que sa durée d'exécution (ex: === ✅ Fin Étape 1 | Durée : 12s | État : SUCCÈS ===).
 * **Gestion du temps (Timers) :**
   * Mesurer le temps d'exécution pour chaque étape.
   * Mesurer le temps global du script.
 * **Résumé Final :**
   * À la toute fin du script, afficher un tableau ou une liste récapitulative présentant, pour chaque étape numérotée : le titre, la durée précise, et l'état final (✅ ou ❌).
   * Afficher le temps total d'exécution.
### 🎛️ 3. Options, Arguments et Configuration
Le script doit accepter des arguments en ligne de commande, et intégrer la gestion d'un fichier de configuration :
 * --config / -c : (Optionnel) Chemin vers un fichier de configuration (ex: config.env). Si fourni, le script doit sourcer ce fichier pour charger les variables.
 * --source / -s : URL de connexion ou host/port/user source (surcharge le fichier de configuration).
 * --target / -t : URL de connexion ou host/port/user cible (surcharge le fichier de configuration).
 * --database / -d : (Optionnel) Permet de ne cibler **qu'une seule base de données** spécifique. Si cette option est omise, le script traite toutes les bases de données (hors bases système).
**Définition des variables du fichier de configuration :**
L'IA doit utiliser ces noms de variables exacts dans le script et générer un exemple de fichier config.env contenant :
 * SRC_HOST : Serveur source
 * SRC_PORT : Port source (ex: 5432)
 * SRC_USER : Utilisateur source
 * SRC_PASS : Mot de passe source (à passer correctement à PostgreSQL via PGPASSWORD en interne)
 * TGT_HOST : Serveur cible
 * TGT_PORT : Port cible (ex: 5432)
 * TGT_USER : Utilisateur cible
 * TGT_PASS : Mot de passe cible
 * TARGET_DB : (Optionnel) Base de données à cibler
*Note à l'IA :* Tu devras fournir un exemple clair de ce fichier de configuration dans un bloc séparé.
### 📊 Tableau Récapitulatif du Pipeline Attendu

| Étape | Action | Outils PostgreSQL (via Pipes) |
| :--- | :--- | :--- |
| **1** | Synchronisation des utilisateurs manquants | pg_dumpall -r | psql |
| **2** | Migration de la structure | pg_dump -s | psql |
| **3** | Migration des données | pg_dump -a | psql |
| **4** | Uniformisation des Owners | Requêtes dynamiques ALTER ... OWNER TO via psql |
| **5** | Optimisation | Requête VACUUM ANALYZE via psql |
| **6** | Audit Diffs (Données + Structure) | Requêtes dynamiques psql |

**Livrable attendu :** Fournis-moi uniquement le code source complet du script Bash, prêt à être exécuté, avec des commentaires clairs. Fournis également un exemple du fichier de configuration attendu avec les variables définies. Assure-toi que les en-têtes, pieds de page, le résumé final et les pipes shell soient parfaitement implémentés.