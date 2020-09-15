alias gst='git status'
alias gcm="git commit -m"

vmssh()
{
	local vm=$1
	shift
 	ssh -i ./id_rsa root@$vm $@
}
