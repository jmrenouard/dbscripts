#!/bin/bash
set -euo pipefail

# --- Minimal Utility Functions ---
now() { echo "$(date "+%F %T %Z")($(hostname -s))"; }
info() { echo "$(now) INFO: $*" 1>&2; }
error() { echo "$(now) ERROR: $*" 1>&2; return 1; }
ok() { info "[SUCCESS] $* [SUCCESS]"; }
sep1() { echo "$(now) -----------------------------------------------------------------------------"; }
title1() { sep1; echo "$(now) $*"; sep1; }
cmd() {
    local tcmd="$1"
    local descr=${2:-"$tcmd"}
    title1 "RUNNING: $descr"
    set +e
    eval "$tcmd"
    local cRC=$?
    set -e
    if [ $cRC -eq 0 ]; then
        ok "$descr"
    else
        error "$descr (RC=$cRC)"
    fi
    return $cRC
}
banner() { title1 "START: $*"; info "run as $(whoami)@$(hostname -s)"; }
footer() {
    local lRC=${lRC:-"$?"}
    info "FINAL EXIT CODE: $lRC"
    [ $lRC -eq 0 ] && title1 "END: $* SUCCESSFUL" || title1 "END: $* FAILED"
    return $lRC
}
# --- End of Utility Functions ---

RET_OK=0
RET_WARN=1
RET_CRIT=2
RET_UNKN=3
RET_ERR=127

while getopts "p:d:C:W:c:w:v" option
do
        case $option in
                p)
					FILE_PATTERN=$OPTARG
					;;
                d)
					TARGET_DIR=$OPTARG
                    ;;
                c)
                    NB_MIN_FILE_CRITICAL=$OPTARG
                    ;;
                w)
                    NB_MIN_FILE_WARNING=$OPTARG
                    ;;
                C)
                    NB_MAX_FILE_CRITICAL=$OPTARG
                    ;;
                W)
                    NB_MAX_FILE_WARNING=$OPTARG
                    ;;
                v)
                	DEBUG=1
                	;;
               *)
					echo "WRONG PARAMETERS"
					exit $RET_ERR
        esac
done

if [ -z "$TARGET_DIR" -o ! -d "$TARGET_DIR" ]; then
	echo "WRONG PARAMETERS: -d "
	exit $RET_ERR
fi

[ "$DEBUG" = "1" ] && echo "DEBUG: $TARGET_DIR EXISTS"

[ -z "$FILE_PATTERN" ] && FILE_PATTERN='*'

[ "$DEBUG" = "1" ] && echo "DEBUG: $TARGET_DIR/$FILE_PATTERN"

NB_FILE=$(find $TARGET_DIR -type f -iname "$FILE_PATTERN" | wc -l)

if [ -n "$NB_MIN_FILE_CRITICAL" ];then
	if [  $NB_FILE -le $NB_MIN_FILE_CRITICAL ];then
		echo "(CRITICAL)$TARGET_DIR COUNT FILE: $NB_FILE EXPECTED MORE THAN $NB_MIN_FILE_CRITICAL FILES"
		exit $RET_CRIT
	fi
else
	NB_MIN_FILE_CRITICAL="X"
fi
if [ -n "$NB_MAX_FILE_CRITICAL" ]; then
	if  [ $NB_FILE -ge $NB_MAX_FILE_CRITICAL ];then
		echo "(CRITICAL)$TARGET_DIR COUNT FILE: $NB_FILE EXPECTED LESS THAN $NB_MAX_FILE_CRITICAL FILES"
		exit $RET_CRIT
	fi
else
	NB_MAX_FILE_CRITICAL="X"
fi

if [ -n "$NB_MIN_FILE_WARNING" ]; then
	if [ $NB_FILE -le $NB_MIN_FILE_WARNING ];then
		echo "(WARNING)$TARGET_DIR COUNT FILE: $NB_FILE EXPECTED MORE THAN $NB_MIN_FILE_WARNING FILES"
		exit $RET_WARN
	fi
else
	NB_MIN_FILE_WARNING="X"
fi

if [ -n "$NB_MAX_FILE_WARNING" ];then
	if [ $NB_FILE -ge $NB_MAX_FILE_WARNING ]; then
		echo "(WARNING)$TARGET_DIR COUNT FILE: $NB_FILE EXPECTED LESS THAN $NB_MAX_FILE_WARNING FILES"
		exit $RET_WARN
	fi
else
	NB_MAX_FILE_WARNING="X"
fi

echo "(OK)$TARGET_DIR COUNT FILE: $NB_FILE (Max: $NB_MAX_FILE_WARNING/$NB_MAX_FILE_CRITICAL - Min: $NB_MIN_FILE_WARNING/$NB_MIN_FILE_CRITICAL)"

exit $RET_OK
