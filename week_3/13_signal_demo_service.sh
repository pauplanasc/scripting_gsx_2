#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# ==============================
# 12_signal_demo.sh
# Demonstrates signal handling
# ==============================

RUNNING=true
COUNTER=0

graceful_shutdown() {
    echo
    echo "SIGINT received: Performing graceful shutdown..."
    echo "Saving state before exit..."
    echo "Final counter value: $COUNTER"
    RUNNING=false
}

handle_usr1() {
    echo
    echo "SIGUSR1 received: Current counter = $COUNTER"
}

handle_usr2() {
    echo
    echo "SIGUSR2 received: Simulating state checkpoint..."
}

trap graceful_shutdown SIGINT
trap handle_usr1 SIGUSR1
trap handle_usr2 SIGUSR2

echo "Signal demo running with PID $$"
echo "Send signals using:"
echo "  kill -USR1 $$"
echo "  kill -USR2 $$"
echo "  kill -INT  $$  (graceful stop)"
echo

while "$RUNNING"; do
    COUNTER=$((COUNTER + 1))
    sleep 1
done

echo "Exited cleanly."