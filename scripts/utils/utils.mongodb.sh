#!/bin/bash
# ==============================================================================
#
#          Script d'Utilitaires pour la Gestion de MongoDB
#
# Auteur:         Généré par Gemini pour Jean-Marie Renouard
# Version:        1.0
# Description:    Ce script fournit un ensemble de fonctions et d'alias pour
#                 simplifier l'administration des instances MongoDB.
#                 Il est inspiré d'un script équivalent pour PostgreSQL.
#
# Prérequis:      - mongosh (le nouveau shell MongoDB)
#                 - Outils BDD MongoDB (mongodump, mongorestore)
#                 - jq (pour le parsing JSON, fortement recommandé)
#
# Utilisation:    Sourcez ce script dans votre .bashrc ou .bash_profile :
#                 source /chemin/vers/mongo_utils.sh
#
# ==============================================================================

# --- Configuration ---
# Définissez ici vos URI de connexion MongoDB.
# Séparez les URI par des espaces.
# Pour les replica sets, une seule URI pointant vers un membre suffit.
# Exemple : MONGO_URIS="mongodb://user:pass@host1:27017/admin mongodb://host2:27018"
# Pour cet exemple, nous utilisons des instances locales sans authentification.
export MONGO_URIS="mongodb://localhost:27017"

# Noms personnalisés pour les instances (optionnel)
# La clé est générée en remplaçant '://' par '_' et ':' par '_'.
# export INSTANCE_NAME_mongodb_localhost_27017="primary_mongo"

_DIR="$(dirname "$(readlink -f "$0")")"
# Si vous avez un fichier utils.sh, vous pouvez le sourcer ici
source $_DIR/utils.sh

# --- Fonctions Utilitaires Internes ---

# Affiche un message d'erreur en rouge
error() { echo -e "\033[0;31m[ERREUR] $1\033[0m"; }

# Affiche un message de succès en vert
ok() { echo -e "\033[0;32m[OK] $1\033[0m"; }

# Affiche une information en jaune
info() { echo -e "\033[0;33m[INFO] $1\033[0m"; }

# Affiche un titre
title() { echo -e "\n\033[1;34m--- $1 ---\033[0m"; }

# Fonction pour parser une URI et retourner l'hôte et le port
_mongo_get_host_port_from_uri() {
    local uri=$1
    # Extrait la partie host:port de l'URI
    echo $uri | sed -E 's/mongodb:\/\/(.*@)?([^/]+).*/\2/'
}

# --- Alias ---
alias msh='mongosh'
alias l='ls -lsh'
alias lh='ls -lsht'
alias la='ls -lsha'
alias ii='mongo_info'
alias lport='netstat -ltnp | grep mongo'

# --- Fonctions Principales ---

#
# Vérifie le statut d'une instance MongoDB
#
mongo_status() {
    local lRC=0
    info "Vérification du statut des instances MongoDB..."
    for uri in $MONGO_URIS; do
        host_port=$(_mongo_get_host_port_from_uri $uri)
        mongosh "$uri" --eval "db.adminCommand({ping: 1})" --quiet &>/dev/null
        lRC=$?
        if [ $lRC -eq 0 ]; then
            ok "Le serveur MongoDB sur '$host_port' est démarré et accepte les connexions."
        else
            error "Le serveur MongoDB sur '$host_port' est arrêté ou inaccessible."
            return 1
        fi
    done
    return 0
}

#
# Liste les noms des instances configurées
#
mongo_instances() {
    for uri in $MONGO_URIS; do
        host_port=$(_mongo_get_host_port_from_uri $uri)
        # Utilise un nom personnalisé s'il existe, sinon l'hôte:port
        key="INSTANCE_NAME_$(echo $uri | sed 's|://|_|g' | sed 's|:|_|g')"
        eval "name=\$$key"
        if [ -n "$name" ]; then
            echo $name
        else
            echo $host_port
        fi
    done
}

