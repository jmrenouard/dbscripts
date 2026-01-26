# Installing MongoDB Community with Docker

## Overview

You can run MongoDB Community Edition as a Docker container using the official MongoDB Community image. Using a Docker image is useful for:

- Quickly setting up a deployment.
- Managing configuration files.
- Testing different features across multiple MongoDB versions.

## Procedure

### Step 1: Pull the MongoDB Docker Image

```bash
docker pull mongodb/mongodb-community-server:latest
```

### Step 2: Run the Image as a Container

```bash
docker run --name mongodb -p 27017:27017 -d mongodb/mongodb-community-server:latest
```

### Step 3: Verify the Container is Running

```bash
docker container ls
```

### Step 4: Connect with mongosh

```bash
mongosh --port 27017
```
