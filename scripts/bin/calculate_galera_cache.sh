#!/bin/bash
set -euo pipefail

# --- Minimal Utility Functions ---
now() { echo "$(date "+%F %T %Z")($(hostname -s))"; }
info() { echo "$(now) INFO: $*" 1>&2; }
error() { echo "$(now) ERROR: $*" 1>&2; return 1; }
ok() { info "[SUCCESS] $* [SUCCESS]"; }
sep1() { echo "$(now) -----------------------------------------------------------------------------"; }
title1() { sep1; echo "$(now) $*"; sep1; }
cmd() {
    local tcmd="$1"
    local descr=${2:-"$tcmd"}
    title1 "RUNNING: $descr"
    set +e
    eval "$tcmd"
    local cRC=$?
    set -e
    if [ $cRC -eq 0 ]; then
        ok "$descr"
    else
        error "$descr (RC=$cRC)"
    fi
    return $cRC
}
banner() { title1 "START: $*"; info "run as $(whoami)@$(hostname -s)"; }
footer() {
    local lRC=${lRC:-"$?"}
    info "FINAL EXIT CODE: $lRC"
    [ $lRC -eq 0 ] && title1 "END: $* SUCCESSFUL" || title1 "END: $* FAILED"
    return $lRC
}
# --- End of Utility Functions ---

bytesToHumanReadable() {
    local i=${1:-0} d="" s=0 S=("Bytes" "KiB" "MiB" "GiB" "TiB" "PiB" "EiB" "YiB" "ZiB")
    while ((i > 1024 && s < ${#S[@]}-1)); do
        printf -v d ".%02d" $((i % 1024 * 100 / 1024))
        i=$((i / 1024))
        s=$((s + 1))
    done
    echo "$i$d ${S[$s]}"
}

innodb_written_avt=$(mysql -Nrs -e "show global status like 'innodb_data_written'" | awk '{print $2}')
received_avt=$(mysql -Nrs -e "show global status like 'wsrep_received_bytes'" | awk '{print $2}')
replicated_avt=$(mysql -Nrs -e "show global status like 'wsrep_replicated_bytes'"| awk '{print $2}')
echo "REC: $received_avt - REP: $replicated_avt"

sleep 60s

innodb_written_apr=$(mysql -Nrs -e "show global status like 'innodb_data_written'" | awk '{print $2}')
received_apr=$(mysql -Nrs -e "show global status like 'wsrep_received_bytes'" | awk '{print $2}')
replicated_apr=$(mysql -Nrs -e "show global status like 'wsrep_replicated_bytes'"| awk '{print $2}')
echo "REC: $received_apr - REP: $replicated_apr"

itaillemin=$(( $innodb_written_apr - $innodb_written_avt ))
taillemin=$(( $received_apr + $replicated_apr - $received_avt - $replicated_avt ))
echo "Taille par minute: $(bytesToHumanReadable $taillemin) - $(bytesToHumanReadable $itaillemin)"
echo "Taille par heure : $(bytesToHumanReadable $(( $taillemin * 60))) $(bytesToHumanReadable $(( $itaillemin * 60))) "
for nbh in 2 3 5 7 9 10 12 15 18 24 48; do
	echo "Taille pour $nbh heures : $(bytesToHumanReadable $(( $taillemin * 60 * $nbh )) ) - $(bytesToHumanReadable $(( $itaillemin * 60 * $nbh )) )"
done