#
# Affiche des informations détaillées sur chaque instance
#
mongo_info() {
(
    echo -e "INSTANCE\tVERSION\tPROCESSUS\tHOST\tUPTIME\tROLE\tREPL_SET\tDB_PATH\tSTATUS"
    for uri in $MONGO_URIS; do
        host_port=$(_mongo_get_host_port_from_uri $uri)
        
        # Récupération des données en une seule commande pour l'efficacité
        json_data=$(mongosh "$uri" --quiet --eval "JSON.stringify({
            serverStatus: db.serverStatus(), 
            replSetStatus: rs.status(), 
            hostInfo: db.hostInfo(),
            cmdLineOpts: db.adminCommand({getCmdLineOpts: 1})
        }, null, 2)" 2>/dev/null)

        # Si la connexion échoue
        if [ -z "$json_data" ]; then
            echo -e "$host_port\t-\t-\t-\t-\t-\t-\t-\tDOWN"
            continue
        fi

        # Parsing des données JSON avec jq (ou autre outil)
        VERSION=$(echo "$json_data" | jq -r '.serverStatus.version // "N/A"')
        PROCESS=$(echo "$json_data" | jq -r '.serverStatus.process // "N/A"')
        HOST=$(echo "$json_data" | jq -r '.serverStatus.host // "N/A"')
        UPTIME_S=$(echo "$json_data" | jq -r '.serverStatus.uptime // 0')
        UPTIME_H=$(awk -v seconds=$UPTIME_S 'BEGIN{printf "%.2f", seconds/3600}')"h"
        
        IS_MASTER=$(echo "$json_data" | jq -r '.serverStatus.repl.ismaster // "false"')
        IS_SECONDARY=$(echo "$json_data" | jq -r '.serverStatus.repl.secondary // "false"')
        REPL_SET=$(echo "$json_data" | jq -r '.serverStatus.repl.setName // "STANDALONE"')
        DB_PATH=$(echo "$json_data" | jq -r '.cmdLineOpts.parsed.storage.dbPath // "N/A"')
        
        ROLE="-"
        if [ "$IS_MASTER" == "true" ]; then
            ROLE="PRIMARY"
        elif [ "$IS_SECONDARY" == "true" ]; then
            ROLE="SECONDARY"
        elif [ "$REPL_SET" != "STANDALONE" ]; then
            ROLE="OTHER"
        else
            ROLE="STANDALONE"
        fi

        echo -e "$host_port\t$VERSION\t$PROCESS\t$HOST\t$UPTIME_H\t$ROLE\t$REPL_SET\t$DB_PATH\tUP"
    done
) | column -t
}

#
# Wrapper pour arrêter un serveur MongoDB (méthode propre)
#
mongo_stop() {
    local uri=$1
    if [ -z "$uri" ]; then
        error "Veuillez spécifier une URI d'instance."
        return 1
    fi
    title "Arrêt de l'instance $uri"
    mongosh "$uri/admin" --eval "db.shutdownServer()"
    return $?
}

#
# Liste les bases de données d'une instance
#
mongo_dbs() {
    local uri=$1
    if [ -z "$uri" ]; then
        error "Veuillez spécifier une URI d'instance."
        return 1
    fi
    mongosh "$uri" --quiet --eval "db.getMongo().getDBNames().join('\n')"
}

#
# Liste les collections d'une base de données
#
mongo_collections() {
    local uri=$1
    local db=$2
    if [ -z "$uri" ] || [ -z "$db" ]; then
        error "Syntaxe: mongo_collections <uri> <database>"
        return 1
    fi
    mongosh "$uri/$db" --quiet --eval "db.getCollectionNames().join('\n')"
}

#
# Compte les documents dans les collections d'une base de données
#
mongo_count_docs() {
(
    local uri=$1
    local db=$2
    if [ -z "$uri" ] || [ -z "$db" ]; then
        error "Syntaxe: mongo_count_docs <uri> <database>"
        return 1
    fi
    title "Comptage des documents dans la base '$db' sur $uri"
    echo -e "COLLECTION\tNB_DOCUMENTS"
    for col in $(mongo_collections $uri $db); do
        count=$(mongosh "$uri/$db" --quiet --eval "db.getCollection('$col').countDocuments()")
        echo -e "$col\t$count"
    done
) | column -t
}

#
# Sauvegarde logique d'une base de données (mongodump)
#
mongo_backup() {
    local uri=$1
    local db=$2
    local target_dir=${3:-"./backups"}
    local horodate=$(date "+%Y-%m-%d_%H-%M-%S")
    local backup_path="$target_dir/${db}_${horodate}"

    if [ -z "$uri" ] || [ -z "$db" ]; then
        error "Syntaxe: mongo_backup <uri> <database> [target_directory]"
        return 1
    fi

    mkdir -p "$target_dir"
    title "Sauvegarde de la base '$db' depuis '$uri'"
    info "Destination: $backup_path"

    mongodump --uri="$uri" --db="$db" --out="$backup_path" --gzip
    local lRC=$?

    if [ $lRC -eq 0 ]; then
        ok "Sauvegarde terminée avec succès."
        info "Archive: ${backup_path}.tar.gz"
        # Créer une archive tar.gz pour faciliter la manipulation
        (cd "$target_dir" && tar -czf "${db}_${horodate}.tar.gz" "${db}_${horodate}" && rm -rf "${db}_${horodate}")
    else
        error "La sauvegarde a échoué avec le code de retour $lRC."
    fi
    return $lRC
}

