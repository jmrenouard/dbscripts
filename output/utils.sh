# ##############################################################################
# Author:       jmrenouard/jean-Marie Renouard
# Email:        jmrenouard@lightpath.fr
#
# Description:
#   A comprehensive Bash utility script providing a wide range of helper functions.
#   It includes functionalities for logging, command timing, remote execution via SSH,
#   file encryption, LVM management, and various system checks. This script is
#   intended to be sourced by other scripts to provide a standardized toolkit for
#   common operations.
#
# Usage:
#   source utils.sh
#
# Examples:
#   # Example 1: Sourcing the script in another Bash file.
#   source utils.sh
#
#   # Example 2: Using a logging function after sourcing.
#   info "Starting the process."
#
#   # Example 3: Running a command with status reporting.
#   cmd "ls -l /tmp" "List contents of /tmp"
# ##############################################################################
#!/bin/bash

if [ "$0" != "-bash" -a "$0" != "/bin/bash" -a "$0" != "/bin/sh" -a "$0" != "-bash" -a "$0" != "bash" -a "$0" != "-su" ]; then
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
    IS_SHELL_CONTEXT=1
fi
[ -f '/etc/os-release' ] && source /etc/os-release
export LC_ALL="C"
HA_SOCKET=/tmp/admin.sock

export PATH=$PATH:/opt/local/bin:/opt/local/MySQLTuner-perl:.

export my_private_ipv4=$(ip a | grep inet | grep 'brd' | grep -E '(192.168|172.2)'| cut -d/ -f1 | awk '{print $2}'|head -n1)
export my_public_ipv4=$(ip a | grep inet | grep 'brd' | grep -E '(192.168|172.2)'| cut -d/ -f1 | awk '{print $2}'|head -n1)

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

# ------------------------------------------------------------------------------
# Description:
#   Prints the current date, time, timezone, and short hostname.
#
# Arguments:
#   None
#
# Outputs:
#   - Writes the formatted date string to stdout (e.g., "YYYY-MM-DD HH:MM:SS TZ(hostname)").
# ------------------------------------------------------------------------------
now() {
    # echo "$(date "+%F %T %Z")"
    echo "$(date "+%F %T %Z")($(hostname -s))"
}

# ------------------------------------------------------------------------------
# Description:
#   Converts a given string to lowercase.
#
# Arguments:
#   $* - The string to be converted.
#
# Outputs:
#   - Writes the lowercase version of the string to stdout.
# ------------------------------------------------------------------------------
to_lower()
{
    echo "$*" | tr '[:upper:]' '[:lower:]'
}

# ------------------------------------------------------------------------------
# Description:
#   Converts a given string to uppercase.
#
# Arguments:
#   $* - The string to be converted.
#
# Outputs:
#   - Writes the uppercase version of the string to stdout.
# ------------------------------------------------------------------------------
to_upper()
{
    echo "$*" | tr '[:lower:]' '[:upper:]'
}

# ------------------------------------------------------------------------------
# Description:
#   Reverses a return code. If the input is 0, it returns 26. Otherwise, it returns 0.
#
# Arguments:
#   $1 - The return code to reverse.
#
# Outputs:
#   - Writes the new return code to stdout.
#   - Returns 0 or 26.
# ------------------------------------------------------------------------------
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
# ------------------------------------------------------------------------------
# Description:
#   Starts a timer by recording the current time in an environment variable.
#
# Arguments:
#   $1 - (Optional) A label for the timer. Defaults to "GENERIC".
#
# Outputs:
#   - Exports a global variable START_TIME_<LABEL> with the current epoch time.
# ------------------------------------------------------------------------------
start_timer()
{
    local LABEL=${1:-"GENERIC"}
    eval "export START_TIME_$LABEL=$(date +%s);"
}

# ------------------------------------------------------------------------------
# Description:
#   Updates a timer, calculates the duration since the last update or start,
#   and resets the start time to the current time.
#
# Arguments:
#   $1 - (Optional) The label for the timer. Defaults to "GENERIC".
#
# Outputs:
#   - Exports STOP_TIME_<LABEL> and LAST_DURATION_<LABEL> variables.
#   - Returns the return code of the previously executed command.
# ------------------------------------------------------------------------------
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

