#!/bin/bash

################################################################################
# AudioGridder Setup pour REAPER OS
# Serveur de VST Windows avec isolation complète
# AudioGridder = VST Host Windows en réseau/IPC depuis REAPER
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WINE_PREFIX="${WINE_PREFIX:-$HOME/.wine}"
AUDIOGRIDDER_PATH="${AUDIOGRIDDER_PATH:-/opt/audiogridder}"

log_info() { echo "[AUDIOGRIDDER] $1"; }
log_err() { echo "[ERROR] $1"; exit 1; }

log_info "╔═════════════════════════════════════════╗"
log_info "║  AudioGridder Setup pour REAPER OS      ║"
log_info "║  VST Windows Server avec Isolation      ║"
log_info "╚═════════════════════════════════════════╝"

# ==============================================================================
# 1. Télécharger et installer AudioGridder
# ==============================================================================

install_audiogridder() {
    log_info "Installation d'AudioGridder..."
    
    # Détecter l'architecture
    ARCH=$(uname -m)
    case $ARCH in
        x86_64)
            AUDIOGRIDDER_ARCH="linux_x86_64"
            ;;
        i686)
            AUDIOGRIDDER_ARCH="linux_x86"
            ;;
        *)
            log_err "Architecture non supportée: $ARCH"
            ;;
    esac
    
    # Télécharger la dernière version
    log_info "Téléchargement d'AudioGridder (dernière version)..."
    
    mkdir -p "$AUDIOGRIDDER_PATH"
    cd "$AUDIOGRIDDER_PATH"
    
    # Récupérer la dernière release depuis GitHub
    RELEASE_URL=$(curl -s https://api.github.com/repos/apohl79/audiogridder/releases/latest \
        | grep "browser_download_url.*${AUDIOGRIDDER_ARCH}" | cut -d'"' -f4 | head -1)
    
    if [ -z "$RELEASE_URL" ]; then
        log_err "Impossible de trouver AudioGridder pour $ARCH"
    fi
    
    log_info "Téléchargement depuis: $RELEASE_URL"
    wget -q "$RELEASE_URL" -O audiogridder.tar.gz
    
    # Extraire
    tar -xzf audiogridder.tar.gz
    rm audiogridder.tar.gz
    
    log_info "AudioGridder installé dans: $AUDIOGRIDDER_PATH"
}

# ==============================================================================
# 2. Créer la configuration AudioGridder
# ==============================================================================

setup_audiogridder_config() {
    log_info "Configuration d'AudioGridder..."
    
    mkdir -p "$HOME/.config/AudioGridder"
    
    # Configuration du serveur AudioGridder
    cat > "$HOME/.config/AudioGridder/server.conf" << 'EOF'
[Server]
# Port d'écoute (IPC Unix socket par défaut)
port=55055
# Adresse IP (127.0.0.1 pour localhost seulement)
bind=127.0.0.1
# Support SSL (optionnel)
# ssl=true

[VST]
# Chemin des VST Windows
vstpath=~/.wine/drive_c/Program Files/Common Files/VST:~/.wine/drive_c/Program Files (x86)/Common Files/VST:~/.wine/drive_c/Program Files/Common Files/VST3

# Latency compensation
latencyCompensation=true

# CPU load limiting (%)
cpuLoad=90

# Preset directory
presetDir=~/.config/AudioGridder/presets

[Audio]
# Configuration audio JACK
sampleRate=48000
bufferSize=256
channels=2

[Debug]
# Debug mode (false pour production)
debug=false
# Log file
logFile=~/.config/AudioGridder/server.log
EOF
    
    log_info "Configuration créée: $HOME/.config/AudioGridder/server.conf"
}

# ==============================================================================
# 3. Installer le plugin VST AudioGridder dans REAPER
# ==============================================================================

