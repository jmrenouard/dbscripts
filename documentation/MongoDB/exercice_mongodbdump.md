### Exercice : Utilisation de `mongodump` pour Sauvegarder une Base de Données MongoDB

#### Objectif

L'objectif de cet exercice est de vous montrer comment utiliser `mongodump` pour créer une sauvegarde complète d'une base de données MongoDB. Nous allons utiliser une base de données `bibliotheque` comme exemple.

#### Prérequis

- MongoDB installé et en cours d'exécution.
- `mongodump` installé (fait partie des MongoDB Database Tools).
- Une base de données `bibliotheque` avec des collections et des documents existants.

#### Étapes

1. **Préparer les Données**

   Assurez-vous que vous avez une base de données `bibliotheque` avec des collections et des documents. Vous pouvez utiliser `mongoimport` pour importer des données si nécessaire. Voici un exemple de document dans la collection `livres` :

   ```json
   {
     "titre": "Le Petit Prince",
     "auteur": "Antoine de Saint-Exupéry",
     "année": 1943,
     "genres": ["Littérature", "Fable"],
     "disponible": true
   }
   ```

2. **Créer une Sauvegarde Complète de la Base de Données**

   Utilisez `mongodump` pour créer une sauvegarde complète de la base de données `bibliotheque`.

   ```sh
   mongodump --db bibliotheque --out /path/to/backup
   ```

   **Explication des Options :**
   - `--db bibliotheque` : Spécifie la base de données à sauvegarder, ici `bibliotheque`.
   - `--out /path/to/backup` : Spécifie le répertoire de sortie où la sauvegarde sera stockée. Remplacez `/path/to/backup` par le chemin réel vers le répertoire de votre choix.

   **Résultat :**
   - Un répertoire `/path/to/backup/bibliotheque` sera créé contenant les fichiers BSON des collections de la base de données `bibliotheque`.

3. **Créer une Sauvegarde Complète de Toutes les Bases de Données**

   Si vous souhaitez sauvegarder toutes les bases de données, vous pouvez omettre l'option `--db`.

   ```sh
   mongodump --out /path/to/backup
   ```

   **Explication des Options :**
   - `--out /path/to/backup` : Spécifie le répertoire de sortie où la sauvegarde sera stockée. Remplacez `/path/to/backup` par le chemin réel vers le répertoire de votre choix.

   **Résultat :**
   - Un répertoire `/path/to/backup` sera créé contenant des sous-répertoires pour chaque base de données, chacun contenant les fichiers BSON des collections.

4. **Vérifier les Fichiers de Sauvegarde**

   Naviguez dans le répertoire de sauvegarde pour vérifier les fichiers créés. Vous devriez voir des fichiers BSON pour chaque collection de la base de données `bibliotheque`.

   ```sh
   ls /path/to/backup/bibliotheque
   ```

   **Résultat :**
   - Vous devriez voir des fichiers avec des extensions `.bson` et `.metadata.json` pour chaque collection.

#### Conclusion

Cet exercice vous a montré comment utiliser `mongodump` pour créer des sauvegardes complètes d'une base de données MongoDB. `mongodump` est un outil puissant pour sauvegarder vos données, ce qui est essentiel pour la récupération en cas de perte de données ou pour les migrations de données. Vous pouvez utiliser ces sauvegardes pour restaurer vos données en utilisant `mongorestore`.