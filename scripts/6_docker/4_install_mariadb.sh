#!/bin/bash

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

_NAME="$(basename "$(readlink -f "$0")")"
NAME="${_NAME}"

# Parameters
MARIADB_VERSION=${1:-"latest"}
HOST_PORT=${2:-"3306"}

# Credentials
DB_ROOT_PASSWORD="rootpassword"
DB_USER="dbuser"
DB_PASSWORD="dbpassword"

# Container and Paths
CONTAINER_NAME="mariadb-server"
CONF_DIR="/opt/docker/mariadb/conf.d"
DATA_DIR="/opt/docker/mariadb/data"

title1 "DEPLOYING MARIADB CONTAINER"

# Ensure Docker is running
if ! systemctl is-active --quiet docker; then
    echo "Docker is not running. Starting Docker..."
    systemctl start docker
fi

# Prepare directories
echo "Preparing directories..."
mkdir -p "$CONF_DIR"
mkdir -p "$DATA_DIR"

# Create a default custom configuration if it doesn't exist
if [ ! -f "$CONF_DIR/my_custom.cnf" ]; then
    echo "Creating default custom configuration..."
    cat <<EOF > "$CONF_DIR/my_custom.cnf"
[mysqld]
character-set-server=utf8mb4
collation-server=utf8mb4_unicode_ci
max_connections=100
EOF
fi

# Cleanup existing container
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "Removing existing container: ${CONTAINER_NAME}"
    docker stop "$CONTAINER_NAME" >/dev/null 2>&1
    docker rm "$CONTAINER_NAME" >/dev/null 2>&1
fi

# Deploy Container
echo "Deploying MariaDB ${MARIADB_VERSION} on port ${HOST_PORT}..."
docker run -d \
    --name "$CONTAINER_NAME" \
    --restart unless-stopped \
    -p "${HOST_PORT}:3306" \
    -e MARIADB_ROOT_PASSWORD="$DB_ROOT_PASSWORD" \
    -e MARIADB_USER="$DB_USER" \
    -e MARIADB_PASSWORD="$DB_PASSWORD" \
    -v "$CONF_DIR:/etc/mysql/conf.d" \
    -v "$DATA_DIR:/var/lib/mysql" \
    mariadb:"$MARIADB_VERSION"

# Check status
if [ $? -eq 0 ]; then
    echo "-----------------------------------------------"
    echo "MariaDB deployed successfully!"
    echo "Container: $CONTAINER_NAME"
    echo "Port: $HOST_PORT"
    echo "User: $DB_USER"
    echo "Config: $CONF_DIR"
    echo "-----------------------------------------------"
else
    echo "Failed to deploy MariaDB container."
    exit 1
fi
