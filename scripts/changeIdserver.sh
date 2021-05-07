#!/bin/bash

finalID=$(hostname -s|cut -da -f3)

perl -i -pe "s/<ID>/$finalID/g" /etc/my.cnf.d/60_server.cnf

