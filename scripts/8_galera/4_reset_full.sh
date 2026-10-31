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
    eval "$tcmd"
    local cRC=$?
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

_NAME="$(basename "$(readlink -f "$0")")"
NAME="${_NAME}"
my_private_ipv4=$(ip a| grep '192.168' |grep inet|awk '{print $2}'| cut -d/ -f1| head -n 1)


lRC=0
DATADIR="/var/lib/mysql"

banner "BEGIN SCRIPT: $_NAME"

cmd "journalctl --rotate -u mariadb"
cmd "journalctl --vacuum-time=1s -u mariadb"

cmd "systemctl stop mariadb"

sleep 2s

cmd "rm -rf $DATADIR /var/log/mysql/*"
cmd "mysql_install_db --user mysql --skip-name-resolve --datadir=$DATADIR"

cmd "systemctl enable mariadb"
cmd "systemctl daemon-reload"
cmd "systemctl restart mariadb"

sleep 3s

cmd "netstat -ltnp"

ps -edf |grep [m]ysqld

cmd "ls -ls $DATADIR"

cmd "journalctl -xe --no-pager -o cat -u mariadb"

cmd "tail -n 30 /var/log/mysql/mysqld.log"


#cd /opt/local
#if [ -d "./mariadb-sys" ]; then
#	cmd "git clone https://github.com/FromDual/mariadb-sys.git"
#	lRC=$(($lRC + $?))
#fi
#cd /opt/local/mariadb-sys
#mysql -f < sys_10.sql

footer "END SCRIPT: $NAME"
exit $lRC