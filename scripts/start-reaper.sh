#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Charger la configuration Wine (si existe)
if [ -f "/opt/reaper-os/wine-config/wine-env.conf" ]; then
    source "/opt/reaper-os/wine-config/wine-env.conf"
fi

# Essayer REAPER natif Linux d'abord
REAPER_NATIVE=""
for reaper_path in /opt/REAPER/reaper /opt/reaper-linux/reaper /usr/local/bin/reaper /usr/bin/reaper; do
    if [ -x "$reaper_path" ]; then
        REAPER_NATIVE="$reaper_path"
        break
    fi
done

if [ -n "$REAPER_NATIVE" ]; then
    echo ""
    echo "╔═══════════════════════════════════════════╗"
    echo "║   REAPER OS - Professional DAW            ║"
    echo "║   Démarrage de REAPER (Linux natif)...    ║"
    echo "╚═══════════════════════════════════════════╝"
    echo ""
    exec "$REAPER_NATIVE" "$@"
fi

# Fallback: REAPER via Wine
export WINE_PREFIX="${WINE_PREFIX:-$HOME/.wine}"
export WINEARCH=win64
export WINEPREFIX="$WINE_PREFIX"

REAPER_EXE="$WINE_PREFIX/drive_c/Program Files/REAPER/reaper.exe"

if [ ! -f "$REAPER_EXE" ]; then
    REAPER_EXE="$(find "$WINE_PREFIX" -name "reaper.exe" 2>/dev/null | head -1)"
fi

if [ ! -f "$REAPER_EXE" ]; then
    echo ""
    echo "╔═══════════════════════════════════════════╗"
    echo "║   REAPER Non Trouvé                       ║"
    echo "╚═══════════════════════════════════════════╝"
    echo ""
    echo "REAPER doit être installé pour continuer."
    echo ""
    echo "Téléchargement: https://www.cockos.com/reaper/download-linux/"
    echo ""
    xdg-open "https://www.cockos.com/reaper/download-linux/" &
    exit 1
fi

echo ""
echo "╔═══════════════════════════════════════════╗"
echo "║   REAPER OS - Professional DAW            ║"
echo "║   Démarrage de REAPER (Wine)...           ║"
echo "╚═══════════════════════════════════════════╝"
echo ""

exec wine "$REAPER_EXE" "$@"
