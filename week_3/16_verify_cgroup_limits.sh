#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SERVICE_NAME="limited-workload.service"

echo "Checking systemd limits..."
systemctl show "$SERVICE_NAME" | grep -E "CPUQuota|MemoryMax"

echo
echo "Checking cgroup path..."

CGROUP_PATH=$(systemctl show -p ControlGroup --value "$SERVICE_NAME")

if [[ -z "$CGROUP_PATH" ]]; then
    echo "Could not determine cgroup path."
    exit 1
fi

FULL_PATH="/sys/fs/cgroup$CGROUP_PATH"

echo "Cgroup location: $FULL_PATH"

echo
echo "CPU limit:"
cat "$FULL_PATH/cpu.max" 2>/dev/null || echo "Not available"

echo
echo "Memory limit:"
cat "$FULL_PATH/memory.max" 2>/dev/null || echo "Not available"

echo
echo "Current usage:"
cat "$FULL_PATH/memory.current" 2>/dev/null || echo "Not available"

echo
echo "Verification complete."