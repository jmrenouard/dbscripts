### Exercice : Utilisation de `mongotop` pour Surveiller les Performances des Collections MongoDB

#### Objectif

L'objectif de cet exercice est de vous montrer comment utiliser `mongotop` pour surveiller les performances des collections dans votre instance MongoDB. `mongotop` fournit des statistiques en temps réel sur le temps passé par le serveur à effectuer des opérations de lecture et d'écriture sur chaque collection.

#### Prérequis

- MongoDB installé et en cours d'exécution.
- `mongotop` installé (fait partie des MongoDB Database Tools).

#### Étapes

1. **Lancer `mongotop`**

   Ouvrez un terminal et exécutez la commande suivante pour lancer `mongotop` :

   ```sh
   mongotop
   ```

   **Explication :**
   - Par défaut, `mongotop` affiche des statistiques toutes les secondes.

2. **Comprendre les Champs de Résultat**

   `mongotop` affiche plusieurs champs qui fournissent des informations sur le temps passé par le serveur à effectuer des opérations sur chaque collection. Voici une description des champs principaux :

   - **mongotop.ns** : Contient le namespace de la base de données, qui combine le nom de la base de données et le nom de la collection.
     - Si vous utilisez `mongotop --locks`, le champ `ns` n'apparaît pas dans la sortie de `mongotop`.

   - **mongotop.db** : Contient le nom de la base de données. La base de données nommée `.` fait référence au verrou global, plutôt qu'à une base de données spécifique.
     - Ce champ n'apparaît que si vous avez invoqué `mongotop` avec l'option `--locks`.

   - **mongotop.total** : Fournit le temps total passé par ce `mongod` à opérer sur ce namespace.

   - **mongotop.read** : Fournit le temps passé par ce `mongod` à effectuer des opérations de lecture sur ce namespace.

   - **mongotop.write** : Fournit le temps passé par ce `mongod` à effectuer des opérations d'écriture sur ce namespace.

   - **mongotop.<timestamp>** : Fournit une horodatage pour les données retournées.

3. **Interpréter les Résultats**

   Voici un exemple de sortie de `mongotop` :

   ```
   2023-10-05T10:30:00.000-0400 connected to: 127.0.0.1
   ns       total     read      write
   bibliotheque.livres  81802ms   0ms       81802ms
   bibliotheque.auteurs 0ms       0ms       0ms
   ```

   **Explication des Valeurs :**
   - `ns` : Le namespace de la base de données et de la collection. Par exemple, `bibliotheque.livres` indique la collection `livres` dans la base de données `bibliotheque`.
   - `total` : Le temps total passé par le serveur à opérer sur cette collection, en millisecondes. Par exemple, `81802ms` indique que le serveur a passé 81,802 millisecondes à opérer sur la collection `livres`.
   - `read` : Le temps passé par le serveur à effectuer des opérations de lecture sur cette collection, en millisecondes. Par exemple, `0ms` indique qu'aucune opération de lecture n'a été effectuée sur la collection `auteurs`.
   - `write` : Le temps passé par le serveur à effectuer des opérations d'écriture sur cette collection, en millisecondes. Par exemple, `81802ms` indique que le serveur a passé 81,802 millisecondes à effectuer des opérations d'écriture sur la collection `livres`.

4. **Utiliser l'Option `--locks`**

   Si vous souhaitez surveiller les verrous globaux plutôt que les collections spécifiques, vous pouvez utiliser l'option `--locks` :

   ```sh
   mongotop --locks
   ```

   **Exemple de Sortie :**

   ```
   2023-10-05T10:30:00.000-0400 connected to: 127.0.0.1
   db       total     read      write
   .        81802ms   0ms       81802ms
   bibliotheque 0ms       0ms       0ms
   ```

   **Explication :**
   - `db` : Le nom de la base de données. La base de données nommée `.` fait référence au verrou global.
   - `total`, `read`, `write` : Les mêmes champs que précédemment, mais appliqués au verrou global ou à la base de données spécifique.

5. **Arrêter `mongotop`**

   Pour arrêter `mongotop`, appuyez sur `Ctrl+C` dans le terminal.

#### Conclusion

Cet exercice vous a montré comment utiliser `mongotop` pour surveiller les performances des collections dans votre instance MongoDB. `mongotop` est un outil puissant pour obtenir des statistiques en temps réel sur le temps passé par le serveur à effectuer des opérations de lecture et d'écriture sur chaque collection, ce qui est essentiel pour le monitoring et le débogage. Vous pouvez utiliser ces informations pour identifier les collections les plus actives, surveiller les performances et prendre des décisions éclairées pour optimiser votre déploiement MongoDB.