#!/bin/bash


create_sysbench_user()
{
	local sbpass=${1:-"waephei8eihoh2Id"}
	echo "DROP DATABASE if exists sbtest;
create database sbtest;
drop user if exists 'sbtest'@'192.168.%';
drop user if exists 'sbtest'@'localhost';

grant all on sbtest.* to 'sbtest'@'192.168.%'
identified by '${sbpass}';
grant all on sbtest.* to 'sbtest'@'localhost'
identified by '${sbpass}';
show grants for 'sbtest'@'192.168.%';
show grants for 'sbtest'@'localhost';" | mysql -f

add_password_history sbtest $sbpass
}


my_sysbench="sysbench --db-driver=mysql --mysql-user=sbtest --mysql_password=$(grep sbtest $HOME/.pass_mariadb| tail -n 1 |awk 'NF{ print $NF }') --mysql-db=sbtest"
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

$my_sysbench --tables=120 --table-size=1000000 /usr/share/sysbench/oltp_read_write.lua cleanup
$my_sysbench --tables=120 --table-size=1000000 /usr/share/sysbench/oltp_read_write.lua prepare

$my_sysbench --tables=120 --table-size=1000000 --threads=4 --time=0 --events=0 --report-interval=1 /usr/share/sysbench/oltp_read_write.lua run
$my_sysbench --tables=120 --table-size=1000000 --threads=4 --time=0 --events=0 --report-interval=1 --rate=40 /usr/share/sysbench/oltp_read_write.lua run

#Limiter à 5 minutes
$my_sysbench --tables=120 --table-size=1000000 --threads=8 --time=300 --events=0 --report-interval=1 --rate=40 /usr/share/sysbench/oltp_read_write.lua run