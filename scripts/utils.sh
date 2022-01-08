#!/bin/bash

if [ "$0" != "/bin/bash" -a "$0" != "/bin/sh" -a "$0" != "-bash" -a "$0" != "bash" -a "$0" != "-su" ]; then
    _DIR="$(dirname "$(readlink -f "$0")")"
    _NAME="$(basename "$(readlink -f "$0")")"
    _CONF_FILE=$(readlink -f "${_DIR}/../etc/$(basename ${_NAME} .sh).conf")
    if [ -f "$_CONF_FILE" ];then
        source $_CONF_FILE
    else
        mkdir -p $(dirname "$_CONF_FILE")
        #echo "# Config for $_NAME SCRIPT at $(date)" | tee -a $_CONF_FILE
    fi
else
    _DIR="$(readlink -f ".")"
    _NAME="INLINE SHELL"
fi
[ -f '/etc/os-release' ] && source /etc/os-release
export LC_ALL="C"
HA_SOCKET=/tmp/admin.sock

export PATH=$PATH:/opt/local/bin:/opt/local/MySQLTuner-perl:.

export my_private_ipv4=$(ip a | grep inet | grep 'brd' | grep '192.168'| cut -d/ -f1 | awk '{print $2}')
export my_public_ipv4=$(ip a | grep inet | grep 'brd' | grep -v '192.168'| cut -d/ -f1 | awk '{print $2}')

export DEBIAN_FRONTEND=noninteractive
SSH_CLIENT="ssh -q -o TCPKeepAlive=yes -o ServerAliveInterval=50 -o strictHostKeyChecking=no"
SCP_CLIENT="scp -q -o TCPKeepAlive=yes -o ServerAliveInterval=50 -o strictHostKeyChecking=no"

# Some Alias
alias h=history
alias s=sudo
alias rsh='ssh -l root'
alias lh='ls -lsh'
alias ll='ls -ls'
alias la='ls -lsa'

alias gst='git status'
alias grm='git rm -f'
alias gadd='git add'
alias gcm='git commit -m'
alias gps='git push'
alias gpl='git pull'
alias glg='git log'
alias gmh='git log --follow -p --'
alias gbl='git blame'
alias grs='git reset --soft HEAD~1'
alias grh='git reset --hard HEAD~1'

