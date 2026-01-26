# MongoDB CRUD Operations

## Overview

CRUD operations (Create, Read, Update, Delete) are the fundamental operations for interacting with data in MongoDB.

## Operations

### Create

- `insertOne()`: Inserts a single document.
- `insertMany()`: Inserts multiple documents.

### Read

- `find()`: Queries documents from a collection.
- `findOne()`: Returns a single document that matches the query.

### Update

- `updateOne()`: Updates a single document.
- `updateMany()`: Updates multiple documents.
- `replaceOne()`: Replaces a single document.

### Delete

- `deleteOne()`: Deletes a single document.
- `deleteMany()`: Deletes multiple documents.

## Examples

```javascript
// Create
db.users.insertOne({ name: "Alice", age: 30 })

// Read
db.users.find({ age: { $gt: 25 } })

// Update
db.users.updateOne({ name: "Alice" }, { $set: { age: 31 } })

// Delete
db.users.deleteOne({ name: "Alice" })
```
