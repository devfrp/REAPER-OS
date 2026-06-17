#!/bin/bash

################################################################################
# Initialisation de la configuration REAPER pour REAPER OS
# Configure REAPER au premier boot
################################################################################

set -e

REAPER_CONFIG_DIR="${REAPER_CONFIG_DIR:-$HOME/.config/REAPER}"
WINE_PREFIX="${WINE_PREFIX:-$HOME/.wine}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log_info() { echo "[REAPER CONFIG] $1"; }

main() {
    log_info "Initialisation de REAPER..."
    
    # Créer les dossiers de configuration
    mkdir -p "$REAPER_CONFIG_DIR"
    mkdir -p "$HOME/.cache/reaper/vst-scan"
    
    # Créer reaper.ini avec configuration optimale
    cat > "$REAPER_CONFIG_DIR/reaper.ini" << 'EOF'
[AUDIO]
audiodevice=JACK
buffersize=256
samplerate=48000
recordmeterdb=1
preciseaudiotime=1

[VST]
vstpath=C:\Program Files\Common Files\VST;C:\Program Files (x86)\Common Files\VST
vstpath3=C:\Program Files\Common Files\VST3
vstcache=1
vstrescan=0
vstarchitect=2
vstarchitect2=2

[INTERFACE]
theme=dark
fontsize=14
customtheme=reaper-dark.ReaperThemeZip

[JACK]
jackconnect=1
jackautoconnect=1
jacklatency=128
jackbuffering=256

[MIDI]
midiindev=all
midioutdev=
midieventmode=1
midiccmode=1

[PERFORMANCE]
maxdiskio=16384
buildcache=1
asyncmixmode=1

[GENERAL]
screenupdatetime=0
checkforupdates=0
EOF
    
    log_info "Configuration REAPER créée"
    
    # Setup des protocoles de contrôle
    log_info "Configuration des protocoles de contrôle (MCU, Eucon, OSC, etc.)..."
    if [ -f "$SCRIPT_DIR/control-protocols-setup.sh" ]; then
        bash "$SCRIPT_DIR/control-protocols-setup.sh"
    fi
    
    # Créer le script de lancement REAPER
    cat > "$SCRIPT_DIR/../scripts/start-reaper.sh" << 'EOF'
#!/bin/bash
# Lance REAPER avec configuration REAPER OS

export WINE_PREFIX="${WINE_PREFIX:-$HOME/.wine}"
export REAPER_CONFIG_DIR="${REAPER_CONFIG_DIR:-$HOME/.config/REAPER}"

# Charger les variables Wine/Proton
if [ -f "$SCRIPT_DIR/../wine-config/wine-env.conf" ]; then
    source "$SCRIPT_DIR/../wine-config/wine-env.conf"
fi

# Chercher REAPER
REAPER_EXE="$WINE_PREFIX/drive_c/Program Files/REAPER/reaper.exe"

if [ ! -f "$REAPER_EXE" ]; then
    echo "REAPER non trouvé à: $REAPER_EXE"
    echo "Installation nécessaire"
    exit 1
fi

echo "🎵 Démarrage de REAPER..."
wine "$REAPER_EXE"
EOF
    
    chmod +x "$SCRIPT_DIR/../scripts/start-reaper.sh"
    
    log_info "Configuration REAPER terminée!"
}

main "$@"
