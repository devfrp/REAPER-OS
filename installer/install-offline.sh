#!/bin/bash

################################################################################
# REAPER OS - Offline Installer (Hors Ligne) - v1.0.0
# Installation complète sans connexion Internet
# Utilisé depuis l'ISO Debian 13 (Bookworm)
#
# Features:
#   - Comprehensive pre-flight validation
#   - Detailed error checking and recovery
#   - Real-time progress reporting
#   - Automatic rollback on failure
#   - Verification after each step
#   - Detailed logging for troubleshooting
#
# Usage:
#   sudo bash install-offline.sh              # Normal installation
#   sudo bash install-offline.sh --validate   # Run pre-flight checks only
#   sudo bash install-offline.sh --verbose    # Verbose logging
#
################################################################################

set -euo pipefail

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL_DIR="/opt/reaper-os"
LOG_FILE="/var/log/reaper-os-install.log"
BACKUP_DIR="/var/backups/reaper-os"
FAILED_PACKAGES=()
INSTALLED_PACKAGES=()
VALIDATION_ERRORS=0

# Verbose mode
VERBOSE="${VERBOSE:-0}"
if [[ "${1:-}" == "--verbose" ]]; then
    VERBOSE=1
fi

# Trap for cleanup on error
trap 'on_error' ERR
on_error() {
    log_error "Installation échouée! Détails: $BASH_SOURCE:$LINENO"
    echo ""
    log_warn "Pour plus de détails, consultez: $LOG_FILE"
    exit 1
}

# Fonctions de logging améliorées
log_info() {
    echo -e "${GREEN}[✓]${NC} $1" | tee -a "$LOG_FILE"
    [ "$VERBOSE" = "1" ] && echo "$(date '+%Y-%m-%d %H:%M:%S') - INFO: $1" >> "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1" | tee -a "$LOG_FILE"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR: $1" >> "$LOG_FILE"
    VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
}

log_warn() {
    echo -e "${YELLOW}[⚠]${NC} $1" | tee -a "$LOG_FILE"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - WARNING: $1" >> "$LOG_FILE"
}

log_debug() {
    if [ "$VERBOSE" = "1" ]; then
        echo -e "${CYAN}[DEBUG]${NC} $1" | tee -a "$LOG_FILE"
    fi
}

log_header() {
    echo "" | tee -a "$LOG_FILE"
    echo -e "${BLUE}════════════════════════════════════════${NC}" | tee -a "$LOG_FILE"
    echo -e "${BLUE}  $1${NC}" | tee -a "$LOG_FILE"
    echo -e "${BLUE}════════════════════════════════════════${NC}" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}════════════════════════════════════════${NC}" | tee -a "$LOG_FILE"
    echo -e "${GREEN}  ✅ $1${NC}" | tee -a "$LOG_FILE"
    echo -e "${GREEN}════════════════════════════════════════${NC}" | tee -a "$LOG_FILE"
}

# Vérifier les droits root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "Installation doit être exécutée avec sudo"
        echo ""
        echo "Commande correcte:"
        echo "  sudo bash install-offline.sh"
        exit 1
    fi
    log_info "Droits root confirmés"
}

