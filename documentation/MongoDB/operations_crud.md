# Opérations CRUD dans MongoDB

Les opérations CRUD (Create, Read, Update, Delete) sont les opérations de base pour interagir avec les documents dans une base de données MongoDB. Vous pouvez effectuer ces opérations en utilisant des méthodes de pilote et les exécuter pour des déploiements hébergés dans les environnements suivants. Vous pouvez également effectuer des opérations CRUD via l'interface utilisateur pour des déploiements hébergés sur MongoDB Atlas.

## Opérations de Création

Les opérations de création ou d'insertion ajoutent de nouveaux documents à une collection. Si la collection n'existe pas actuellement, les opérations d'insertion créeront la collection.

MongoDB fournit les méthodes suivantes pour insérer des documents dans une collection :

- `db.collection.insertOne()`
- `db.collection.insertMany()`

Les opérations d'insertion ciblent une seule collection. Toutes les opérations d'écriture dans MongoDB sont atomiques au niveau d'un seul document.

Pour des exemples, voir [Insérer des documents](https://docs.mongodb.com/manual/tutorial/insert-documents/).

## Opérations de Lecture

Les opérations de lecture récupèrent des documents à partir d'une collection, c'est-à-dire qu'elles interrogent une collection pour des documents. MongoDB fournit les méthodes suivantes pour lire des documents à partir d'une collection :

- `db.collection.find()`

Vous pouvez spécifier des filtres ou des critères qui identifient les documents à retourner.

Pour des exemples, voir :
- [Interroger des documents](https://docs.mongodb.com/manual/tutorial/query-documents/)
- [Interroger des documents intégrés/imbriqués](https://docs.mongodb.com/manual/tutorial/query-embedded-documents/)
- [Interroger un tableau](https://docs.mongodb.com/manual/tutorial/query-arrays/)
- [Interroger un tableau de documents intégrés](https://docs.mongodb.com/manual/tutorial/query-array-of-documents/)

## Opérations de Mise à Jour

Les opérations de mise à jour modifient des documents existants dans une collection. MongoDB fournit les méthodes suivantes pour mettre à jour des documents d'une collection :

- `db.collection.updateOne()`
- `db.collection.updateMany()`
- `db.collection.replaceOne()`

Les opérations de mise à jour ciblent une seule collection. Toutes les opérations d'écriture dans MongoDB sont atomiques au niveau d'un seul document.

Vous pouvez spécifier des critères ou des filtres qui identifient les documents à mettre à jour. Ces filtres utilisent la même syntaxe que les opérations de lecture.

Pour des exemples, voir [Mettre à jour des documents](https://docs.mongodb.com/manual/tutorial/update-documents/).

## Opérations de Suppression

Les opérations de suppression suppriment des documents d'une collection. MongoDB fournit les méthodes suivantes pour supprimer des documents d'une collection :

- `db.collection.deleteOne()`
- `db.collection.deleteMany()`

Les opérations de suppression ciblent une seule collection. Toutes les opérations d'écriture dans MongoDB sont atomiques au niveau d'un seul document.

Vous pouvez spécifier des critères ou des filtres qui identifient les documents à supprimer. Ces filtres utilisent la même syntaxe que les opérations de lecture.

Pour des exemples, voir [Supprimer des documents](https://docs.mongodb.com/manual/tutorial/remove-documents/).

## Écriture en Bulk

MongoDB fournit la possibilité d'effectuer des opérations d'écriture en bulk. Pour plus de détails, voir [Opérations d'écriture en bulk](https://docs.mongodb.com/manual/core/bulk-write-operations/).