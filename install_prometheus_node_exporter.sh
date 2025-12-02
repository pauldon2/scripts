#!/bin/bash
set -ex
#--------------------------------------------------------------------
# Script to Install Prometheus Node_Exporter on Ubuntu 24.04 Linux
#--------------------------------------------------------------------
# https://github.com/prometheus/node_exporter/releases
NODE_EXPORTER_VERSION="1.10.2"

useradd --system --no-create-home --shell /bin/false node_exporter

cd /tmp
wget https://github.com/prometheus/node_exporter/releases/download/v$NODE_EXPORTER_VERSION/node_exporter-$NODE_EXPORTER_VERSION.linux-amd64.tar.gz
tar xvfz node_exporter-$NODE_EXPORTER_VERSION.linux-amd64.tar.gz
cd node_exporter-$NODE_EXPORTER_VERSION.linux-amd64

mv node_exporter /usr/local/bin/

chown node_exporter:node_exporter /usr/local/bin/node_exporter

cat <<EOF> /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target
StartLimitIntervalSec=500
StartLimitBurst=5

[Service]
User=node_exporter
Group=node_exporter
Type=simple
Restart=on-failure
RestartSec=5s
ExecStart=/usr/local/bin/node_exporter \
    --collector.logind

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable node_exporter
systemctl start node_exporter
systemctl status node_exporter

node_exporter --version