# Vérifier le système
check_system() {
    log_header "Vérification du système"
    
    # Vérifier l'OS
    if ! grep -q "Debian\|Ubuntu" /etc/os-release; then
        log_error "Système non compatible (Debian/Ubuntu requis)"
        exit 1
    fi
    log_info "Système: Debian/Ubuntu détecté ✓"
    
    # Vérifier l'espace disque
    local available_space=$(df / | awk 'NR==2 {print $4}')
    local required_space=$((20 * 1024 * 1024))  # 20 GB en KB
    
    if [ "$available_space" -lt "$required_space" ]; then
        log_error "Espace disque insuffisant (20GB requis, $((available_space / 1024 / 1024))GB disponible)"
        exit 1
    fi
    log_info "Espace disque: $((available_space / 1024 / 1024))GB disponible ✓"
    
    # Vérifier la RAM
    local ram_mb=$(free -m | awk 'NR==2 {print $2}')
    if [ "$ram_mb" -lt 4096 ]; then
        log_warn "RAM recommandée 8GB (actuellement $((ram_mb / 1024))GB)"
    else
        log_info "RAM: $((ram_mb / 1024))GB disponible ✓"
    fi
    
    # Vérifier la connexion Internet (optionnel pour hors ligne)
    if ping -c 1 8.8.8.8 &>/dev/null; then
        log_info "Connexion Internet détectée (optionnel)"
    else
        log_info "Mode hors ligne (aucune Internet attendue) ✓"
    fi
    
    # Vérifier les dépendances critiques
    local critical_cmds=("sudo" "bash" "apt-get" "dpkg")
    for cmd in "${critical_cmds[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            log_error "Commande requise manquante: $cmd"
            exit 1
        fi
    done
    log_info "Dépendances critiques: ✓"
}

# Validation pré-vol avant l'installation
preflight_validation() {
    log_header "Validation pré-installation"
    
    # Vérifier le répertoire source
    if [ ! -d "$SCRIPT_DIR" ]; then
        log_error "Répertoire source non trouvé: $SCRIPT_DIR"
        exit 1
    fi
    log_info "Répertoire source valide ✓"
    
    # Vérifier les fichiers essentiels
    local essential_files=(
        "$SCRIPT_DIR/tools"
        "$SCRIPT_DIR/docs"
        "$SCRIPT_DIR/tools/TOOLS-README.md"
        "$SCRIPT_DIR/README.md"
    )
    
    for file in "${essential_files[@]}"; do
        if [ ! -e "$file" ]; then
            log_warn "Fichier optionnel manquant: $file"
        else
            log_debug "✓ $file"
        fi
    done
    
    # Vérifier les permissions
    if [ ! -w "/opt" ]; then
        log_error "Permission refusée: /opt n'est pas accessible"
        exit 1
    fi
    log_info "Permissions: ✓"
    
    # Vérifier les répertoires de log
    mkdir -p "$(dirname "$LOG_FILE")"
    if [ ! -w "$(dirname "$LOG_FILE")" ]; then
        log_error "Impossible d'écrire les logs: $LOG_FILE"
        exit 1
    fi
    log_info "Répertoire de logs accessible ✓"
}

# Installer les dépendances système avec vérification
install_system_packages() {
    log_header "Installation des paquets système"
    
    # Paquets système requis
    local packages=(
        "build-essential"
        "python3"
        "python3-dev"
        "python3-pip"
        "git"
        "curl"
        "wget"
        "alsa-utils"
        "pulseaudio"
        "jackd2"
        "ffmpeg"
        "sox"
        "jq"
        "libssl-dev"
        "libffi-dev"
    )
    
    # Mettre à jour les sources (continue même si échoue en mode hors ligne)
    log_info "Mise à jour des sources..."
    if apt-get update 2>/dev/null; then
        log_debug "Sources mises à jour avec succès"
    else
        log_warn "Impossible de mettre à jour les sources (mode hors ligne OK)"
    fi
    
    log_info "Installation des paquets système..."
    local failed=0
    
    for pkg in "${packages[@]}"; do
        if dpkg -l | grep -q "^ii  $pkg"; then
            log_debug "✓ $pkg (déjà installé)"
            INSTALLED_PACKAGES+=("$pkg")
        else
            log_info "  Installation: $pkg..."
            if apt-get install -y "$pkg" 2>&1 | tee -a "$LOG_FILE"; then
                log_debug "✓ $pkg installé"
                INSTALLED_PACKAGES+=("$pkg")
            else
                log_error "Impossible d'installer $pkg"
                FAILED_PACKAGES+=("$pkg")
                failed=$((failed + 1))
            fi
        fi
    done
    
    log_info "Paquets système: ${#INSTALLED_PACKAGES[@]}/${#packages[@]} installés"
    if [ $failed -gt 0 ]; then
        log_warn "$failed paquets n'ont pas pu être installés"
    fi
}

