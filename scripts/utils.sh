#!/bin/bash
# utils.sh - Unified entry point for dbscripts utilities

# 1. Environment and Context Detection
if [ "$0" != "-bash" -a "$0" != "/bin/bash" -a "$0" != "/bin/sh" -a "$0" != "-bash" -a "$0" != "bash" -a "$0" != "-su" ]; then
    _DIR="$(dirname "$(readlink -f "$0")")"
    _NAME="$(basename "$(readlink -f "$0")")"
    _CONF_FILE=$(readlink -f "${_DIR}/../etc/$(basename ${_NAME} .sh).conf")
    if [ -f "$_CONF_FILE" ];then
        source $_CONF_FILE
    else
        mkdir -p $(dirname "$_CONF_FILE")
    fi
else
    _DIR="$(readlink -f ".")"
    _NAME="INLINE SHELL"
    IS_SHELL_CONTEXT=1
fi
[ -f '/etc/os-release' ] && source /etc/os-release
export LC_ALL="C"
HA_SOCKET=/tmp/admin.sock

export PATH=$PATH:/opt/local/bin:/opt/local/MySQLTuner-perl:.
export DEBIAN_FRONTEND=noninteractive

# 2. Source modular utilities
_UTILS_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/utils"
[ -f "$_UTILS_DIR/utils.network.sh" ] && source "$_UTILS_DIR/utils.network.sh"
[ -f "$_UTILS_DIR/utils.timer.sh" ] && source "$_UTILS_DIR/utils.timer.sh"
[ -f "$_UTILS_DIR/utils.git.sh" ] && source "$_UTILS_DIR/utils.git.sh"
[ -f "$_UTILS_DIR/utils.system.sh" ] && source "$_UTILS_DIR/utils.system.sh"
[ -f "$_UTILS_DIR/utils.mysql.sh" ] && source "$_UTILS_DIR/utils.mysql.sh"
[ -f "$_UTILS_DIR/utils.pgsql.sh" ] && source "$_UTILS_DIR/utils.pgsql.sh"
[ -f "$_UTILS_DIR/utils.mongodb.sh" ] && source "$_UTILS_DIR/utils.mongodb.sh"

# 3. Essential Core Functions (Minimal footprint)
now() { echo "$(date "+%F %T %Z")($(hostname -s))"; }
to_lower() { echo "$*" | tr '[:upper:]' '[:lower:]'; }
to_upper() { echo "$*" | tr '[:lower:]' '[:upper:]'; }
reverse_rc() {
    [ "$1" = "0" ] && { echo "26"; return 26; }
    echo "0"; return 0
}

# 4. Core Logger / Output
error() {
    local lRC=$?
    echo "$(now) ERROR: $*" 1>&2
    [ -n "${TEE_LOG_FILE:-}" ] && echo "$(now) ERROR: $*">>$TEE_LOG_FILE
    return $lRC
}
die() { error "$*"; exit 1; }
info() {
    [ "${quiet:-}" != "yes" ] && echo "$(now) INFO: $*" 1>&2
    [ -n "${TEE_LOG_FILE:-}" ] && echo "$(now) INFO: $*">>$TEE_LOG_FILE
    return 0
}
debug() {
    [ "${DEBUG:-}" = "1" ] || return 0
    [ "${quiet:-}" != "yes" ] && echo "$(now) DEBUG: $*" 1>&2
    [ -n "${TEE_LOG_FILE:-}" ] && echo "$(now) DEBUG: $*">>$TEE_LOG_FILE
    return 0
}
ok() { info "[SUCCESS]  $*  [SUCCESS]"; }
warn() {
    local lRC=$?
    echo "$(now) WARNING: $*" 1>&2
    [ -n "${TEE_LOG_FILE:-}" ] && echo "$(now) WARNING: $*">>$TEE_LOG_FILE
    return $lRC
}
sep1() {
    echo "$(now) -----------------------------------------------------------------------------" 1>&2
    [ -n "${TEE_LOG_FILE:-}" ] && echo "$(now) -----------------------------------------------------------------------------" >>$TEE_LOG_FILE
}
title1() { sep1; echo "$(now) $*" 1>&2; [ -n "${TEE_LOG_FILE:-}" ] && echo "$(now) $*">>$TEE_LOG_FILE; sep1; }
banner() { start_timer; title1 "START: $*"; info " run as $(whoami)@$(hostname -s)"; }
footer() {
    local lRC=${lRC:-"$?"}
    dump_timer
    info "FINAL CODE RETOUR: $lRC"
    [ $lRC -eq 0 ] && title1 "END: $* ENDED SUCCESSFULLY" || title1 "END: $* ENDED WITH WARNING OR ERROR"
    return $lRC
}

# 5. Core Command Execution
cmd() {
    local cRC=0
    local tcmd="$1"
    local descr=${2:-"$tcmd"}
    title1 "$descr"; info "RUNNING COMMAND: $tcmd"; sep1
    $tcmd; cRC=$?
    info "RETURN CODE: $cRC"
    [ $cRC -eq 0 ] && ok "$descr" || error "$descr"
    sep1; return $cRC
}

# 6. Basic Helpers
ask_yes_or_no() {
    read -p "$1 ([y]es or [n]o): "
    case $(echo $REPLY | tr '[A-Z]' '[a-z]') in
        y|Y|yes) echo "yes";return 0 ;;
        *)     echo "no"; return 1;;
    esac
}
get_val() { eval "echo \$${1}"; }
set_val() { eval "${1}='${2}'"; }

rl() {
    unset UTILS_MYSQL_IS_LOADED UTILS_IS_LOADED
    [ -f "/etc/profile.d/utils.sh" ] && source /etc/profile.d/utils.sh
}

UTILS_IS_LOADED="1"
