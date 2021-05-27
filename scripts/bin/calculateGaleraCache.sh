#!/bin/bash

bytesToHumanReadable() {
    local i=${1:-0} d="" s=0 S=("Bytes" "KiB" "MiB" "GiB" "TiB" "PiB" "EiB" "YiB" "ZiB")
    while ((i > 1024 && s < ${#S[@]}-1)); do
        printf -v d ".%02d" $((i % 1024 * 100 / 1024))
        i=$((i / 1024))
        s=$((s + 1))
    done
    echo "$i$d ${S[$s]}"
}

received_avt=$(mysql -Nrs -e "show global status like 'wsrep_received_bytes'" | awk '{print $2}')
replicated_avt=$(mysql -Nrs -e "show global status like 'wsrep_replicated_bytes'"| awk '{print $2}')
echo "REC: $received_avt - REP: $replicated_avt"

sleep 60s

received_apr=$(mysql -Nrs -e "show global status like 'wsrep_received_bytes'" | awk '{print $2}')
replicated_apr=$(mysql -Nrs -e "show global status like 'wsrep_replicated_bytes'"| awk '{print $2}')
echo "REC: $received_apr - REP: $replicated_apr"

taillemin=$(( $received_apr + $replicated_apr - $received_avt - $replicated_avt))
echo "Taille par minute: $(bytesToHumanReadable $taillemin)"
echo "Taille par heure : $(bytesToHumanReadable $(( $taillemin * 60)) )"
for nbh in 2 3 5 7 9 10 12 15 18 24 48; do
	echo "Taille pour $nbh heures : $(bytesToHumanReadable $(( $taillemin * 60 * $nbh )) )"
done
