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

<<<<<<< HEAD
=======
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
}
>>>>>>> 15e50e384fd9101c32d2459043406a2d438e0a9a
