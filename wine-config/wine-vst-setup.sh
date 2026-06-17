#!/bin/bash

################################################################################
# Configuration Wine/Proton pour VST Windows
# Setup automatique du préfixe Wine pour plugins VST
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WINE_PREFIX="${WINE_PREFIX:-$HOME/.wine}"
PROTON_PATH="${PROTON_PATH:-/opt/proton}"

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_err() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Vérifier les prérequis
check_requirements() {
    log_info "Vérification des prérequis..."
    
    # Wine ou Proton
    if ! command -v wine &> /dev/null && [ ! -d "$PROTON_PATH" ]; then
        log_err "Wine ou Proton non trouvé!"
    fi
    
    # Dependencies
    local deps=("winetricks")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            log_warn "$dep non trouvé - installation recommandée"
        fi
    done
    
    log_info "Prérequis vérifiés"
}

# Créer le préfixe Wine 64-bit
create_wine_prefix() {
    log_info "Création du préfixe Wine 64-bit..."
    
    export WINEARCH=win64
    export WINEPREFIX="$WINE_PREFIX"
    
    # Créer le préfixe
    wine wineboot --init 2>/dev/null || {
        log_err "Échec de la création du préfixe Wine"
    }
    
    log_info "Préfixe Wine créé"
}

# Installer les composants essentiels
install_wine_components() {
    log_info "Installation des composants Wine..."
    
    export WINEARCH=win64
    export WINEPREFIX="$WINE_PREFIX"
    
    # Installation des Visual C++ Runtimes
    log_info "Installation de Visual C++ Runtime..."
    winetricks vcrun2019 dotnet48 2>/dev/null || true
    
    # Installation des codecs
    log_info "Installation des codecs audio..."
    winetricks d3dx11 xact 2>/dev/null || true
    
    log_info "Composants installés"
}

# Créer les dossiers VST
setup_vst_folders() {
    log_info "Configuration des dossiers VST..."
    
    local vst_dirs=(
        "$WINE_PREFIX/drive_c/Program Files/Common Files/VST"
        "$WINE_PREFIX/drive_c/Program Files/Common Files/VST3"
        "$WINE_PREFIX/drive_c/Program Files (x86)/Common Files/VST"
    )
    
    for dir in "${vst_dirs[@]}"; do
        mkdir -p "$dir"
        log_info "Dossier créé: $dir"
    done
}

# Optimiser le registre Wine
optimize_wine_registry() {
    log_info "Optimisation du registre Wine..."
    
    export WINEARCH=win64
    export WINEPREFIX="$WINE_PREFIX"
    
    # Désactiver les effets visuels pour performance
    wine reg add 'HKEY_CURRENT_USER\Software\Wine\AppDefaults' \
        /v "VideoMemorySize" /d "2048" /t REG_SZ /f 2>/dev/null || true
    
    # Activer CSMT (Command Stream Multithreading)
    wine reg add 'HKEY_CURRENT_USER\Software\Wine\Direct3D' \
        /v "CSMT" /d "enabled" /t REG_SZ /f 2>/dev/null || true
    
    # Désactiver les bordures de fenêtre pour plugins
    wine reg add 'HKEY_CURRENT_USER\Software\Wine\Explorer\Desktops' \
        /v "Default" /d "800x600" /t REG_SZ /f 2>/dev/null || true
    
    log_info "Registre optimisé"
}

# Configurer les variables d'environnement
setup_env_variables() {
    log_info "Configuration des variables d'environnement..."
    
    local config_file="${SCRIPT_DIR}/wine-env.conf"
    
    cat > "$config_file" << 'EOF'
#!/bin/bash
# Variables d'environnement Wine/Proton pour VST

# Paths
export WINE_PREFIX="${WINE_PREFIX:-$HOME/.wine}"
export WINEARCH=win64
export WINEPREFIX="$WINE_PREFIX"

# Proton (si disponible)
export PROTON_PATH="/opt/proton"
export PROTON_LOG=1
export PROTON_LOG_DIR="$HOME/.logs/proton"
export PROTON_FORCE_LARGE_ADDRESS_AWARE=1

# Audio Performance
export PULSE_LATENCY_MSEC=10
export JACK_LATENCY_CB=1
export PA_LATENCY_MSEC=10

# GPU Optimizations
export DXVK_ASYNC=1
export DXVK_HUD=off
export DXVK_LOG_LEVEL=warn

# Wine Optimizations
export WINE_LARGE_ADDRESS_AWARE=1
export NOMSCOREE=1

# Désactiver les crashdumps
export WINEDEBUG=-all

# LSP (Language Server Protocol) disable
export WINE_LSP=cygwin
EOF
    
    chmod +x "$config_file"
    log_info "Configuration d'environnement sauvegardée: $config_file"
}

# Scanner VST initial
scan_vst_plugins() {
    log_info "Scan des plugins VST..."
    
    export WINEARCH=win64
    export WINEPREFIX="$WINE_PREFIX"
    
    local vst_dirs=(
        "$WINE_PREFIX/drive_c/Program Files/Common Files/VST"
        "$WINE_PREFIX/drive_c/Program Files (x86)/Common Files/VST"
    )
    
    for dir in "${vst_dirs[@]}"; do
        if [ -d "$dir" ]; then
            log_info "Scan de: $dir"
            find "$dir" -name "*.dll" 2>/dev/null | head -5 | while read -r vst; do
                log_info "  VST trouvé: $(basename "$vst")"
            done
        fi
    done
    
    log_info "Scan VST terminé"
}

# Créer un script de démarrage REAPER
create_reaper_launcher() {
    log_info "Création du lanceur REAPER..."
    
    local launcher="${SCRIPT_DIR}/../scripts/reaper-launcher.sh"
    
    cat > "$launcher" << 'EOF'
#!/bin/bash
# Lance REAPER avec la configuration Wine pour VST

# Charger les variables d'environnement
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../wine-config/wine-env.conf" 2>/dev/null

# Chercher REAPER
REAPER_INSTALL="${REAPER_INSTALL:-$HOME/.wine/drive_c/Program Files/REAPER}"

if [ ! -f "$REAPER_INSTALL/reaper.exe" ]; then
    echo "REAPER non trouvé à: $REAPER_INSTALL"
    exit 1
fi

# Lancer REAPER avec Wine
echo "Lancement de REAPER avec support VST Windows..."
wine "$REAPER_INSTALL/reaper.exe" "$@"
EOF
    
    chmod +x "$launcher"
    log_info "Lanceur créé: $launcher"
}

# Fonction principale
main() {
    echo ""
    echo "╔═════════════════════════════════════════════╗"
    echo "║  Wine/Proton Setup pour VST Windows         ║"
    echo "║  REAPER OS VST Plugin Support               ║"
    echo "╚═════════════════════════════════════════════╝"
    echo ""
    
    check_requirements
    create_wine_prefix
    install_wine_components
    setup_vst_folders
    optimize_wine_registry
    setup_env_variables
    scan_vst_plugins
    create_reaper_launcher
    
    echo ""
    echo "✓ Configuration Wine/Proton complète!"
    echo "✓ Les VST Windows peuvent maintenant être installés"
    echo ""
    echo "Prochaines étapes:"
    echo "1. Placer vos VST dans: $WINE_PREFIX/drive_c/Program Files/Common Files/VST/"
    echo "2. Lancer REAPER avec: ${SCRIPT_DIR}/../scripts/reaper-launcher.sh"
    echo "3. Configurer REAPER pour scanner les VST"
    echo ""
}

main "$@"