is() {
    if [ "$1" == "--help" ]; then
        cat << EOF
Conditions:
  is equal VALUE_A VALUE_B
  is matching REGEXP VALUE
  is substring VALUE_A VALUE_B
  is empty VALUE
  is number VALUE
  is gt NUMBER_A NUMBER_B
  is lt NUMBER_A NUMBER_B
  is ge NUMBER_A NUMBER_B
  is le NUMBER_A NUMBER_B
  is file PATH
  is dir PATH
  is link PATH
  is existing PATH
  is readable PATH
  is writeable PATH
  is executable PATH
  is available COMMAND
  is older PATH_A PATH_B
  is newer PATH_A PATH_B
  is true VALUE
  is false VALUE
  is fowner PATH USER
  is fgroup  PATH GROUP
  is fmountpoint PATH MOUNTPOINT
  is fempty PATH
  is fsize PATH BYTE_SIZE
  is fsizelt PATH$path BYTE_SIZE
  is fsizegt PATH$path BYTE_SIZE
  is forights PATH OCTALRIGHTS
  is fuser USER
  is tcp_port PORTNUMBER

Negation:
  is not equal VALUE_A VALUE_B

Optional article:
  is not a number VALUE
  is an existing PATH
  is the file PATH
EOF
        exit
    fi

    if [ "$1" == "--version" ]; then
        echo "is.sh 1.1.0"
        exit
    fi

    local condition="$1"
    local value_a="$2"
    local value_b="$3"

    if [ "$condition" == "not" ]; then
        shift 1
        ! is "${@}"
        return $?
    fi

    if [ "$condition" == "a" ] || [ "$condition" == "an" ] || [ "$condition" == "the" ]; then
        shift 1
        is "${@}"
        return $?
    fi

    case "$condition" in
        file)
            [ -f "$value_a" ]; return $?;;
        dir|directory)
            [ -d "$value_a" ]; return $?;;
        link|symlink)
            [ -L "$value_a" ]; return $?;;
        existent|existing|exist|exists)
            [ -e "$value_a" ]; return $?;;
        readable)
            [ -r "$value_a" ]; return $?;;
        writeable)
            [ -w "$value_a" ]; return $?;;
        executable)
            [ -x "$value_a" ]; return $?;;
        available|installed)
            which "$value_a"; return $?;;
        tcp_port_open|tcp_port|tport)
            netstat -ltn | grep -E ":${value_a}\s" | grep -q 'LISTEN'; return $?;;
        fowner|fuser)
            [ "$(stat -c %U $value_a)" = "$value_b" ]; return $?;;
        fgroup)
            [ "$(stat -c %G $value_a)" = "$value_b" ]; return $?;;
        fmountpoint)
            [ "$(stat -c %m $value_a)" = "$value_b" ]; return $?;;
        fempty)
            [ "$(stat -c %s $value_a)" = "0" ]; return $?;;
        fsize)
            [ $(stat -c %s $value_a) -eq $value_b ]; return $?;;
        fsizelt)
            [ $(stat -c %s $value_a) -lt $value_b ]; return $?;;
        fsizegt)
            [ $(stat -c %s $value_a) -gt $value_b ]; return $?;;
        forights)
            [ "$(stat -c %a $value_a)" = "$value_b" ]; return $?;;
        fagegt)
            [ $(fileAge $value_a) -gt $value_b ]; return  $?;;
        fagelt)
            [ $(fileAge $value_a) -lt $value_b ]; return  $?;;
        fmagegt)
            [ $(fileMinAge $value_a) -gt $value_b ]; return  $?;;
        fmagelt)
            [ $(fileMinAge $value_a) -lt $value_b ]; return  $?;;
        fhagegt)
            [ $(fileHourAge $value_a) -gt $value_b ]; return  $?;;
        fhagelt)
            [ $(fileHourAge $value_a) -lt $value_b ]; return  $?;;
        fdagegt)
            [ $(fileDayAge $value_a) -gt $value_b ]; return  $?;;
        fdagelt)
            [ $(fileDayAge $value_a) -lt $value_b ]; return  $?;;
        fcontains)
            shift;
            grep -q "$*" $value_a
            return  $?
            ;;
        user)
            is eq $(whoami) $value_a; return $?;;
        empty)
            [ -z "$value_a" ]; return $?;;
        number)
            echo "$value_a" | grep -E '^[0-9]+(\.[0-9]+)?$'; return $?;;
        older)
            [ "$value_a" -ot "$value_b" ]; return $?;;
        newer)
            [ "$value_a" -nt "$value_b" ]; return $?;;
        gt)
            is not a number "$value_a"      && return 1;
            is not a number "$value_b"      && return 1;
            awk "BEGIN {exit $value_a > $value_b ? 0 : 1}"; return $?;;
        lt)
            is not a number "$value_a"      && return 1;
            is not a number "$value_b"      && return 1;
            awk "BEGIN {exit $value_a < $value_b ? 0 : 1}"; return $?;;
        ge)
            is not a number "$value_a"      && return 1;
            is not a number "$value_b"      && return 1;
            awk "BEGIN {exit $value_a >= $value_b ? 0 : 1}"; return $?;;
        le)
            is not a number "$value_a"      && return 1;
            is not a number "$value_b"      && return 1;
            awk "BEGIN {exit $value_a <= $value_b ? 0 : 1}"; return $?;;
        eq|equal)
            [ "$value_a" = "$value_b" ]     && return 0;
            is not a number "$value_a"      && return 1;
            is not a number "$value_b"      && return 1;
            awk "BEGIN {exit $value_a == $value_b ? 0 : 1}"; return $?;;
        match|matching)
            echo "$value_b" | grep -xE "$value_a"; return $?;;
        substr|substring)
            echo "$value_b" | grep -F "$value_a"; return $?;;
        true)
            [ "$value_a" == true ] || [ "$value_a" == 0 ]; return $?;;
        false)
            [ "$value_a" != true ] && [ "$value_a" != 0 ]; return $?;;
    esac > /dev/null

    return 1
}

now() {
    # echo "$(date "+%F %T %Z")"
    echo "$(date "+%F %T %Z")($(hostname -s))"
}


to_lower()
{
    echo "$*" | tr '[:upper:]' '[:lower:]'
}

to_upper()
{
    echo "$*" | tr '[:lower:]' '[:upper:]'
}

reverse_rc()
{
    local lrc=$1
    if [ "$lrc" = "0" ]; then
        echo "26"
        return 26
    fi
    echo "0"
    return 0

}


################################################################################
start_timer()
{
    local LABEL=${1:-"GENERIC"}
    eval "export START_TIME_$LABEL=$(date +%s);"
}

