#!/bin/bash
#creation du point de montage
mkdir /mnt/glusterfs
#ajout de notre point de montage à /etc/fstab afin qu'il soit actif au démarrage de notre serveur
cat << 'EOL' |  tee -a /etc/fstab
127.0.0.1:/glustervol1 /mnt/glusterfs glusterfs defaults,_netdev 0 0
EOL
#montage de notre système
mount /mnt/glusterfs
#creation de notre dossier pour le volume docker
mkdir -p /mnt/glusterfs/docker_volume/mariadb