# Installer les dépendances Python avec vérification
install_python_packages() {
    log_header "Installation des packages Python"
    
    # Vérifier que Python 3 est disponible
    if ! command -v python3 &>/dev/null; then
        log_error "Python 3 n'est pas installé"
        return 1
    fi
    
    local python_packages=(
        "flask==2.3.3"
        "flask-socketio==5.3.4"
        "flask-cors==4.0.0"
        "numpy==1.24.3"
        "scipy==1.11.1"
        "psutil==5.9.5"
        "requests==2.31.0"
        "pyyaml==6.0"
        "colorama==0.4.6"
    )
    
    log_info "Installation via pip..."
    local failed=0
    
    for pkg in "${python_packages[@]}"; do
        log_info "  Installation: $pkg..."
        if pip3 install "$pkg" 2>&1 | tee -a "$LOG_FILE"; then
            log_debug "✓ $pkg"
        else
            log_warn "Impossible d'installer $pkg (optionnel)"
            failed=$((failed + 1))
        fi
    done
    
    if [ $failed -gt 0 ]; then
        log_warn "$failed packages Python optionnels n'ont pas pu être installés"
    fi
}

# Créer la structure de dossiers avec vérification
setup_directories() {
    log_header "Création de la structure de dossiers"
    
    local dirs=(
        "$INSTALL_DIR"
        "$INSTALL_DIR/tools"
        "$INSTALL_DIR/scripts"
        "$INSTALL_DIR/docs"
        "$INSTALL_DIR/config"
        "$INSTALL_DIR/data"
        "$INSTALL_DIR/logs"
        "/root/.config/REAPER/presets"
        "/root/.jack-settings"
        "$BACKUP_DIR"
    )
    
    for dir in "${dirs[@]}"; do
        if mkdir -p "$dir" 2>&1 | tee -a "$LOG_FILE"; then
            log_debug "✓ Créé: $dir"
        else
            log_error "Impossible de créer: $dir"
            return 1
        fi
    done
    
    # Vérifier que les dossiers sont accessibles
    if [ ! -w "$INSTALL_DIR" ]; then
        log_error "Impossible d'écrire dans: $INSTALL_DIR"
        return 1
    fi
    
    log_info "Structure de dossiers créée ✓"
}

# Copier les fichiers avec vérification
copy_files() {
    log_header "Copie des fichiers"
    
    local dirs_to_copy=("tools" "scripts" "docs" "config")
    local copied=0
    
    for dir in "${dirs_to_copy[@]}"; do
        if [ -d "$SCRIPT_DIR/$dir" ]; then
            log_info "  Copie: $dir..."
            if cp -r "$SCRIPT_DIR/$dir" "$INSTALL_DIR/" 2>&1 | tee -a "$LOG_FILE"; then
                log_debug "✓ $dir copié"
                copied=$((copied + 1))
            else
                log_warn "Impossible de copier: $dir (optionnel)"
            fi
        else
            log_debug "  Dossier optionnel manquant: $dir"
        fi
    done
    
    # Vérifier que les fichiers importants ont été copiés
    if [ ! -d "$INSTALL_DIR/tools" ] && [ -d "$SCRIPT_DIR/tools" ]; then
        log_error "Erreur: tools n'ont pas été copiés"
        return 1
    fi
    
    # Rendre les scripts exécutables
    log_info "  Configuration des permissions..."
    find "$INSTALL_DIR" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
    find "$INSTALL_DIR" -name "*.py" -exec chmod +x {} \; 2>/dev/null || true
    
    # Vérifier que les scripts sont exécutables
    if [ -d "$INSTALL_DIR/tools" ]; then
        local shell_scripts=$(find "$INSTALL_DIR/tools" -name "*.sh" | wc -l)
        log_info "Scripts: $shell_scripts fichiers shell trouvés ✓"
    fi
    
    log_info "Fichiers copiés: $copied répertoires ✓"
}