update_timer()
{
    local LAST_RC=$?
    local LABEL=${1:-"GENERIC"}
    [ "$LABEL" = "GENERIC" ] || shift;

    eval "export STOP_TIME_$LABEL=$(date +%s);"
    eval "local STOP_TIME=\$STOP_TIME_$LABEL;"
    eval "local START_TIME=\$START_TIME_$LABEL;"
    debug "START_TIME $LABEL = $(get_val START_TIME_$LABEL)"
    debug "STOP_TIME $LABEL = $(get_val STOP_TIME_$LABEL)"
    debug "START_TIME = $(get_val START_TIME)"
    debug "STOP_TIME  = $(get_val STOP_TIME)"
    local STR_RESULT=$(echo $(($STOP_TIME-$START_TIME)) | awk '{printf "%02dh:%02dm:%02ds",$1/3600,$1%3600/60,$1%60}')
    eval "export START_TIME_$LABEL=\$STOP_TIME_$LABEL;"

    eval "export LAST_DURATION_$LABEL=\$STR_RESULT;"
    debug "LAST DURATION $LABEL = $(get_val LAST_DURATION_$LABEL)"
    return $LAST_RC
}

reset_all_timers()
{
    unset $(env| grep START_TIME|cut -d= -f 1| xargs)
    unset $(env| grep LAST_DURATION|cut -d= -f 1| xargs)
}

reset_timer()
{
    local LABEL=${1:-"GENERIC"}
    unset $(env| grep "START_TIME_$LABEL"|cut -d= -f 1| xargs)
    unset $(env| grep "LAST_DURATION_$LABEL"|cut -d= -f 1| xargs)
}

dump_timer()
{
    local LABEL=${1:-"GENERIC"}
    env| grep "START_TIME_$LABEL"
    env| grep "LAST_DURATION_$LABEL"
}

get_timer_duration()
{
    local LAST_RC=$?
    local LABEL=${1:-"GENERIC"}
    eval "local LAST_DURATION=\$LAST_DURATION_$LABEL;"
    if [ -z "$LAST_DURATION" ]; then
        echo "NO '$LABEL' DURATION"
    else
        echo $LAST_DURATION
    fi
    return $LAST_RC
}

get_timer_start_date()
{
    local LAST_RC=$?
    local LABEL=${1:-"GENERIC"}
    local result=$(get_val START_TIME_$LABEL)
    if [ -z "$result" ]; then
        echo "NO START DATE FOR $LABEL label"
    else
        echo $result
    fi
    return $LAST_RC
}

get_timer_stop_date()
{
    local LAST_RC=$?
    local LABEL=${1:-"GENERIC"}
    local result=$(get_val STOP_TIME_$LABEL)
    if [ -z "$result" ]; then
        echo "NO STOP DATE FOR $LABEL label"
    else
        echo $result
    fi
    return $LAST_RC
}

dump_timer()
{
    local LAST_RC=$?
    local LABEL=${1:-"GENERIC"}
    info "START DATE($LABEL): $(printf "%(%F %T %Z)T" $(get_timer_start_date $LABEL))"
    update_timer $LABEL
    info "STOP DATE($LABEL) : $(printf "%(%F %T %Z)T" $(get_timer_stop_date $LABEL))"
    info "DURATION($LABEL)  : $(get_timer_duration $LABEL)"

    return $LAST_RC
}

trim_len()
{
    local l=$1
    shift
    echo -n $* | head -c $l
    echo "..."
}

error() {
    local lRC=$?
    echo "$(now) ERROR: $*" 1>&2
    [ -n "$TEE_LOG_FILE" ] && echo "$(now) ERROR: $*">>$TEE_LOG_FILE
    return $lRC
}

die() {
    error $*
    exit 1
}

info() {
    [ "$quiet" != "yes" ] && echo "$(now) INFO: $*" 1>&2
    [ -n "$TEE_LOG_FILE" ] && echo "$(now) INFO: $*">>$TEE_LOG_FILE
    return 0
}

debug() {
    [ "$DEBUG" = "1" ] || return 0
    [ "$quiet" != "yes" ] && echo "$(now) DEBUG: $*" 1>&2
    [ -n "$TEE_LOG_FILE" ] && echo "$(now) DEBUG: $*">>$TEE_LOG_FILE
    return 0
}

ok()
{
    info "[SUCCESS]  $*  [SUCCESS]"
    return $?
}

warn() {
    local lRC=$?
    echo "$(now) WARNING: $*" 1>&2
    [ -n "$TEE_LOG_FILE" ] && echo "$(now) WARNING: $*">>$TEE_LOG_FILE
    return $lRC
}

