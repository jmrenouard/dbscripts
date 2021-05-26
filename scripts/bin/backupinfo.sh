#!/bin/bash

echo "DERNIERS BACKUPS COMPLETS:"
sudo find /backups/mariabackup/base  -mindepth 1 -type d | sort -n
echo "============================================"
echo "DERNIERS BACKUPS INCREMENTAUX:"
sudo find /backups/mariabackup/incr  -mindepth 2 -type d | sort -n
echo "============================================"
