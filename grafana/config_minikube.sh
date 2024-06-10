#minikube start --nodes 5 --driver=virtualbox


add_minikube_bridged_network()
{
    minikube stop

    nic=$( VBoxManage showvminfo minikube --machinereadable | grep ^nic | grep '"none"' | head -n1 | cut -d= -f1 | cut -c4- )
    int=$( route | grep '^default' | grep -o '[^ ]*$')

    if [ -n "${MINIKUBE_NIC_BRIDGED_MAC:-}" ]; then
    opts="--macaddress$nic $MINIKUBE_NIC_BRIDGED_MAC"
    fi

    for vm in minikube minikube-m02  minikube-m03  minikube-m04  minikube-m05; do
    VBoxManage modifyvm $vm --nic$nic bridged --bridgeadapter$nic $int $opts
    done

    minikube start
}

alias kubectl="minikube kubectl --"
alias mcp="minikube cp"
alias mssh="minikube ssh"

alias gst='git status'
alias gcm='git commit -m'
alias gadd='git add -A'

list_minikube_hosts()
{
    minikube status| grep -vE '^(.+): '| xargs
}

generate_minikube_hosts()
{
    for mh in $(list_minikube_hosts); do
        echo "$(minikube ip -n "$mh") $mh"
    done
}