#!/bin/bash
# ==============================================================================
# Script : sync_pg_databases.sh
# Rôle   : Synchronisation, migration et audit de bases PostgreSQL.
# Auteur : Expert DevOps / DBA PostgreSQL
# #================================#================================#==============
# Fichier de configuration : config.env
# #================================#================================#==============
# Paramètres de connexion à #l'instance PostgreSQL SOURCE
#SRC_HOST=10.0.0.10
#SRC_PORT=5432
#SRC_USER=postgres_admin_src
#SRC_PASS=SuperSecretPasswordSrc!
# Paramètres de connexion à l'instance PostgreSQL CIBLE
#TGT_HOST=10.0.0.20
#TGT_PORT=5432
#TGT_USER=postgres_admin_tgt
#TGT_PASS=SuperSecretPasswordTgt!
# Base de données cible #spécifique (Optionnel, laisser #vide pour tout synchroniser)
# Surchargeable avec l'argument #-d ou --database
#TARGET_DB=my_production_db

#================================#================================#==============

set -euo pipefail

# Sauvegarde des arguments initiaux pour la double passe d'analyse
ORIGINAL_ARGS=("$@")

# ==============================================================================
# 0. VARIABLES ET INITIALISATION
# ==============================================================================
GLOBAL_START=$(date +%s)
declare -a SUMMARY_TITLES
declare -a SUMMARY_DURATIONS
declare -a SUMMARY_STATUS
STEP_NUM=1

# Variables par défaut
CONFIG_FILE=""
TARGET_DB=""

# ==============================================================================
# FONCTIONS UTILITAIRES
# ==============================================================================

# Vérification des prérequis
check_dependencies() {
    for cmd in psql pg_dump pg_dumpall comm diff; do
        if ! command -v $cmd &> /dev/null; then
            echo "❌ Erreur : La commande '$cmd' est introuvable."
            exit 1
        fi
    done
}

# Gestion de l'affichage des étapes
start_step() {
    local title="$1"
    echo -e "\n=== 🚀 Étape ${STEP_NUM} : ${title} ==="
    STEP_START=$(date +%s)
    SUMMARY_TITLES+=("$title")
}

end_step() {
    local status="$1"
    local STEP_END=$(date +%s)
    local duration=$((STEP_END - STEP_START))
    SUMMARY_DURATIONS+=("${duration}s")

    if [ "$status" -eq 0 ]; then
        echo -e "=== ✅ Fin Étape ${STEP_NUM} | Durée : ${duration}s | État : SUCCÈS ==="
        SUMMARY_STATUS+=("✅ SUCCÈS")
    else
        echo -e "=== ❌ Fin Étape ${STEP_NUM} | Durée : ${duration}s | État : ÉCHEC ==="
        SUMMARY_STATUS+=("❌ ÉCHEC")
    fi
    ((STEP_NUM++))
}

# ==============================================================================
# PARSING DES ARGUMENTS ET CONFIGURATION
# ==============================================================================

# Passe 1 : Récupération exclusive de la configuration
while [[ $# -gt 0 ]]; do
    if [[ "$1" == "-c" || "$1" == "--config" ]]; then
        CONFIG_FILE="$2"
        if [ -f "$CONFIG_FILE" ]; then
            source "$CONFIG_FILE"
            echo "ℹ️ Configuration chargée depuis : $CONFIG_FILE"
        else
            echo "❌ Fichier de configuration introuvable : $CONFIG_FILE"
            exit 1
        fi
        break
    fi
    shift
done

# Restauration des arguments
set -- "${ORIGINAL_ARGS[@]}"

# Passe 2 : Surcharge des variables via les arguments CLI
while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--config) shift 2 ;; # Déjà traité
        -s|--source)
            if [[ "$2" =~ ^([^:]+):([^@]+)@([^:]+):([0-9]+)$ ]]; then
                SRC_USER="${BASH_REMATCH[1]}"
                SRC_PASS="${BASH_REMATCH[2]}"
                SRC_HOST="${BASH_REMATCH[3]}"
                SRC_PORT="${BASH_REMATCH[4]}"
            else
                echo "❌ Format --source invalide. Attendu : user:pass@host:port"
                exit 1
            fi
            shift 2 ;;
        -t|--target)
            if [[ "$2" =~ ^([^:]+):([^@]+)@([^:]+):([0-9]+)$ ]]; then
                TGT_USER="${BASH_REMATCH[1]}"
                TGT_PASS="${BASH_REMATCH[2]}"
                TGT_HOST="${BASH_REMATCH[3]}"
                TGT_PORT="${BASH_REMATCH[4]}"
            else
                echo "❌ Format --target invalide. Attendu : user:pass@host:port"
                exit 1
            fi
            shift 2 ;;
        -d|--database) TARGET_DB="$2"; shift 2 ;;
        *) echo "❌ Option inconnue : $1"; exit 1 ;;
    esac
