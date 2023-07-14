#!/bin/sh
set -o errexit
set -o nounset
set -o pipefail

if [ ! "$1" ] ; then
    echo "Usage: $0 [user@]<dest_server>[:port] [~/.ssh/proxies.lst]"
    exit 1
fi

SSH_TIMEOUT=3

DEST_USER=$(echo $1 | cut -d '@' -f 1 -s)
DEST_ADDR=$(echo $1 | cut -d '@' -f 2 | cut -d ':' -f 1)
DEST_PORT=$(echo $1 | cut -d ':' -f 2 -s)

PROXIES_FILE=${2:-"~/.ssh/proxies.lst"}
PROXY_CACHE=${PROXIES_FILE:-"~/.ssh/known_proxy"}

if [ ! "$DEST_USER" ]; then
    DEST_USER=$(whoami)
fi
if [ ! "$DEST_PORT" ]; then
    DEST_PORT="22"
fi

# look for proxy in cache
# Proxy cache format: <user>@<proxy>:<port> proxy_ip
get_proxy_from_cache() {
    if [ -f "$PROXY_CACHE" ]; then
        grep -E "^$1 " "$PROXY_CACHE" | cut -d ' ' -f 2
        return 
    fi
    echo ""
    return 1
}

get_proxies_list() {
    if [ -f "$PROXIES_FILE" ]; then
        cat $PROXIES_FILE
        return 0
    fi
    echo ""
    return 1
}

# get_host_ip <host>
get_host_ip() {
    host "$1" | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -n 1
}

test_direct_connection() {
    ssh -F /dev/null -o ConnectTimeout=$SSH_TIMEOUT "$1" exit
}

test_proxy_connection() {
    local tip=$1
    local pip=$2
    ssh -F /dev/null -o ConnectTimeout=$SSH_TIMEOUT -o "ProxyCommand=ssh -o ConnectTimeout=$SSH_TIMEOUT $pip"  "$tip" exit
}

DEST_IP=$(get_host_ip "$DEST_ADDR")

if test_direct_connection "$DEST_IP"; then
    echo "Direct connection to $DEST_IP is possible"
    exec nc $DEST_IP $DEST_PORT
    exit 0
fi

PROXY_FROM_CACHE=$(get_proxy_from_cache "$DEST_USER@$DEST_ADDR:$DEST_PORT")

TARGET_PROXY=""
[ -n "$PROXY_FROM_CACHE" ] && TARGET_PROXY="$PROXY_FROM_CACHE"

if [ -z "$TARGET_PROXY" ]; then
    PROXIES_LIST=$(get_proxies_list)
    if [ -n "$PROXIES_LIST" ]; then
        for proxy in $PROXIES_LIST; do
            proxy_ip=$(get_host_ip "$proxy")
            if test_proxy_connection "$DEST_IP" "$proxy_ip"; then
                TARGET_PROXY="$proxy_ip"
                break
            fi
        done
    fi
fi

if [ -z "$TARGET_PROXY" ]; then
    echo "No proxy found for $DEST_ADDR"
    exit 1
fi
echo "SUCCESS: Found good proxy $TARGET_PROXY for $DEST_ADDR($DEST_IP)"
ssh -o ConnectTimeout=$SSH_TIMEOUT -o "ProxyCommand=ssh -o ConnectTimeout=$SSH_TIMEOUT $DEST_USER@$TARGET_PROXY