# ------------------------------------------------------------------------------
# Description:
#   Resets and removes all timer-related environment variables.
#
# Arguments:
#   None
#
# Outputs:
#   None
# ------------------------------------------------------------------------------
reset_all_timers()
{
    unset $(env| grep START_TIME|cut -d= -f 1| xargs)
    unset $(env| grep LAST_DURATION|cut -d= -f 1| xargs)
}

# ------------------------------------------------------------------------------
# Description:
#   Resets a specific timer by unsetting its environment variables.
#
# Arguments:
#   $1 - (Optional) The label of the timer to reset. Defaults to "GENERIC".
#
# Outputs:
#   None
# ------------------------------------------------------------------------------
reset_timer()
{
    local LABEL=${1:-"GENERIC"}
    unset $(env| grep "START_TIME_$LABEL"|cut -d= -f 1| xargs)
    unset $(env| grep "LAST_DURATION_$LABEL"|cut -d= -f 1| xargs)
}

# ------------------------------------------------------------------------------
# Description:
#   Prints all environment variables associated with a specific timer.
#
# Arguments:
#   $1 - (Optional) The label of the timer to dump. Defaults to "GENERIC".
#
# Outputs:
#   - Writes the timer's environment variables to stdout.
# ------------------------------------------------------------------------------
dump_timer()
{
    local LABEL=${1:-"GENERIC"}
    env| grep "START_TIME_$LABEL"
    env| grep "LAST_DURATION_$LABEL"
}

# ------------------------------------------------------------------------------
# Description:
#   Gets the calculated duration of a specific timer.
#
# Arguments:
#   $1 - (Optional) The label of the timer. Defaults to "GENERIC".
#
# Outputs:
#   - Writes the duration (e.g., 00h:01m:30s) or an error message to stdout.
# ------------------------------------------------------------------------------
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

# ------------------------------------------------------------------------------
# Description:
#   Gets the start timestamp of a specific timer.
#
# Arguments:
#   $1 - (Optional) The label of the timer. Defaults to "GENERIC".
#
# Outputs:
#   - Writes the Unix epoch timestamp or an error message to stdout.
# ------------------------------------------------------------------------------
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

# ------------------------------------------------------------------------------
# Description:
#   Gets the stop timestamp of a specific timer.
#
# Arguments:
#   $1 - (Optional) The label of the timer. Defaults to "GENERIC".
#
# Outputs:
#   - Writes the Unix epoch timestamp or an error message to stdout.
# ------------------------------------------------------------------------------
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

# ------------------------------------------------------------------------------
# Description:
#   Dumps a formatted summary of a timer including start date, stop date,
#   and total duration.
#
# Arguments:
#   $1 - (Optional) The label of the timer. Defaults to "GENERIC".
#
# Outputs:
#   - Writes the formatted summary to stdout via the `info` function.
# ------------------------------------------------------------------------------
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

# ------------------------------------------------------------------------------
# Description:
#   Truncates a string to a specified length and appends "...".
#
# Arguments:
#   $1 - The maximum length of the output string.
#   $* - The string to truncate.
#
# Outputs:
#   - Writes the truncated string to stdout.
# ------------------------------------------------------------------------------
trim_len()
{
    local l=$1
    shift
    echo -n $* | head -c $l
    echo "..."
}

# ------------------------------------------------------------------------------
# Description:
#   Logs an error message to stderr and, if configured, to a log file.
#
# Arguments:
#   $* - The error message to log.
#
# Outputs:
#   - Writes a formatted error message to stderr.
#   - Appends the message to $TEE_LOG_FILE if the variable is set.
# ------------------------------------------------------------------------------
error() {
    local lRC=$?
    echo "$(now) ERROR: $*" 1>&2
    [ -n "$TEE_LOG_FILE" ] && echo "$(now) ERROR: $*">>$TEE_LOG_FILE
    return $lRC
}

# ------------------------------------------------------------------------------
# Description:
#   Logs an error message and exits the script with a status code of 1.
#
# Arguments:
#   $* - The fatal error message to log.
#
# Outputs:
#   - Writes a formatted error message to stderr.
# ------------------------------------------------------------------------------
die() {
    error $*
    exit 1
}