done

check_dependencies

# Récupération de la liste des bases de données cibles
if [ -n "$TARGET_DB" ]; then
    DBS="$TARGET_DB"
else
    echo "ℹ️ Aucune base spécifique fournie, récupération de toutes les bases utilisateurs sources..."
    DBS=$(PGPASSWORD="$SRC_PASS" psql -h "$SRC_HOST" -p "$SRC_PORT" -U "$SRC_USER" -d postgres -tAc "SELECT datname FROM pg_database WHERE datistemplate = false AND datname NOT IN ('postgres', 'rdsadmin');")
fi

# ==============================================================================
# PIPELINE DE MIGRATION
# ==============================================================================

# --- ÉTAPE 1 : RÔLES ET UTILISATEURS ---
start_step "Copie des rôles/utilisateurs"
STEP_ERR=0
echo "⏳ Analyse des utilisateurs existants..."
SRC_USERS=$(PGPASSWORD="$SRC_PASS" psql -h "$SRC_HOST" -p "$SRC_PORT" -U "$SRC_USER" -d postgres -tAc "SELECT rolname FROM pg_roles WHERE rolname NOT LIKE 'pg_%';")
TGT_USERS=$(PGPASSWORD="$TGT_PASS" psql -h "$TGT_HOST" -p "$TGT_PORT" -U "$TGT_USER" -d postgres -tAc "SELECT rolname FROM pg_roles WHERE rolname NOT LIKE 'pg_%';")

# comm nécessite des listes triées
MISSING_USERS=$(comm -23 <(echo "$SRC_USERS" | sort) <(echo "$TGT_USERS" | sort))

if [ -z "$MISSING_USERS" ]; then
    echo "ℹ️ Aucun utilisateur manquant détecté. Synchronisation ignorée."
else
    echo "ℹ️ Utilisateurs manquants identifiés : $(echo $MISSING_USERS | tr '\n' ' ')"
    CMD_LOG="PGPASSWORD='***' pg_dumpall -r -h $SRC_HOST -p $SRC_PORT -U $SRC_USER | PGPASSWORD='***' psql -h $TGT_HOST -p $TGT_PORT -U $TGT_USER -d postgres"
    echo "⏳ Commande : $CMD_LOG"
    
    # On désactive temporairement 'set -e' car psql remonte des erreurs normales si un rôle existe déjà.
    set +e +o pipefail
    PGPASSWORD="$SRC_PASS" pg_dumpall -r -h "$SRC_HOST" -p "$SRC_PORT" -U "$SRC_USER" | \
    PGPASSWORD="$TGT_PASS" psql -h "$TGT_HOST" -p "$TGT_PORT" -U "$TGT_USER" -d postgres -q > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        # On ne marque pas d'erreur critique ici, le "already exists" est attendu.
        echo "ℹ️ Remarque : La synchronisation a signalé quelques avertissements (normal si rôles partiels existants)."
    fi
    set -e -o pipefail
fi
end_step $STEP_ERR

