#!/bin/bash

_DIR="$(dirname "$(readlink -f "$0")")"
source $_DIR/utils.sh
alias use='psql'

rl()
{
    [ -f "/etc/profile.d/utils.sh" ] && source /etc/profile.d/utils.sh
    chsh -s /bin/bash root
}

## Code PostgreSQL
pg_status()
{
    local lRC=0
    $SSH_CMD pg_isready 2>&1 | grep -qiE 'accepting connections'
    lRC=$?
    if [ $lRC -eq 0 ]; then
        ok "PostgreSQL server is running ...."
        return 0
    fi
    error "PostgreSQL server is stopped ...."
    return 1
}

pgGetVal()
{
    get_val $*
}

pgSetVal()
{
    set_val $*
}