# ------------------------------------------------------------------------------
# Description:
#   Logs an informational message to stderr and, if configured, to a log file.
#   Output is suppressed if the 'quiet' variable is set to "yes".
#
# Arguments:
#   $* - The message to log.
#
# Outputs:
#   - Writes a formatted info message to stderr.
#   - Appends the message to $TEE_LOG_FILE if the variable is set.
# ------------------------------------------------------------------------------
info() {
    [ "$quiet" != "yes" ] && echo "$(now) INFO: $*" 1>&2
    [ -n "$TEE_LOG_FILE" ] && echo "$(now) INFO: $*">>$TEE_LOG_FILE
    return 0
}

# ------------------------------------------------------------------------------
# Description:
#   Logs a debug message if the DEBUG environment variable is set to "1".
#
# Arguments:
#   $* - The debug message to log.
#
# Outputs:
#   - Writes a formatted debug message to stderr.
#   - Appends the message to $TEE_LOG_FILE if the variable is set.
# ------------------------------------------------------------------------------
debug() {
    [ "$DEBUG" = "1" ] || return 0
    [ "$quiet" != "yes" ] && echo "$(now) DEBUG: $*" 1>&2
    [ -n "$TEE_LOG_FILE" ] && echo "$(now) DEBUG: $*">>$TEE_LOG_FILE
    return 0
}

# ------------------------------------------------------------------------------
# Description:
#   Logs a success message, typically used to indicate a successful operation.
#
# Arguments:
#   $* - The success message to display.
#
# Outputs:
#   - Writes a formatted success message via the `info` function.
# ------------------------------------------------------------------------------
ok()
{
    info "[SUCCESS]  $*  [SUCCESS]"
    return $?
}

# ------------------------------------------------------------------------------
# Description:
#   Logs a warning message to stderr and, if configured, to a log file.
#
# Arguments:
#   $* - The warning message to log.
#
# Outputs:
#   - Writes a formatted warning message to stderr.
#   - Appends the message to $TEE_LOG_FILE if the variable is set.
# ------------------------------------------------------------------------------
warn() {
    local lRC=$?
    echo "$(now) WARNING: $*" 1>&2
    [ -n "$TEE_LOG_FILE" ] && echo "$(now) WARNING: $*">>$TEE_LOG_FILE
    return $lRC
}

# ------------------------------------------------------------------------------
# Description:
#   An alias for the `warn` function.
#
# Arguments:
#   $* - The warning message to log.
#
# Outputs:
#   - See `warn` function.
# ------------------------------------------------------------------------------
warning()
{
    warn "$*"
}
# ------------------------------------------------------------------------------
# Description:
#   Prints a standard separator line using dashes.
#
# Arguments:
#   None
#
# Outputs:
#   - Writes a separator line to stderr and a log file if configured.
# ------------------------------------------------------------------------------
sep1()
{
    echo "$(now) -----------------------------------------------------------------------------" 1>&2
    [ -n "$TEE_LOG_FILE" ] && echo "$(now) -----------------------------------------------------------------------------" >>$TEE_LOG_FILE
}
# ------------------------------------------------------------------------------
# Description:
#   Prints a standard separator line using underscores.
#
# Arguments:
#   None
#
# Outputs:
#   - Writes a separator line to stderr and a log file if configured.
# ------------------------------------------------------------------------------
sep2()
{
    echo "$(now) _____________________________________________________________________________" 1>&2
    [ -n "$TEE_LOG_FILE" ] && echo "$(now) _____________________________________________________________________________" >>$TEE_LOG_FILE
}
# ------------------------------------------------------------------------------
# Description:
#   Prints a formatted title block with dash separators.
#
# Arguments:
#   $* - The title text.
#
# Outputs:
#   - Writes a formatted title block to stderr and a log file if configured.
# ------------------------------------------------------------------------------
title1() {
    sep1
    echo "$(now) $*" 1>&2
    [ -n "$TEE_LOG_FILE" ] && echo "$(now) $*">>$TEE_LOG_FILE
    sep1
}