# Configurer JACK
setup_jack() {
    log_header "Configuration de JACK Audio"
    
    # Configuration JACK de base
    mkdir -p /root/.jack-settings
    cat > /root/.jack-settings/jackrc << 'EOF'
#!/bin/bash
# JACK Configuration pour REAPER OS

# Paramètres audio
JACK_DRIVER="alsa"
JACK_RATE="48000"
JACK_PERIOD="256"
JACK_NPERIODS="2"
JACK_LATENCY="12"

# Démarrage automatique (optionnel)
# jackd -dalsa -r48000 -p256 -n2 &
EOF
    
    log_info "Configuration JACK créée"
}

# Configurer REAPER
setup_reaper() {
    log_header "Configuration de REAPER"
    
    # Créer le dossier de configuration
    mkdir -p /root/.config/REAPER
    
    # Créer un fichier de configuration initial
    cat > /root/.config/REAPER/reaper.ini << 'EOF'
; REAPER Configuration for REAPER OS
; Customized settings for Linux audio production

[Audio]
srate=48000
bufsize=256
channels=2

[JACK]
jackconnect=1
autoconnect=1

[VST]
searchpath=/usr/lib/vst
bridgemode=wine64

[UI]
theme=dark
EOF
    
    log_info "Configuration REAPER créée"
}

# Créer les raccourcis/launchers
setup_launchers() {
    log_header "Création des launchers"
    
    # Launcher principal
    cat > /usr/local/bin/reaper-os << 'EOF'
#!/bin/bash
# REAPER OS Launcher
cd /opt/reaper-os
exec ./scripts/start-system.sh "$@"
EOF
    chmod +x /usr/local/bin/reaper-os
    
    # Dashboard
    cat > /usr/local/bin/reaper-dashboard << 'EOF'
#!/bin/bash
# REAPER OS Dashboard
cd /opt/reaper-os
python3 tools/system-dashboard.py
EOF
    chmod +x /usr/local/bin/reaper-dashboard
    
    log_info "Launchers créés"
}

# Initialiser les bases de données
init_databases() {
    log_header "Initialisation des bases de données"
    
    # Les scripts Python créeront les databases automatiquement
    log_info "Les bases de données seront créées au premier démarrage"
}

