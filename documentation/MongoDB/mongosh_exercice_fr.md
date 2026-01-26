### Exercice : Utilisation de MongoDB Shell (mongosh)

#### Objectif

L'objectif de cet exercice est de vous familiariser avec MongoDB Shell (`mongosh`), un outil interactif pour interagir avec une instance MongoDB. Vous apprendrez à vous connecter à une instance MongoDB, à exécuter des commandes CRUD (Create, Read, Update, Delete), et à utiliser des fonctionnalités avancées comme les agrégations.

#### Prérequis

- MongoDB installé et en cours d'exécution.
- MongoDB Shell (`mongosh`) installé.

#### Étapes

1. **Démarrer MongoDB Shell**

   Ouvrez un terminal et démarrez MongoDB Shell en exécutant la commande suivante :

   ```sh
   mongosh
   ```

   **Explication :**
   - Par défaut, `mongosh` se connecte à une instance MongoDB locale sur le port 27017.

2. **Se Connecter à une Instance MongoDB**

   Si vous devez vous connecter à une instance MongoDB distante ou sur un port différent, utilisez la commande suivante :

   ```javascript
   mongosh "mongodb://<host>:<port>"
   ```

   **Exemple :**
   ```javascript
   mongosh "mongodb://localhost:27017"
   ```

3. **Sélectionner une Base de Données**

   Utilisez la commande `use` pour sélectionner une base de données. Si la base de données n'existe pas, elle sera créée lors de la première insertion de document.

   ```javascript
   use bibliotheque
   ```

4. **Insérer des Documents**

   Utilisez la méthode `insertOne` pour insérer un document dans une collection.

   ```javascript
   db.livres.insertOne({
     titre: "Le Petit Prince",
     auteur: "Antoine de Saint-Exupéry",
     année: 1943,
     genres: ["Littérature", "Fable"],
     disponible: true
   })
   ```

   Utilisez la méthode `insertMany` pour insérer plusieurs documents.

   ```javascript
   db.livres.insertMany([
     {
       titre: "1984",
       auteur: "George Orwell",
       année: 1949,
       genres: ["Dystopie", "Science-fiction"],
       disponible: false
     },
     {
       titre: "Le Seigneur des Anneaux",
       auteur: "J.R.R. Tolkien",
       année: 1954,
       genres: ["Fantasy", "Aventure"],
       disponible: true
     }
   ])
   ```

5. **Lire des Documents**

   Utilisez la méthode `find` pour lire des documents dans une collection.

   ```javascript
   db.livres.find().pretty()
   ```

   Utilisez des filtres pour rechercher des documents spécifiques.

   ```javascript
   db.livres.find({ auteur: "J.R.R. Tolkien" }).pretty()
   ```

6. **Mettre à Jour des Documents**

   Utilisez la méthode `updateOne` pour mettre à jour un document.

   ```javascript
   db.livres.updateOne(
     { titre: "Le Petit Prince" },
     { $set: { disponible: false } }
   )
   ```

   Utilisez la méthode `updateMany` pour mettre à jour plusieurs documents.

   ```javascript
   db.livres.updateMany(
     { disponible: true },
     { $set: { disponible: false } }
   )
   ```

7. **Supprimer des Documents**

   Utilisez la méthode `deleteOne` pour supprimer un document.

   ```javascript
   db.livres.deleteOne({ titre: "Le Petit Prince" })
   ```

   Utilisez la méthode `deleteMany` pour supprimer plusieurs documents.

   ```javascript
   db.livres.deleteMany({ disponible: false })
   ```

8. **Utiliser les Agrégations**

   Utilisez la méthode `aggregate` pour effectuer des opérations d'agrégation.

   ```javascript
   db.livres.aggregate([
     { $match: { disponible: true } },
     { $group: { _id: "$auteur", totalLivres: { $sum: 1 } } }
   ])
   ```

   **Explication :**
   - `$match` : Filtre les documents où `disponible` est `true`.
   - `$group` : Groupe les documents par `auteur` et compte le nombre total de livres pour chaque auteur.

9. **Quitter MongoDB Shell**

   Pour quitter MongoDB Shell, utilisez la commande suivante :

   ```javascript
   quit()
   ```

#### Conclusion

Cet exercice vous a montré comment utiliser MongoDB Shell (`mongosh`) pour interagir avec une instance MongoDB. Vous avez appris à vous connecter à une instance MongoDB, à exécuter des commandes CRUD, et à utiliser des fonctionnalités avancées comme les agrégations. MongoDB Shell est un outil puissant pour administrer et manipuler vos bases de données MongoDB de manière interactive. Vous pouvez utiliser ces commandes pour effectuer des opérations de base de données courantes et des analyses avancées.