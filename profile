alias gst='git status'
alias gcm="git commit -m"

vmssh()
{
	local vm=$1
	shift
 	ssh -i ./id_rsa root@$vm $@
}
export ANSIBLE_SSH_ARGS="-i $HOME/galeracluster/vms/id_rsa "
export ANSIBLE_INVENTORY="$HOME/galeracluster/vms/inventory"

execall()
{
	for srv in galera1 galera2 galera3 galera4; do
			echo $srv
			echo "------------------"
			ssh -i ./id_rsa root@$srv "$*"
			echo "------------------"
	done
}
cpall()
{
	for srv in galera1 galera2 galera3 galera4; do
			echo $srv
			echo "------------------"
			scp -i ./id_rsa $1 root@$srv:$2
			echo "------------------"
	done
}

##
# cpall mariadb.repo  /etc/yum.repos.d
# execall "yum -y install MariaDB-server MariaDB-client"
# execall "systemctl start mariadb"
# execall "systemctl status mariadb"


# execall "iptables --flush;iptables -L"
# execall "setenforce 0;sestatus"

# execall "yum -y install socat MariaDB-backup rsync lsof percona-toolkit mysql-utilities"
# execall "yum -y install ntpdate"
# execall "ntpdate -vqd fr.pool.ntp.org"