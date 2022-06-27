##########################################
# Functions display and tests
##########################################
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