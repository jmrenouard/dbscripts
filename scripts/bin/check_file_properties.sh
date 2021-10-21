#!/bin/bash

RET_OK=0
RET_WARN=1
RET_CRIT=2
RET_UNKN=3
RET_ERR=127


while getopts "p:d:o:g:r:v" option
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

if [ -z "$EOWNER" -o -z "$EGROUP" -o -z "$ERIGHTS" ]; then
	echo "WRONG PARAMETERS: -o, -g or -r "
	exit $RET_ERR
fi

[ "$DEBUG" = "1" ] && echo "DEBUG: $TARGET_DIR EXISTS"

[ -z "$FILE_PATTERN" ] && FILE_PATTERN='*'

[ "$DEBUG" = "1" ] && echo "DEBUG: $TARGET_DIR/$FILE_PATTERN"

#find $TARGET_DIR -type f -iname "$FILE_PATTERN"
LIST_FILES=$(find $TARGET_DIR -type f -iname "$FILE_PATTERN")

for f in $LIST_FILES; do
	[ "$DEBUG" = "1" ] && echo "DEBUG: HANDLING $f"
	o=$(stat --format '%U' $f)
	g=$(stat --format '%G' $f)
	r=$(stat --format '%a' $f)
	if [ "$o" != "$EOWNER" ];then
		echo "(CRITICAL)$f OWNER $o EXPECTED $EOWNER"
		exit $RET_CRIT
	fi
	if [ "$g" != "$EGROUP" ];then
		echo "(CRITICAL)$f GROUP $g EXPECTED $EOWNER"
		exit $RET_CRIT
	fi
	if [  "$r" != "$ERIGHTS" ];then
		echo "(CRITICAL)$f RIGHTS $r EXPECTED $ERIGHTS"
		exit $RET_CRIT
	fi
done

echo "(OK)$TARGET_DIR FILE: ALL FILES $FILE_PATTERN ARE $EOWNER / $EGROUP ($ERIGHTS)"

exit $RET_OK

