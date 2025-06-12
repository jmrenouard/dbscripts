🚀 Multi-Version Database Manager with DockerThis project provides a flexible development environment to quickly launch different versions of MySQL, MariaDB, and Percona Server using Docker, Docker Compose, and a Makefile for streamlined management.Thanks to a Traefik reverse proxy, all database instances are accessible through a single, stable port (localhost:3306), regardless of which version you choose to run.📋 PrerequisitesBefore you begin, ensure you have the following tools installed on your machine:DockerDocker Compose (usually included with Docker Desktop)make (available on most Linux/macOS systems, or via choco install make on Windows with Chocolatey)⚙️ SetupThe only required configuration step is to set the root password for your databases.Create a .env file in the project's root directory.Add the following environment variable to this file:# File: .env
DB_ROOT_PASSWORD=your_super_secret_password
⚠️ Important: Replace your_super_secret_password with a strong password of your choice. Do not use quotes.✨ Usage with MakefileThe Makefile is the main entry point for managing the environment. It simplifies all operations into short, memorable commands.Main Commandsmake CommandIconDescriptionhelp or make📜Displays the full list of all available commands.status📊Shows the status of the project's active containers (Traefik + DB).stop🛑Stops and properly removes all containers for this project.Starting a DatabaseTo start an instance, simply use the make command corresponding to the desired version. The command will first stop any other running instance before launching the new one.make CommandVendorVersionmysql93🐬 MySQL9.3mysql84🐬 MySQL8.4mysql80🐬 MySQL8.0mariadb114🐧 MariaDB11.4mariadb1011🐧 MariaDB10.11mariadb106🐧 MariaDB10.6percona84⚡ Percona8.4percona80⚡ Percona8.0Example: To switch from MySQL 8.0 to Percona 8.4:# 1. You are working with MySQL 8.0
make mysql80

# 2. You want to switch to Percona 8.4. No need to stop manually.
make percona84
🏛️ ArchitectureThe system uses a Traefik reverse proxy that acts as a smart router. It is the only service exposed on your host machine's port 3306 and automatically forwards traffic to the currently active database instance.graph TD
    subgraph "💻 Your Host Machine"
        App[Your App / SQL Client]
    end

    subgraph "🐳 Docker Engine"
        direction LR
        subgraph "🚪 Single Entrypoint"
            Traefik[traefik-db-proxy<br/>always on port 3306]
        end
        subgraph "🚀 On-Demand Container"
            id1>"Active Database<br/>(e.g., percona80)"]
        end
    end

    App -- "Connect to localhost:3306" --> Traefik
    Traefik -- "Dynamically routes traffic" --> id1
✨ Traefik Dashboard: To see this routing in action, open your browser and navigate to http://localhost:8080.📁 Project Structure.
├── 📜 .env                 # Secrets file (password), to be created
├── 🐳 docker-compose.yml  # Defines all services (Traefik, DBs)
├── 🛠️ Makefile             # Simplified commands to manage the environment
└── 📖 README.md           # This file
└── 📖 README.fr.md           # French version of this file