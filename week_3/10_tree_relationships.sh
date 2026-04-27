#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# ==============================
# 10_tree_relationship.sh
# Displays process tree relationships
# ==============================

PID_FILTER="${1:-}"

# Check for pstree or fallback
if command -v pstree >/dev/null 2>&1; then
    if [[ -n "$PID_FILTER" ]]; then
        if ! [[ "$PID_FILTER" =~ ^[0-9]+$ ]]; then
            echo "PID must be numeric."
            exit 1
        fi
        echo "Displaying process tree for PID $PID_FILTER"
        pstree -p "$PID_FILTER"
    else
        echo "Displaying full process tree"
        pstree -p
    fi
else
    echo "pstree not found. Falling back to ps --forest"
    if [[ -n "$PID_FILTER" ]]; then
        if ! [[ "$PID_FILTER" =~ ^[0-9]+$ ]]; then
            echo "PID must be numeric."
            exit 1
        fi
        ps -ef --forest | grep -E "PID|$PID_FILTER"
    else
        ps -ef --forest
    fi
fi

echo
echo "Process tree displayed successfully."