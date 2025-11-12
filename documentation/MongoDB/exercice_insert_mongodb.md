### Exercice : Injection de Données avec `insertOne` et `insertMany` dans MongoDB

#### Étape 1 : Définir un Modèle de Document

Supposons que nous travaillons avec une collection de livres dans une bibliothèque. Chaque document dans cette collection représentera un livre avec les champs suivants :
- `titre` : Le titre du livre (chaîne de caractères)
- `auteur` : Le nom de l'auteur (chaîne de caractères)
- `année` : L'année de publication (nombre entier)
- `genres` : Une liste de genres littéraires (tableau de chaînes de caractères)
- `disponible` : Un booléen indiquant si le livre est disponible (true) ou non (false)

Voici un exemple de document pour un livre :

```json
{
  "titre": "Le Petit Prince",
  "auteur": "Antoine de Saint-Exupéry",
  "année": 1943,
  "genres": ["Littérature", "Fable"],
  "disponible": true
}
```

#### Étape 2 : Insérer un Document avec `insertOne`

Pour insérer un seul document dans la collection `livres`, nous utiliserons la méthode `insertOne`. Voici un exemple de requête pour insérer un livre :

```javascript
// Connexion à la base de données et sélection de la collection "livres"
use bibliotheque;
db.livres.insertOne({
  "titre": "Le Petit Prince",
  "auteur": "Antoine de Saint-Exupéry",
  "année": 1943,
  "genres": ["Littérature", "Fable"],
  "disponible": true
});
```

#### Étape 3 : Insérer Plusieurs Documents avec `insertMany`

Pour insérer plusieurs documents en une seule opération, nous utiliserons la méthode `insertMany`. Voici un exemple de requête pour insérer plusieurs livres :

```javascript
// Connexion à la base de données et sélection de la collection "livres"
use bibliotheque;
db.livres.insertMany([
  {
    "titre": "1984",
    "auteur": "George Orwell",
    "année": 1949,
    "genres": ["Dystopie", "Science-fiction"],
    "disponible": false
  },
  {
    "titre": "Le Seigneur des Anneaux",
    "auteur": "J.R.R. Tolkien",
    "année": 1954,
    "genres": ["Fantasy", "Aventure"],
    "disponible": true
  },
  {
    "titre": "Harry Potter à l'école des sorciers",
    "auteur": "J.K. Rowling",
    "année": 1997,
    "genres": ["Fantasy", "Jeunesse"],
    "disponible": true
  }
]);
```

### Explication des Requêtes

1. **Connexion à la Base de Données** :
   - `use bibliotheque;` : Cette commande sélectionne la base de données `bibliotheque`. Si elle n'existe pas, MongoDB la créera lors de la première insertion.

2. **Insertion d'un Document avec `insertOne`** :
   - `db.livres.insertOne({ ... })` : Cette méthode insère un seul document dans la collection `livres`. Si la collection n'existe pas, elle sera créée automatiquement.

3. **Insertion de Plusieurs Documents avec `insertMany`** :
   - `db.livres.insertMany([{ ... }, { ... }, { ... }])` : Cette méthode insère plusieurs documents dans la collection `livres`. Elle est plus efficace que d'appeler `insertOne` plusieurs fois, car elle réduit le nombre de communications avec la base de données.

### Conclusion

Cet exercice montre comment définir un modèle de document et comment utiliser les méthodes `insertOne` et `insertMany` pour insérer des données dans une collection MongoDB. Ces opérations sont fondamentales pour peupler une base de données avec des données initiales ou pour ajouter de nouveaux documents de manière efficace.