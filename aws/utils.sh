#!/bin/bash

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

get_aws_accounts()
{
    cat ~/.aws/credentials | grep -E '^\[.*\]' | sed 's/\[//g' | sed 's/\]//g' | grep -v default
}

get_priv_keys()
{
    find ~/.ssh -name "id_rsa*" -type f| grep -v ".pub" |sort -r
}

get_hostname_ip()
{
    host ${1:-"localhost"} | awk '/has address/ { print $4 }'| head -n 1
}


generate_host_alias()
{
    for AWS_PROFILE in $(get_aws_accounts); do
        AWS_PROFILE=$AWS_PROFILE make -f $(dirname $0)/makefile/Makefile host_config
        [ $? -eq 0 ] ||break
    done
}
clear_host_alias()
{
    for AWS_PROFILE in $(get_aws_accounts); do
        AWS_PROFILE=$AWS_PROFILE make -f $(dirname $0)/makefile/Makefile clear_config
        [ $? -eq 0 ] ||break
    done
}
 get_all_bastion_ips()
 {
    for AWS_PROFILE in $(get_aws_accounts); do
        AWS_PROFILE=$AWS_PROFILE make -f $(dirname $0)/makefile/Makefile get_bastion_ips 
    done| grep -vE '(echo|aws|Account)' | xargs -n70 | xargs -n1
 }
for cmd in $@; do
    $cmd
    [ $? -eq 0 ] || break
done