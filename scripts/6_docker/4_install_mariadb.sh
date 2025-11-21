#!/bin/bash

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh

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
