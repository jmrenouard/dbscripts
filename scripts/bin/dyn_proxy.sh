#!/bin/bash
#set -o errexit
#set -o nounset
#set -o pipefail
#set -x
if [ -z "$1" ] ; then
    echo "Usage: $0 [user@]<dest_server>[:port] [~/.ssh/proxies.lst]"
    exit 1
fi

SSH_TIMEOUT=5


DEST_USER=$(echo $1 | cut -d '@' -f 1 -s)
DEST_ADDR=$(echo $1 | cut -d '@' -f 2 | cut -d ':' -f 1)
DEST_PORT=$(echo $1 | cut -d ':' -f 2 -s)

if [ ! "$DEST_USER" ]; then
    DEST_USER=$(whoami)
fi
if [ ! "$DEST_ADDR" ]; then
    DEST_ADDR="127.0.0.1"
fi

if [ ! "$DEST_PORT" ]; then
    DEST_PORT="22"
fi

PROXIES_FILE=${2:-"/home/$(whoami)/.ssh/proxies.lst"}
PROXY_CACHE=${PROXIES_FILE}.cache

# look for proxy in cache
# Proxy cache format: dest_ip proxy_ip
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
    ssh -q -F /dev/null -o UserKnownHostsFile=/dev/null -o "StrictHostKeyChecking=no" -o ConnectTimeout=$SSH_TIMEOUT "$1" exit &>/dev/null
}

test_proxy_connection() {
    local tip=$1
    local pip=$2
    ssh -q -F /dev/null -o ConnectTimeout=$SSH_TIMEOUT -o UserKnownHostsFile=/dev/null -o "StrictHostKeyChecking=no" -o "ProxyCommand=ssh -W %h:%p -o ConnectTimeout=$SSH_TIMEOUT $pip"  "$tip" exit &>/dev/null
    return $?
}

find_proxy() {
    local DEST_IP=$1
    local DEST_ADDR=$2
    PROXIES_LIST=$(get_proxies_list)
    if [ -n "$PROXIES_LIST" ]; then
        for proxy_ip in $PROXIES_LIST; do
            if test_proxy_connection "$DEST_IP" "$proxy_ip"; then
                echo "$proxy_ip"
                echo "$DEST_IP $proxy_ip" >> "$PROXY_CACHE"
                echo "$DEST_ADDR $proxy_ip" >> "$PROXY_CACHE"
                return 0
            fi
        done
    fi
    echo ""
}

if [ "$1" = "testproxies" ]; then
    for proxy_ip in $(get_proxies_list); do
        echo -n "Testing proxy $proxy_ip"
        if test_direct_connection  "$proxy_ip"; then
            echo " [SUCCESS]"
        else 
            echo " [FAILED]"
        fi
    done
    exit 0
fi


if [ "$1" = "update" ]; then
    for hst in $(grep -E ".aws$" /etc/hosts | awk '{print $2}') $(grep -E "\saws" /etc/hosts | awk '{print $2}'); do 
        if ! grep "$hst" $PROXY_CACHE; then
            find_proxy "$(get_host_ip $hst)" "$hst"
        fi
    done
    exit 0
fi

DEST_IP=$(get_host_ip "$DEST_ADDR")

PROXY_FROM_CACHE=$(get_proxy_from_cache "$DEST_ADDR")
[ -z "$PROXY_FROM_CACHE" ] && PROXY_FROM_CACHE=$(get_proxy_from_cache "$DEST_IP")

TARGET_PROXY=""
[ -n "$PROXY_FROM_CACHE" ] && TARGET_PROXY="$PROXY_FROM_CACHE"

if [ "$TARGET_PROXY" = "" ]; then
    if test_direct_connection "$DEST_IP"; then
        #echo "Direct connection to $DEST_IP is possible"
        exec nc $DEST_IP $DEST_PORT
        exit 0
    fi
fi

[ -z "$TARGET_PROXY" ] && TARGET_PROXY=$(find_proxy "$DEST_IP" "$DEST_ADDR")

if [ -z "$TARGET_PROXY" ]; then
    echo "No proxy found for $DEST_ADDR"
    exit 1
fi
#echo "SUCCESS: Found good proxy $TARGET_PROXY for $DEST_ADDR($DEST_IP)"
exec ssh -q -F /dev/null -W $DEST_IP:$DEST_PORT -o UserKnownHostsFile=/dev/null -o ConnectTimeout=$SSH_TIMEOUT -o "StrictHostKeyChecking=no" $DEST_USER@$TARGET_PROXY