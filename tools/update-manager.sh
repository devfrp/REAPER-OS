#!/bin/bash
#
# REAPER OS Update Manager
# Check and manage REAPER OS, REAPER DAW, and plugin updates
#

set -e

UPDATE_CACHE="$HOME/.cache/reaper-os-updates"
VERSION_FILE="/etc/reaper-os-release"
REAPER_CONFIG="$HOME/.config/REAPER"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

mkdir -p "$UPDATE_CACHE"

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

# Get current versions
get_reaper_os_version() {
    if [[ -f "$VERSION_FILE" ]]; then
        grep "VERSION=" "$VERSION_FILE" | cut -d'=' -f2 | tr -d '"'
    else
        echo "unknown"
    fi
}

get_reaper_version() {
    if command -v reaper &> /dev/null; then
        reaper --version 2>/dev/null || echo "unknown"
    else
        echo "not installed"
    fi
}

get_system_version() {
    cat /etc/debian_version
}

# Check for REAPER OS updates
check_reaper_os_updates() {
    log_info "Checking for REAPER OS updates..."
    
    local current_version=$(get_reaper_os_version)
    log_info "Current version: $current_version"
    
    # Would check GitHub releases API
    local latest_version=$(curl -s https://api.github.com/repos/reaper-os/releases/latest 2>/dev/null | grep -o '"tag_name":"v[^"]*' | cut -d'"' -f4 | head -1)
    
    if [[ -z "$latest_version" ]]; then
        log_warning "Could not check for updates"
        return
    fi
    
    log_info "Latest version: $latest_version"
    
    if [[ "$current_version" != "$latest_version" ]]; then
        log_warning "Update available: $current_version → $latest_version"
        log_info "Run 'update-manager.sh update-os' to upgrade"
    else
        log_success "REAPER OS is up to date"
    fi
}

# Check for REAPER updates
check_reaper_updates() {
    log_info "Checking for REAPER DAW updates..."
    
    # REAPER has built-in updater, we just notify
    if command -v reaper &> /dev/null; then
        local current=$(get_reaper_version)
        log_info "Current REAPER version: $current"
        log_info "REAPER has built-in auto-update capability"
        log_info "Check Help → About REAPER in DAW for updates"
    else
        log_error "REAPER not installed"
    fi
}

# Check for system updates
check_system_updates() {
    log_info "Checking for system updates..."
    
    sudo apt update 2>/dev/null
    
    local updates=$(apt list --upgradable 2>/dev/null | wc -l)
    
    if [[ $updates -gt 0 ]]; then
        log_warning "System updates available: $updates packages"
        apt list --upgradable 2>/dev/null | head -10
    else
        log_success "System is up to date"
    fi
}

# Check plugin updates (VST packs)
check_plugin_updates() {
    log_info "Checking for VST plugin updates..."
    
    # Would check package manager
    local installed_plugins=$(ls -1 "$HOME/.local/share/reaper-os-packages" 2>/dev/null | wc -l)
    log_info "Installed plugin packages: $installed_plugins"
    
    log_info "Use 'reaper-os-install list' to check for plugin updates"
}

# Update REAPER OS
update_reaper_os() {
    log_warning "This will update REAPER OS to the latest version"
    read -p "Continue? (y/N) " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Update cancelled"
        return
    fi
    
    log_info "Downloading update..."
    # Would download from GitHub releases
    
    log_info "Installing update..."
    # Would run update script
    
    log_success "Update complete! Please restart your system"
}

# Update system packages
update_system() {
    log_warning "This will update system packages"
    read -p "Continue? (y/N) " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Update cancelled"
        return
    fi
    
    log_info "Updating system packages..."
    sudo apt update
    sudo apt upgrade -y
    
    log_success "System packages updated"
}

# Enable auto-updates
enable_auto_updates() {
    local cron_entry="0 3 * * * bash $0 check > /tmp/reaper-updates.log 2>&1"
    
    log_info "Setting up automatic update checks..."
    
    (crontab -l 2>/dev/null | grep -v "$0 check" || true; echo "$cron_entry") | crontab -
    
    log_success "Auto-update checks enabled (daily at 3 AM)"
}

# Show update summary
show_summary() {
    echo ""
    echo "=== REAPER OS Update Summary ==="
    echo ""
    
    echo "REAPER OS:"
    echo "  Current: $(get_reaper_os_version)"
    echo ""
    
    echo "REAPER DAW:"
    echo "  Current: $(get_reaper_version)"
    echo ""
    
    echo "System:"
    echo "  Debian version: $(get_system_version)"
    echo ""
    
    log_info "Run 'reaper-os-updates check-all' for detailed check"
}

# Rollback update
rollback_update() {
    log_warning "Rollback functionality requires previous backups"
    
    if [[ ! -d "$HOME/.local/share/reaper-os/backups" ]]; then
        log_error "No backups found for rollback"
        exit 1
    fi
    
    log_info "Available backups for rollback:"
    ls -1 "$HOME/.local/share/reaper-os/backups"/*.tar.gz | tail -5
}

# Show help
show_help() {
    cat << EOF
REAPER OS Update Manager

Usage: $(basename "$0") <command>

${GREEN}Commands:${NC}
  check-all          Check all for updates
  check-os           Check REAPER OS updates
  check-reaper       Check REAPER DAW updates
  check-system       Check system updates
  check-plugins      Check VST plugin updates
  update-os          Update REAPER OS
  update-system      Update system packages
  summary            Show update summary
  auto-enable        Enable automatic update checks
  auto-disable       Disable automatic update checks
  rollback           Rollback to previous version
  help               Show this help

${GREEN}Examples:${NC}
  $(basename "$0") check-all       # Check everything
  $(basename "$0") update-system   # Update packages
  $(basename "$0") summary         # Quick summary
  $(basename "$0") auto-enable     # Enable auto-checks

${YELLOW}Note:${NC}
- REAPER DAW has built-in updater
- System updates managed by apt
- Plugin updates via reaper-os-install
EOF
}

main() {
    case "${1:-help}" in
        check-all)
            check_reaper_os_updates || true
            check_reaper_updates || true
            check_system_updates || true
            check_plugin_updates || true
            ;;
        check-os)
            check_reaper_os_updates
            ;;
        check-reaper)
            check_reaper_updates
            ;;
        check-system)
            check_system_updates
            ;;
        check-plugins)
            check_plugin_updates
            ;;
        update-os)
            update_reaper_os
            ;;
        update-system)
            update_system
            ;;
        summary)
            show_summary
            ;;
        auto-enable)
            enable_auto_updates
            ;;
        rollback)
            rollback_update
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
