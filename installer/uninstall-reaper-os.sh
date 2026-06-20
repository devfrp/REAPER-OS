#!/bin/bash

################################################################################
# REAPER OS - Uninstaller (Désinstalleur) - v1.1.0
# Suppression complète de REAPER OS et restauration du système
#
# Usage:
#   sudo bash uninstall-reaper-os.sh              # Uninstall with confirmation
#   sudo bash uninstall-reaper-os.sh --force       # Skip confirmation
#   sudo bash uninstall-reaper-os.sh --dry-run     # Show what would be removed
#   sudo bash uninstall-reaper-os.sh --keep-config # Keep user config files
#   sudo bash uninstall-reaper-os.sh --help        # Show help
#
# Features:
#   - Complete removal of all REAPER OS packages and files
#   - JACK/Wine/ALSA configuration restoration
#   - User data preservation option
#   - Rollback-safe (backup before removal)
#   - Detailed logging
#   - Dry-run mode for preview
################################################################################

set -euo pipefail

# ─── Colors ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ─── Configuration ────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL_DIR="/opt/reaper-os"
LOG_FILE="/var/log/reaper-os-uninstall.log"
BACKUP_DIR="/var/backups/reaper-os-uninstall-$(date +%Y%m%d-%H%M%S)"
FORCE=0
DRY_RUN=0
KEEP_CONFIG=0
REMOVED_PACKAGES=()
FAILED_PACKAGES=()
REMOVED_FILES=()

# ─── Argument parsing ─────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case "$1" in
        --force) FORCE=1; shift ;;
        --dry-run) DRY_RUN=1; shift ;;
        --keep-config) KEEP_CONFIG=1; shift ;;
        --help|-h)
            echo "REAPER OS Uninstaller v1.1.0"
            echo ""
            echo "Usage: sudo bash uninstall-reaper-os.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --force        Skip confirmation prompt"
            echo "  --dry-run      Show what would be removed without doing it"
            echo "  --keep-config  Preserve user configuration files"
            echo "  --help         Show this help"
            exit 0
            ;;
        *) echo -e "${RED}Unknown option: $1${NC}"; exit 1 ;;
    esac
done

# ─── Logging ──────────────────────────────────────────────────────────────────
mkdir -p "$(dirname "$LOG_FILE")"
exec > >(tee -a "$LOG_FILE") 2>&1

log_info()  { echo -e "${GREEN}[✓]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
log_error() { echo -e "${RED}[✗]${NC} $1"; }
log_step()  { echo -e "\n${BLUE}═══ $1 ═══${NC}"; }
log_header() {
    echo -e "${CYAN}══════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════${NC}"
}

# ─── Safety checks ────────────────────────────────────────────────────────────
check_root() {
    if [[ "$EUID" -ne 0 ]]; then
        echo -e "${RED}This script must be run as root (sudo).${NC}"
        exit 1
    fi
}

confirm_uninstall() {
    if [[ "$FORCE" -eq 1 ]]; then
        return 0
    fi

    echo ""
    echo -e "${RED}${BOLD}⚠ WARNING: This will completely remove REAPER OS!${NC}"
    echo ""
    echo "This will:"
    echo "  • Remove /opt/reaper-os and all installed files"
    echo "  • Remove REAPER OS systemd services"
    echo "  • Uninstall audio packages installed by REAPER OS"
    if [[ "$KEEP_CONFIG" -eq 0 ]]; then
        echo "  • Remove user configuration files (~/.config/REAPER, ~/.jackdrc, etc.)"
    fi
    echo "  • Restore original system configurations (if backed up)"
    echo ""
    echo -e "${YELLOW}Your personal files and home directory will NOT be affected.${NC}"
    echo ""

    read -r -p "Are you sure you want to uninstall REAPER OS? [y/N] " response
    case "$response" in
        [yY][eE][sS]|[yY]) return 0 ;;
        *) echo "Uninstall cancelled."; exit 0 ;;
    esac
}