#
# Restauration logique d'une base de données (mongorestore)
#
mongo_restore() {
    local uri=$1
    local backup_archive=$2
    
    if [ -z "$uri" ] || [ -z "$backup_archive" ]; then
        error "Syntaxe: mongo_restore <uri_destination> <chemin_vers_archive_tar_gz>"
        return 1
    fi

    if [ ! -f "$backup_archive" ]; then
        error "Le fichier de sauvegarde '$backup_archive' n'existe pas."
        return 1
    fi

    local temp_dir=$(mktemp -d)
    info "Extraction de l'archive $backup_archive vers $temp_dir"
    tar -xzf "$backup_archive" -C "$temp_dir"
    
    # Le chemin de restauration est le répertoire créé à l'intérieur de temp_dir
    local restore_path=$(find "$temp_dir" -mindepth 1 -maxdepth 1 -type d)

    title "Restauration vers '$uri' depuis '$backup_archive'"
    mongorestore --uri="$uri" --drop --gzip "$restore_path"
    local lRC=$?

    if [ $lRC -eq 0 ]; then
        ok "Restauration terminée avec succès."
    else
        error "La restauration a échoué avec le code de retour $lRC."
    fi
    
    info "Nettoyage du répertoire temporaire..."
    rm -rf "$temp_dir"
    return $lRC
}


#
# Affiche les opérations en cours
#
mongo_active_ops() {
    local uri=$1
    if [ -z "$uri" ]; then
        error "Veuillez spécifier une URI d'instance."
        return 1
    fi
    mongosh "$uri" --quiet --eval "db.currentOp(true).inprog.forEach(op => {
        if (op.op !== 'none') {
            printjson({
                opid: op.opid,
                op: op.op,
                ns: op.ns,
                secs_running: op.secs_running,
                client: op.client,
                query: op.query,
                msg: op.msg
            });
        }
    })"
}

#
# Affiche le statut du replica set
#
mongo_replset_status() {
(
    local uri=$1
    if [ -z "$uri" ]; then
        error "Veuillez spécifier une URI d'instance."
        return 1
    fi
    
    echo -e "HOST\tID\tSTATE\tUPTIME\tPING_MS\tHEALTH\tLAST_HEARTBEAT"
    # Utilisation de jq pour un parsing robuste
    mongosh "$uri" --quiet --eval "JSON.stringify(rs.status())" | jq -r '.members[] | [
        .name, 
        ._id, 
        .stateStr, 
        .uptime,
        .pingMs,
        .health,
        .lastHeartbeatRecv
    ] | @tsv' 2>/dev/null
) | column -t
}

#
# Crée un nouvel utilisateur
#
mongo_create_user() {
    local uri=$1
    local db=$2
    local user=$3
    local pass=$4
    local roles=${5:-"readWrite"} # Ex: "readWrite,dbAdmin"

    if [ -z "$uri" ] || [ -z "$db" ] || [ -z "$user" ] || [ -z "$pass" ]; then
        error "Syntaxe: mongo_create_user <uri> <database> <user> <password> [roles_comma_separated]"
        return 1
    fi

    # Formatter les rôles pour le JSON
    local roles_json=$(echo "$roles" | awk -F, '{
        for (i=1; i<=NF; i++) {
            printf "{ \"role\": \"%s\", \"db\": \"%s\" }", $i, db
            if (i<NF) printf ","
        }
    }')
    
    title "Création de l'utilisateur '$user' sur la base '$db'"
    mongosh "$uri/$db" --quiet --eval "
        db.createUser({
            user: '$user',
            pwd: '$pass',
            roles: [ $roles_json ]
        })
    "
    local lRC=$?
    if [ $lRC -eq 0 ]; then
        ok "Utilisateur '$user' créé avec succès."
    else
        error "Échec de la création de l'utilisateur '$user'."
    fi
    return $lRC
}

#
# Supprime un utilisateur
#
mongo_drop_user() {
    local uri=$1
    local db=$2
    local user=$3
    
    if [ -z "$uri" ] || [ -z "$db" ] || [ -z "$user" ]; then
        error "Syntaxe: mongo_drop_user <uri> <database> <user>"
        return 1
    fi
    
    title "Suppression de l'utilisateur '$user' de la base '$db'"
    mongosh "$uri/$db" --quiet --eval "db.dropUser('$user')"
    local lRC=$?
    if [ $lRC -eq 0 ]; then
        ok "Utilisateur '$user' supprimé avec succès."
    else
        error "Échec de la suppression de l'utilisateur '$user'."
    fi
    return $lRC
}

info "Script d'utilitaires MongoDB chargé."
info "Commandes disponibles: mongo_status, mongo_info, mongo_dbs, mongo_collections, etc."

# --- Fin du script ---