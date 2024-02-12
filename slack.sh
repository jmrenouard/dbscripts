##########################################
# Functions SLACK
##########################################
SLACK_USERNAME="Jean-Marie RENOUARD"
SLACK_URL_dba="https://hooks.slack.com/services/T34FSQURG/XXXXXXXXXXXXXXXXXXXX/YYYYYYYYYYYYYYYYYYYYYYYY"
SLACK_URL_ops="https://hooks.slack.com/services/T34FSQURG/XXXXXXXXXXXXXXXXXXXX/YYYYYYYYYYYYYYYYYYYYYYYY"
SLACK_URL_demo_live="https://hooks.slack.com/services/XXXXXXXXXXXXXXXXXXXX/YYYYYYYYYYYYYYYYYYYYYYYY"
slack_send()
{
    local chann=$1
    shift
    local msg="$*"
    curl -X POST -H 'Content-type: application/json' --data "{\"as_user\": true, \"username\": \"$SLACK_USERNAME\", \"text\":\"$msg\"}" $(getVal "SLACK_URL_$chann")
}
alias slack_send_ops='slack_send ops'
alias slack_send_dba='slack_send dba'
alias slack_send_demo_live='slack_send demo_live'
