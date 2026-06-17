#!/bin/bash

################################################################################
# Audio Interface Auto-Detection and Setup for REAPER OS
# Support for RME, Universal Audio, Focusrite, Behringer, MOTU, etc.
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."
AUDIO_CONFIG_DIR="$HOME/.config/audio-interfaces"
WINE_PREFIX="${WINE_PREFIX:-$HOME/.wine}"

log_info() { echo "[AUDIO] $1"; }
log_warn() { echo "[WARN] $1"; }
log_err() { echo "[ERROR] $1"; exit 1; }

# ==============================================================================
# 1. DÉTECTER LES CARTES AUDIO
# ==============================================================================

detect_audio_interfaces() {
    log_info "Détection des cartes audio..."
    
    mkdir -p "$AUDIO_CONFIG_DIR"
    
    # Lister les cartes USB ALSA
    echo "Cartes audio détectées:" > "$AUDIO_CONFIG_DIR/detected.txt"
    echo "" >> "$AUDIO_CONFIG_DIR/detected.txt"
    
    # Utilisez lsusb et lsalsa pour déterminer les cartes
    log_info "=== Cartes ALSA ===" 
    aplay -l | grep -E "card|device" >> "$AUDIO_CONFIG_DIR/detected.txt" || true
    
    log_info "=== Cartes USB ===" 
    lsusb | grep -iE "RME|Audio|Focusrite|Behringer|MOTU|Universal Audio|Soundcraft" \
        >> "$AUDIO_CONFIG_DIR/detected.txt" || true
    
    cat "$AUDIO_CONFIG_DIR/detected.txt"
}

# ==============================================================================
# 2. IDENTIFIER LE TYPE DE CARTE AUDIO
# ==============================================================================

identify_interface() {
    local vendor_id="$1"
    local product_id="$2"
    
    # Mapping USB Vendor/Product IDs vers nom/config
    case "$vendor_id:$product_id" in
        # RME Interfaces
        0424:*)
            echo "RME"
            ;;
        # Universal Audio
        18d4:*)
            echo "UniversalAudio"
            ;;
        # Focusrite
        1235:*)
            echo "Focusrite"
            ;;
        # Behringer
        1397:*)
            echo "Behringer"
            ;;
        # MOTU
        0a92:*)
            echo "MOTU"
            ;;
        # Roland
        0582:*)
            echo "Roland"
            ;;
        # Ableton Push
        2982:*)
            echo "AbletonPush"
            ;;
        *)
            echo "Unknown"
            ;;
    esac
}

# ==============================================================================
# 3. INSTALLER LES DRIVERS ALSA NATIFS
# ==============================================================================

setup_alsa_native() {
    log_info "Configuration ALSA native..."
    
    # Vérifier ALSA
    if ! command -v aplay &> /dev/null; then
        log_err "ALSA non installé"
    fi
    
    # Installer les firmware optionnels
    sudo apt-get install -y alsa-utils alsa-tools 2>/dev/null || true
    
    # Support USB audio
    sudo modprobe snd_usb_audio 2>/dev/null || true
    sudo modprobe snd_usb_caiaq 2>/dev/null || true  # Native Instruments
    
    log_info "ALSA configuré"
}

# ==============================================================================
# 4. SETUP SPÉCIFIQUE PAR CARTE: RME
# ==============================================================================

setup_rme_interface() {
    log_info "Configuration RME audio interface..."
    
    local serial="$1"
    local card="$2"
    
    # RME Babyface Pro / UFX / Fireface USB
    log_info "Détecté RME $card"
    
    # Installer les tools RME
    sudo apt-get install -y rme-tools 2>/dev/null || true
    
    # Configurar ALSA pour RME
    mkdir -p "$HOME/.alsa"
    cat > "$HOME/.alsa/rme-$card.conf" << 'EOF'
# RME Audio Interface ALSA Configuration
# Supports: Babyface Pro, UFX, UFX II, Fireface USB, Quad-Capture

pcm.rme_input {
    type hw
    card [CARD]
    device 0
}

pcm.rme_output {
    type hw
    card [CARD]
    device 0
}

ctl.rme {
    type hw
    card [CARD]
}
EOF
    
    log_info "RME ALSA config créé: $HOME/.alsa/rme-$card.conf"
    
    # Créer un wrapper Wine pour RME Control Panel (si Windows installer trouvé)
    create_wine_wrapper_rme "$card"
}

