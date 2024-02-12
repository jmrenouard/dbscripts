#!/bin/bash

source /admin/scripts/profile.sh

DISTRIB_HOSTS="10.151.212.11
10.151.212.12
10.51.11.11"
TARIF_HOSTS="10.151.212.13
10.151.212.14
10.51.11.12"

for srv in $DISTRIB_HOSTS $TARIF_HOSTS; do
        echo "============$srv - 9200 ==================="
        curl -v http://${srv}:9200/
        echo "============$srv - 9201 ==================="
        curl -v http://${srv}:9201/
done


