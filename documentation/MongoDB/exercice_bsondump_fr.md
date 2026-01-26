### Exercice : Utilisation de `bsondump` pour Inspecter des Fichiers BSON

#### Objectif

L'objectif de cet exercice est de vous montrer comment utiliser `bsondump` pour inspecter le contenu des fichiers BSON. Les fichiers BSON sont utilisés par MongoDB pour stocker des documents de manière binaire. `bsondump` permet de convertir ces fichiers BSON en un format JSON lisible.

#### Prérequis

- MongoDB installé et en cours d'exécution.
- `bsondump` installé (fait partie des MongoDB Database Tools).
- Une sauvegarde de la base de données `bibliotheque` créée avec `mongodump`.

#### Étapes

1. **Préparer la Sauvegarde**

   Assurez-vous que vous avez une sauvegarde de la base de données `bibliotheque` créée avec `mongodump`. Par exemple, la sauvegarde pourrait être stockée dans le répertoire `/path/to/backup/bibliotheque`.

2. **Inspecter un Fichier BSON**

   Utilisez `bsondump` pour convertir et afficher le contenu d'un fichier BSON spécifique.

   ```sh
   bsondump /path/to/backup/bibliotheque/livres.bson
   ```

   **Explication des Options :**
   - `/path/to/backup/bibliotheque/livres.bson` : Spécifie le fichier BSON à inspecter. Remplacez `/path/to/backup/bibliotheque/livres.bson` par le chemin réel vers le fichier BSON.

   **Résultat :**
   - Le contenu du fichier BSON sera affiché au format JSON dans la console.

3. **Rediriger la Sortie vers un Fichier**

   Si vous souhaitez enregistrer le contenu JSON dans un fichier, vous pouvez rediriger la sortie de `bsondump`.

   ```sh
   bsondump /path/to/backup/bibliotheque/livres.bson > livres.json
   ```

   **Explication des Options :**
   - `> livres.json` : Redirige la sortie JSON vers un fichier nommé `livres.json`.

   **Résultat :**
   - Un fichier `livres.json` sera créé dans le répertoire courant contenant le contenu du fichier BSON au format JSON.

4. **Inspecter Tous les Fichiers BSON d'une Collection**

   Si vous souhaitez inspecter tous les fichiers BSON d'une collection, vous pouvez utiliser une boucle shell pour traiter chaque fichier.

   ```sh
   for file in /path/to/backup/bibliotheque/*.bson; do
     bsondump "$file" > "${file%.bson}.json"
   done
   ```

   **Explication :**
   - `for file in /path/to/backup/bibliotheque/*.bson; do ... done` : Boucle à travers tous les fichiers BSON dans le répertoire spécifié.
   - `bsondump "$file" > "${file%.bson}.json"` : Convertit chaque fichier BSON en JSON et enregistre le résultat dans un fichier avec la même base de nom mais avec l'extension `.json`.

   **Résultat :**
   - Pour chaque fichier BSON dans le répertoire `/path/to/backup/bibliotheque`, un fichier JSON correspondant sera créé.

5. **Vérifier les Fichiers JSON**

   Ouvrez les fichiers JSON générés dans un éditeur de texte pour vérifier leur contenu. Vous devriez voir les documents de la collection `livres` au format JSON.

#### Conclusion

Cet exercice vous a montré comment utiliser `bsondump` pour inspecter et convertir des fichiers BSON en format JSON lisible. `bsondump` est un outil utile pour examiner le contenu des fichiers BSON, ce qui peut être particulièrement utile pour le débogage ou l'analyse des données. Vous pouvez utiliser ces commandes pour convertir des fichiers BSON individuels ou tous les fichiers d'une collection en JSON.