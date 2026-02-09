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

create_sysbench_user()
{
	local sbpass=${1:-"waephei8eihoh2Id"}
	echo "DROP DATABASE if exists sbtest;
create database sbtest;
drop user if exists 'sbtest'@'192.168.%';
drop user if exists 'sbtest'@'localhost';

CREATE USER IF NOT EXISTS 'sbtest'@'192.168.%' IDENTIFIED BY '${sbpass}';
CREATE USER IF NOT EXISTS 'sbtest'@'localhost' IDENTIFIED BY '${sbpass}';
grant all on sbtest.* to 'sbtest'@'192.168.%';
grant all on sbtest.* to 'sbtest'@'localhost';
show grants for 'sbtest'@'192.168.%';
show grants for 'sbtest'@'localhost';" 

#add_password_history sbtest $sbpass
}

my_sysbench="sysbench --db-driver=mysql --mysql-user=${SYSBENCH_MYSQL_USER:-"sbtest"} --mysql_password=${SYSBENCH_MYSQL_PASSWORD:-"waephei8eihoh2Id"} --mysql-db=sbtest --mysql-port=${SYSBENCH_MYSQL_PORT:-"3306"} --mysql-host=${SYSBENCH_MYSQL_HOST:-"127.0.0.1"}"
run_load()
{ 
	nbmin=${1:-"15"}
	scenarios="read_write write_only read_only"
	mthreads="2 4 8 16 32 64 128 256 512 1024 1280"
	mtime=$(($nbmin * 60))
	(    
		for scenario in $scenarios; do
			for thrd in $mthreads; do
				opt_scenario=""
				[ "$scenario" != "write_only" ] && opt_scenario=" --skip_trx=on"
				echo "-------------------------------------------------------"
				echo "SCENARIO $scenario WITH $thrd THREADS FOR ${mtime} sec.($nbmin min.)"
				echo "-------------------------------------------------------"
				date
				echo "-------------------------------------------------------"
				tmpScript=$(mktemp)
				echo "#!/bin/bash
				source $HOME/.bash_profile
				my_sysbench --threads=$thrd --tables=16 --rate=10 --table-size=10000 --time=$mtime /usr/share/sysbench/oltp_${scenario}.lua run" > $tmpScript
				chmod 755 $tmpScript
				nohup /bin/bash $tmpScript 
				echo "-------------------------------------------------------" 
				date
				echo "-------------------------------------------------------"
				rm -f $tmpScript
			done    
		done 2>&1
	) | tee run_load_${nbmin}_$(date +%Y%m%d_%H%M).log}
}

simple_run_docker()
{
	gen_opts="--db-driver=mysql --mysql-user=sbtest --mysql_password=waephei8eihoh2Id --mysql-db=sbtest --mysql-host=192.168.68.57 --threads=5 --time=120 --report-interval=2 --tables=5 --table-size=100000 /usr/share/sysbench/oltp_read_write.lua"
	set -x
	for port in 3307 3308; do
	  sysbench --mysql-port=$port $gen_opts cleanup
  	  sysbench --mysql-port=$port $gen_opts prepare
	  sysbench --mysql-port=$port $gen_opts run
	done
}
echo "$my_sysbench --tables=120 --table-size=1000000 /usr/share/sysbench/oltp_read_write.lua cleanup
$my_sysbench --tables=120 --table-size=1000000 /usr/share/sysbench/oltp_read_write.lua prepare

$my_sysbench --tables=120 --table-size=1000000 --threads=4 --time=0 --events=0 --report-interval=1 /usr/share/sysbench/oltp_read_write.lua run
$my_sysbench --tables=120 --table-size=1000000 --threads=4 --time=0 --events=0 --report-interval=1 --rate=40 /usr/share/sysbench/oltp_read_write.lua run

#Limiter à 5 minutes
$my_sysbench --tables=120 --table-size=1000000 --threads=8 --time=300 --events=0 --report-interval=1 --rate=40 /usr/share/sysbench/oltp_read_write.lua run"
