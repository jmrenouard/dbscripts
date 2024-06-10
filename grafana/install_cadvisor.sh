#!/bin/bash

version="${VERSION:-"0.49.1"}"
arch="${ARCH:-"linux-amd64"}"
bin_dir="${BIN_DIR:-/usr/local/bin}"

mkdir -p /usr/local/bin
curl -L -o ${bin_dir}/cadvisor "https://github.com/google/cadvisor/releases/download/v${version}/cadvisor-v${version}-${arch}"

chown root:staff $bin_dir/*
chmod 755 $bin_dir/*

systemctl disable cadvisor.service
systemctl stop cadvisor.service

cat <<EOF > /etc/systemd/system/cadvisor.service
[Unit]
Description=Prometheus cadvisor exporter
After=local-fs.target network-online.target network.target
Wants=local-fs.target network-online.target network.target

[Service]
Type=simple
ExecStartPre=-/sbin/iptables -I INPUT 1 -p tcp --dport 9202 -j ACCEPT
ExecStartPre=-/sbin/iptables -I INPUT 3 -p tcp --dport 9202 -j DROP
ExecStart=/usr/local/bin/cadvisor --port 9202

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable cadvisor.service
systemctl start cadvisor.service

echo "SUCCESS! Installation succeeded!"
sleep 2s
curl http://localhost:9202/metrics | wc -l