create_wine_wrapper_rme() {
    local card="$1"
    
    log_info "Création wrapper Wine pour RME Control Panel..."
    
    # Installer les dépendances Wine si nécessaire
    winetricks vcrun2019 dotnet48 2>/dev/null || true
    
    # Créer le launcher
    mkdir -p "$HOME/.local/bin"
    cat > "$HOME/.local/bin/rme-control-panel" << 'EOF'
#!/bin/bash
# RME Control Panel Wrapper for Wine

export WINE_PREFIX="${WINE_PREFIX:-$HOME/.wine}"
export WINEARCH=win64

# Chercher l'application Windows
RME_APP="$WINE_PREFIX/drive_c/Program Files/RME/RME Control Panel/rme-control-panel.exe"

if [ ! -f "$RME_APP" ]; then
    RME_APP=$(find "$WINE_PREFIX" -name "*rme*control*" -iname "*.exe" 2>/dev/null | head -1)
fi

if [ -z "$RME_APP" ]; then
    echo "❌ RME Control Panel non trouvé"
    echo "Installer RME Control Panel Windows via Wine"
    exit 1
fi

echo "🎛️ Lancement RME Control Panel (Wine)..."
wine "$RME_APP"
EOF
    
    chmod +x "$HOME/.local/bin/rme-control-panel"
    
    # Créer une .desktop entry pour le menu
    mkdir -p "$HOME/.local/share/applications"
    cat > "$HOME/.local/share/applications/rme-control-panel.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=RME Control Panel
Comment=RME Audio Interface Control
Exec=rme-control-panel
Icon=audio-card
Categories=Multimedia;Audio;
EOF
    
    log_info "RME Control Panel wrapper créé"
}

# ==============================================================================
# 5. SETUP SPÉCIFIQUE PAR CARTE: UNIVERSAL AUDIO
# ==============================================================================

setup_universal_audio_interface() {
    log_info "Configuration Universal Audio interface..."
    
    local card="$1"
    
    log_info "Détecté Universal Audio (Apollo, Arrow, Volt, etc.)"
    
    # Support natif ALSA pour UAD
    setup_alsa_native
    
    # Créer wrapper Wine pour UAD Console
    create_wine_wrapper_uad "$card"
}

create_wine_wrapper_uad() {
    local card="$1"
    
    log_info "Création wrapper Wine pour UAD Console..."
    
    # Installer dépendances
    winetricks vcrun2019 dotnet48 d3dx11 2>/dev/null || true
    
    # Créer le launcher
    mkdir -p "$HOME/.local/bin"
    cat > "$HOME/.local/bin/uad-console" << 'EOF'
#!/bin/bash
# Universal Audio Console Wrapper for Wine

export WINE_PREFIX="${WINE_PREFIX:-$HOME/.wine}"
export WINEARCH=win64
export DXVK_ASYNC=1

# Chercher l'application
UAD_APP="$WINE_PREFIX/drive_c/Program Files/Universal Audio/UAD Console/uad-console.exe"

if [ ! -f "$UAD_APP" ]; then
    UAD_APP=$(find "$WINE_PREFIX" -path "*Universal Audio*" -iname "*console*.exe" 2>/dev/null | head -1)
fi

if [ -z "$UAD_APP" ]; then
    echo "❌ UAD Console non trouvé"
    echo "Installer Universal Audio Console via Wine"
    exit 1
fi

echo "🎛️ Lancement UAD Console (Wine)..."
wine "$UAD_APP"
EOF
    
    chmod +x "$HOME/.local/bin/uad-console"
    
    # Desktop entry
    mkdir -p "$HOME/.local/share/applications"
    cat > "$HOME/.local/share/applications/uad-console.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=UAD Console
Comment=Universal Audio Interface Control
Exec=uad-console
Icon=audio-card
Categories=Multimedia;Audio;
EOF
    
    log_info "UAD Console wrapper créé"
}