# ------------------------------------------------------------------------------
# Description:
#   Prints a formatted title block with an underscore separator below.
#
# Arguments:
#   $* - The title text.
#
# Outputs:
#   - Writes a formatted title block to stderr and a log file if configured.
# ------------------------------------------------------------------------------
title2()
{
    echo "$(now) $*" 1>&2
    [ -n "$TEE_LOG_FILE" ] && echo "$(now) $*">>$TEE_LOG_FILE
    sep2
}
# ------------------------------------------------------------------------------
# Description:
#   Prints a banner to mark the start of a major section or script.
#   It starts a timer and logs the script's user and hostname.
#
# Arguments:
#   $* - The title for the banner.
#
# Outputs:
#   - Writes a formatted banner to stderr.
# ------------------------------------------------------------------------------
banner()
{
    start_timer
    title1 "START: $*"
    info " run as $(whoami)@$(hostname -s)"
}

# ------------------------------------------------------------------------------
# Description:
#   Prints a footer to mark the end of a major section or script.
#   It dumps the timer duration and indicates success or failure based on the last exit code.
#
# Arguments:
#   $* - The title for the footer.
#
# Outputs:
#   - Writes a formatted footer to stderr.
#   - Returns the last command's exit code.
# ------------------------------------------------------------------------------
footer()
{
    local lRC=${lRC:-"$?"}
    dump_timer
    info "FINAL CODE RETOUR: $lRC"
    [ $lRC -eq 0 ] && title1 "END: $* ENDED SUCCESSFULLY"
    [ $lRC -eq 0 ] || title1 "END: $* ENDED WITH WARNING OR ERROR"
    return $lRC
}

# ------------------------------------------------------------------------------
# Description:
#   Executes a command and logs its execution, status, and return code.
#
# Arguments:
#   $1 - The command to execute.
#   $2 - (Optional) A description of the command.
#
# Outputs:
#   - Logs the command and its outcome using `title1`, `ok`, and `error`.
#   - Returns the exit code of the executed command.
# ------------------------------------------------------------------------------
cmd()
{
    local cRC=0
    local tcmd="$1"
    local descr=${2:-"$tcmd"}
    if [ -z "$2" ]; then
        title1 "RUNNING COMMAND: $(trim_len 60 $tcmd)"
    else
        title1 "$descr"
        info "RUNNING COMMAND: $(trim_len 60 $tcmd)"
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

# ------------------------------------------------------------------------------
# Description:
#   Executes a command and prefixes each line of its output with ">>".
#
# Arguments:
#   $1 - The command to execute.
#   $2 - (Optional) A description of the command.
#
# Outputs:
#   - Logs the command's output line-by-line using the `info` function.
#   - Returns the exit code of the executed command.
# ------------------------------------------------------------------------------
info_cmd()
{
    local cRC=0
    local tcmd="$1"
    if [ -z "$2" ]; then
        title1 "RUNNING COMMAND: $(trim_len 60 $tcmd)"
    else
        title1 "$descr"
        info "RUNNING COMMAND: $(trim_len 60 $tcmd)"
        sep1
    fi
    eval "$tcmd 2>&1" | while read -r line;do
      info ">> $(trim_len 60 $line)"
    done
    cRC=$?
    info "RETURN CODE: $cRC"
    if [ $cRC -eq 0 ]; then
        ok "$(trim_len 60 $tcmd)"
    else
        error "$(trim_len 60 $tcmd)"
    fi
    sep1
    return $cRC
}

# ------------------------------------------------------------------------------
# Description:
#   Prompts the user with a yes/no question and captures the response.
#
# Arguments:
#   $1 - The question to ask the user.
#
# Outputs:
#   - Writes "yes" or "no" to stdout.
#   - Returns 0 for "yes" and 1 for "no".
# ------------------------------------------------------------------------------
function ask_yes_or_no() {
    read -p "$1 ([y]es or [n]o): "
    case $(echo $REPLY | tr '[A-Z]' '[a-z]') in
        y|Y|yes) echo "yes";return 0 ;;
        *)     echo "no"; return 1;;
    esac
    return 1
}