warning()
{
    warn "$*"
}
sep1()
{
    echo "$(now) -----------------------------------------------------------------------------" 1>&2
    [ -n "$TEE_LOG_FILE" ] && echo "$(now) -----------------------------------------------------------------------------" >>$TEE_LOG_FILE
}
sep2()
{
    echo "$(now) _____________________________________________________________________________" 1>&2
    [ -n "$TEE_LOG_FILE" ] && echo "$(now) _____________________________________________________________________________" >>$TEE_LOG_FILE
}
title1() {
    sep1
    echo "$(now) $*" 1>&2
    [ -n "$TEE_LOG_FILE" ] && echo "$(now) $*">>$TEE_LOG_FILE
    sep1
}

title2()
{
    echo "$(now) $*" 1>&2
    [ -n "$TEE_LOG_FILE" ] && echo "$(now) $*">>$TEE_LOG_FILE
    sep2
}
banner()
{
    start_timer
    title1 "START: $*"
    info " run as $(whoami)@$(hostname -s)"
}

footer()
{
    local lRC=${lRC:-"$?"}
    dump_timer
    info "FINAL CODE RETOUR: $lRC"
    [ $lRC -eq 0 ] && title1 "END: $* ENDED SUCCESSFULLY"
    [ $lRC -eq 0 ] || title1 "END: $* ENDED WITH WARNING OR ERROR"
    return $lRC
}

cmd()
{
    local cRC=0
    local tcmd="$1"
    local descr=${2:-"$tcmd"}
    if [ -z "$2" ]; then
        title1 "RUNNING COMMAND: $(trim_len 25 $tcmd)"
    else
        title1 "$descr"
        info "RUNNING COMMAND: $(trim_len 25 $tcmd)"
        sep1
    fi
    $tcmd
    cRC=$?
    info "RETURN CODE: $cRC"
    if [ $cRC -eq 0 ]; then
        ok "$descr"
    else
        error "$descr"
    fi
    sep1
    return $cRC
}

info_cmd()
{
    local cRC=0
    local tcmd="$1"
    if [ -z "$2" ]; then
        title1 "RUNNING COMMAND: $(trim_len 25 $tcmd)"
    else
        title1 "$descr"
        info "RUNNING COMMAND: $(trim_len 25 $tcmd)"
        sep1
    fi
    eval "$tcmd 2>&1" | while read -r line;do
      info ">> $(trim_len 40 $line)"
    done
    cRC=$?
    info "RETURN CODE: $cRC"
    if [ $cRC -eq 0 ]; then
        ok "$(trim_len 25 $tcmd)"
    else
        error "$(trim_len 25 $tcmd)"
    fi
    sep1
    return $cRC
}

function ask_yes_or_no() {
    read -p "$1 ([y]es or [n]o): "
    case $(echo $REPLY | tr '[A-Z]' '[a-z]') in
        y|Y|yes) echo "yes";return 0 ;;
        *)     echo "no"; return 1;;
    esac
    return 1
}

pauseenter()
{
    read -p "Press Enter to continue" </dev/tty
}

get_val()
{
    local value=$1
    echo $(eval "echo \$${value}")
}

set_val()
{
    local var=$1
    shift
    eval "${var}='$*'"
}


rl()
{
    [ -f "/etc/profile.d/utils.sh" ] && source /etc/profile.d/utils.sh
    chsh -s /bin/bash root
}
#----------------------------------------------------------------------------------------------------
# Create the logical volume and the file system
#----------------------------------------------------------------------------------------------------
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



which python &>/dev/null
if [ $? -eq 0 ]; then
    python --version 2>/dev/null| grep -q 'Python 3'
    if [ $? -eq 0 ]; then
        alias serve="python -m $(python -c 'import sys; print("http.server" if sys.version_info[:2] > (2,7) else "SimpleHTTPServer")')"
    else
        alias serve="python3 -m $(python3 -c 'import sys; print("http.server" if sys.version_info[:2] > (2,7) else "SimpleHTTPServer")')"
    fi
fi

gunt() {
    git status | \
    grep -vE '(Changes to be committed:| to publish your local commits|git add|git restore|On branch|Your branch|Untracked files|nclude in what will b|but untracked files present|no changes added to commit|modified:|deleted:|Changes not staged for commit)' |\
    sort | uniq | \
    xargs -n 1 $*
}

gam() {
    git status | \
    grep 'modified:' | \
    cut -d: -f2- | \
    sort | uniq | \
    xargs -n 1 git add
}