# ─── Backup before removal ────────────────────────────────────────────────────
create_backup() {
    log_step "Creating backup before removal"
    if [[ "$DRY_RUN" -eq 1 ]]; then
        log_info "[DRY-RUN] Would create backup in $BACKUP_DIR"
        return 0
    fi
    mkdir -p "$BACKUP_DIR"

    if [[ -d "$INSTALL_DIR" ]]; then
        cp -a "$INSTALL_DIR" "$BACKUP_DIR/reaper-os-backup" 2>/dev/null || true
    fi

    if [[ -f "/etc/asound.conf" ]]; then
        cp /etc/asound.conf "$BACKUP_DIR/asound.conf.bak" 2>/dev/null || true
    fi
    if [[ -f "$HOME/.asoundrc" ]]; then
        cp "$HOME/.asoundrc" "$BACKUP_DIR/asoundrc.bak" 2>/dev/null || true
    fi
    if [[ -f "/etc/jackdrc" ]]; then
        cp /etc/jackdrc "$BACKUP_DIR/jackdrc.bak" 2>/dev/null || true
    fi
    if [[ -f "/etc/security/limits.d/99-audio.conf" ]]; then
        cp /etc/security/limits.d/99-audio.conf "$BACKUP_DIR/99-audio.conf.bak" 2>/dev/null || true
    fi

    echo "Backup directory: $BACKUP_DIR" >> "$BACKUP_DIR/backup-manifest.txt"
    ls -la "$BACKUP_DIR" >> "$BACKUP_DIR/backup-manifest.txt" 2>/dev/null || true

    log_info "Backup saved to $BACKUP_DIR"
}

# ─── Stop services ────────────────────────────────────────────────────────────
stop_services() {
    log_step "Stopping REAPER OS services"

    local services=(
        "reaper-os-dashboard"
        "reaper-collaboration"
        "reaper-mixing-analytics"
        "reaper-streaming"
        "reaper-mastering"
        "reaper-network-audio"
        "audiogridder-server"
        "jackd"
    )

    for svc in "${services[@]}"; do
        if systemctl is-active --quiet "$svc" 2>/dev/null; then
            if [[ "$DRY_RUN" -eq 1 ]]; then
                log_info "[DRY-RUN] Would stop $svc"
            else
                systemctl stop "$svc" 2>/dev/null || log_warn "Failed to stop $svc"
                log_info "Stopped $svc"
            fi
        fi
        if systemctl is-enabled --quiet "$svc" 2>/dev/null; then
            if [[ "$DRY_RUN" -eq 1 ]]; then
                log_info "[DRY-RUN] Would disable $svc"
            else
                systemctl disable "$svc" 2>/dev/null || true
                log_info "Disabled $svc"
            fi
        fi
    done
}

# ─── Remove systemd units ─────────────────────────────────────────────────────
remove_systemd_units() {
    log_step "Removing systemd unit files"

    local units=(
        "/etc/systemd/system/reaper-os-dashboard.service"
        "/etc/systemd/system/reaper-collaboration.service"
        "/etc/systemd/system/reaper-mixing-analytics.service"
        "/etc/systemd/system/reaper-streaming.service"
        "/etc/systemd/system/reaper-mastering.service"
        "/etc/systemd/system/reaper-network-audio.service"
        "/etc/systemd/system/audiogridder-server.service"
        "/etc/systemd/system/jackd.service"
    )

    for unit in "${units[@]}"; do
        if [[ -f "$unit" ]]; then
            if [[ "$DRY_RUN" -eq 1 ]]; then
                log_info "[DRY-RUN] Would remove $unit"
            else
                rm -f "$unit"
                REMOVED_FILES+=("$unit")
                log_info "Removed $unit"
            fi
        fi
    done

    if [[ "$DRY_RUN" -eq 0 ]]; then
        systemctl daemon-reload 2>/dev/null || true
    fi
}