setup_audiogridder_vst() {
    log_info "Installation du plugin AudioGridder pour REAPER..."
    
    # Copier le plugin VST dans le répertoire REAPER
    local vst_path="$HOME/.wine/drive_c/Program Files/Common Files/VST/AudioGridder.dll"
    
    if [ -f "$AUDIOGRIDDER_PATH/AudioGridder.dll" ]; then
        cp "$AUDIOGRIDDER_PATH/AudioGridder.dll" "$vst_path"
        log_info "Plugin VST installé: $vst_path"
    else
        log_info "Note: Plugin VST AudioGridder sera scanné automatiquement"
    fi
    
    # Créer aussi un raccourci VST3 si disponible
    if [ -d "$HOME/.wine/drive_c/Program Files/Common Files/VST3" ]; then
        cp "$AUDIOGRIDDER_PATH/AudioGridder.vst3" \
            "$HOME/.wine/drive_c/Program Files/Common Files/VST3/" 2>/dev/null || true
    fi
}

# ==============================================================================
# 4. Créer un service systemd pour AudioGridder Server
# ==============================================================================

setup_systemd_service() {
    log_info "Création du service systemd AudioGridder..."
    
    mkdir -p "$HOME/.config/systemd/user"
    
    cat > "$HOME/.config/systemd/user/audiogridder-server.service" << EOF
[Unit]
Description=AudioGridder Server (VST Windows Plugin Host)
After=jack.service pulseaudio.service

[Service]
Type=simple
ExecStart=$AUDIOGRIDDER_PATH/AudioGridderServer
Restart=on-failure
RestartSec=5

# Audio settings
Environment="WINE_PREFIX=$WINE_PREFIX"
Environment="WINEARCH=win64"
Environment="PULSE_LATENCY_MSEC=10"
Environment="JACK_LATENCY_CB=1"

# CPU affinity (utiliser le premier CPU core)
CPUAffinity=0

[Install]
WantedBy=default.target
EOF
    
    # Recharger systemd
    systemctl --user daemon-reload
    
    log_info "Service systemd créé"
    log_info "Démarrer le serveur avec: systemctl --user start audiogridder-server"
}

# ==============================================================================
# 5. Créer un script de démarrage du serveur AudioGridder
# ==============================================================================

create_server_launcher() {
    log_info "Création du launcher serveur..."
    
    cat > "$SCRIPT_DIR/../scripts/audiogridder-server-start.sh" << 'EOF'
#!/bin/bash
# Lance le serveur AudioGridder pour REAPER

export WINE_PREFIX="${WINE_PREFIX:-$HOME/.wine}"
export WINEARCH=win64
export WINEPREFIX="$WINE_PREFIX"

# Variables audio optimisées
export PULSE_LATENCY_MSEC=10
export JACK_LATENCY_CB=1
export DXVK_ASYNC=1

AUDIOGRIDDER_SERVER="/opt/audiogridder/AudioGridderServer"

if [ ! -f "$AUDIOGRIDDER_SERVER" ]; then
    echo "❌ AudioGridder Server non trouvé à: $AUDIOGRIDDER_SERVER"
    exit 1
fi

echo "🔌 Démarrage du serveur AudioGridder..."
echo "   Plugin: VST Windows Host"
echo "   Port: 55055"
echo ""

exec "$AUDIOGRIDDER_SERVER"
EOF
    
    chmod +x "$SCRIPT_DIR/../scripts/audiogridder-server-start.sh"
    log_info "Launcher créé: $SCRIPT_DIR/../scripts/audiogridder-server-start.sh"
}

# ==============================================================================
# 6. Configurer Wine pour AudioGridder (optimisations)
# ==============================================================================

