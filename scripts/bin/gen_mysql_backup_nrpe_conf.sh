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

one_hour=60
one_day=$((24 *$one_hour))

#perl -i.bak -pe 's/^(allowed_hosts)=.*/$1=127.0.0.1/g;s/^(dont_blame_nrpe|allow_bash_command_substitution|debug)=.*/$1=1/g' /etc/nagios/nrpe.cfg
#usermod -G backupbdd nagios

for confFile in /etc/mybackupbdd/ssh_lgconfig_*.conf; do
	echo "--------------------------------------------------------------------------------------"
	echo "=> $confFile"
	source $confFile
	echo "CHECKING $SSH_HOSTNAME HOST"
	echo "--------------------------------------------------------------------------------------"
	(
		echo "command[access_ssh_$(basename $SSH_HOSTNAME)]=/usr/lib/nagios/plugins/check_ssh -4 -t6 -p22 $SSH_HOSTNAME"
		echo "command[backup_count_$(basename $SSH_HOSTNAME)]=/opt/local/mysql/bin/check_file_count.sh -d $BCK_DIR  -p '*.gz' -c 1 -w 4 -C 10 -W 7"
		echo "command[backup_file_status_$(basename $SSH_HOSTNAME)]=/opt/local/mysql/bin/check_file_properties.sh -d $BCK_DIR -p '*.gz' -o backupbdd -g backupbdd -r 750 -s 1 -S 800 -A $((10*$one_day)) -a $((26*$one_hour))"

	) >/etc/nagios/nrpe.d/backup_${SSH_HOSTNAME}.cfg

	# Vérification port SSH ouvert
	/usr/lib/nagios/plugins/check_ssh -4 -t6 -p22 $SSH_HOSTNAME
	lRC=$(($lRC + $?))
	echo "CHECKING THERE IS AT LEAST ONE gz files and NO MORE THAN 10 GZ FILES"
	echo "--------------------------------------------------------------------------------------"
	bash /opt/local/mysql/bin/check_file_count.sh -d $BCK_DIR  -p '*.gz' -c 1 -w 4 -C 10 -W 7
	lRC=$(($lRC + $?))
	echo "--------------------------------------------------------------------------------------"
	echo "CHECKING GZ FILE are backupbdd:backupbdd (740) and LAST GZ is less than 26 hours max gz file age no more than 10 DAys size GZ between 1Mb and 800 Mb "

	bash /var/tmp/mysqlscripts/bin/check_file_properties.sh -d $BCK_DIR -p '*.gz' -o backupbdd -g backupbdd -r 750 -s 1 -S 800 -A $((10*$one_day)) -a $((26*$one_hour))
	lRC=$(($lRC + $?))
done

if [ $lRC -gt 0 ]; then
	echo "CONF BAD"
	exit 3
fi
systemctl restart nagios-nrpe-server

check_nrpe_conf()
{
    local confFile=$1
    tmpRc=0

    grep -E '^command\[' $confFile | cut -d\] -f1| cut -d\[ -f2 | while IFS= read -r line; do
        echo "---------------------------------------------------------"
        echo "$confFile / $line"
        grep $line $confFile
        echo "---------------------------------------------------------":wq

        /usr/lib/nagios/plugins/check_nrpe -4 -H 127.0.0.1 -c $line
        tmpRc=$?
        if [ $tmpRc -ne 0 ]; then
            error "CHECKING $line => FAILED"
        else
            info "CHECKING $line => OK"
        fi
        lRC=$((lRC + $tmpRc))
        echo ""
        echo ""

    done
    return $lRC
}

for backup_conf in /etc/nagios/nrpe.d/*; do
	check_nrpe_conf $backup_conf
done

exit $lRC
