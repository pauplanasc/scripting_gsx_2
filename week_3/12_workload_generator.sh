#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# ==============================
# 12_workload_generator.sh
# Creates CPU workload using yes command
# ==============================

NUM_PROCESSES="${1:-2}"

if ! [[ "$NUM_PROCESSES" =~ ^[0-9]+$ ]] || [[ "$NUM_PROCESSES" -le 0 ]]; then
    echo "Usage: $0 [number_of_processes]"
    exit 1
fi

# Store PIDs
declare -a PIDS=()

cleanup() {
    echo "Cleaning up workload processes..."
    for pid in "${PIDS[@]}"; do
        if kill -0 "$pid" 2>/dev/null; then
            kill -TERM "$pid" 2>/dev/null || true
        fi
    done
    wait
    echo "All workload processes terminated."
}

trap cleanup EXIT

echo "Starting $NUM_PROCESSES CPU workload processes..."

for ((i=1; i<=NUM_PROCESSES; i++)); do
    yes > /dev/null &
    PIDS+=("$!")
    echo "Started yes process with PID ${PIDS[-1]}"
done

echo
echo "Use Ctrl+C to stop gracefully."
echo "Monitor with: top or ps -eo pid,%cpu,comm --sort=-%cpu | head"

wait