# ==============================================================================
# 6. SETUP SPÉCIFIQUE PAR CARTE: FOCUSRITE
# ==============================================================================

setup_focusrite_interface() {
    log_info "Configuration Focusrite interface..."
    
    local card="$1"
    
    log_info "Détecté Focusrite (Scarlett, Clarett, etc.)"
    
    # Support natif ALSA
    setup_alsa_native
    
    # Focusrite a généralement bon support ALSA natif
    # Mais on peut créer un wrapper pour Focusrite Control
    create_wine_wrapper_focusrite "$card"
}

create_wine_wrapper_focusrite() {
    local card="$1"
    
    log_info "Création wrapper Wine pour Focusrite Control..."
    
    winetricks vcrun2019 2>/dev/null || true
    
    mkdir -p "$HOME/.local/bin"
    cat > "$HOME/.local/bin/focusrite-control" << 'EOF'
#!/bin/bash
export WINE_PREFIX="${WINE_PREFIX:-$HOME/.wine}"
export WINEARCH=win64

FOCUSRITE_APP="$WINE_PREFIX/drive_c/Program Files/Focusrite/Focusrite Control/focusrite-control.exe"

if [ ! -f "$FOCUSRITE_APP" ]; then
    FOCUSRITE_APP=$(find "$WINE_PREFIX" -path "*Focusrite*" -iname "*control*.exe" 2>/dev/null | head -1)
fi

if [ -z "$FOCUSRITE_APP" ]; then
    echo "Focusrite Control non trouvé"
    exit 1
fi

echo "🎛️ Lancement Focusrite Control (Wine)..."
wine "$FOCUSRITE_APP"
EOF
    
    chmod +x "$HOME/.local/bin/focusrite-control"
    
    mkdir -p "$HOME/.local/share/applications"
    cat > "$HOME/.local/share/applications/focusrite-control.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=Focusrite Control
Comment=Focusrite Interface Control
Exec=focusrite-control
Icon=audio-card
Categories=Multimedia;Audio;
EOF
}

# ==============================================================================
# 7. SETUP SPÉCIFIQUE: BEHRINGER / MOTU / AUTRES
# ==============================================================================

setup_generic_interface() {
    local interface_type="$1"
    local card="$2"
    
    log_info "Configuration générique pour $interface_type..."
    
    # Support ALSA natif
    setup_alsa_native
    
    # Charger les modules USB appropriés
    case "$interface_type" in
        MOTU)
            sudo modprobe snd_usb_caiaq 2>/dev/null || true
            ;;
        Behringer)
            # Behringer a généralement bon support ALSA
            sudo modprobe snd_usb_audio 2>/dev/null || true
            ;;
    esac
    
    log_info "$interface_type config terminé"
}

# ==============================================================================
# 8. CONFIGURER JACK POUR LA CARTE
# ==============================================================================

setup_jack_for_interface() {
    local card_number="$1"
    local interface_name="$2"
    
    log_info "Configuration JACK pour $interface_name (carte $card_number)..."
    
    mkdir -p "$HOME/.config"
    
    # Créer configuration JACK optimale pour la carte
    cat > "$HOME/.jackrc-$interface_name" << EOF
#!/bin/bash
# JACK configuration for $interface_name

# Audio interface
JACK_DEVICE="hw:$card_number"

# Paramètres audio
SAMPLE_RATE=48000
BUFFER_SIZE=256
PERIODS=2

# Lancer JACK
/usr/bin/jackd -R -d alsa -d \$JACK_DEVICE -r \$SAMPLE_RATE -p \$BUFFER_SIZE -n \$PERIODS
EOF
    
    chmod +x "$HOME/.jackrc-$interface_name"
    
    log_info "JACK config créé: $HOME/.jackrc-$interface_name"
}

# ==============================================================================
# 9. CRÉER UN SCRIPT DE DÉMARRAGE UNIFIÉ
# ==============================================================================

