#!/bin/bash

#-------------------------------------------------------------------------------
# METADATA
#-------------------------------------------------------------------------------
##title_en: MongoDB TLS/SSL configuration
##title_fr: Configuration TLS/SSL pour MongoDB
##goals_en: Generate CA and server certificates / Configure MongoDB for TLS encryption
##goals_fr: Génération des certificats CA et serveur / Configuration de MongoDB pour le chiffrement TLS

#-------------------------------------------------------------------------------
# UTILS (fonctions simulées pour la portabilité)
#-------------------------------------------------------------------------------
# Tente de sourcer les fichiers d'utilitaires s'ils existent
source /etc/os-release

# --- Minimal Utility Functions ---
now() { echo "$(date "+%F %T %Z")($(hostname -s))"; }
info() { echo "$(now) INFO: $*" 1>&2; }
error() { echo "$(now) ERROR: $*" 1>&2; return 1; }
ok() { info "[SUCCESS] $* [SUCCESS]"; }
sep1() { echo "$(now) -----------------------------------------------------------------------------"; }
title1() { sep1; echo "$(now) $*"; sep1; }
cmd() {
    local tcmd="$1"
    local descr=${2:-"$tcmd"}
    title1 "RUNNING: $descr"
    eval "$tcmd"
    local cRC=$?
    if [ $cRC -eq 0 ]; then
        ok "$descr"
    else
        error "$descr (RC=$cRC)"
    fi
    return $cRC
}
banner() { title1 "START: $*"; info "run as $(whoami)@$(hostname -s)"; }
footer() {
    local lRC=${lRC:-"$?"}
    info "FINAL EXIT CODE: $lRC"
    [ $lRC -eq 0 ] && title1 "END: $* SUCCESSFUL" || title1 "END: $* FAILED"
    return $lRC
}
# --- End of Utility Functions ---

#-------------------------------------------------------------------------------
# CONFIGURATION
#-------------------------------------------------------------------------------
lRC=0
CONF_FILE="/etc/mongod.conf"

# Premier argument: répertoire des certificats. Par défaut: /etc/ssl/mongodb
CERT_DIR=${1:-"/etc/ssl/mongodb"}

# Second argument: informations pour le sujet du certificat
CRT_INFO=${2:-"ST=FR/C=FR/L=Rennes/O=Lightpath/OU=DSI"}

#-------------------------------------------------------------------------------
# DÉBUT DU SCRIPT
#-------------------------------------------------------------------------------
_NAME=$(basename "$(readlink -f "$0")")
NAME="${_NAME}"
banner "BEGIN SCRIPT: ${_NAME}"

# Vérification de l'existence du fichier de configuration MongoDB
if [ ! -f "$CONF_FILE" ]; then
    error "Le fichier de configuration de MongoDB n'a pas été trouvé à l'emplacement $CONF_FILE"
    footer "END SCRIPT: ${_NAME}"
    exit 1
fi

# Sujets des certificats pour l'autorité de certification (CA) et le serveur
CRT_CA_INFO="/CN=$(hostname -s)-CASERVER/$CRT_INFO/"
CRT_SERVER_INFO="/CN=$(hostname -s)/$CRT_INFO/"

# Création du répertoire des certificats s'il n'existe pas
[ -d "$CERT_DIR" ] || mkdir -p "$CERT_DIR"
cd "$CERT_DIR" || exit 1

### --- 1. Génération de l'Autorité de Certification (CA) ---
info "Génération de l'Autorité de Certification (CA)..."
if [ ! -f "ca-key.pem" ]; then
    # Clé privée de la CA
    info "CMD: openssl genrsa 2048 > ca-key.pem"
    openssl genrsa 2048 > ca-key.pem
fi