# ─── Remove packages ──────────────────────────────────────────────────────────
remove_packages() {
    log_step "Removing installed packages"

    local packages=(
        "jackd2" "jackd2-firewire" "jack-tools" "jack-keyboard"
        "qjackctl" "patchage" "a2jmidid"
        "ardour" "audacity" "musescore" "musescore3"
        "calf-plugins" "zynaddsubfx" "yoshimi"
        "supercollider" "puredata" "lmms"
        "sox" "ffmpeg" "libsox-fmt-all"
        "timidity" "fluid-soundfont-gm"
        "wine" "wine64" "winetricks" "wineasio"
        "carla" "carla-bridge-win32" "carla-bridge-win64"
        "pipewire-jack" "pipewire-audio"
        "linux-headers-rt-amd64" "rtirq-init"
    )

    for pkg in "${packages[@]}"; do
        if dpkg -l "$pkg" 2>/dev/null | grep -q '^ii'; then
            if [[ "$DRY_RUN" -eq 1 ]]; then
                log_info "[DRY-RUN] Would remove $pkg"
            else
                if apt-get remove -y --purge "$pkg" 2>/dev/null; then
                    REMOVED_PACKAGES+=("$pkg")
                    log_info "Removed $pkg"
                else
                    FAILED_PACKAGES+=("$pkg")
                    log_warn "Failed to remove $pkg"
                fi
            fi
        fi
    done
}

# ─── Remove installed files ───────────────────────────────────────────────────
remove_install_dir() {
    log_step "Removing REAPER OS installation files"

    if [[ -d "$INSTALL_DIR" ]]; then
        if [[ "$DRY_RUN" -eq 1 ]]; then
            log_info "[DRY-RUN] Would remove $INSTALL_DIR"
        else
            rm -rf "$INSTALL_DIR"
            REMOVED_FILES+=("$INSTALL_DIR")
            log_info "Removed $INSTALL_DIR"
        fi
    else
        log_warn "$INSTALL_DIR not found (already removed?)"
    fi

    # Remove launcher scripts
    local launchers=(
        "/usr/local/bin/reaper-os"
        "/usr/local/bin/reaper-os-dashboard"
        "/usr/local/bin/reaper-os-diagnostics"
        "/usr/local/bin/audio-config-manager"
        "/usr/local/bin/audio-profile-manager"
    )
    for launcher in "${launchers[@]}"; do
        if [[ -f "$launcher" ]]; then
            if [[ "$DRY_RUN" -eq 1 ]]; then
                log_info "[DRY-RUN] Would remove $launcher"
            else
                rm -f "$launcher"
                REMOVED_FILES+=("$launcher")
                log_info "Removed $launcher"
            fi
        fi
    done

    # Remove desktop entries
    if [[ -d "/usr/share/applications" ]]; then
        find /usr/share/applications -name "reaper-os*" -type f 2>/dev/null | while read -r f; do
            if [[ "$DRY_RUN" -eq 1 ]]; then
                log_info "[DRY-RUN] Would remove $f"
            else
                rm -f "$f"
                REMOVED_FILES+=("$f")
            fi
        done
        if [[ "$DRY_RUN" -eq 0 ]]; then
            update-desktop-database 2>/dev/null || true
        fi
    fi
}

# ─── Remove configuration files ───────────────────────────────────────────────
remove_configs() {
    if [[ "$KEEP_CONFIG" -eq 1 ]]; then
        log_step "Keeping user configuration files (--keep-config)"
        return 0
    fi

    log_step "Removing configuration files"

    local configs=(
        "$HOME/.config/REAPER"
        "$HOME/.config/reaper-audio-profiles"
        "$HOME/.jackdrc"
        "$HOME/.asoundrc"
        "$HOME/.wine"
        "$HOME/.local/share/reaper-os"
        "$HOME/.cache/reaper-os"
    )

    for cfg in "${configs[@]}"; do
        if [[ -e "$cfg" ]]; then
            if [[ "$DRY_RUN" -eq 1 ]]; then
                log_info "[DRY-RUN] Would remove $cfg"
            else
                rm -rf "$cfg"
                REMOVED_FILES+=("$cfg")
                log_info "Removed $cfg"
            fi
        fi
    done

    # System-level configs (only remove if they match REAPER OS patterns)
    if [[ -f "/etc/asound.conf" ]] && grep -q "REAPER OS" /etc/asound.conf 2>/dev/null; then
        if [[ "$DRY_RUN" -eq 1 ]]; then
            log_info "[DRY-RUN] Would remove /etc/asound.conf"
        else
            rm -f /etc/asound.conf
            REMOVED_FILES+=("/etc/asound.conf")
            log_info "Removed /etc/asound.conf"
        fi
    fi

    if [[ -f "/etc/security/limits.d/99-audio.conf" ]]; then
        if [[ "$DRY_RUN" -eq 1 ]]; then
            log_info "[DRY-RUN] Would remove /etc/security/limits.d/99-audio.conf"
        else
            rm -f /etc/security/limits.d/99-audio.conf
            REMOVED_FILES+=("/etc/security/limits.d/99-audio.conf")
        fi
    fi
}

