#!/bin/bash
set -ex
#--------------------------------------------------------------------
# Script to Install VictoriaMetrics Single Server to Ubuntu24.04
#--------------------------------------------------------------------
VC_VERSION="v1.125.1"

apt-get update
apt-get install -y apt-transport-https software-properties-common wget

wget -P /tmp https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/${VC_VERSION}/victoria-metrics-linux-amd64-${VC_VERSION}.tar.gz

tar -xvf /tmp/victoria-metrics-linux-amd64-${VC_VERSION}.tar.gz -C /usr/local/bin
mv /usr/local/bin/victoria-metrics-prod /usr/local/bin/victoria-metrics

chown root:root /usr/local/bin/victoria-metrics

useradd -r -s /usr/sbin/nologin victoriametrics
mkdir -p /var/lib/victoriametrics
chown victoriametrics: /var/lib/victoriametrics

mkdir -p /etc/prometheus

cat <<EOF >/etc/prometheus/scrape.yaml
scrape_configs:
- job_name: node-exporter
  static_configs:
  - targets:
    - localhost:9100
- job_name: victoriametrics
  static_configs:
  - targets:
    - http://localhost:8428/metrics
EOF


cat <<EOF >/etc/systemd/system/victoriametrics.service
[Unit]
Description=VictoriaMetrics service
After=network.target

[Service]
Type=simple
User=victoriametrics
Group=victoriametrics

ExecStart=/usr/local/bin/victoria-metrics \
   -storageDataPath=/var/lib/victoriametrics \
   -retentionPeriod=30d \
   -promscrape.config=/etc/prometheus/scrape.yaml \
   -selfScrapeInterval=10s

SyslogIdentifier=victoriametrics
Restart=always

PrivateTmp=yes
ProtectHome=yes
NoNewPrivileges=yes

ProtectSystem=full

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload && systemctl enable --now victoriametrics.service
systemctl status victoriametrics.service


