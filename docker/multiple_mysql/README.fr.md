🚀 Gestionnaire de Bases de Données Multi-versions avec DockerCe projet fournit un environnement de développement flexible pour lancer rapidement différentes versions de MySQL, MariaDB et Percona Server en utilisant Docker, Docker Compose et un Makefile pour une gestion simplifiée.Grâce à un reverse proxy Traefik, toutes les instances de bases de données sont accessibles via un port unique et stable (localhost:3306), peu importe la version que vous choisissez de démarrer.📋 PrérequisAvant de commencer, assurez-vous d'avoir les outils suivants installés sur votre machine :DockerDocker Compose (généralement inclus avec Docker Desktop)make (disponible sur la plupart des systèmes Linux/macOS, ou via choco install make sur Windows avec Chocolatey)⚙️ InstallationLa seule étape de configuration requise est de définir le mot de passe root pour vos bases de données.Créez un fichier .env à la racine du projet.Ajoutez la variable d'environnement suivante dans ce fichier :# Fichier: .env
DB_ROOT_PASSWORD=votre_mot_de_passe_super_secret
⚠️ Important : Remplacez votre_mot_de_passe_super_secret par un mot de passe robuste de votre choix. N'ajoutez pas de guillemets.✨ Utilisation avec MakefileLe Makefile est le point d'entrée principal pour gérer l'environnement. Il simplifie toutes les opérations en commandes courtes et mémorables.Commandes PrincipalesCommande makeIcôneDescriptionhelp ou make📜Affiche la liste complète de toutes les commandes disponibles.status📊Affiche le statut des conteneurs actifs du projet (Traefik + la BDD).stop🛑Arrête et supprime proprement tous les conteneurs du projet.Démarrage d'une Base de DonnéesPour démarrer une instance, utilisez simplement la commande make correspondant à la version souhaitée. La commande arrêtera d'abord toute autre instance en cours avant de lancer la nouvelle.Commande makeFournisseurVersionmysql93🐬 MySQL9.3mysql84🐬 MySQL8.4mysql80🐬 MySQL8.0mariadb114🐧 MariaDB11.4mariadb1011🐧 MariaDB10.11mariadb106🐧 MariaDB10.6percona84⚡ Percona8.4percona80⚡ Percona8.0Exemple : Pour passer de MySQL 8.0 à Percona 8.4 :# 1. Vous travaillez sur MySQL 8.0
make mysql80

# 2. Vous voulez changer pour Percona 8.4. Pas besoin d'arrêter manuellement.
make percona84
🏛️ ArchitectureLe système utilise un reverse proxy Traefik qui agit comme un aiguilleur intelligent. Il est le seul service exposé sur le port 3306 de votre machine et redirige automatiquement le trafic vers la seule instance de base de données active.graph TD
    subgraph "💻 Votre Machine (Hôte)"
        App[Votre App / Client SQL]
    end

    subgraph "🐳 Moteur Docker"
        direction LR
        subgraph "🚪 Point d'Entrée Unique"
            Traefik[traefik-db-proxy<br/>toujours sur le port 3306]
        end
        subgraph "🚀 Conteneur à la demande"
            id1>"Base de données active<br/>(ex: percona80)"]
        end
    end

    App -- "Connexion sur localhost:3306" --> Traefik
    Traefik -- "Route le trafic dynamiquement" --> id1
✨ Tableau de bord Traefik : Pour visualiser ce routage en direct, ouvrez votre navigateur et allez sur http://localhost:8080.📁 Structure du projet.
├── 📜 .env                 # Fichier des secrets (mot de passe), à créer
├── 🐳 docker-compose.yml  # Définition de tous les services (Traefik, BDD)
├── 🛠️ Makefile             # Commandes simplifiées pour gérer l'environnement
└── 📖 README.md           # Documentation en anglais
└── 📖 README.fr.md           # Ce fichier
