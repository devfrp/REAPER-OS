#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${SCRIPT_DIR}/.."

echo "╔═══════════════════════════════════════════╗"
echo "║   REAPER OS - System Start                ║"
echo "╚═══════════════════════════════════════════╝"
echo ""

export REAPER_OS_ROOT="$PROJECT_ROOT"
export PATH="$PROJECT_ROOT/tools:$PATH"

if [ -f "$PROJECT_ROOT/scripts/setup-asnux.sh" ]; then
    bash "$PROJECT_ROOT/scripts/setup-asnux.sh"
fi

if [ -f "$PROJECT_ROOT/scripts/setup-jack.sh" ]; then
    bash "$PROJECT_ROOT/scripts/setup-jack.sh"
fi

if [ -f "$PROJECT_ROOT/scripts/start-reaper.sh" ]; then
    exec bash "$PROJECT_ROOT/scripts/start-reaper.sh"
else
    echo "Error: start-reaper.sh not found"
    exit 1
fi
