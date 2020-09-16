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

