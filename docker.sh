#!/bin/bash

# Start the docker-compose stack in the current directory
alias dcu="docker-compose up -d"

# Start the docker-compose stack in the current directory and rebuild the images
alias dcub="docker-compose up -d --build"

# Stop, delete (down) or restart the docker-compose stack in the current directory
alias dcs="docker-compose stop"
alias dcd="docker-compose down"
alias dcr="docker-compose restart"

# Show the logs for the docker-compose stack in the current directory
# May be extended with the service name to get service-specific logs, like
# 'dcl php' to get the logs of the php container
alias dcl="docker-compose logs"

# Quickly run the docker exec command like this: 'dex container-name bash'
alias dex="docker exec -it"

# 'docker ps' displays the currently running containers
alias dps="docker ps"

# This command is a neat shell pipeline to stop all running containers no matter
# where you are and without knowing any container names
alias dsa="docker ps -q | awk '{print \$1}' | xargs -o docker stop"

# Docker aliases (shortcuts)
# List all containers by status using custom format
alias dpsa='docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"'

# Removes a container, it requires the container name \ ID as parameter
alias drm='docker rm -f'
alias drme="docker ps -a | grep -i existed| awk '{print \$1}' | xargs -n1 docker rm -f"
alias drma="docker ps -a | awk '{print \$1}' | xargs -n1 docker rm -f"

# Removes an image, it requires the image name \ ID as parameter
alias drmi='docker rmi'
# Lists all images by repository sorted by tag name
alias dimg='docker image ls --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}"'
# Lists all persistent volumes
alias dvlm='docker volume ls'
# Diplays a container log, it requires the image name \ ID as parameter
alias dlog='docker logs'
# Streams a container log, it requires the image name \ ID as parameter
alias dlogf='docker logs -f'

# Starts a container, it requires the image name \ ID as parameter
alias dstart='docker start'
# Stops a container, it requires the image name \ ID as parameter
alias dstop='docker stop'


alias drun="docker run -d --rm --name "
alias drunp="docker run -d --restart=always --name "

dfrom()
{
    docker ps -a | grep -E "$1" | awk '{print $1}'
}