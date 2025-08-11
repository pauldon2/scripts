#!/bin/bash -ex
#Script to Install Prometheus Server on Linux Ubuntu 24.04


PROMETHEUS_VERSION="3.3.0"
PROMETHEUS_CONFIG="/etc/prometheus"
PROMETHEUS_DATA="/var/lib/prometheus"


useradd --no-create-home --shell /bin/false prometheus

mkdir -p $PROMETHEUS_CONFIG
mkdir -p $PROMETHEUS_DATA

cd /tmp

wget https://github.com/prometheus/prometheus/releases/download/v$PROMETHEUS_VERSION/prometheus-$PROMETHEUS_VERSION.linux-amd64.tar.gz
tar xvfz prometheus-$PROMETHEUS_VERSION.linux-amd64.tar.gz
cd prometheus-$PROMETHEUS_VERSION.linux-amd64

#mv console* /etc/prometheus

mv prometheus /usr/local/bin/
mv promtool /usr/local/bin

cat <<EOF> $PROMETHEUS_CONFIG/prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name      : "prometheus"
    static_configs:
      - targets: ["localhost:9090"]
EOF

cat <<EOF> /etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus Server
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
 --config.file ${PROMETHEUS_CONFIG}/prometheus.yml \
 --storage.tsdb.path ${PROMETHEUS_DATA} \
 --web.console.templates=${PROMETHEUS_CONFIG}/consoles \
 --web.console.libraries=${PROMETHEUS_CONFIG}/console_libraries

[Install]
WantedBy=multi-user.target

EOF


chown prometheus:prometheus /var/lib/prometheus
chown -R prometheus:prometheus /etc/prometheus
chown prometheus:prometheus /usr/local/bin/prometheus
chown prometheus:prometheus /usr/local/bin/promtool

#Check config
#promtool check config /etc/prometheus/prometheus.yml

systemctl daemon-reload
systemctl start prometheus
systemctl enable prometheus
systemctl status prometheus --no-pager
prometheus --version
