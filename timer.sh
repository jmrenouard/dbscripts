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
    #eval "export START_TIME_$LABEL=\$STOP_TIME_$LABEL;"

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
