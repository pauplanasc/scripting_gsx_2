#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# ==============================
# 09_top_consumer.sh
# Lists top CPU and Memory consumers
# ==============================

# Default number of processes to display
TOP_N="${1:-5}"

# Validate input (must be positive integer)
if ! [[ "$TOP_N" =~ ^[0-9]+$ ]] || [[ "$TOP_N" -le 0 ]]; then
    echo "Usage: $0 [number_of_processes]"
    exit 1
fi

# Check required commands
for cmd in ps sort head; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Error: Required command '$cmd' not found."
        exit 1
    fi
done

echo "======================================"
echo " Top $TOP_N Processes by CPU Usage"
echo "======================================"
ps -eo pid,ppid,user,%cpu,%mem,comm --sort=-%cpu | head -n "$((TOP_N + 1))"

echo
echo "======================================"
echo " Top $TOP_N Processes by Memory Usage"
echo "======================================"
ps -eo pid,ppid,user,%cpu,%mem,comm --sort=-%mem | head -n "$((TOP_N + 1))"

echo
echo "Script completed successfully."