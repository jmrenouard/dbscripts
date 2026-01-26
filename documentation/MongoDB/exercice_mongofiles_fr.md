### Exercice : Utilisation de `mongofiles` pour Gérer les Fichiers dans MongoDB

#### Objectif

L'objectif de cet exercice est de vous montrer comment utiliser `mongofiles` pour gérer les fichiers dans MongoDB GridFS. GridFS est une spécification pour stocker et récupérer des fichiers qui dépassent la taille limite d'un seul document MongoDB (16 Mo).

#### Prérequis

- MongoDB installé et en cours d'exécution.
- `mongofiles` installé (fait partie des MongoDB Database Tools).
- Une base de données MongoDB configurée pour utiliser GridFS.

#### Étapes

1. **Préparer un Fichier à Téléverser**

   Créez un fichier texte simple nommé `example.txt` avec le contenu suivant :

   ```txt
   Ceci est un exemple de fichier texte pour MongoDB GridFS.
   ```

2. **Téléverser un Fichier avec `mongofiles`**

   Utilisez `mongofiles` pour téléverser le fichier `example.txt` dans MongoDB GridFS.

   ```sh
   mongofiles --db bibliotheque --put example.txt
   ```

   **Explication des Options :**
   - `--db bibliotheque` : Spécifie la base de données à utiliser, ici `bibliotheque`.
   - `--put example.txt` : Spécifie le fichier à téléverser, ici `example.txt`.

   **Résultat :**
   - Le fichier `example.txt` sera téléversé dans la collection GridFS de la base de données `bibliotheque`.

3. **Lister les Fichiers Téléchargés**

   Utilisez `mongofiles` pour lister tous les fichiers téléversés dans la base de données `bibliotheque`.

   ```sh
   mongofiles --db bibliotheque --list
   ```

   **Explication des Options :**
   - `--list` : Liste tous les fichiers téléversés dans la collection GridFS.

   **Résultat :**
   - Une liste des fichiers téléversés dans la base de données `bibliotheque` sera affichée.

4. **Télécharger un Fichier avec `mongofiles`**

   Utilisez `mongofiles` pour télécharger un fichier spécifique depuis MongoDB GridFS.

   ```sh
   mongofiles --db bibliotheque --get example.txt --local downloaded_example.txt
   ```

   **Explication des Options :**
   - `--get example.txt` : Spécifie le fichier à télécharger depuis GridFS.
   - `--local downloaded_example.txt` : Spécifie le nom local du fichier téléchargé.

   **Résultat :**
   - Le fichier `example.txt` sera téléchargé depuis GridFS et enregistré sous le nom `downloaded_example.txt`.

5. **Supprimer un Fichier avec `mongofiles`**

   Utilisez `mongofiles` pour supprimer un fichier spécifique depuis MongoDB GridFS.

   ```sh
   mongofiles --db bibliotheque --delete example.txt
   ```

   **Explication des Options :**
   - `--delete example.txt` : Spécifie le fichier à supprimer depuis GridFS.

   **Résultat :**
   - Le fichier `example.txt` sera supprimé de la collection GridFS de la base de données `bibliotheque`.

6. **Vérifier les Fichiers Téléchargés et Supprimés**

   Utilisez `mongofiles` pour lister les fichiers restants dans la base de données `bibliotheque` pour vérifier que les opérations de téléversement, téléchargement et suppression ont été effectuées correctement.

   ```sh
   mongofiles --db bibliotheque --list
   ```

   **Résultat :**
   - Une liste des fichiers restants dans la base de données `bibliotheque` sera affichée.

#### Conclusion

Cet exercice vous a montré comment utiliser `mongofiles` pour gérer les fichiers dans MongoDB GridFS. `mongofiles` est un outil utile pour téléverser, lister, télécharger et supprimer des fichiers dans GridFS, ce qui est essentiel pour gérer des fichiers volumineux dans MongoDB. Vous pouvez utiliser ces commandes pour interagir avec GridFS et gérer vos fichiers de manière efficace.