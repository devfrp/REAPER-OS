#!/bin/bash
#
# REAPER OS Package Manager
# Install VST packs, themes, scripts, drivers easily
#
# Usage: reaper-os-install <package>
#        reaper-os-install list
#        reaper-os-install search <query>
#        reaper-os-install info <package>
#        reaper-os-install remove <package>

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
PACKAGES_DIR="$PROJECT_ROOT/packages"
INSTALLED_DIR="$HOME/.local/share/reaper-os-packages"
MANIFEST_FILE="$PACKAGES_DIR/manifest.json"
CACHE_DIR="$HOME/.cache/reaper-os-packages"
REAPER_OS_REPO="${REAPER_OS_REPO:-https://github.com/devfrp/REAPER-OS}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Ensure directories exist
ensure_directories() {
    mkdir -p "$INSTALLED_DIR"
    mkdir -p "$CACHE_DIR"
}

# Load package manifest
load_manifest() {
    if [[ ! -f "$MANIFEST_FILE" ]]; then
        log_error "Package manifest not found: $MANIFEST_FILE"
        return 1
    fi
    cat "$MANIFEST_FILE"
}

# List all packages
list_packages() {
    log_info "Available packages:\n"
    
    load_manifest | jq -r '.packages[] | "\(.id)\t\(.name)\t\(.version)\t\(.category)"' | \
        column -t -s $'\t' -N "ID,NAME,VERSION,CATEGORY"
}

# Search packages
search_packages() {
    local query="$1"
    log_info "Searching for: $query\n"
    
    load_manifest | jq -r ".packages[] | select(.name | contains(\"$query\") or .id | contains(\"$query\")) | \"\(.id)\t\(.name)\t\(.description)\""
}

# Get package info
get_package_info() {
    local package_id="$1"
    
    log_info "Package: $package_id\n"
    
    local info=$(load_manifest | jq ".packages[] | select(.id == \"$package_id\")")
    
    if [[ -z "$info" ]]; then
        log_error "Package not found: $package_id"
        return 1
    fi
    
    echo "$info" | jq -r '
        "Name: \(.name)\n" +
        "Version: \(.version)\n" +
        "Category: \(.category)\n" +
        "Description: \(.description)\n" +
        "Size: \(.size)\n" +
        "Author: \(.author)\n" +
        "Dependencies: \(.dependencies | join(", "))\n" +
        "URL: \(.url)"
    '
}

# Check dependencies
check_dependencies() {
    local package_id="$1"
    
    local deps=$(load_manifest | jq -r ".packages[] | select(.id == \"$package_id\") | .dependencies[]?" 2>/dev/null)
    
    if [[ -z "$deps" ]]; then
        return 0
    fi
    
    while read -r dep; do
        if [[ ! -d "$INSTALLED_DIR/$dep" ]]; then
            log_warning "Missing dependency: $dep"
            return 1
        fi
    done <<< "$deps"
    
    return 0
}

# Install package
install_package() {
    local package_id="$1"
    
    log_info "Installing package: $package_id"
    
    # Check if already installed
    if [[ -d "$INSTALLED_DIR/$package_id" ]]; then
        log_warning "Package already installed: $package_id"
        return 0
    fi
    
    # Get package info
    local package_info=$(load_manifest | jq ".packages[] | select(.id == \"$package_id\")")
    
    if [[ -z "$package_info" ]]; then
        log_error "Package not found: $package_id"
        return 1
    fi
    
    # Check dependencies
    if ! check_dependencies "$package_id"; then
        log_error "Unmet dependencies"
        return 1
    fi
    
    # Download package
    local url=$(echo "$package_info" | jq -r '.url')
    # Remplacer le placeholder YOUR-REPO par le vrai dépôt
    url="${url//YOUR-REPO/${REAPER_OS_REPO#https://github.com/}}"
    local download_path="$CACHE_DIR/$package_id.tar.gz"
    
    if [[ ! -f "$download_path" ]]; then
        log_info "Downloading package..."
        curl -L "$url" -o "$download_path" --progress-bar
        if [[ $? -ne 0 ]]; then
            log_error "Failed to download package"
            return 1
        fi
    fi
    
    # Verify checksum (sauter si placeholder)
    local checksum=$(echo "$package_info" | jq -r '.checksum')
    if [[ "$checksum" == "abc123def456..." ]] || [[ "$checksum" == *"..." ]]; then
        log_warning "Checksum placeholder détecté, vérification ignorée"
    else
        local file_checksum=$(sha256sum "$download_path" | cut -d' ' -f1)
        if [[ "$checksum" != "$file_checksum" ]]; then
            log_error "Checksum mismatch!"
            return 1
        fi
        log_success "Checksum verified"
    fi
    
    # Extract package
    log_info "Extracting package..."
    mkdir -p "$INSTALLED_DIR/$package_id"
    tar -xzf "$download_path" -C "$INSTALLED_DIR/$package_id"
    
    # Run install script if exists
    if [[ -f "$INSTALLED_DIR/$package_id/install.sh" ]]; then
        log_info "Running installation script..."
        bash "$INSTALLED_DIR/$package_id/install.sh"
    fi
    
    # Create metadata file
    echo "$package_info" > "$INSTALLED_DIR/$package_id/metadata.json"
    
    log_success "Package installed: $package_id"
}

