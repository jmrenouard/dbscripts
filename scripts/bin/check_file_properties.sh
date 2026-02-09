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

while getopts "p:d:o:g:r:a:A:s:S:v" option
do
	case $option in
        p)
			FILE_PATTERN=$OPTARG
			;;
        d)
			TARGET_DIR=$OPTARG
            ;;
        o)
            EOWNER=$OPTARG
            ;;
        g)
            EGROUP=$OPTARG
            ;;
        r)
            ERIGHTS=$OPTARG
            ;;
        a)
			EMIN_AGE_FILES=$OPTARG
			EMIN_AGE_FILES=$(($EMIN_AGE_FILES * 60))
			;;
		A)
			EMAX_AGE_FILES=$OPTARG
			EMAX_AGE_FILES=$(($EMAX_AGE_FILES * 60))
			;;
		s)
			EMIN_SIZE_FILES=$OPTARG
			;;
		S)
			EMAX_SIZE_FILES=$OPTARG
			;;
        v)
        	DEBUG=1
        	;;
       *)
			echo "WRONG PARAMETERS"
			exit $RET_ERR
	esac
done

function display_time {
  local T=$1
  local D=$((T/60/60/24))
  local H=$((T/60/60%24))
  local M=$((T/60%60))
  local S=$((T%60))
  (( $D > 0 )) && printf '%d days ' $D
  (( $H > 0 )) && printf '%d hours ' $H
  (( $M > 0 )) && printf '%d minutes ' $M
  (( $D > 0 || $H > 0 || $M > 0 )) && printf 'and '
  printf '%d seconds\n' $S
}

if [ -z "$TARGET_DIR" -o ! -d "$TARGET_DIR" ]; then
	echo "WRONG PARAMETERS: -d "
	exit $RET_ERR
fi

if [ -z "$EOWNER" -o -z "$EGROUP" -o -z "$ERIGHTS" ]; then
	echo "WRONG PARAMETERS: -o, -g or -r "
	exit $RET_ERR
fi

[ "$DEBUG" = "1" ] && echo "DEBUG: $TARGET_DIR EXISTS"

[ -z "$FILE_PATTERN" ] && FILE_PATTERN='*'

[ "$DEBUG" = "1" ] && echo "DEBUG: $TARGET_DIR/$FILE_PATTERN"

#find $TARGET_DIR -type f -iname "$FILE_PATTERN"
LIST_FILES=$(find $TARGET_DIR -type f -iname "$FILE_PATTERN")
tnow=$(date +"%s")
[ "$DEBUG" = "1" ] && echo "DEBUG: NOW $tnow - $(date -d@$tnow)"

min_fage=$tnow
last_file=""

max_fage=0
oldest_file=""

for f in $LIST_FILES; do
	[ "$DEBUG" = "1" ] && echo "DEBUG: HANDLING $f"
	o=$(stat --format '%U' $f)
	g=$(stat --format '%G' $f)
	r=$(stat --format '%a' $f)
	a=$(stat --format '%Y' $f)
	fage=$(($tnow - $a))
	s=$(stat --format '%s' $f)
	sm=$(($s /1024 /1024))
	[ "$DEBUG" = "1" ] && echo "DEBUG: $(basename $f) - SIZE Mb: $sm / $EMIN_SIZE_FILES / $EMAX_SIZE_FILES"
	[ "$DEBUG" = "1" ] && echo "DEBUG: $(basename $f) - LMD: $(date -d@$a)"
	[ "$DEBUG" = "1" ] && echo "DEBUG: AGE: $(display_time $fage) "
	[ "$DEBUG" = "1" ] && echo "DEBUG: current min fage: $(display_time $min_fage)"
	if [ $fage -lt $min_fage ]; then
		min_fage=$fage
		last_file=$(basename $f)
	fi

	if [ $fage -gt $max_fage ]; then
		max_fage=$fage
		oldest_file=$(basename $f)
	fi

	if [ "$o" != "$EOWNER" ];then
		echo "(CRITICAL)$(basename $f) OWNER $o EXPECTED $EOWNER"
		exit $RET_CRIT
	fi
	if [ "$g" != "$EGROUP" ];then
		echo "(CRITICAL)$(basename $f) GROUP $g EXPECTED $EOWNER"
		exit $RET_CRIT
	fi
	if [  "$r" != "$ERIGHTS" ];then
		echo "(CRITICAL)$(basename $f) RIGHTS $r EXPECTED $ERIGHTS"
		exit $RET_CRIT
	fi

	if [ $sm -lt $EMIN_SIZE_FILES ];then
		echo "(CRITICAL)$(basename $f) MIN SIZE $sm Mb EXPECTED $EMIN_SIZE_FILES Mb"
		exit $RET_CRIT
	fi
	if [ $sm -gt $EMAX_SIZE_FILES ];then
		echo "(CRITICAL)$(basename $f) MAX SIZE $sm Mb EXPECTED $EMAX_SIZE_FILES Mb"
		exit $RET_CRIT
	fi
done

[ "$DEBUG" = "1" ] && echo -e "DEBUG:  Min file age detected: $(display_time $min_fage) - $min_fage"
[ "$DEBUG" = "1" ] && echo -e "DEBUG:  EXPECTED:$(display_time $EMIN_AGE_FILES) - $EMIN_AGE_FILES"
[ "$DEBUG" = "1" ] && echo "DEBUG: $min_fage < $EMIN_AGE_FILES"

if [ $min_fage -gt $EMIN_AGE_FILES ]; then
		echo "(CRITICAL) MIN AGE DETECTED: $(display_time $min_fage) > $(display_time $EMIN_AGE_FILES) LAST FILE: $last_file"
		exit $RET_CRIT
fi

[ "$DEBUG" = "1" ] && echo -e "DEBUG:  Max file age detected: $(display_time $max_fage) - $max_fage"
[ "$DEBUG" = "1" ] && echo -e "DEBUG:  EXPECTED:$(display_time $EMAX_AGE_FILES) - $EMAX_AGE_FILES"
[ "$DEBUG" = "1" ] && echo "DEBUG: $max_fage > $EMAX_AGE_FILES"
if [ $max_fage -gt $EMAX_AGE_FILES ]; then
		echo "(CRITICAL) MAX AGE DETECTED: $(display_time $max_fage) > $(display_time $EMAX_AGE_FILES) LAST FILE: $oldest_file"
		exit $RET_CRIT
fi
echo "(OK)$TARGET_DIR FILE: ALL FILES $FILE_PATTERN ARE $EOWNER / $EGROUP ($ERIGHTS) - MIN FILE AGE: $(display_time $min_fage) - MAX FILE AGE: $(display_time $max_fage)"
exit $RET_OK
