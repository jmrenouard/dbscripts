#!/bin/bash


[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh
[ -f "/etc/profile.d/docker.sh" ] && source /etc/profile.d/docker.sh

lRC=0

title1 "PROVISIONNING DOCKER PORTAINER AGENT"
systemctl start docker

docker run -d -p 9001:9001 \
--name portainer_agent --restart=always \
-v /var/run/docker.sock:/var/run/docker.sock \
-v /var/lib/docker/volumes:/var/lib/docker/volumes portainer/agent

