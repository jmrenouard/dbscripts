### Exercice : Utilisation de `mongorestore` pour Restaurer une Base de Données MongoDB

#### Objectif

L'objectif de cet exercice est de vous montrer comment utiliser `mongorestore` pour restaurer une base de données MongoDB à partir d'une sauvegarde créée avec `mongodump`. Nous allons utiliser une base de données `bibliotheque` comme exemple.

#### Prérequis

- MongoDB installé et en cours d'exécution.
- `mongorestore` installé (fait partie des MongoDB Database Tools).
- Une sauvegarde de la base de données `bibliotheque` créée avec `mongodump`.

#### Étapes

1. **Préparer la Sauvegarde**

   Assurez-vous que vous avez une sauvegarde de la base de données `bibliotheque` créée avec `mongodump`. Par exemple, la sauvegarde pourrait être stockée dans le répertoire `/path/to/backup/bibliotheque`.

2. **Restaurer une Base de Données Spécifique**

   Utilisez `mongorestore` pour restaurer la base de données `bibliotheque` à partir de la sauvegarde.

   ```sh
   mongorestore --db bibliotheque /path/to/backup/bibliotheque
   ```

   **Explication des Options :**
   - `--db bibliotheque` : Spécifie la base de données de destination, ici `bibliotheque`.
   - `/path/to/backup/bibliotheque` : Spécifie le répertoire contenant les fichiers de sauvegarde de la base de données `bibliotheque`. Remplacez `/path/to/backup/bibliotheque` par le chemin réel vers le répertoire de sauvegarde.

   **Résultat :**
   - La base de données `bibliotheque` sera restaurée avec toutes les collections et documents présents dans la sauvegarde.

3. **Restaurer Toutes les Bases de Données**

   Si vous avez sauvegardé toutes les bases de données et souhaitez les restaurer, vous pouvez omettre l'option `--db`.

   ```sh
   mongorestore /path/to/backup
   ```

   **Explication des Options :**
   - `/path/to/backup` : Spécifie le répertoire contenant les sauvegardes de toutes les bases de données. Remplacez `/path/to/backup` par le chemin réel vers le répertoire de sauvegarde.

   **Résultat :**
   - Toutes les bases de données présentes dans le répertoire de sauvegarde seront restaurées.

4. **Vérifier les Données Restaurées**

   Utilisez MongoDB Shell ou MongoDB Compass pour vérifier que les données ont été correctement restaurées.

   #### Utilisation de MongoDB Shell

   ```sh
   mongo
   use bibliotheque
   db.livres.find().pretty()
   ```

   #### Utilisation de MongoDB Compass

   1. Ouvrez MongoDB Compass.
   2. Connectez-vous à votre instance MongoDB.
   3. Sélectionnez la base de données `bibliotheque`.
   4. Cliquez sur la collection `livres` pour afficher les documents restaurés.

#### Conclusion

Cet exercice vous a montré comment utiliser `mongorestore` pour restaurer une base de données MongoDB à partir d'une sauvegarde créée avec `mongodump`. `mongorestore` est un outil essentiel pour la récupération de données en cas de perte ou pour les migrations de données. Vous pouvez utiliser ces commandes pour restaurer vos bases de données complètes ou spécifiques en fonction de vos besoins.