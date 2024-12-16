#!/bin/bash

#ps -edf | grep -v exporter  | grep -qE '([p]ostgres|[m]aria|[m]ysql)'
#if [ $? -eq 0 ]; then
#    echo -e "$(hostname -s)\t$(grep -E '^(VERSION|NAME)=' /etc/os-release | cut -d= -f 2 | tr '"' ' ' | xargs -n 5)\t$(nproc)\t$(free -m| grep Mem|awk '{print $2}')\t$(ps -edf | grep -E '([p]ostgres|[m]aria|[m]ysql)' | grep -v exporter | awk '{ print $1, $8}'| tr ' ' '\t')"
#else
#    echo -e "$(hostname -s)\t$(grep -E '^(VERSION|NAME)=' /etc/os-release | cut -d= -f 2 | tr '"' ' ' | xargs -n 5)\t$(nproc)\t$(free -m| grep Mem|awk '{print $2}')\tNO DATABASE"
#fi


to_lower()
{
    echo "$*" | tr '[:upper:]' '[:lower:]'
}

for srv in $(ls -1 /etc/mybackupbdd/| grep renater.fr| perl -pe 's/ssh_lgconfig_//g;s/.conf$//g'); do
    hostn=$(ssh -q service-sgbd@$srv "hostname -s")
    #echo -e "$srv\n${hostn}.renater.fr"
    if [ "$(to_lower ${hostn}.renater.fr)" == "$(to_lower ${srv})" ]; then
        echo -e "[ OK ]\t$srv"
    else
        echo -e "[FAIL]\t$srv"
        continue
    fi

    ssh -q service-sgbd@$srv "sudo mysqladmin ping"

done