# ------------------------------------------------------------------------------
# Description:
#   Pauses the script and waits for the user to press the Enter key.
#
# Arguments:
#   None
#
# Outputs:
#   - Writes a prompt to the controlling TTY.
# ------------------------------------------------------------------------------
pauseenter()
{
    read -p "Press Enter to continue" </dev/tty
}

# ------------------------------------------------------------------------------
# Description:
#   Gets the value of a variable whose name is passed as an argument.
#
# Arguments:
#   $1 - The name of the variable to retrieve.
#
# Outputs:
#   - Writes the value of the specified variable to stdout.
# ------------------------------------------------------------------------------
get_val()
{
    local value=$1
    echo $(eval "echo \$${value}")
}

# ------------------------------------------------------------------------------
# Description:
#   Sets a variable to a given value.
#
# Arguments:
#   $1 - The name of the variable to set.
#   $* - The value to assign to the variable.
#
# Outputs:
#   - None.
# ------------------------------------------------------------------------------
set_val()
{
    local var=$1
    shift
    eval "${var}='$*'"
}

# ------------------------------------------------------------------------------
# Description:
#   Reloads the utils.sh script from /etc/profile.d/ and sets the root shell to bash.
#
# Arguments:
#   None
#
# Outputs:
#   - None.
# ------------------------------------------------------------------------------
rl()
{
    unset UTILS_MYSQL_IS_LOADED
    unset UTILS_IS_LOADED
    [ -f "/etc/profile.d/utils.sh" ] && source /etc/profile.d/utils.sh
    chsh -s /bin/bash root
}
#----------------------------------------------------------------------------------------------------
# Create the logical volume and the file system
#----------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# Description:
#   Decrypts a file that was encrypted with `cypher_file`, using openssl.
#
# Arguments:
#   $1 - The path to the encrypted file (e.g., file.enc.gz).
#   $2 - (Optional) Path to the key file. Defaults to /opt/mysql/.encrypted.cnf.
#   $3 - (Optional) Path for the output file. Defaults to the input filename without .enc.gz.
#
# Outputs:
#   - Creates the decrypted file on disk.
#   - Returns 1 if the input file does not exist, 0 otherwise.
# ------------------------------------------------------------------------------
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

# ------------------------------------------------------------------------------
# Description:
#   Encrypts a file using openssl and compresses it with gzip.
#
# Arguments:
#   $1 - The path to the file to encrypt.
#   $2 - (Optional) Path to the key file. Defaults to /opt/mysql/.encrypted.cnf.
#   $3 - (Optional) Path for the output file. Defaults to the input filename with .enc.gz appended.
#
# Outputs:
#   - Creates the encrypted and gzipped file on disk.
#   - Returns 1 if the input file does not exist, 0 otherwise.
# ------------------------------------------------------------------------------
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

# ------------------------------------------------------------------------------
# Description:
#   Creates an LVM logical volume, formats it, mounts it, and adds it to /etc/fstab.
#
# Arguments:
#   $1 - vg: The volume group name.
#   $2 - lv: The logical volume name.
#   $3 - lvsize: The size of the LV (e.g., 10G or 100%FREE).
#   $4 - lvuser: The user to own the mount point.
#   $5 - lvhome: The mount point directory.
#   $6 - lvfstype: (Optional) The filesystem type. Defaults to "ext4".
#
# Outputs:
#   - Writes status messages to stdout.
#   - Returns 1 on failure, 0 on success.
# ------------------------------------------------------------------------------
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

# ------------------------------------------------------------------------------
# Description:
#   A git helper function that finds untracked files via `git status` and
#   executes a provided command on each file.
#
# Arguments:
#   $* - The command to execute on each untracked file (e.g., `rm -f`).
#
# Outputs:
#   - Executes the command on each file found.
# ------------------------------------------------------------------------------
gunt() {
    git status | \
    grep -vE '(Changes to be committed:| to publish your local commits|git add|git restore|On branch|Your branch|Untracked files|nclude in what will b|but untracked files present|no changes added to commit|modified:|deleted:|Changes not staged for commit)' |\
    sort | uniq | \
    xargs -n 1 $*
}
alias gad='git status | grep deleted:  | cut -d: -f2 | xargs -n1 git rm -f'
alias gadd='git add'
alias gam='git status | grep modified: | cut -d: -f2 | xargs -n 1 git add'


