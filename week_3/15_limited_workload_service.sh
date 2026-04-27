#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# ==============================
# 15_limited_workload_service.sh
# Creates a systemd service with CPU & memory limits
# ==============================

SERVICE_NAME="limited-workload.service"
SERVICE_PATH="/etc/systemd/system/$SERVICE_NAME"

if [[ ! -f "$SERVICE_PATH" ]]; then
    echo "Creating $SERVICE_NAME..."

    cat <<EOF | sudo tee "$SERVICE_PATH" > /dev/null
[Unit]
Description=Limited CPU & Memory Workload
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/yes
Restart=always

# Resource limits (cgroups v2)
CPUQuota=30%
MemoryMax=100M

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable "$SERVICE_NAME"
else
    echo "$SERVICE_NAME already exists. Skipping creation."
fi

echo "Starting service..."
sudo systemctl restart "$SERVICE_NAME"

echo "Service status:"
systemctl status "$SERVICE_NAME" --no-pager