# --- ÉTAPE 2 : STRUCTURE ---
start_step "Copie des définitions (Structure)"
STEP_ERR=0
for db in $DBS; do
    echo "ℹ️ Traitement de la base : $db"
    
    # Création de la base sur la cible si elle n'existe pas
    EXISTS=$(PGPASSWORD="$TGT_PASS" psql -h "$TGT_HOST" -p "$TGT_PORT" -U "$TGT_USER" -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname = '$db';")
    if [ -z "$EXISTS" ]; then
        echo "⏳ Création de la base '$db' sur la cible..."
        PGPASSWORD="$TGT_PASS" psql -h "$TGT_HOST" -p "$TGT_PORT" -U "$TGT_USER" -d postgres -c "CREATE DATABASE \"$db\";" > /dev/null
    fi

    CMD_LOG="PGPASSWORD='***' pg_dump -s -h $SRC_HOST -p $SRC_PORT -U $SRC_USER -d $db | PGPASSWORD='***' psql -h $TGT_HOST -p $TGT_PORT -U $TGT_USER -d $db"
    echo "⏳ Commande : $CMD_LOG"
    
    set +e
    if ! PGPASSWORD="$SRC_PASS" pg_dump -s -h "$SRC_HOST" -p "$SRC_PORT" -U "$SRC_USER" -d "$db" 2>/dev/null | PGPASSWORD="$TGT_PASS" psql -h "$TGT_HOST" -p "$TGT_PORT" -U "$TGT_USER" -d "$db" -q > /dev/null 2>&1; then
        echo "❌ Erreur critique lors de la copie de la structure pour $db"
        STEP_ERR=1
    fi
    set -e
done
end_step $STEP_ERR

# --- ÉTAPE 3 : DONNÉES ---
start_step "Copie des données"
STEP_ERR=0
for db in $DBS; do
    echo "ℹ️ Traitement de la base : $db"
    CMD_LOG="PGPASSWORD='***' pg_dump -a -h $SRC_HOST -p $SRC_PORT -U $SRC_USER -d $db | PGPASSWORD='***' psql -h $TGT_HOST -p $TGT_PORT -U $TGT_USER -d $db"
    echo "⏳ Commande : $CMD_LOG"
    
    set +e
    if ! PGPASSWORD="$SRC_PASS" pg_dump -a --disable-triggers -h "$SRC_HOST" -p "$SRC_PORT" -U "$SRC_USER" -d "$db" 2>/dev/null | PGPASSWORD="$TGT_PASS" psql -h "$TGT_HOST" -p "$TGT_PORT" -U "$TGT_USER" -d "$db" -q > /dev/null 2>&1; then
        echo "❌ Erreur critique lors de l'import des données pour $db"
        STEP_ERR=1
    fi
    set -e
done
end_step $STEP_ERR

# --- ÉTAPE 4 : RÉAFFECTATION DES OWNERS ---
start_step "Réaffectation des propriétaires (Ownership)"
STEP_ERR=0
for db in $DBS; do
    echo "ℹ️ Traitement de la base : $db"
    
    # 1. Identifier le propriétaire de la base
    DB_OWNER=$(PGPASSWORD="$TGT_PASS" psql -h "$TGT_HOST" -p "$TGT_PORT" -U "$TGT_USER" -d postgres -tAc "SELECT pg_catalog.pg_get_userbyid(datdba) FROM pg_catalog.pg_database WHERE datname = '$db';")
    echo "ℹ️ Nouveau propriétaire appliqué : $DB_OWNER"
    
    # 2. Générer et exécuter le script dynamique pour Schemas, Tables, Vues et Séquences
    QUERY="
    SELECT 'ALTER SCHEMA ' || quote_ident(nspname) || ' OWNER TO ' || quote_ident('$DB_OWNER') || ';' FROM pg_namespace WHERE nspname NOT LIKE 'pg_%' AND nspname != 'information_schema';
    SELECT 'ALTER TABLE ' || quote_ident(schemaname) || '.' || quote_ident(tablename) || ' OWNER TO ' || quote_ident('$DB_OWNER') || ';' FROM pg_tables WHERE schemaname NOT LIKE 'pg_%' AND schemaname != 'information_schema';
    SELECT 'ALTER VIEW ' || quote_ident(schemaname) || '.' || quote_ident(viewname) || ' OWNER TO ' || quote_ident('$DB_OWNER') || ';' FROM pg_views WHERE schemaname NOT LIKE 'pg_%' AND schemaname != 'information_schema';
    SELECT 'ALTER SEQUENCE ' || quote_ident(sequence_schema) || '.' || quote_ident(sequence_name) || ' OWNER TO ' || quote_ident('$DB_OWNER') || ';' FROM information_schema.sequences WHERE sequence_schema NOT LIKE 'pg_%' AND sequence_schema != 'information_schema';
    "
    CMD_LOG="PGPASSWORD='***' psql ... -tAc \"Génération des ALTERS\" | PGPASSWORD='***' psql -d $db"
    echo "⏳ Commande : $CMD_LOG"

    set +e
    if ! PGPASSWORD="$TGT_PASS" psql -h "$TGT_HOST" -p "$TGT_PORT" -U "$TGT_USER" -d "$db" -tAc "$QUERY" | PGPASSWORD="$TGT_PASS" psql -h "$TGT_HOST" -p "$TGT_PORT" -U "$TGT_USER" -d "$db" -q > /dev/null 2>&1; then
        echo "❌ Échec de la réaffectation des droits sur $db"
        STEP_ERR=1
    fi
    set -e
done
end_step $STEP_ERR

# --- ÉTAPE 5 : OPTIMISATION ---
start_step "Optimisation (VACUUM ANALYZE)"
STEP_ERR=0
for db in $DBS; do
    echo "ℹ️ Traitement de la base : $db"
    CMD_LOG="PGPASSWORD='***' psql -h $TGT_HOST -p $TGT_PORT -U $TGT_USER -d $db -c 'VACUUM ANALYZE;'"
    echo "⏳ Commande : $CMD_LOG"
    
    set +e
    if ! PGPASSWORD="$TGT_PASS" psql -h "$TGT_HOST" -p "$TGT_PORT" -U "$TGT_USER" -d "$db" -c "VACUUM ANALYZE;" -q > /dev/null 2>&1; then
        echo "❌ Échec du VACUUM sur $db"
        STEP_ERR=1
    fi
    set -e
done
end_step $STEP_ERR

# --- ÉTAPE 6 : AUDIT ET VALIDATION ---
start_step "Audit et Validation (Diffs)"
STEP_ERR=0
for db in $DBS; do
    echo "ℹ️ Audit de la base : $db"
    
    # -- 6.1 DIFF COUNT --
    echo "⏳ Analyse du nombre de lignes par table..."
    TABLES=$(PGPASSWORD="$SRC_PASS" psql -h "$SRC_HOST" -p "$SRC_PORT" -U "$SRC_USER" -d "$db" -tAc "SELECT schemaname || '.' || tablename FROM pg_tables WHERE schemaname NOT LIKE 'pg_%' AND schemaname != 'information_schema';")
    
    for tbl in $TABLES; do
        SRC_CNT=$(PGPASSWORD="$SRC_PASS" psql -h "$SRC_HOST" -p "$SRC_PORT" -U "$SRC_USER" -d "$db" -tAc "SELECT count(*) FROM $tbl;")
        TGT_CNT=$(PGPASSWORD="$TGT_PASS" psql -h "$TGT_HOST" -p "$TGT_PORT" -U "$TGT_USER" -d "$db" -tAc "SELECT count(*) FROM $tbl;")
        
        if [ "$SRC_CNT" != "$TGT_CNT" ]; then
            echo "  ❌ Écart détecté sur $tbl : Source ($SRC_CNT) != Cible ($TGT_CNT)"
            STEP_ERR=1
        else
            echo "  ✅ Lignes identiques pour $tbl ($SRC_CNT)"
        fi
    done

    # -- 6.2 DIFF SCHEMA --
    echo "⏳ Comparaison de la structure DDL..."
    PGPASSWORD="$SRC_PASS" pg_dump -s -h "$SRC_HOST" -p "$SRC_PORT" -U "$SRC_USER" -d "$db" > /tmp/src_schema_${db}.sql
    PGPASSWORD="$TGT_PASS" pg_dump -s -h "$TGT_HOST" -p "$TGT_PORT" -U "$TGT_USER" -d "$db" > /tmp/tgt_schema_${db}.sql
    
    set +e
    diff -u /tmp/src_schema_${db}.sql /tmp/tgt_schema_${db}.sql > /tmp/diff_schema_${db}.patch
    DIFF_RES=$?
    set -e

    if [ $DIFF_RES -ne 0 ]; then
        echo "  ❌ Différences de structure détectées pour $db ! Consultez : /tmp/diff_schema_${db}.patch"
        STEP_ERR=1
    else
        echo "  ✅ Structure strictement identique pour $db."
        rm -f /tmp/diff_schema_${db}.patch /tmp/src_schema_${db}.sql /tmp/tgt_schema_${db}.sql
    fi
done
end_step $STEP_ERR

# ==============================================================================
# RÉSUMÉ FINAL
# ==============================================================================
GLOBAL_END=$(date +%s)
GLOBAL_DUR=$((GLOBAL_END - GLOBAL_START))

echo -e "\n================================================================================"
echo -e "📊 RÉSUMÉ FINAL DE L'EXÉCUTION"
echo -e "================================================================================"
printf "%-5s | %-45s | %-10s | %-10s\n" "Étape" "Titre" "Durée" "État"
echo "--------------------------------------------------------------------------------"
for i in "${!SUMMARY_TITLES[@]}"; do
    printf "%-5s | %-45s | %-10s | %-10s\n" "$((i+1))" "${SUMMARY_TITLES[$i]}" "${SUMMARY_DURATIONS[$i]}" "${SUMMARY_STATUS[$i]}"
done
echo "--------------------------------------------------------------------------------"
echo -e "⏱️  Temps total d'exécution : ${GLOBAL_DUR} secondes."
echo -e "================================================================================"

if [[ " ${SUMMARY_STATUS[*]} " =~ "❌" ]]; then
    exit 1
fi

