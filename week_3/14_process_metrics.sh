#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# ==============================
# 14_process_metrics.sh
# Extract detailed metrics for a specific PID
# ==============================

PID="${1:-}"

if [[ -z "$PID" ]] || ! [[ "$PID" =~ ^[0-9]+$ ]]; then
    echo "Usage: $0 <PID>"
    exit 1
fi

if [[ ! -d "/proc/$PID" ]]; then
    echo "Process with PID $PID does not exist."
    exit 1
fi

echo "====================================="
echo " Metrics for PID: $PID"
echo "====================================="

STATUS_FILE="/proc/$PID/status"
STAT_FILE="/proc/$PID/stat"

echo
echo "Basic Info:"
grep -E 'Name|State|PPid|Threads|VmSize|VmRSS' "$STATUS_FILE"

echo
echo "CPU Info:"
read -r _ _ _ _ _ _ _ _ _ _ _ _ _ utime stime _ < "$STAT_FILE"

CLK_TCK=$(getconf CLK_TCK)
CPU_TIME=$(( (utime + stime) / CLK_TCK ))

echo "Total CPU Time (seconds): $CPU_TIME"

echo
echo "Open File Descriptors:"
ls -1 "/proc/$PID/fd" 2>/dev/null | wc -l

echo
echo "Done."