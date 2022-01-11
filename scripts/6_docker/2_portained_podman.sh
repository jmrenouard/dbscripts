#!/bin/bash


[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh
[ -f "/etc/profile.d/docker.sh" ] && source /etc/profile.d/docker.sh

lRC=0

title1 "PROVISIONNING DOCKER PORTAINER"
sudo systemctl start podman
sudo systemctl enable podman

sudo docker volume create portainer_data

echo -n "portainer" > /var/tmp/portainer_password

sudo docker ps -a |grep portainer| awk ''| xargs -n 1 sudo docker rm -f

sudo docker run -d -p 9000:9000 -p 8000:8000 \
--name=portainer --restart=always \
-v /var/run/docker.sock:/var/run/docker.sock \
-v portainer_data:/data \
-v /var/tmp/portainer_password:/var/tmp/portainer_password portainer/portainer-ce \
--admin-password-file /var/tmp/portainer_password

