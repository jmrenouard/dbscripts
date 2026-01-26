### Exercice : Utilisation de `mongostat` pour Surveiller les Performances de MongoDB

#### Objectif

L'objectif de cet exercice est de vous montrer comment utiliser `mongostat` pour surveiller les performances de votre instance MongoDB. `mongostat` fournit des statistiques en temps réel sur les opérations et les performances du serveur, ce qui est essentiel pour le monitoring et le débogage.

#### Prérequis

- MongoDB installé et en cours d'exécution.
- `mongostat` installé (fait partie des MongoDB Database Tools).

#### Étapes

1. **Lancer `mongostat`**

   Ouvrez un terminal et exécutez la commande suivante pour lancer `mongostat` :

   ```sh
   mongostat
   ```

   **Explication :**
   - Par défaut, `mongostat` affiche des statistiques toutes les secondes.

2. **Comprendre les Champs de Résultat**

   `mongostat` affiche plusieurs champs qui fournissent des informations sur les opérations et les performances du serveur. Voici une description des champs principaux :

   - **inserts** : Le nombre d'objets insérés dans la base de données par seconde. Si suivi d'un astérisque (`*`), cela indique une opération répliquée.
   - **query** : Le nombre d'opérations de requête par seconde.
   - **update** : Le nombre d'opérations de mise à jour par seconde.
   - **delete** : Le nombre d'opérations de suppression par seconde.
   - **getmore** : Le nombre d'opérations de récupération de batch (cursors) par seconde.
   - **command** : Le nombre de commandes par seconde. Sur les systèmes secondaires, `mongostat` présente deux valeurs séparées par un pipe (`|`), sous la forme `local|repliquées`.
   - **flushes** : Pour le moteur de stockage WiredTiger, `flushes` indique le nombre de checkpoints WiredTiger déclenchés entre chaque intervalle de sondage.
   - **dirty** : Pour le moteur de stockage WiredTiger, le pourcentage de la mémoire cache WiredTiger avec des octets sales, calculé par `wiredTiger.cache.tracked dirty bytes in the cache / wiredTiger.cache.maximum bytes configured`.
   - **used** : Pour le moteur de stockage WiredTiger, le pourcentage de la mémoire cache WiredTiger utilisée, calculé par `wiredTiger.cache.bytes currently in the cache / wiredTiger.cache.maximum bytes configured`.
   - **vsize** : La quantité de mémoire virtuelle en mégaoctets utilisée par le processus au moment de l'appel à `mongostat`.
   - **res** : La quantité de mémoire résidente en mégaoctets utilisée par le processus au moment de l'appel à `mongostat`.
   - **locked** : Le pourcentage de temps passé dans un verrou global d'écriture. N'apparaît que lorsque `mongostat` s'exécute contre des instances MongoDB pré-3.0.
   - **qr** : La longueur de la file d'attente des clients attendant de lire des données depuis l'instance MongoDB.
   - **qw** : La longueur de la file d'attente des clients attendant d'écrire des données vers l'instance MongoDB.
   - **ar** : Le nombre de clients actifs effectuant des opérations de lecture.
   - **aw** : Le nombre de clients actifs effectuant des opérations d'écriture.
   - **netIn** : La quantité de trafic réseau en octets reçue par l'instance MongoDB. Cela inclut le trafic de `mongostat` lui-même.
   - **netOut** : La quantité de trafic réseau en octets envoyée par l'instance MongoDB. Cela inclut le trafic de `mongostat` lui-même.
   - **conn** : Le nombre total de connexions ouvertes.
   - **set** : Le nom, s'il y en a un, du réplica set.
   - **repl** : Le statut de réplication du membre.
     - **PRI** : Primaire
     - **SEC** : Secondaire
     - **REC** : En cours de récupération
     - **UNK** : Inconnu
     - **RTR** : Processus `mongos` (routeur)
     - **ARB** : Arbitre

3. **Interpréter les Résultats**

   Voici un exemple de sortie de `mongostat` :

   ```
   insert query update delete getmore command flushes vsize   res qr|qw ar|aw netIn netOut conn set repl
   *0     1     *0     *0       0     1|0     0     168.0M  16.0M  0|0   0|0     0     0  1|0   bibliotheque PRI
   ```

   **Explication des Valeurs :**
   - `insert` : 0 objets insérés par seconde.
   - `query` : 1 opération de requête par seconde.
   - `update` : 0 opérations de mise à jour par seconde.
   - `delete` : 0 opérations de suppression par seconde.
   - `getmore` : 0 opérations de récupération de batch par seconde.
   - `command` : 1 commande locale par seconde, 0 commandes répliquées.
   - `flushes` : 0 checkpoints WiredTiger entre chaque intervalle.
   - `vsize` : 168.0 Mo de mémoire virtuelle utilisée.
   - `res` : 16.0 Mo de mémoire résidente utilisée.
   - `qr|qw` : 0 clients en attente de lecture, 0 clients en attente d'écriture.
   - `ar|aw` : 0 clients actifs en lecture, 0 clients actifs en écriture.
   - `netIn` : 0 octets reçus par le réseau.
   - `netOut` : 0 octets envoyés par le réseau.
   - `conn` : 1 connexion ouverte.
   - `set` : Nom du réplica set `bibliotheque`.
   - `repl` : Statut de réplication `PRI` (primaire).

4. **Arrêter `mongostat`**

   Pour arrêter `mongostat`, appuyez sur `Ctrl+C` dans le terminal.

#### Conclusion

Cet exercice vous a montré comment utiliser `mongostat` pour surveiller les performances de votre instance MongoDB. `mongostat` est un outil puissant pour obtenir des statistiques en temps réel sur les opérations et les performances du serveur, ce qui est essentiel pour le monitoring et le débogage. Vous pouvez utiliser ces informations pour identifier les goulots d'étranglement, surveiller les performances et prendre des décisions éclairées pour optimiser votre déploiement MongoDB.