# ------------------------------------------------------------------------------
# Description:
#   Checks all NRPE command definitions found in NRPE configuration files
#   by executing them locally via check_nrpe.
#
# Arguments:
#   $1 - (Optional) A regex pattern to filter which checks to run.
#
# Outputs:
#   - Writes the status of each check to stdout.
# ------------------------------------------------------------------------------
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

# ------------------------------------------------------------------------------
# Description:
#   Queries HAProxy status by sending a command to its admin socket.
#
# Arguments:
#   $1 - (Optional) The parameter to show (e.g., "info", "stat"). Defaults to "info".
#
# Outputs:
#   - Writes the output from the HAProxy socket to stdout.
# ------------------------------------------------------------------------------
ha_status()
{
    local param=${1:-"info"}
    echo "show $param" |  socat unix-connect:$HA_SOCKET stdio
}
# ------------------------------------------------------------------------------
# Description:
#   Displays the state of HAProxy backends in a formatted table.
#
# Arguments:
#   None
#
# Outputs:
#   - Writes a table of backend names, types, and states to stdout.
# ------------------------------------------------------------------------------
ha_states()
{
   (echo -e "NAME TYPE STATE"
    echo "show stat" |  socat unix-connect:$HA_SOCKET stdio| cut -d, -f1,2,18 | tr ',' '\t'| sort -k 3| grep -ve '^#'
    )|column -t
}
# ------------------------------------------------------------------------------
# Description:
#   Disables a specific server in an HAProxy backend.
#
# Arguments:
#   $1 - The server to disable (e.g., "galera/node1").
#
# Outputs:
#   - Writes the output from the HAProxy socket to stdout.
# ------------------------------------------------------------------------------
ha_disable()
{
    echo "disable server ${1:-"galera/node1"}" |  socat unix-connect:$HA_SOCKET stdio
}
# ------------------------------------------------------------------------------
# Description:
#   Enables a specific server in an HAProxy backend.
#
# Arguments:
#   $1 - The server to enable (e.g., "galera/node1").
#
# Outputs:
#   - Writes the output from the HAProxy socket to stdout.
# ------------------------------------------------------------------------------
ha_enable()
{
    echo "enable server ${1:-"galera/node1"}" |  socat unix-connect:$HA_SOCKET stdio
}

# ------------------------------------------------------------------------------
# Description:
#   Executes one or more local scripts on a list of remote servers via SSH.
#
# Arguments:
#   $1 - A space, comma, or colon-separated list of server hostnames.
#   $* - The paths to the local script files to execute on the remote servers.
#
# Outputs:
#   - Writes execution logs to stderr.
#   - Returns a cumulative return code from all executions.
# ------------------------------------------------------------------------------
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

# ------------------------------------------------------------------------------
# Description:
#   Executes a single command string on a list of remote servers via SSH.
#
# Arguments:
#   $1 - A space, comma, or colon-separated list of server hostnames.
#   $2 - The command string to execute.
#   $3 - (Optional) If set to "silent", suppresses title/footer logging.
#
# Outputs:
#   - Writes command output to stdout.
#   - Writes execution logs to stderr unless in silent mode.
#   - Returns a cumulative return code.
# ------------------------------------------------------------------------------
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

# ------------------------------------------------------------------------------
# Description:
#   Copies a local file or directory to a list of remote servers using rsync.
#   Can optionally set ownership and permissions on the remote system.
#
# Arguments:
#   $1 - A space, comma, or colon-separated list of server hostnames.
#   $2 - The local source file or directory path.
#   $3 - The destination path on the remote servers.
#   $4 - (Optional) The user and group to own the file (e.g., "root").
#   $5 - (Optional) The file mode/permissions (e.g., "755").
#
# Outputs:
#   - Writes rsync and ssh command output to stdout/stderr.
#   - Returns a cumulative return code.
# ------------------------------------------------------------------------------
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