optimize_wine_for_audiogridder() {
    log_info "Optimisation de Wine pour AudioGridder..."
    
    export WINEPREFIX="$WINE_PREFIX"
    export WINEARCH=win64
    
    # Désactiver certaines features qui peuvent ralentir
    wine reg add 'HKEY_CURRENT_USER\Software\Wine\Direct3D' \
        /v CSMT /d disabled /t REG_SZ /f 2>/dev/null || true
    
    wine reg add 'HKEY_CURRENT_USER\Software\Wine\Direct3D' \
        /v VideoMemorySize /d "4096" /t REG_SZ /f 2>/dev/null || true
    
    log_info "Wine optimisé pour AudioGridder"
}

# ==============================================================================
# 7. Créer un helper script pour utiliser AudioGridder
# ==============================================================================

create_usage_guide() {
    log_info "Création du guide d'utilisation..."
    
    cat > "$SCRIPT_DIR/../scripts/audiogridder-usage.sh" << 'EOF'
#!/bin/bash

echo "╔════════════════════════════════════════════╗"
echo "║     AudioGridder - Usage Guide             ║"
echo "╚════════════════════════════════════════════╝"
echo ""

echo "1️⃣  DÉMARRER LE SERVEUR AudioGridder:"
echo "   systemctl --user start audiogridder-server"
echo "   ou"
echo "   bash ~/.config/reaper-os/scripts/audiogridder-server-start.sh &"
echo ""

echo "2️⃣  VÉRIFIER QUE LE SERVEUR EST ACTIF:"
echo "   systemctl --user status audiogridder-server"
echo "   ou"
echo "   netstat -tln | grep 55055"
echo ""

echo "3️⃣  DANS REAPER:"
echo "   a) Ouvrir REAPER normalement"
echo "   b) Insert FX → Search 'AudioGridder'"
echo "   c) Sélectionner le plugin AudioGridder"
echo ""

echo "4️⃣  DANS LE PLUGIN AudioGridder:"
echo "   a) Connect: 127.0.0.1:55055"
echo "   b) Load VST Windows depuis le serveur"
echo "   c) Le VST s'exécute isolé dans le serveur"
echo ""

echo "5️⃣  AVANTAGES DE AudioGridder:"
echo "   ✅ VST Windows isolés (crash ≠ crash REAPER)"
echo "   ✅ Latence minimale"
echo "   ✅ Meilleure gestion des ressources"
echo "   ✅ Support multi-instance"
echo "   ✅ Scan de plugins optimisé"
echo ""

echo "6️⃣  ARRÊTER LE SERVEUR:"
echo "   systemctl --user stop audiogridder-server"
echo ""

echo "📚 Documentation: https://www.audiogridder.com"
echo ""
EOF
    
    chmod +x "$SCRIPT_DIR/../scripts/audiogridder-usage.sh"
    log_info "Guide créé"
}

# ==============================================================================
# MAIN
# ==============================================================================

main() {
    check_requirements() {
        # Vérifier Wine
        if ! command -v wine &> /dev/null; then
            log_err "Wine n'est pas installé"
        fi
        
        # Vérifier curl
        if ! command -v curl &> /dev/null; then
            log_err "curl n'est pas installé"
        fi
        
        # Vérifier git
        if ! command -v git &> /dev/null; then
            log_err "git n'est pas installé"
        fi
    }
    
    check_requirements
    
    install_audiogridder
    setup_audiogridder_config
    setup_audiogridder_vst
    setup_systemd_service
    create_server_launcher
    optimize_wine_for_audiogridder
    create_usage_guide
    
    echo ""
    log_info "╔════════════════════════════════════════════╗"
    log_info "║  ✅ AudioGridder Setup Complété!          ║"
    log_info "╚════════════════════════════════════════════╝"
    echo ""
    log_info "Prochaines étapes:"
    log_info "1. Démarrer le serveur:"
    log_info "   systemctl --user start audiogridder-server"
    log_info ""
    log_info "2. Ouvrir REAPER et scanner les VST"
    log_info "   reaper-start"
    log_info ""
    log_info "3. Utiliser le plugin AudioGridder VST dans REAPER"
    echo ""
}

main "$@"
