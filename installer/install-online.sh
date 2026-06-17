#!/bin/bash

################################################################################
# REAPER OS - Online Installer (En Ligne)
# Installation avec téléchargement des mises à jour et dépendances
################################################################################

set -euo pipefail

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
GITHUB_REPO="https://github.com/devfrp/REAPER-OS"
RELEASES_API="https://api.github.com/repos/devfrp/REAPER-OS/releases"
INSTALL_DIR="/opt/reaper-os"
LOG_FILE="/var/log/reaper-os-install.log"
TEMP_DIR="/tmp/reaper-os-install"

# Fonctions
log_info() {
    echo -e "${GREEN}[✓]${NC} $1" | tee -a "$LOG_FILE"
}

log_warn() {
    echo -e "${YELLOW}[!]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1" | tee -a "$LOG_FILE"
}

log_header() {
    echo -e "${BLUE}════════════════════════════════════════${NC}" | tee -a "$LOG_FILE"
    echo -e "${BLUE}  $1${NC}" | tee -a "$LOG_FILE"
    echo -e "${BLUE}════════════════════════════════════════${NC}" | tee -a "$LOG_FILE"
}

# Vérifier les droits root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "Doit être exécuté avec sudo"
        exit 1
    fi
}

# Vérifier le système
check_system() {
    log_header "Vérification du système"
    
    if ! grep -q "Debian\|Ubuntu" /etc/os-release; then
        log_error "Système non compatible (Debian/Ubuntu requis)"
        exit 1
    fi
    
    # Vérifier la connexion Internet
    log_info "Vérification de la connexion Internet..."
    if ! curl -s --head https://www.github.com | head -n 1 | grep "HTTP" > /dev/null; then
        log_error "Pas de connexion Internet détectée"
        exit 1
    fi
    
    log_info "Système OK et connecté à Internet"
}

# Créer le dossier temporaire
setup_temp() {
    log_header "Préparation"
    
    mkdir -p "$TEMP_DIR"
    mkdir -p "$INSTALL_DIR"
    log_info "Dossiers temporaires créés"
}

# Mettre à jour les sources
update_repos() {
    log_header "Mise à jour des dépôts"
    
    log_info "Mise à jour des sources..."
    apt-get update
    
    # Ajouter les dépôts supplémentaires si nécessaire
    if ! grep -q "backports" /etc/apt/sources.list*; then
        log_info "Ajout du dépôt backports..."
        add-apt-repository -y debian-backports || log_warn "Impossible d'ajouter backports"
    fi
    
    apt-get update
    log_info "Dépôts à jour"
}

# Installer les dépendances système
install_system_packages() {
    log_header "Installation des paquets système"
    
    local packages=(
        "build-essential"
        "python3"
        "python3-dev"
        "python3-pip"
        "git"
        "curl"
        "wget"
        "ca-certificates"
        "alsa-utils"
        "pulseaudio"
        "jackd2"
        "ffmpeg"
        "sox"
        "jq"
        "libssl-dev"
        "libffi-dev"
        "libsndfile1"
        "libsamplerate0"
    )
    
    for pkg in "${packages[@]}"; do
        log_info "Installation: $pkg"
        apt-get install -y "$pkg" || log_error "Impossible d'installer $pkg"
    done
    
    log_info "Tous les paquets système installés"
}

# Installer les dépendances Python (dernière version)
install_python_packages() {
    log_header "Installation des packages Python (dernière version)"
    
    log_info "Mise à niveau de pip..."
    pip3 install --upgrade pip setuptools wheel
    
    local python_packages=(
        "flask"
        "flask-socketio"
        "flask-cors"
        "numpy"
        "scipy"
        "psutil"
        "requests"
        "pyyaml"
        "colorama"
        "click"
        "tqdm"
        "cryptography"
        "python-dotenv"
        "pytest"
        "black"
    )
    
    log_info "Installation des packages Python..."
    for pkg in "${python_packages[@]}"; do
        log_info "  - $pkg"
        pip3 install "$pkg" || log_error "Impossible d'installer $pkg"
    done
    
    log_info "Packages Python à jour"
}

# Cloner/Télécharger les sources depuis GitHub
download_sources() {
    log_header "Téléchargement des sources"
    
    log_info "Téléchargement depuis GitHub..."
    
    # Télécharger la dernière version
    local latest_release=$(curl -s "$RELEASES_API/latest" | jq -r '.tag_name')
    
    if [ -z "$latest_release" ] || [ "$latest_release" = "null" ]; then
        log_warn "Impossible de récupérer la version depuis GitHub, clonage du repo..."
        cd "$TEMP_DIR"
        git clone "$GITHUB_REPO" reaper-os-repo || {
            log_error "Impossible de cloner le repository"
            exit 1
        }
        DOWNLOAD_DIR="$TEMP_DIR/reaper-os-repo"
    else
        log_info "Version détectée: $latest_release"
        cd "$TEMP_DIR"
        
        # Télécharger l'archive
        local download_url="$GITHUB_REPO/archive/refs/tags/$latest_release.tar.gz"
        log_info "Téléchargement: $download_url"
        
        wget -q "$download_url" -O reaper-os.tar.gz || {
            log_error "Impossible de télécharger l'archive"
            exit 1
        }
        
        tar -xzf reaper-os.tar.gz
        DOWNLOAD_DIR="$TEMP_DIR/REAPER-OS-${latest_release#v}"
    fi
    
    log_info "Sources téléchargées: $DOWNLOAD_DIR"
}

