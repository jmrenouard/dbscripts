#!/bin/bash

# Script to generate SSL certificates for MariaDB Cluster
# Highly inspired by MariaDB documentation and best practices

SSL_DIR="./ssl"
mkdir -p "$SSL_DIR"

echo "=========================================================="
echo "🔐 MariaDB SSL Certificate Generator"
echo "=========================================================="

# 1. Create CA (Certificate Authority)
echo ">> 📁 Generating CA..."
openssl genrsa 2048 > "$SSL_DIR/ca-key.pem"
openssl req -new -x509 -nodes -days 3650 \
    -key "$SSL_DIR/ca-key.pem" \
    -out "$SSL_DIR/ca-cert.pem" \
    -subj "/CN=MariaDB-CA"

# 2. Create Server Certificate
echo ">> 📁 Generating Server Certificate..."
openssl req -newkey rsa:2048 -days 3650 -nodes \
    -keyout "$SSL_DIR/server-key.pem" \
    -out "$SSL_DIR/server-req.pem" \
    -subj "/CN=MariaDB-Server"

openssl rsa -in "$SSL_DIR/server-key.pem" \
    -out "$SSL_DIR/server-key.pem"

openssl x509 -req -in "$SSL_DIR/server-req.pem" -days 3650 \
    -CA "$SSL_DIR/ca-cert.pem" \
    -CAkey "$SSL_DIR/ca-key.pem" \
    -set_serial 01 \
    -out "$SSL_DIR/server-cert.pem"

# 3. Create Client Certificate
echo ">> 📁 Generating Client Certificate..."
openssl req -newkey rsa:2048 -days 3650 -nodes \
    -keyout "$SSL_DIR/client-key.pem" \
    -out "$SSL_DIR/client-req.pem" \
    -subj "/CN=MariaDB-Client"

openssl rsa -in "$SSL_DIR/client-key.pem" \
    -out "$SSL_DIR/client-key.pem"

openssl x509 -req -in "$SSL_DIR/client-req.pem" -days 3650 \
    -CA "$SSL_DIR/ca-cert.pem" \
    -CAkey "$SSL_DIR/ca-key.pem" \
    -set_serial 01 \
    -out "$SSL_DIR/client-cert.pem"

# Verify certificates
echo ">> 🔍 Verifying certificates..."
openssl verify -CAfile "$SSL_DIR/ca-cert.pem" \
    "$SSL_DIR/server-cert.pem" "$SSL_DIR/client-cert.pem"

# Set permissions
chmod 644 "$SSL_DIR/"*.pem

echo ""
echo "✅ SSL Certificates generated in $SSL_DIR/"
echo "=========================================================="
