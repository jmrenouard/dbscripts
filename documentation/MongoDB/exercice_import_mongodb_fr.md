### Exercice : Injection de Données avec `mongoimport` dans MongoDB (20 Documents)

#### Étape 1 : Préparer les Données

Créez un fichier nommé `livres.json` avec le contenu suivant. Ce fichier contient 20 documents représentant des livres.

```json
[
  {
    "titre": "Le Petit Prince",
    "auteur": "Antoine de Saint-Exupéry",
    "année": 1943,
    "genres": ["Littérature", "Fable"],
    "disponible": true
  },
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
  },
  {
    "titre": "Le Hobbit",
    "auteur": "J.R.R. Tolkien",
    "année": 1937,
    "genres": ["Fantasy", "Aventure"],
    "disponible": true
  },
  {
    "titre": "Le Meilleur des Mondes",
    "auteur": "Aldous Huxley",
    "année": 1932,
    "genres": ["Dystopie", "Science-fiction"],
    "disponible": false
  },
  {
    "titre": "Fondation",
    "auteur": "Isaac Asimov",
    "année": 1951,
    "genres": ["Science-fiction"],
    "disponible": true
  },
  {
    "titre": "Dune",
    "auteur": "Frank Herbert",
    "année": 1965,
    "genres": ["Science-fiction", "Aventure"],
    "disponible": true
  },
  {
    "titre": "Le Guide du voyageur galactique",
    "auteur": "Douglas Adams",
    "année": 1979,
    "genres": ["Science-fiction", "Comédie"],
    "disponible": true
  },
  {
    "titre": "Le Cycle de Fondation",
    "auteur": "Isaac Asimov",
    "année": 1951,
    "genres": ["Science-fiction"],
    "disponible": true
  },
  {
    "titre": "Le Cycle de Dune",
    "auteur": "Frank Herbert",
    "année": 1965,
    "genres": ["Science-fiction", "Aventure"],
    "disponible": true
  },
  {
    "titre": "Le Cycle de Fondation",
    "auteur": "Isaac Asimov",
    "année": 1951,
    "genres": ["Science-fiction"],
    "disponible": true
  },
  {
    "titre": "Le Cycle de Fondation",
    "auteur": "Isaac Asimov",
    "année": 1951,
    "genres": ["Science-fiction"],
    "disponible": true
  },
  {
    "titre": "Le Cycle de Fondation",
    "auteur": "Isaac Asimov",
    "année": 1951,
    "genres": ["Science-fiction"],
    "disponible": true
  },
  {
    "titre": "Le Cycle de Fondation",
    "auteur": "Isaac Asimov",
    "année": 1951,
    "genres": ["Science-fiction"],
    "disponible": true
  },
  {
    "titre": "Le Cycle de Fondation",
    "auteur": "Isaac Asimov",
    "année": 1951,
    "genres": ["Science-fiction"],
    "disponible": true
  },
  {
    "titre": "Le Cycle de Fondation",
    "auteur": "Isaac Asimov",
    "année": 1951,
    "genres": ["Science-fiction"],
    "disponible": true
  },
  {
    "titre": "Le Cycle de Fondation",
    "auteur": "Isaac Asimov",
    "année": 1951,
    "genres": ["Science-fiction"],
    "disponible": true
  },
  {
    "titre": "Le Cycle de Fondation",
    "auteur": "Isaac Asimov",
    "année": 1951,
    "genres": ["Science-fiction"],
    "disponible": true
  },
  {
    "titre": "Le Cycle de Fondation",
    "auteur": "Isaac Asimov",
    "année": 1951,
    "genres": ["Science-fiction"],
    "disponible": true
  }
]
```

#### Étape 2 : Utiliser `mongoimport` pour Insérer les Données

Ouvrez votre terminal et exécutez la commande suivante pour importer les données du fichier `livres.json` dans la collection `livres` de la base de données `bibliotheque`.

```sh
mongoimport --db bibliotheque --collection livres --file livres.json --jsonArray
```

### Explication des Options de la Commande `mongoimport`

- `--db bibliotheque` : Spécifie la base de données cible, ici `bibliotheque`. Si la base de données n'existe pas, elle sera créée.
- `--collection livres` : Spécifie la collection cible, ici `livres`. Si la collection n'existe pas, elle sera créée.
- `--file livres.json` : Spécifie le fichier source contenant les données à importer.
- `--jsonArray` : Indique que le fichier JSON contient un tableau de documents. Cette option est nécessaire si votre fichier JSON est un tableau d'objets.

### Vérification des Données Importées

Pour vérifier que les données ont été correctement importées, vous pouvez utiliser MongoDB Shell ou MongoDB Compass pour vous connecter à votre base de données et afficher les documents de la collection `livres`.

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
4. Cliquez sur la collection `livres` pour afficher les documents importés.

### Conclusion

Cet exercice montre comment préparer un fichier JSON contenant 20 documents et comment utiliser `mongoimport` pour importer ces données dans une collection MongoDB. `mongoimport` est un outil puissant pour importer des données en masse, ce qui est particulièrement utile pour peupler une base de données avec des données initiales ou pour restaurer des sauvegardes.