# Créer la structure de dossiers
setup_directories() {
    log_header "Création de la structure"
    
    mkdir -p "$INSTALL_DIR"/{tools,scripts,docs,config,data,logs,tests}
    mkdir -p /root/.config/REAPER/presets
    mkdir -p /root/.jack-settings
    
    log_info "Structure créée"
}

# Copier les fichiers
copy_files() {
    log_header "Copie des fichiers"
    
    for dir in tools scripts docs config tests; do
        if [ -d "$DOWNLOAD_DIR/$dir" ]; then
            log_info "Copie: $dir/"
            cp -r "$DOWNLOAD_DIR/$dir" "$INSTALL_DIR/"
        fi
    done
    
    # Copier les fichiers racine importants
    if [ -f "$DOWNLOAD_DIR/README.md" ]; then
        cp "$DOWNLOAD_DIR/README.md" "$INSTALL_DIR/"
    fi
    
    if [ -f "$DOWNLOAD_DIR/CHANGELOG.md" ]; then
        cp "$DOWNLOAD_DIR/CHANGELOG.md" "$INSTALL_DIR/"
    fi
    
    # Rendre exécutables
    find "$INSTALL_DIR" -name "*.sh" -exec chmod +x {} \;
    find "$INSTALL_DIR" -name "*.py" -exec chmod +x {} \;
    
    log_info "Fichiers copiés et configurés"
}

# Installer les requirements Python du projet
install_project_requirements() {
    log_header "Installation des dépendances du projet"
    
    if [ -f "$DOWNLOAD_DIR/requirements.txt" ]; then
        log_info "Installation depuis requirements.txt"
        pip3 install -r "$DOWNLOAD_DIR/requirements.txt" || log_warn "Certains packages ont échoué"
    else
        log_warn "requirements.txt non trouvé"
    fi
}

# Configurer JACK
setup_jack() {
    log_header "Configuration de JACK Audio"
    
    mkdir -p /root/.jack-settings
    cat > /root/.jack-settings/jackrc << 'EOF'
#!/bin/bash
# JACK Configuration pour REAPER OS - Installeur En Ligne

# Paramètres audio optimisés
JACK_DRIVER="alsa"
JACK_RATE="48000"
JACK_PERIOD="256"
JACK_NPERIODS="2"
JACK_LATENCY="12"

# Démarrage optionnel
# jackd -dalsa -r48000 -p256 -n2 &
EOF
    
    log_info "Configuration JACK créée"
}

# Configurer REAPER
setup_reaper() {
    log_header "Configuration de REAPER"
    
    mkdir -p /root/.config/REAPER
    
    cat > /root/.config/REAPER/reaper.ini << 'EOF'
; REAPER Configuration pour REAPER OS - Installeur En Ligne
; Paramètres optimisés pour Linux

[Audio]
srate=48000
bufsize=256
channels=2

[JACK]
jackconnect=1
autoconnect=1

[VST]
searchpath=/usr/lib/vst:/usr/local/lib/vst
bridgemode=wine64
scanvsts=1

[UI]
theme=dark
hidpi=1
EOF
    
    log_info "Configuration REAPER créée"
}

# Créer les launchers
setup_launchers() {
    log_header "Création des launchers"
    
    cat > /usr/local/bin/reaper-os << 'EOF'
#!/bin/bash
cd /opt/reaper-os
exec ./scripts/start-system.sh "$@"
EOF
    chmod +x /usr/local/bin/reaper-os
    
    cat > /usr/local/bin/reaper-dashboard << 'EOF'
#!/bin/bash
cd /opt/reaper-os
python3 tools/system-dashboard.py
EOF
    chmod +x /usr/local/bin/reaper-dashboard
    
    log_info "Launchers créés"
}

# Exécuter les tests (optionnel)
run_tests() {
    log_header "Tests (optionnel)"
    
    if [ -d "$INSTALL_DIR/tests" ]; then
        log_info "Tests disponibles dans: $INSTALL_DIR/tests"
        log_warn "Exécution des tests non automatisée"
    fi
}

# Nettoyer
cleanup() {
    log_header "Nettoyage"
    
    log_info "Suppression des fichiers temporaires..."
    rm -rf "$TEMP_DIR"
    
    log_info "Nettoyage terminé"
}

# Afficher le résumé
summary() {
    log_header "INSTALLATION EN LIGNE TERMINÉE"
    
    echo ""
    echo "✅ REAPER OS v1.0.0 installé avec succès!"
    echo ""
    echo "📍 Emplacement: $INSTALL_DIR"
    echo ""
    echo "🚀 Commandes disponibles:"
    echo "   reaper-os          - Lance le système"
    echo "   reaper-dashboard   - Lance le tableau de bord"
    echo ""
    echo "📚 Documentation:"
    echo "   $INSTALL_DIR/docs/"
    echo ""
    echo "⚙️  Logs:"
    echo "   $LOG_FILE"
    echo ""
    echo "🔄 Mise à jour:"
    echo "   cd $INSTALL_DIR && git pull"
    echo ""
}

# Main
main() {
    log_header "REAPER OS - Installeur En Ligne v1.0.0"
    
    check_root
    check_system
    setup_temp
    update_repos
    install_system_packages
    install_python_packages
    download_sources
    setup_directories
    copy_files
    install_project_requirements
    setup_jack
    setup_reaper
    setup_launchers
    run_tests
    cleanup
    summary
    
    log_info "Installation complète et réussie!"
}

main "$@"