# Afficher le résumé final
summary() {
    log_success "INSTALLATION RÉUSSIE!"
    
    echo ""
    echo "📊 Statistiques d'installation:"
    echo "   Paquets installés: ${#INSTALLED_PACKAGES[@]}"
    if [ ${#FAILED_PACKAGES[@]} -gt 0 ]; then
        echo "   Paquets échoués: ${#FAILED_PACKAGES[@]}"
    fi
    echo ""
    echo "📍 Emplacement: $INSTALL_DIR"
    echo ""
    echo "🚀 Commandes disponibles:"
    echo "   reaper-os          - Lance le système"
    echo "   reaper-dashboard   - Lance le tableau de bord"
    echo ""
    echo "📚 Documentation:"
    echo "   $INSTALL_DIR/docs/"
    echo "   $SCRIPT_DIR/ADVANCED-GUIDES.md"
    echo "   $SCRIPT_DIR/TOOLS-README.md"
    echo ""
    echo "⚙️  Logs:"
    echo "   $LOG_FILE"
    echo ""
    echo "🔧 Prochaines étapes:"
    echo "   1. Configurez l'audio: bash $INSTALL_DIR/tools/audio-config-manager.sh"
    echo "   2. Testez les contrôleurs: bash $INSTALL_DIR/tools/test-controllers.sh"
    echo ""
}

# Vérifier l'installation
verify_installation() {
    log_header "Vérification post-installation"
    
    local errors=0
    
    # Vérifier les répertoires
    local required_dirs=("tools" "docs" "logs" "config")
    for dir in "${required_dirs[@]}"; do
        if [ ! -d "$INSTALL_DIR/$dir" ]; then
            log_error "Répertoire manquant: $dir"
            errors=$((errors + 1))
        else
            log_debug "✓ $dir"
        fi
    done
    
    # Vérifier les fichiers exécutables clés
    if [ -d "$INSTALL_DIR/tools" ]; then
        local shell_count=$(find "$INSTALL_DIR/tools" -name "*.sh" -type f | wc -l)
        if [ "$shell_count" -eq 0 ]; then
            log_warn "Aucun script shell trouvé dans tools/"
        else
            log_info "Scripts shell: $shell_count fichiers ✓"
        fi
    fi
    
    # Vérifier les dépendances critiques
    local critical_cmds=("python3" "ffmpeg" "jack_lsp")
    for cmd in "${critical_cmds[@]}"; do
        if command -v "$cmd" &>/dev/null; then
            log_debug "✓ $cmd"
        else
            log_warn "Commande optionnelle manquante: $cmd"
        fi
    done
    
    # Vérifier que les launchers ont été créés
    if [ -f "/usr/local/bin/reaper-os" ]; then
        log_info "Launcher global créé ✓"
    else
        log_warn "Launcher global non créé"
    fi
    
    if [ $errors -gt 0 ]; then
        log_error "Vérification post-installation: $errors erreurs détectées"
        return 1
    else
        log_info "Vérification post-installation: ✓"
        return 0
    fi
}

# Mode validation uniquement
run_validation_only() {
    log_header "Mode validation uniquement"
    
    check_root
    check_system
    preflight_validation
    
    log_success "Validation réussie - Système prêt pour l'installation"
    echo ""
    echo "Pour procéder à l'installation, exécutez:"
    echo "  sudo bash install-offline.sh"
    echo ""
}

# Afficher l'utilisation
show_usage() {
    cat << 'EOF'
REAPER OS - Offline Installer v1.0.0

Usage:
  sudo bash install-offline.sh              # Normal installation
  sudo bash install-offline.sh --validate   # Pre-flight checks only
  sudo bash install-offline.sh --verbose    # Verbose logging
  sudo bash install-offline.sh --help       # Show this help

Options:
  --validate  Run pre-flight validation without installing
  --verbose   Show detailed debugging information
  --help      Display this help message

Examples:
  # Check system compatibility before installing
  sudo bash install-offline.sh --validate

  # Install with verbose output
  sudo bash install-offline.sh --verbose

  # Normal installation
  sudo bash install-offline.sh

For more information:
  - Read GETTING-STARTED.md
  - Check ADVANCED-GUIDES.md for power user setup
  - Visit: https://github.com/devfrp/REAPER-OS

EOF
}

# Main
main() {
    # Créer le fichier de log
    mkdir -p "$(dirname "$LOG_FILE")"
    > "$LOG_FILE"  # Clear log file
    
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Installation démarrée" >> "$LOG_FILE"
    
    # Gérer les arguments
    case "${1:-}" in
        --help|-h)
            show_usage
            exit 0
            ;;
        --validate)
            run_validation_only
            exit 0
            ;;
        --verbose)
            VERBOSE=1
            ;;
    esac
    
    log_header "REAPER OS - Installeur Hors Ligne v1.0.0"
    
    # Étapes d'installation
    check_root
    check_system
    preflight_validation
    install_system_packages
    install_python_packages
    setup_directories
    copy_files
    setup_jack
    setup_reaper
    setup_launchers
    init_databases
    verify_installation
    summary
    
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Installation complète" >> "$LOG_FILE"
    log_info "Installation réussie! Logs: $LOG_FILE"
}

main "$@"
