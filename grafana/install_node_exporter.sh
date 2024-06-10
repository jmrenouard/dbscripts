#!/bin/bash

version="${VERSION:-1.8.1}"
arch="${ARCH:-linux-amd64}"
bin_dir="${BIN_DIR:-/usr/local/bin}"

#wget "https://github.com/prometheus/node_exporter/releases/download/v$version/node_exporter-$version.$arch.tar.gz" \
#    -O /tmp/node_exporter.tar.gz \

curl -L o /tmp/node_exporter.tar.gz \
https://github.com/prometheus/node_exporter/releases/download/v$version/node_exporter-$version.$arch.tar.gz

mkdir -p /usr/local/bin
mkdir -p /tmp/node_exporter

cd /tmp || { echo "ERROR! No /tmp found.."; exit 1; }

tar xfz /tmp/node_exporter.tar.gz -C /tmp/node_exporter || { echo "ERROR! Extracting the node_exporter tar"; exit 1; }

cp "/tmp/node_exporter/node_exporter-$version.$arch/node_exporter" "$bin_dir"/node_exporter
chown root:staff "$bin_dir/node_exporter"
chmod 755 "$bin_dir/node_exporter"

systemctl disable node_exporter.service
systemctl stop node_exporter.service

cat <<EOF > /etc/systemd/system/node_exporter.service
[Unit]
Description=Prometheus node exporter
After=local-fs.target network-online.target network.target
Wants=local-fs.target network-online.target network.target

[Service]
Type=simple
ExecStartPre=-/sbin/iptables -I INPUT 1 -p tcp --dport 9100 -j ACCEPT
ExecStartPre=-/sbin/iptables -I INPUT 3 -p tcp --dport 9100 -j DROP
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF

systemctl enable node_exporter.service
systemctl start node_exporter.service

echo "SUCCESS! Installation succeeded!"

sleep 2s
curl http://localhost:9100/metrics | wc -l