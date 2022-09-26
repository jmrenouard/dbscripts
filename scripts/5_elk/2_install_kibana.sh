#!/bin/bash

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh

lRC=0
defaultPassword="elastic"
banner "BEGIN SCRIPT: $_NAME"

title1 "STEP 1: INSTALL AND CONFIGURE KIBANA"
cmd "dnf -y install java-1.8.0-openjdk"
[ $? -ne 0 ] && exit 127

cmd "dnf -y update"
[ $? -ne 0 ] && exit 127

cmd "dnf -y install kibana"
[ $? -ne 0 ] && exit 127


cmd "/bin/systemctl daemon-reload"

cmd "/bin/systemctl enable kibana.service"

sed -i -e "/server.host/d" \
-e "/server.name/d" \
-e "/elasticsearch.hosts/d" \
-e "/elasticsearch.username/d" \
-e "/elasticsearch.password/d" \
/etc/kibana/kibana.yml
[ $? -ne 0 ] && exit 127
echo "
server.host: 0.0.0.0
server.name: \"Test Kibana Server\"

elasticsearch.hosts: [ \"http://localhost:9200\" ]
elasticsearch.username: \"elastic\"
elasticsearch.password: \"elastic\"" >>/etc/kibana/kibana.yml

firewall-cmd --zone=public --permanent --add-port=5601/tcp
firewall-cmd --zone=public --permanent --add-port=9200/tcp

cmd "/bin/systemctl restart kibana.service"

info "ACEESS to http://${my_private_ipv4}:5601/ elastic/alastic"
footer "END SCRIPT: $NAME"
exit $lRC

