#!/bin/bash

source /etc/os-release

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
my_private_ipv4=$(ip a | grep inet | grep 'brd' | grep -E '(192.168|172.2)'| cut -d/ -f1 | awk '{print $2}'|head -n1)

lRC=0
defaultPassword="elastic"
banner "BEGIN SCRIPT: ${_NAME}"

title1 "STEP 1: INSTALL AND CONFIGURE ELASTICSEARCH"
cmd "dnf -y install java-1.8.0-openjdk" "INSTALL JAVA JDK 8"
[ $? -ne 0 ] && exit 127

cmd "rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch"
[ $? -ne 0 ] && exit 127


echo "[elasticstack]
name=Elastic repository for 7.x packages
baseurl=https://artifacts.elastic.co/packages/7.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md" > /etc/yum.repos.d/elacticsearch.repo

cmd "dnf -y update"
[ $? -ne 0 ] && exit 127

cmd "dnf -y install elasticsearch"
[ $? -ne 0 ] && exit 127

sed -i -e "/network.host/d" \
-e "/http.port/d" \
-e "/discovery.type/d" \
-e "/xpack.security.enabled/d" \
/etc/elasticsearch/elasticsearch.yml
[ $? -ne 0 ] && exit 127
echo "
#network.host: $my_private_ipv4
network.host: 0.0.0.0
#network.bind_host: \"0.0.0.0\"
http.port: 9200

discovery.type: single-node

xpack.security.enabled: true
" >>/etc/elasticsearch/elasticsearch.yml

sed -i '/preferIPv4Stack/d' /etc/elasticsearch/jvm.options
echo "-Djava.net.preferIPv4Stack=true" >> /etc/elasticsearch/jvm.options
grep -E "(http.port|network.host)" /etc/elasticsearch/elasticsearch.yml

export PATH=$PATH:/usr/share/elasticsearch


firewall-cmd --zone=public --permanent --add-port=9200/tcp
firewall-cmd --zone=public --permanent --add-port=5601/tcp

title1 "STEP 2: START ELASTICSEARCH SERVICE"
cmd "/bin/systemctl stop elasticsearch"

rm -rf /var/lib/elasticsearch/* /etc/elasticsearch/elasticsearch.keystore
/usr/share/elasticsearch/bin/elasticsearch-keystore create -v

cmd "/bin/systemctl daemon-reload"

cmd "/bin/systemctl enable elasticsearch.service"

# Configure Bootstrap Password
BootstrapPassword="${defaultPassword}"
printf "%s" "$BootstrapPassword" \
  | /usr/share/elasticsearch/bin/elasticsearch-keystore add -x "bootstrap.password"

cmd "/bin/systemctl restart elasticsearch.service"
[ $? -ne 0 ] && exit 127

# Set passwords for various users
for User in "kibana" "logstash_system" "apm_system" "beats_system" "elastic"
do
  UserPassword="${defaultPassword}"
  curl -u "elastic:${BootstrapPassword}" \
    -XPOST "http://localhost:9200/_xpack/security/user/${User}/_password" \
    -d'{"password":"'"${UserPassword}"'"}' -H "Content-Type: application/json"
  printf "\n * %s=%s\n" "$User" "$UserPassword"
done

curl -u "elastic:elastic" "http://localhost:9200/_cluster/health" 2>/dev/null
lRC=$?
echo ""


footer "END SCRIPT: ${_NAME}"
exit $lRC
