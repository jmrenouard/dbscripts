### Exercice : Utilisation de `mongoexport` pour Exporter des Données depuis MongoDB

#### Objectif

L'objectif de cet exercice est de vous montrer comment utiliser `mongoexport` pour exporter des données depuis une collection MongoDB vers un fichier JSON ou CSV. Nous allons utiliser une collection de livres comme exemple.

#### Prérequis

- MongoDB installé et en cours d'exécution.
- `mongoexport` installé (fait partie des MongoDB Database Tools).
- Une collection `livres` avec des documents existants dans une base de données `bibliotheque`.

#### Étapes

1. **Préparer les Données**

   Assurez-vous que vous avez une collection `livres` dans la base de données `bibliotheque` avec des documents. Vous pouvez utiliser `mongoimport` pour importer des données si nécessaire. Voici un exemple de document dans la collection `livres` :

   ```json
   {
     "titre": "Le Petit Prince",
     "auteur": "Antoine de Saint-Exupéry",
     "année": 1943,
     "genres": ["Littérature", "Fable"],
     "disponible": true
   }
   ```

2. **Exporter les Données en JSON**

   Utilisez `mongoexport` pour exporter les données de la collection `livres` vers un fichier JSON.

   ```sh
   mongoexport --db bibliotheque --collection livres --out livres.json
   ```

   **Explication des Options :**
   - `--db bibliotheque` : Spécifie la base de données source, ici `bibliotheque`.
   - `--collection livres` : Spécifie la collection source, ici `livres`.
   - `--out livres.json` : Spécifie le fichier de sortie, ici `livres.json`.

   **Résultat :**
   - Un fichier `livres.json` sera créé dans le répertoire courant contenant les documents de la collection `livres` au format JSON.

3. **Exporter les Données en CSV**

   Utilisez `mongoexport` pour exporter les données de la collection `livres` vers un fichier CSV.

   ```sh
   mongoexport --db bibliotheque --collection livres --type=csv --out livres.csv --fields titre,auteur,année,genres,disponible
   ```

   **Explication des Options :**
   - `--type=csv` : Spécifie que le format de sortie est CSV.
   - `--fields titre,auteur,année,genres,disponible` : Spécifie les champs à inclure dans le fichier CSV. Vous pouvez ajuster cette liste en fonction des champs de vos documents.

   **Résultat :**
   - Un fichier `livres.csv` sera créé dans le répertoire courant contenant les documents de la collection `livres` au format CSV.

4. **Vérifier les Fichiers Exportés**

   - **Fichier JSON (`livres.json`)** :
     Ouvrez le fichier `livres.json` dans un éditeur de texte pour vérifier son contenu. Vous devriez voir une liste de documents JSON.

   - **Fichier CSV (`livres.csv`)** :
     Ouvrez le fichier `livres.csv` dans un éditeur de texte ou un tableur (comme Excel ou Google Sheets) pour vérifier son contenu. Vous devriez voir une liste de lignes CSV avec les champs spécifiés.

#### Conclusion

Cet exercice vous a montré comment utiliser `mongoexport` pour exporter des données depuis une collection MongoDB vers des fichiers JSON ou CSV. `mongoexport` est un outil puissant pour sauvegarder ou transférer des données hors de MongoDB, ce qui est particulièrement utile pour les sauvegardes ou les migrations de données.