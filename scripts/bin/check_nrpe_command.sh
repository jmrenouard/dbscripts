for cmd in $(grep command /etc/nrpe.d/*.cfg|cut -d\[ -f2| cut -d\] -f1); do 
	echo "-------- $cmd"
	/usr/lib64/nagios/plugins/check_nrpe -H127.0.0.1 -c $cmd
	echo
done
