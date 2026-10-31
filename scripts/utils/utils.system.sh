#!/bin/bash
# utils.system.sh - System and Disk utilities for dbscripts

decypher_file()
{
    local encFile="${1:-}"
    local keyFile="${2:-/opt/mysql/.encrypted.cnf}"
    local outFile="${3:-$(echo "${encFile}" | sed -E 's/\.enc\.gz$//')}"
    local algo="${ENCRYPTED_ALGORITHM:-aes-256-cbc}"
    local gzip_cmd="${GZIP_CMD:-gzip}"
    local cdecat="zcat"
    [ "${gzip_cmd}" = "$(which pigz 2>/dev/null || true)" ] && cdecat="${gzip_cmd} -cd"

    [ -f "${encFile}" ] || return 1
    [ -f "${keyFile}" ] || return 1

    ([ -z "${outFile}" ] || [ "${encFile}" = "${outFile}" ] || ([ -e "${outFile}" ] && [ "${encFile}" -ef "${outFile}" ])) && return 1

    set -o pipefail
    ${cdecat} "${encFile}" | openssl "${algo}" -d -salt -kfile "${keyFile}" > "${outFile}"
    local rc=$?
    if [ ${rc} -eq 0 ] && [ -f "${outFile}" ]; then
        rm -f "${encFile}"
        return 0
    else
        rm -f "${outFile}"
        return 1
    fi
}

cypher_file()
{
    local inFile="${1:-}"
    local keyFile="${2:-/opt/mysql/.encrypted.cnf}"
    local outFile="${3:-${inFile}.enc.gz}"
    local algo="${ENCRYPTED_ALGORITHM:-aes-256-cbc}"
    local gzip_cmd="${GZIP_CMD:-gzip}"

    [ -f "${inFile}" ] || return 1
    [ -f "${keyFile}" ] || return 1

    ([ -z "${outFile}" ] || [ "${inFile}" = "${outFile}" ] || ([ -e "${outFile}" ] && [ "${inFile}" -ef "${outFile}" ])) && return 1

    set -o pipefail
    cat "${inFile}" | openssl "${algo}" -salt -kfile "${keyFile}" | ${gzip_cmd} > "${outFile}"
    local rc=$?
    if [ ${rc} -eq 0 ] && [ -s "${outFile}" ]; then
        rm -f "${inFile}"
        return 0
    else
        rm -f "${outFile}"
        return 1
    fi
}

createLogicalVolume() {
    vg=$1
    lv=$2
    lvsize=$3
    lvuser=$4
    lvhome=$5
    lvfstype=${6:-"ext4"}
    lvdisplay /dev/${vg}/${lv} &>/dev/null
    if [ $? -eq 0 ]; then
        echo "THE LOGICAL VOLUME /dev/${vg}/${lv} HAS BEEN ALREADY CREATED"
        return 1
    fi

    echo "CREATING LOGICAL VOLUME /dev/${vg}/${lv} (SIZE : ${lvsize}) ..."
    mkdir -p ${lvhome}

    if echo "${lvsize}" | grep -q "%"
    then
        lvcreate -l${lvsize} -n ${lv} ${vg}
    else
        lvcreate -L${lvsize} -n ${lv} ${vg}
    fi

    mkfs.${lvfstype} /dev/${vg}/${lv}
    mount /dev/${vg}/${lv} ${lvhome}
    chown ${lvuser}: ${lvhome}
    chmod 755 ${lvhome}

    # Options de montage
    option="${lvfstype}    defaults        0       2"
    if echo "${lvhome}" | grep -q "/home\|/tmp\|/var/log/audit"
    then
        option="${lvfstype}    nosuid,nodev,noexec        0       2"
    elif echo "${lvhome}" | grep -q "/var"
    then
        option="${lvfstype}    nosuid,nodev        0       2"
        if echo "${lvhome}" | grep -q "/var/log"
        then
            option="${lvfstype}    defaults        0       2"
        fi
    fi

    [ `grep -c "^/dev/${vg}/${lv}" /etc/fstab` = 0 ] && \
    echo "/dev/${vg}/${lv}        ${lvhome}       ${option}">>/etc/fstab

    lvdisplay /dev/${vg}/${lv} &>/dev/null
    if [ $? -ne 0 ]; then
        echo "[ERROR] CREATE LOGICAL VOLUME /dev/${vg}/${lv} : NOK"
        return 1
    fi

    echo "[INFO] CREATE LOGICAL VOLUME /dev/${vg}/${lv} : OK"
    return 0
}

check_all_nrpe_conf()
{
    local lFilter=${1:-'.*'}
    lRC=0
    tmpRc=0
    grep 'command\[check_' /etc/nagios/nrpe.cfg /etc/nagios/nrpe.d/*| cut -d\] -f1| cut -d\[ -f2 | grep -E "$lFilter" | while IFS= read -r line; do
        echo "---------------------------------------------------------"
        echo "$line"
        echo "---------------------------------------------------------"
        /usr/lib64/nagios/plugins/check_nrpe -4 -H 127.0.0.1 -c $line
        tmpRc=$?
        if [ $tmpRc -ne 0 ]; then
            error "CHECKING $line => FAILED"
        else
            info "CHECKING $line => OK"
        fi
        lRC=$((lRC + $tmpRc))
        echo ""
        echo ""

    done
}

# Non-fatal compatibility shim for legacy 'is' assertions
is() {
    case "${1:-}" in
        not) shift; ! is "$@" ;;
        user) [ "$(whoami)" = "${2:-}" ] ;;
        eq*) [ "${2:-}" = "${3:-}" ] ;;
        empty) [ -z "${2:-}" ] ;;
        number) echo "${2:-}" | grep -qE '^[0-9]+(\.[0-9]+)?$' ;;
        *port*) netstat -ltn 2>/dev/null | grep -E ":${2:-}\s" | grep -q 'LISTEN' ;;
        file) [ -f "${2:-}" ] ;;
        dir*) [ -d "${2:-}" ] ;;
        *) return 1 ;;
    esac
}
