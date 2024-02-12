#!/bin/bash

# flush the DOCKER-USER (remove old rules)
iptables -F DOCKER-USER

# add rules specifically for lxdbr0
iptables -A DOCKER-USER -o lxdbr0 -j ACCEPT
iptables -A DOCKER-USER -i lxdbr0 -j ACCEPT