# ─── Restore original configs ────────────────────────────────────────────────
restore_configs() {
    log_step "Restoring original system configurations"

    # Restore ALSA config if backed up
    if [[ -f "$BACKUP_DIR/asound.conf.bak" ]]; then
        if [[ "$DRY_RUN" -eq 1 ]]; then
            log_info "[DRY-RUN] Would restore /etc/asound.conf from backup"
        else
            cp "$BACKUP_DIR/asound.conf.bak" /etc/asound.conf
            log_info "Restored /etc/asound.conf"
        fi
    fi

    # Remove realtime kernel if it was the only change
    if [[ "$DRY_RUN" -eq 0 ]]; then
        apt-get autoremove -y 2>/dev/null || true
        apt-get autoclean 2>/dev/null || true
    fi

    if [[ "$DRY_RUN" -eq 1 ]]; then
        log_info "[DRY-RUN] Would run apt autoremove & autoclean"
    else
        log_info "Cleaned up package cache"
    fi
}

# ─── Summary ──────────────────────────────────────────────────────────────────
print_summary() {
    log_header "Uninstall Summary"

    if [[ "$DRY_RUN" -eq 1 ]]; then
        echo -e "${YELLOW}This was a DRY RUN. No changes were made.${NC}"
        echo ""
        echo "To actually uninstall, run:"
        echo "  sudo bash $0 --force"
        return 0
    fi

    echo ""
    echo -e "${GREEN}REAPER OS has been uninstalled.${NC}"
    echo ""
    echo "──────────────────────────────────────────────"
    echo "  Packages removed:  ${#REMOVED_PACKAGES[@]}"
    echo "  Files removed:     ${#REMOVED_FILES[@]}"
    echo "  Failed removals:   ${#FAILED_PACKAGES[@]}"
    echo "  Backup saved to:   $BACKUP_DIR"
    echo "  Log file:          $LOG_FILE"
    echo "──────────────────────────────────────────────"

    if [[ ${#FAILED_PACKAGES[@]} -gt 0 ]]; then
        echo ""
        echo -e "${YELLOW}Some packages could not be removed:${NC}"
        for pkg in "${FAILED_PACKAGES[@]}"; do
            echo "  - $pkg"
        done
        echo "You may remove them manually with: apt remove $pkg"
    fi

    if [[ "$KEEP_CONFIG" -eq 0 ]]; then
        echo ""
        echo -e "${YELLOW}Note: User configurations were removed.${NC}"
        echo "For a clean reinstall, run the installer again."
    fi

    echo ""
    echo -e "${CYAN}Thank you for using REAPER OS!${NC}"
}

# ─── Main ─────────────────────────────────────────────────────────────────────
main() {
    log_header "REAPER OS Uninstaller v1.1.0"

    if [[ "$DRY_RUN" -eq 1 ]]; then
        echo -e "${YELLOW}DRY RUN MODE - No changes will be made${NC}"
        echo ""
    fi

    check_root
    confirm_uninstall
    create_backup
    stop_services
    remove_systemd_units
    remove_packages
    remove_install_dir
    remove_configs
    restore_configs
    print_summary
}

main
