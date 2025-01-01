#!/bin/bash
set -e
#--------------------------------------------------------------------
# Script to Install pushgateway to Ubuntu24.04
#--------------------------------------------------------------------
#
#https://prometheus.io/download/#pushgateway
#
PUSHGATEWAY_VER="1.6.2"

wget https://github.com/prometheus/pushgateway/releases/download/v$PUSHGATEWAY_VER/pushgateway-$PUSHGATEWAY_VER.linux-amd64.tar.gz
tar zxvf pushgateway-*.tar.gz
cp ./pushgateway-$PUSHGATEWAY_VER.linux-amd64/pushgateway /usr/local/bin/

useradd --no-create-home --shell /bin/false pushgateway
chown pushgateway:pushgateway /usr/local/bin/pushgateway


cat <<EOF> /etc/systemd/system/pushgateway.service
[Unit]
Description=Pushgateway Service
After=network.target

[Service]
User=pushgateway
Group=pushgateway
Type=simple
ExecStart=/usr/local/bin/pushgateway \
    --web.listen-address=":9091" \
    --web.telemetry-path="/metrics" \
    --persistence.file="/tmp/metric.store" \
    --persistence.interval=5m \
    --log.level="info" \
    --log.format="json"
ExecReload=/bin/kill -HUP $MAINPID
Restart=on-failure

[Install]
WantedBy=multi-user.target

EOF

systemctl daemon-reload
systemctl enable pushgateway --now
systemctl status pushgateway

netstat -tuplen

