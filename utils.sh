##########################################
# Functions display and tests
##########################################
now() {
    # echo "$(date "+%F %T %Z")"
    echo "$(date "+%F %T %Z")($(hostname -s))"
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

ok()
{
    info "$* [SUCCESS]"
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
	title1 "START: $*"
}

footer()
{
    local lRC=${lRC:-"$?"}

    [ $lRC -eq 0 ] && title1 "END: $* ENDED SUCCESSFULLY"
    [ $lRC -eq 0 ] || title1 "END: $* ENDED WITH WARNING OR ERROR ($lRC)"
    return $lRC
}

getVal()
{
	local value=$1
	echo $(eval "echo \$${value}")
}

setVal()
{
	local var=$1
	shift
	eval "${var}='$*'"
}

##########################################
# Functions UTILITIES
##########################################

ff()
{
find . -iname "$1"
}

yamlval()
{
    time python -c 'import yaml, sys; print(yaml.safe_load(sys.stdin))' < $1
}

ltrim()
{
        perl -i -pe 's/[\t ]+$//g' $1
}

randpw()
{
    if [ ! -f "/usr/bin/pwgen" ]; then
            echo "yum -y install pwgen"
            return 1
    fi
    pwgen -c -n  -y -s -v  12 1
    return $?
}

sanitize_md()
{
    sed -r -i "s/\x1B\[([0-9];)?([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g;s/\[0(;33|33|;32|)m//g"  $*
}

load_venv()
{
    tenv=${1:-"ansible"}
    export _DIR=$HOME/$tenv
    source $_DIR/bin/activate
}

alias load_env=load_venv
# some more ls aliases
alias la='ls -A'
alias l='ls -CF'
alias s=sudo
alias ll='ls -lsh'
alias h=history

reload()
{
    #cd ${_DIR}
    source ${_DIR}/profile
}

alias rl=reload

ppkill()
{
    for pid in $(ps -edf | grep "$1" | awk '{print $2}'); do
        ps -edf | grep " $pid "| grep -v grep 
        echo "KILLING PROCESS: $pid"
        sudo kill -9 $pid
        echo "---------------------------"
    done
}

bytesToHumanReadable() {
    local i=${1:-0} d="" s=0 S=("Bytes" "KiB" "MiB" "GiB" "TiB" "PiB" "EiB" "YiB" "ZiB")
    while ((i > 1024 && s < ${#S[@]}-1)); do
        printf -v d ".%02d" $((i % 1024 * 100 / 1024))
        i=$((i / 1024))
        s=$((s + 1))
    done
    echo "$i$d ${S[$s]}"
}