# ------------------------------------------------------------------------------
# Description:
#   A helper function to update this utils.sh script and associated bin files
#   on a list of remote servers.
#
# Arguments:
#   $1 - A list of server hostnames.
#
# Outputs:
#   - Writes command output to stdout/stderr.
# ------------------------------------------------------------------------------
updateScript()
{
    local lsrv=${1}
    _DIR=/root/dbscripts
    ssh_copy $lsrv $_DIR/scripts/utils.sh /etc/profile.d/utils.sh root 644
    ssh_cmd $lsrv "mkdir -p /opt/local/bin"
    ssh_copy $lsrv $_DIR/scripts/bin /opt/local root 755
    ssh_cmd $lsrv "chmod -R 755 /opt/local/bin"
}

# ------------------------------------------------------------------------------
# Description:
#   A helper function to update this utils.sh script and associated bin files
#   on the local machine.
#
# Arguments:
#   None
#
# Outputs:
#   - Writes command output to stdout/stderr.
# ------------------------------------------------------------------------------
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

# ------------------------------------------------------------------------------
# Description:
#   Pings a list of servers to check for connectivity. Assumes the existence
#   of a `list_svg_srv` function to provide the server list.
#
# Arguments:
#   $1 - (Optional) If "quiet", prints OK status; otherwise, only prints FAIL.
#
# Outputs:
#   - Writes the ping status for each server to stdout.
# ------------------------------------------------------------------------------
test_ping()
{
    #source ansible/source
    for srv in $(list_svg_srv); do
        ping -c2 -W4 $srv &>/dev/null

        if [ $? -ne 0 ];then
            echo -e "$srv\t[FAIL]"
        fi
        [ "$1" == "quiet" ] && echo -e "$srv\t[ OK ]"
    done
}

# ------------------------------------------------------------------------------
# Description:
#   Tests a TCP port on a list of servers. Assumes the existence
#   of a `list_svg_srv` function to provide the server list.
#
# Arguments:
#   $1 - The TCP port number to test.
#   $2 - (Optional) If "quiet", prints OK status; otherwise, only prints FAIL.
#
# Outputs:
#   - Writes the connection status for each server to stdout.
# ------------------------------------------------------------------------------
test_tcp_port()
{
    #source ansible/source
    for srv in $(list_svg_srv); do
        nc -w3 $srv $1 &>/dev/null

        if [ $? -ne 0 ];then
            echo -e "$srv\t[FAIL]"
        fi
        [ "$2" == "quiet" ] && echo -e "$srv\t[ OK ]"
    done
}

# ------------------------------------------------------------------------------
# Description:
#   Connects to a list of remote servers and, from each, tests a TCP port on a
#   fixed target host (`backup.vm.local`).
#
# Arguments:
#   $1 - The TCP port number to test. Defaults to "111".
#   $2 - (Optional) If "quiet", prints OK status; otherwise, only prints FAIL.
#
# Outputs:
#   - Writes the connection status for each server to stdout.
# ------------------------------------------------------------------------------
test_remote_tcp_port()
{
    #source ansible/source
    tgt=backup.vm.local
    port=${1:-"111"}
    for srv in $(list_svg_srv); do
        ssh -q $srv "hostname;nc -v -w1 $tgt $1" #&>/dev/null

        if [ $? -ne 0 ];then
            echo -e "$srv\t[FAIL]"
            continue
        fi
        [ "$2" == "quiet" ] && echo -e "$srv\t[ OK ]"
    done
}

# ------------------------------------------------------------------------------
# Description:
#   Connects to a list of remote servers and, from each, tests a UDP port on a
#   fixed target host (`backup.vm.local`).
#
# Arguments:
#   $1 - The UDP port number to test. Defaults to "111".
#   $2 - (Optional) If "quiet", prints OK status; otherwise, only prints FAIL.
#
# Outputs:
#   - Writes the connection status for each server to stdout.
# ------------------------------------------------------------------------------
test_remote_udp_port()
{
    #source ansible/source
    tgt=backup.vm.local
    port=${1:-"111"}
    for srv in $(list_svg_srv); do
        ssh $srv "nc -vv -u -w3 $tgt $1" #&>/dev/null

        if [ $? -ne 0 ];then
            echo -e "$srv\t[FAIL]"
            continue
        fi
        [ "$2" == "quiet" ] && echo -e "$srv\t[ OK ]"
    done
}

UTILS_IS_LOADED="1"