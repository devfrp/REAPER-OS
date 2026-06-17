#!/bin/bash

################################################################################
# REAPER OS Boot Configuration
# Initialise REAPER OS au premier boot
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${SCRIPT_DIR}/.."

log_info() { echo "[BOOT] $1"; }
log_err() { echo "[ERROR] $1"; exit 1; }

log_info "╔════════════════════════════════════════╗"
log_info "║   REAPER OS - First Boot Configuration  ║"
log_info "╚════════════════════════════════════════╝"

# 1. Vérifier la connexion réseau
log_info "Vérification de la connexion réseau..."
if ! ping -c 1 8.8.8.8 &> /dev/null; then
    log_info "Pas de connexion Internet - configuration minimale"
else
    log_info "Connexion Internet OK"
fi

# 2. Configurer ASNUX (moteur audio basse latence)
log_info "Configuration d'ASNUX (moteur audio basse latence)..."
if [ -f "$PROJECT_ROOT/scripts/setup-asnux.sh" ]; then
    bash "$PROJECT_ROOT/scripts/setup-asnux.sh"
fi

# 2.5 Configurer JACK
log_info "Configuration de JACK Audio..."
if [ -f "$PROJECT_ROOT/scripts/setup-jack.sh" ]; then
    bash "$PROJECT_ROOT/scripts/setup-jack.sh"
fi

# 3. Configurer Wine/Proton
log_info "Configuration de Wine/Proton pour VST..."
if [ -f "$PROJECT_ROOT/wine-config/wine-vst-setup.sh" ]; then
    bash "$PROJECT_ROOT/wine-config/wine-vst-setup.sh"
fi

# 2.5 Setup Audio Interfaces (auto-detection + wrappers)
log_info "Configuration des interfaces audio..."
if [ -f "$PROJECT_ROOT/scripts/audio-interface-setup.sh" ]; then
    bash "$PROJECT_ROOT/scripts/audio-interface-setup.sh"
fi

if [ -f "$PROJECT_ROOT/scripts/audio-device-mapper.sh" ]; then
    bash "$PROJECT_ROOT/scripts/audio-device-mapper.sh"
fi

if [ -f "$PROJECT_ROOT/scripts/audio-control-panel-wrappers.sh" ]; then
    bash "$PROJECT_ROOT/scripts/audio-control-panel-wrappers.sh"
fi

# 2.6 (Optionnel) Configurer AudioGridder pour VST isolation
log_info "Configuration d'AudioGridder (optionnel)..."
if [ -f "$PROJECT_ROOT/wine-config/audiogridder-setup.sh" ]; then
    # Installer AudioGridder en background (peut être lent)
    bash "$PROJECT_ROOT/wine-config/audiogridder-setup.sh" &
fi

# 3. Installer les outils REAPER OS
log_info "Installation des outils diagnostiques..."
if [ -f "$PROJECT_ROOT/tools/install-tools.sh" ]; then
    bash "$PROJECT_ROOT/tools/install-tools.sh"
fi

# 4. Initialiser REAPER
log_info "Initialisation de REAPER..."
if [ -f "$PROJECT_ROOT/reaper-config/reaper-config-init.sh" ]; then
    bash "$PROJECT_ROOT/reaper-config/reaper-config-init.sh"
fi

# 5. Créer les icônes de bureau
log_info "Création des raccourcis..."
mkdir -p "$HOME/.local/share/applications"

cat > "$HOME/.local/share/applications/reaper-os.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=REAPER OS
Comment=Professional DAW for Music Production
Exec=/usr/local/bin/reaper-start
Icon=reaper-os
Terminal=false
Categories=Multimedia;Audio;
EOF

# 6. Configurer Dolphin
log_info "Configuration de Dolphin..."
mkdir -p "$HOME/.config/dolphinrc"

cat > "$HOME/.config/dolphinrc" << 'EOF'
[General]
Version=4
WindowState=@ByteArray(\0\0\0\xff\0\0\0\0\xfd\0\0\0\0\0\0\3\xe8\0\0\x2\xbe\0\0\0\x4\0\0\0\x4\0\0\0\x8\0\0\0\x8\xfc\0\0\0\x1\0\0\0\x4\0\0\x1\xd2\0\0\0\x4\xfc\0\0\0\x1\0\0\0\x2\0\0\x2\x58\0\0\x1\xce\xfc\0\0\0\x1\0\0\x2\xc0\0\0\x2\x58\0\0\0\x4\0\0\0\x4\0\0\0\x8\0\0\0\x8\xfc\0\0\0\x1\0\0\x2\xc0\0\0\x2X)

[Content]
ViewMode=0
Sorting=0
SortFoldersFirst=true

[MainWindow]
ToolBarsMovable=Disabled
EOF

log_info "Configuration de Dolphin terminée"

# 7. Configuration d'auto-démarrage
log_info "Configuration de l'auto-démarrage..."
mkdir -p "$HOME/.config/autostart"

cat > "$HOME/.config/autostart/reaper-os.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=REAPER OS
Exec=/opt/reaper-os/scripts/start-reaper.sh
OnlyShowIn=XFCE;
AutostartCondition=unless-running reaper.exe
EOF

log_info "Bootstrap terminé! REAPER va maintenant démarrer..."
log_info ""

# 8. Démarrer REAPER
sleep 3
exec bash "$PROJECT_ROOT/scripts/start-reaper.sh"
