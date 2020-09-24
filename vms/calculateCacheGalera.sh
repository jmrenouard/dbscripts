#!/bin/sh

received_avt=$(mysql -Nrs -e "show global status like 'wsrep_received_bytes'" | awk '{print $2}')
replicated_avt=$(mysql -Nrs -e "show global status like 'wsrep_replicated_bytes'"| awk '{print $2}')

echo "REC: $received_avt - REP: $replicated_avt"

sleep 60s


received_apr=$(mysql -Nrs -e "show global status like 'wsrep_received_bytes'" | awk '{print $2}')
replicated_apr=$(mysql -Nrs -e "show global status like 'wsrep_replicated_bytes'"| awk '{print $2}')

echo "REC: $received_apr - REP: $replicated_apr"

taillemin=$(( $received_apr + $replicated_apr - $received_avt - $replicated_avt))
echo "Taille par min: $taillemin / $(( $taillemin /1024 )) / $(($taillemin /1024 /1024)) / $(( $taillemin /1024 /1024 /1024))"
echo "Taille par Heure: $(( $taillemin *60 ))"
echo "Taille par 6 Heures: $(( $taillemin * 60 * 6))"

