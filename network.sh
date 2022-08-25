##########################################
# Functions SSH & NETWORK
##########################################
alias sssh='sudo ssh -l root'
alias rsh='ssh -l root'
alias srsync="sudo rsync  -e 'ssh -l root'"
alias pass='pwgen -1 18'



test_ping_hosts()
{
    #set -x
    local pattern=${1:-"qa-"}
    grep $pattern /etc/hosts | awk '{print $2}' | while read -r line; do 
        ping -f -i 0.2 -c3 -W1 $line &>/dev/null
        if [ $? -eq 0 ]; then 
             echo "[OK] (LOCAL)$line: ICMP"
        else 
            echo "[FAIL] (LOCAL)$line: ICMP"
        fi
    done
}

test_ssh_hostname_hosts()
{
    local pattern=${1:-'qa-'}
    #set +x
    lst_hst=$(grep $pattern /etc/hosts | awk '{print $2}')
    for line in $lst_hst; do 
        #ssh -q -o "ConnectTimeout=4s" $bastion ping -f -i 0.2 -c3 -W1 $line &>/dev/null
        rhst=$(ssh -q -o "ConnectTimeout=2s" $line "hostname" 2>&1) 
        
        if [ "$line" == "$rhst" ]; then 
             ok "$line: SSH HOSTNAME"
        else 
            fail "$line: SSH HOSTNAME"
        fi
    done
}

test_tcp_hosts()
{
    local pattern=${1:-'qa-'}
    local port=${2:-"22"}
    grep $pattern /etc/hosts | awk '{print $2}' | while read -r line; do 
        nc -z -v -w1 $line $port &>/dev/null
        if [ $? -eq 0 ]; then 
             ok "$line: $port/TCP"
        else 
            fail "$line: $port/TCP"
        fi
    done
}

test_ssh_tcp_hosts()
{
    local bastion=${1:-'localhost'}
    local pattern=${2:-'qa-'}
    local port=${3:-"22"}
    grep $pattern /etc/hosts | awk '{print $2}' | while read -r line; do 
        ssh -q -o "ConnectTimeout=4s" $bastion "nc -z -v -w1 $line $port &>/dev/null"
        if [ $? -eq 0 ]; then 
             ok "(SSH/$bastion)$line: ICMP"
        else 
            fail "(SSH/$bastion)$line: ICMP"
        fi
    done
}

synchronize_dir()
{
    local src_host=$1
    local src_rep=$2
    local dest_host=$3
    local dest_rep=${4:-"$2"}
    local src_user=root
    local dest_user=root

    echo "* Copie $src_host:$src_rep => $dest_host:$dest_rep"
    date
    ssh ${src_user}@${src_host} "cd ${src_rep};tar -cvzf - ." | ssh ${dest_user}@${dest_host} "mkdir -p ${dest_rep};cd ${dest_rep};tar -xvzf -"
    date
    ssh ${dest_user}@${dest_host} chown -R postgres. $dest_rep
}
#echo "synchronize_dir alipgflif01 /backups/export_07082019 alipgslir05 /backups/test_07082019"

get_ips_v4()
{
    ip a| grep 'inet ' | grep -v -E '(127.0)'| awk '{print $2}'| cut -d/ -f1
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

# 919  cpall changeIdserver.sh /tmp
#  920  execall "cat /etc/my.cnf.d/60_server.cnf"
#  921  execall "sh /tmp/changeIdserver.sh"
#  922  execall "cat /etc/my.cnf.d/60_server.cnf"
#  923  execall "systemctl restart mariadb"

# execall "setenforce  0"
# execall "cat /tmp/security.sql | mysql"
# cpall 61_galera.cnf  /etc/my.cnf.d/
# cpall changeWsrepConfig.sh /tmp
# execall "sh /tmp/changeWsrepConfig.sh"