# Remove package
remove_package() {
    local package_id="$1"
    
    log_info "Removing package: $package_id"
    
    if [[ ! -d "$INSTALLED_DIR/$package_id" ]]; then
        log_error "Package not installed: $package_id"
        return 1
    fi
    
    # Run uninstall script if exists
    if [[ -f "$INSTALLED_DIR/$package_id/uninstall.sh" ]]; then
        log_info "Running uninstallation script..."
        bash "$INSTALLED_DIR/$package_id/uninstall.sh"
    fi
    
    # Remove directory
    rm -rf "$INSTALLED_DIR/$package_id"
    
    log_success "Package removed: $package_id"
}

# Update all packages
update_packages() {
    log_info "Checking for updates..."
    
    for package_dir in "$INSTALLED_DIR"/*; do
        if [[ -d "$package_dir" ]]; then
            local package_id=$(basename "$package_dir")
            log_info "Checking: $package_id"
            
            # Would compare versions and update if needed
        fi
    done
}

# List installed packages
list_installed() {
    log_info "Installed packages:\n"
    
    if [[ ! -d "$INSTALLED_DIR" ]] || [[ -z "$(ls -A "$INSTALLED_DIR")" ]]; then
        log_warning "No packages installed"
        return 0
    fi
    
    for package_dir in "$INSTALLED_DIR"/*; do
        if [[ -d "$package_dir" ]]; then
            local package_id=$(basename "$package_dir")
            local version=$(jq -r '.version' "$package_dir/metadata.json" 2>/dev/null)
            echo "$package_id    v$version"
        fi
    done
}

# Show help
show_help() {
    cat << EOF
${BLUE}REAPER OS Package Manager${NC}

Usage: $(basename "$0") <command> [package]

${GREEN}Commands:${NC}
  install <package>     Install a package
  remove <package>      Remove a package
  list                  List available packages
  search <query>        Search packages
  info <package>        Show package information
  installed             List installed packages
  update                Update all packages
  clean                 Clean cache
  help                  Show this help

${GREEN}Examples:${NC}
  $(basename "$0") install vst-fab-filter
  $(basename "$0") install theme-dark
  $(basename "$0") search vst
  $(basename "$0") list
  $(basename "$0") info vst-fab-filter
  $(basename "$0") remove vst-fab-filter

${GREEN}Package Categories:${NC}
  vst-packs             VST plugin collections
  themes                REAPER themes
  scripts               REAPER scripts & extensions
  drivers               Audio device drivers
  soundsets             Sound libraries
  control-maps          Control surface mappings

EOF
}

# Main
main() {
    ensure_directories
    
    case "${1:-help}" in
        install)
            if [[ -z "$2" ]]; then
                log_error "Package name required"
                show_help
                exit 1
            fi
            install_package "$2"
            ;;
        remove)
            if [[ -z "$2" ]]; then
                log_error "Package name required"
                show_help
                exit 1
            fi
            remove_package "$2"
            ;;
        list)
            list_packages
            ;;
        search)
            if [[ -z "$2" ]]; then
                log_error "Search query required"
                exit 1
            fi
            search_packages "$2"
            ;;
        info)
            if [[ -z "$2" ]]; then
                log_error "Package name required"
                exit 1
            fi
            get_package_info "$2"
            ;;
        installed)
            list_installed
            ;;
        update)
            update_packages
            ;;
        clean)
            log_info "Cleaning cache..."
            rm -rf "$CACHE_DIR"/*
            log_success "Cache cleaned"
            ;;
        help|-h|--help)
            show_help
            ;;
        *)
            log_error "Unknown command: $1"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