create_unified_launcher() {
    log_info "Création du launcher audio unifié..."
    
    mkdir -p "$HOME/.local/bin"
    cat > "$HOME/.local/bin/audio-interface-manager" << 'EOF'
#!/bin/bash
# Unified Audio Interface Manager for REAPER OS

echo "╔════════════════════════════════════════╗"
echo "║ Audio Interface Manager - REAPER OS    ║"
echo "╚════════════════════════════════════════╝"
echo ""

# Lister les cartes disponibles
echo "Cartes audio disponibles:"
aplay -l | grep -E "card.*:" | nl

echo ""
echo "Options:"
echo "  1) Démarrer JACK avec carte par défaut"
echo "  2) Démarrer JACK avec une carte spécifique"
echo "  3) Ouvrir le Control Panel (RME/UAD/Focusrite)"
echo "  4) Test audio"
echo "  5) Afficher les logs JACK"
echo ""
read -p "Choix: " choice

case "$choice" in
    1)
        echo "Démarrage JACK..."
        jackd -d alsa &
        sleep 2
        echo "✓ JACK en cours d'exécution"
        jack_lsp
        ;;
    2)
        read -p "Numéro de carte: " card_num
        jackd -d alsa -d hw:$card_num &
        sleep 2
        echo "✓ JACK lancé sur hw:$card_num"
        ;;
    3)
        echo "Control Panels disponibles:"
        echo "  1) RME Control Panel"
        echo "  2) UAD Console"
        echo "  3) Focusrite Control"
        read -p "Choix: " panel_choice
        
        case "$panel_choice" in
            1) rme-control-panel ;;
            2) uad-console ;;
            3) focusrite-control ;;
        esac
        ;;
    4)
        echo "Test audio..."
        speaker-test -t sine -f 440 -l 5
        ;;
    5)
        journalctl -u jack --follow
        ;;
esac
EOF
    
    chmod +x "$HOME/.local/bin/audio-interface-manager"
    
    log_info "Manager créé: $HOME/.local/bin/audio-interface-manager"
}

# ==============================================================================
# MAIN
# ==============================================================================

main() {
    log_info "╔════════════════════════════════════════════╗"
    log_info "║ Audio Interface Auto-Setup for REAPER OS   ║"
    log_info "╚════════════════════════════════════════════╝"
    echo ""
    
    # 1. Détecter les cartes
    detect_audio_interfaces
    echo ""
    
    # 2. Installer ALSA de base
    setup_alsa_native
    echo ""
    
    # 3. Setup des cartes spécifiques
    log_info "Détection des interfaces spécifiques..."
    
    # Vérifier RME
    if lsusb | grep -qi "RME"; then
        setup_rme_interface "RME" "RME"
    fi
    
    # Vérifier Universal Audio
    if lsusb | grep -qi "Universal Audio"; then
        setup_universal_audio_interface "UAD" "UniversalAudio"
    fi
    
    # Vérifier Focusrite
    if lsusb | grep -qi "Focusrite"; then
        setup_focusrite_interface "Focusrite" "Focusrite"
    fi
    
    # Vérifier Behringer
    if lsusb | grep -qi "Behringer"; then
        setup_generic_interface "Behringer" "Behringer"
    fi
    
    # Vérifier MOTU
    if lsusb | grep -qi "MOTU"; then
        setup_generic_interface "MOTU" "MOTU"
    fi
    
    echo ""
    
    # 4. Setup JACK
    setup_jack_for_interface "0" "default"
    
    # 5. Créer launcher unifié
    create_unified_launcher
    
    echo ""
    log_info "╔════════════════════════════════════════════╗"
    log_info "║  ✅ Audio Interface Setup Complété!        ║"
    log_info "╚════════════════════════════════════════════╝"
    echo ""
    
    log_info "Commandes disponibles:"
    log_info "  audio-interface-manager     - Manager audio"
    log_info "  rme-control-panel          - RME Control Panel"
    log_info "  uad-console                - UAD Console"
    log_info "  focusrite-control          - Focusrite Control"
    log_info ""
}

main "$@"