gad() {
    git status | \
    grep 'deleted:' | \
    cut -d: -f2- | \
    sort | uniq | \
    xargs -n 1 git rm -f
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

ha_status()
{
    local param=${1:-"info"}
    echo "show $param" |  socat unix-connect:$HA_SOCKET stdio
}
ha_states()
{
   (echo -e "NAME TYPE STATE"
    echo "show stat" |  socat unix-connect:$HA_SOCKET stdio| cut -d, -f1,2,18 | tr ',' '\t'| sort -k 3| grep -ve '^#'
    )|column -t
}
ha_disable()
{
    echo "disable server ${1:-"galera/node1"}" |  socat unix-connect:$HA_SOCKET stdio
}
ha_enable()
{
    echo "enable server ${1:-"galera/node1"}" |  socat unix-connect:$HA_SOCKET stdio
}

ssh_exec()
{
    local lsrv=$1
    local lRC=0
    shift

    for fcmd in $*; do
        if [ ! -f "$fcmd" ]; then
            error "$fcmd Not exists"
            return 127
        fi
        INTERPRETER=$(head -n 1 $fcmd | sed -e 's/#!//')

        for srv in $(echo $lsrv | perl -pe 's/[, :]/\n/g'); do
            title2 "RUNNING SCRIPT $(basename $fcmd) ON $srv SERVER"
            (echo "[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh";echo;cat $fcmd) | grep -v "#!" | ssh -T root@$srv -i ${DEFAULT_PRIVATE_KEY:-"/root/.ssh/id_rsa"} $INTERPRETER
            footer "RUNNING SCRIPT $(basename $fcmd) ON $srv SERVER"
            lRC=$(($lRC + $?))
        done
    done
    return $lRC
}

ssh_cmd()
{
    local lsrv=$1
    local lRC=0
    local fcmd=$2
    local silent=$3

    for srv in $(echo $lsrv | perl -pe 's/[, :]/\n/g'); do
        [ -z "$silent" ] && title2 "RUNNING SCRIPT $fcmd ON $srv($vip) SERVER"
        [ -n "$silent" ] && echo -ne "$srv\t$fcmd\t"
        ssh -T root@$srv -i ${DEFAULT_PRIVATE_KEY:-"/root/.ssh/id_rsa"} "$fcmd"
        lRC=$(($lRC + $?))
        [ -n "$silent" ] && echo
        [ -z "$silent" ] && footer "RUNNING SCRIPT $fcmd ON $srv($vip) SERVER"
    done
    return $lRC
}

ssh_copy()
{
    local lsrv=$1
    local fsource=$2
    local fdest=$3
    local own=$4
    local mode=$5
    local lRC=0

    if [ ! -f "$fsource" -a ! -d "$fsource" ]; then
        error "$fsource Not exists"
        return 127
    fi
    for srv in $(echo $lsrv | perl -pe 's/[, :]/\n/g'); do
        rsync -avz  -e "ssh -i ${DEFAULT_PRIVATE_KEY:-"/root/.ssh/id_rsa"}" $fsource root@$srv:$fdest
        lRC=$(($lRC + $?))

        [ -z "$own" ] || ssh_cmd $srv "chown -R $own:$own $fdest" silent
        lRC=$(($lRC + $?))
        [ -z "$mode" ] || ssh_cmd $srv "chmod -R $mode $fdest" silent
        lRC=$(($lRC + $?))

        [ -z "$silent" ] && footer "RUNNING SCRIPT $fcmd ON $srv SERVER"
        lRC=$(($lRC + $?))
    done
    return $lRC
}

updateScript()
{
    local lsrv=${1}
    _DIR=/root/dbscripts
    ssh_copy $lsrv $_DIR/scripts/utils.sh /etc/profile.d/utils.sh root 644
    ssh_cmd $lsrv "mkdir -p /opt/local/bin"
    ssh_copy $lsrv $_DIR/scripts/bin /opt/local root 755
    ssh_cmd $lsrv "chmod -R 755 /opt/local/bin"
}

lUpdateScript()
{
    _DIR=/root/dbscripts
    rsync -av $_DIR/scripts/utils.sh /etc/profile.d/utils.sh
    chown root.root /etc/profile.d/utils.sh
    chmod 755 /etc/profile.d/utils.sh
    [ -d "/opt/local/bin" ] && mkdir -p /opt/local/bin
    rsync -av $_DIR/scripts/bin /opt/local/
    chown -R root.root /opt/local/bin
    chmod -R 755 /opt/local/bin
}

[ -f "/etc/profile.d/utils.mysql.sh" ] && source /etc/profile.d/utils.mysql.sh