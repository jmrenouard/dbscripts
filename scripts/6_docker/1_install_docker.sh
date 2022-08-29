#!/bin/bash


[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh

lRC=0

title1 "PROVISIONNING DOCKER-CE"
yum install -y dnf-utils device-mapper-persistent-data lvm2
yum -y remove docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-engine

yum-config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin nc git

systemctl start docker
docker run hello-world
#usermod -g docker vagrant

systemctl stop docker
systemctl status docker
systemctl start docker
systemctl enable docker
docker images
docker run hello-world
curl -L "https://github.com/docker/compose/releases/download/v2.10.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/bin/docker-compose
chmod +x /usr/bin/docker-compose

(
	cat <<'EndOfScript'
alias dk='docker'
alias dklc='docker ps -l'  # List last Docker container
alias dklcid='docker ps -l -q'  # List last Docker container ID
alias dklcip='docker inspect -f "{{.NetworkSettings.IPAddress}}" $(docker ps -l -q)'  # Get IP of last Docker container
alias dkps='docker ps'  # List running Docker containers
alias dkpsa='docker ps -a'  # List all Docker containers
alias dki='docker images'  # List Docker images
alias dkrmac='docker rm $(docker ps -a -q)'  # Delete all Docker containers

case $OSTYPE in
  darwin*|*bsd*|*BSD*)
    alias dkrmui='docker images -q -f dangling=true | xargs docker rmi'  # Delete all untagged Docker images
    ;;
  *)
    alias dkrmui='docker images -q -f dangling=true | xargs -r docker rmi'  # Delete all untagged Docker images
    ;;
esac

if [ ! -z "$(command ls "${BASH_IT}/enabled/"{[0-9][0-9][0-9]${BASH_IT_LOAD_PRIORITY_SEPARATOR}docker,docker}.plugin.bash 2>/dev/null | head -1)" ]; then
# Function aliases from docker plugin:
    alias dkrmlc='docker-remove-most-recent-container'  # Delete most recent (i.e., last) Docker container
    alias dkrmall='docker-remove-stale-assets'  # Delete all untagged images and exited containers
    alias dkrmli='docker-remove-most-recent-image'  # Delete most recent (i.e., last) Docker image
    alias dkrmi='docker-remove-images'  # Delete images for supplied IDs or all if no IDs are passed as arguments
    alias dkideps='docker-image-dependencies'  # Output a graph of image dependencies using Graphiz
    alias dkre='docker-runtime-environment'  # List environmental variables of the supplied image ID
fi
alias dkelc='docker exec -it $(dklcid) bash --login' # Enter last container (works with Docker 1.3 and above)
alias dkrmflast='docker rm -f $(dklcid)'
alias dkbash='dkelc'
alias dkex='docker exec -it ' # Useful to run any commands into container without leaving host
alias dkri='docker run --rm -i '
alias dkric='docker run --rm -i -v $PWD:/cwd -w /cwd '
alias dkrit='docker run --rm -it '
alias dkritc='docker run --rm -it -v $PWD:/cwd -w /cwd '

# Added more recent cleanup options from newer docker versions
alias dkip='docker image prune -a -f'
alias dkvp='docker volume prune -f'
alias dksp='docker system prune -a -f'
EndOfScript

) | tee /etc/profile.d/docker.sh

chmod 755 /etc/profile.d/docker.sh
