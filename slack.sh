##########################################
# Functions SLACK
##########################################
SLACK_USERNAME="Jean-Marie RENOUARD"
SLACK_URL_dba="https://hooks.slack.com/services/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"
SLACK_URL_ops="https://hooks.slack.com/services/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"
SLACK_URL_prod_live="https://hooks.slack.com/services/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"
slack_send()
{
    local chann=$1
    shift
    local msg="$*"
    curl -X POST -H 'Content-type: application/json' --data "{\"as_user\": true, \"username\": \"$SLACK_USERNAME\", \"text\":\"$msg\"}" $(getVal "SLACK_URL_$chann")
}
alias slack_send_ops='slack_send ops'
alias slack_send_dba='slack_send dba'
alias slack_send_prod='slack_send prod_live'
