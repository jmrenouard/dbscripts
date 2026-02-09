#!/bin/bash
# utils.system.sh - System and Disk utilities for dbscripts

decypher_file()
{
    cdecat="zcat"
    [ "$GZIP_CMD" = "$(which pigz)" ] && cdecat="$GZIP_CMD -cd"
    local encFile=$1
    local keyFile=${2:-"/opt/mysql/.encrypted.cnf"}

    [ -f "$1" ] || return 1

    local outFile=${3:-"$(echo $encFile | sed -E 's/\.enc\.gz$//')"}
    [ -z "$ENCRPYTED_ALGORITHM" ] && ENCRPYTED_ALGORITHM="aes-256-cbc"
    $cdecat $encFile | openssl $ENCRPYTED_ALGORITHM -d -salt -kfile "$keyFile" > $outFile
    [ $? -eq 0 ] && rm -f $encFile
}

cypher_file()
{
    local inFile=$1
    local keyFile=${2:-"/opt/mysql/.encrypted.cnf"}
    local outFile=${3:-"${inFile}.enc.gz"}

    [ -f "$1" ] || return 1

    [ -z "$ENCRPYTED_ALGORITHM" ] && ENCRPYTED_ALGORITHM="aes-256-cbc"

    cat $inFile | openssl $ENCRPYTED_ALGORITHM -salt -kfile "$keyFile" | $GZIP_CMD >> $outFile
    [ $? -eq 0 ] && rm -f $inFile
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

    if $(grep -q "%" <<< "${lvsize}")
    then
        lvcreate -L${lvsize} -n ${lv} ${vg}
    else
        lvcreate -l${lvsize} -n ${lv} ${vg}
    fi

    mkfs.${lvfstype} /dev/${vg}/${lv}
    mount /dev/${vg}/${lv} ${lvhome}
    chown ${lvuser}: ${lvhome}
    chmod 755 ${lvhome}

    # Options de montage
    if $(grep -q "/home\|/tmp\|/var/log/audit" <<< "${lvhome}")
    then
        option="${lvfstype}    nosuid,nodev,noexec        0       2"
    elif $(grep -q "/var" <<< "${lvhome}")
    then
        option="${lvfstype}    nosuid,nodev        0       2"
        if $(grep -q "/var/log" <<< "${lvhome}")
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