if [ ! -f "ca-cert.pem" ]; then
    # Certificat auto-signé de la CA (valide 100 ans)
    info "CMD: openssl req -new -x509 -nodes -days 36500 -key ca-key.pem -out ca-cert.pem -subj \"$CRT_CA_INFO\""
    openssl req -new -x509 -nodes -days 36500 -key ca-key.pem -out ca-cert.pem -subj "$CRT_CA_INFO"
fi

### --- 2. Génération du certificat pour le serveur MongoDB ---
info "Génération du certificat serveur..."
if [ ! -f "server-key.pem" ]; then
    # Requête de certificat et clé privée pour le serveur
    info "CMD: openssl req -newkey rsa:2048 -days 36500 -nodes -keyout server-key.pem -out server-req.pem -subj \"$CRT_SERVER_INFO\""
    openssl req -newkey rsa:2048 -days 36500 -nodes -keyout server-key.pem -out server-req.pem -subj "$CRT_SERVER_INFO"
fi

if [ -f "server-key.pem" ] && [ ! -f "server-cert.pem" ]; then
    # Signature du certificat serveur par notre CA
    info "CMD: openssl x509 -req -in server-req.pem -days 36500 -CA ca-cert.pem -CAkey ca-key.pem -set_serial 01 -out server-cert.pem"
    openssl x509 -req -in server-req.pem -days 36500 -CA ca-cert.pem -CAkey ca-key.pem -set_serial 01 -out server-cert.pem
fi

### --- 3. Vérification et assemblage ---
info "Vérification de la chaîne de certificats..."
openssl verify -verbose -CAfile ca-cert.pem server-cert.pem
if [ $? -ne 0 ]; then
    error "La vérification du certificat a échoué. Le certificat serveur n'est pas valide."
    footer "END SCRIPT: ${_NAME}"
    exit 1
fi
info "La vérification du certificat est réussie."

info "Assemblage de la clé et du certificat serveur dans un unique fichier .pem pour MongoDB..."
# MongoDB attend un seul fichier contenant la clé privée ET le certificat.
cat server-key.pem server-cert.pem > mongodb.pem
lRC=$(($lRC + $?))

### --- 4. Application des permissions ---
info "Application des permissions pour l'utilisateur 'mongodb'..."
# Le répertoire et les fichiers doivent appartenir à l'utilisateur qui exécute MongoDB
chown -R mongodb:mongodb "$CERT_DIR"
# La clé privée (contenue dans mongodb.pem) doit être lisible uniquement par son propriétaire.
chmod 600 "$CERT_DIR"/*.pem
lRC=$(($lRC + $?))

### --- 5. Configuration de MongoDB ---
info "Mise à jour du fichier de configuration: $CONF_FILE"

# Vérification si TLS est déjà configuré pour éviter les doublons
if grep -q "certificateKeyFile:" "$CONF_FILE"; then
    error "La configuration TLS (certificateKeyFile) semble déjà présente dans $CONF_FILE."
    error "Veuillez vérifier le fichier manuellement avant de continuer."
    footer "END SCRIPT: ${_NAME}"
    exit 1
fi

info "Ajout de la configuration TLS à $CONF_FILE..."
# On ajoute la section net.tls en YAML.
# ATTENTION: Ceci suppose que la section 'net:' n'est pas déjà configurée de manière conflictuelle.
echo "
# --- Configuration TLS/SSL ajoutée par script ---
net:
  port: 27017
  bindIp: 0.0.0.0 # Écoute sur toutes les interfaces, ajustez si besoin
  tls:
    mode: requireTLS
    certificateKeyFile: $CERT_DIR/mongodb.pem
    CAFile: $CERT_DIR/ca-cert.pem
# --- Fin de la configuration TLS/SSL ---
" | tee -a "$CONF_FILE"

### --- 6. Redémarrage du service ---
info "Redémarrage du service mongod pour appliquer la configuration..."
cmd "systemctl restart mongod"
lRC=$(($lRC + $?))
sleep 2
cmd "systemctl status mongod --no-pager"

footer "END SCRIPT: ${_NAME}"
exit $lRC