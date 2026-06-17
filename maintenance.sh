#!/bin/bash
# REAPER OS Maintenance & Update Script - v1.0.0
# Automates common maintenance tasks

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
LOG_FILE="$HOME/.reaper-os-maintenance.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

# Logging
log() {
    echo "[${DATE}] $1" >> "$LOG_FILE"
    echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
    echo "[${DATE}] ✓ $1" >> "$LOG_FILE"
    echo -e "${GREEN}✓${NC} $1"
}

log_error() {
    echo "[${DATE}] ✗ $1" >> "$LOG_FILE"
    echo -e "${RED}✗${NC} $1"
}

log_warn() {
    echo "[${DATE}] ⚠ $1" >> "$LOG_FILE"
    echo -e "${YELLOW}⚠${NC} $1"
}

# Functions
show_menu() {
    echo ""
    echo -e "${BLUE}REAPER OS Maintenance & Update${NC}"
    echo "================================="
    echo "1. Update system packages"
    echo "2. Update audio tools"
    echo "3. Clean system cache"
    echo "4. Backup projects"
    echo "5. Health check"
    echo "6. JACK optimization"
    echo "7. Plugin scan"
    echo "8. Full maintenance (all tasks)"
    echo "9. View maintenance log"
    echo "0. Exit"
    echo ""
    read -p "Select option [0-9]: " choice
}

update_system() {
    log "Starting system package update..."
    
    # Update package lists
    sudo apt update || log_error "Failed to update package lists"
    log_success "Package lists updated"
    
    # Upgrade packages
    sudo apt upgrade -y || log_error "Failed to upgrade packages"
    log_success "System packages upgraded"
    
    # Auto-remove unused packages
    sudo apt autoremove -y
    log_success "Unused packages removed"
}

update_audio_tools() {
    log "Updating audio tools..."
    
    AUDIO_PACKAGES=(
        "reaper"
        "ardour"
        "audacity"
        "ffmpeg"
        "sox"
        "timidity"
        "musescore"
        "qjackctl"
        "calf-studio-gear"
        "supercollider"
        "puredata"
    )
    
    for package in "${AUDIO_PACKAGES[@]}"; do
        if dpkg -l | grep -q "^ii.*$package"; then
            log "Updating $package..."
            sudo apt install --only-upgrade "$package" -y 2>/dev/null || true
        fi
    done
    
    log_success "Audio tools updated"
}

clean_cache() {
    log "Cleaning system cache..."
    
    # Remove apt cache
    sudo apt clean
    sudo apt autoclean
    log "APT cache cleaned"
    
    # Remove old log files
    sudo find /var/log -name "*.log" -mtime +30 -delete 2>/dev/null || true
    log "Old log files cleaned"
    
    # Remove temporary files
    find "$HOME" -name "*.tmp" -mtime +7 -delete 2>/dev/null || true
    find "$HOME" -name "*.bak" -mtime +30 -delete 2>/dev/null || true
    log "Temporary files cleaned"
    
    # Show disk usage
    DISK_USAGE=$(du -sh "$HOME" | cut -f1)
    log_success "Cache cleaned. Home directory: $DISK_USAGE"
}

backup_projects() {
    log "Backing up REAPER projects..."
    
    BACKUP_DIR="$HOME/backup-reaper-$(date +%Y%m%d-%H%M%S)"
    REAPER_DIR="$HOME/.config/REAPER"
    
    if [ -d "$REAPER_DIR" ]; then
        mkdir -p "$BACKUP_DIR"
        cp -r "$REAPER_DIR" "$BACKUP_DIR/" 2>/dev/null || log_warn "Couldn't backup all REAPER config"
        
        BACKUP_SIZE=$(du -sh "$BACKUP_DIR" | cut -f1)
        log_success "REAPER config backed up ($BACKUP_SIZE)"
    fi
    
    # Backup audio projects if they exist
    if [ -d "$HOME/ReaperProjects" ]; then
        mkdir -p "$BACKUP_DIR"
        cp -r "$HOME/ReaperProjects" "$BACKUP_DIR/" 2>/dev/null || log_warn "Couldn't backup all projects"
        log_success "Audio projects backed up"
    fi
}

health_check() {
    log "Running health check..."
    
    # Check disk space
    DISK_FREE=$(df / | awk 'NR==2 {print $4}')
    if [ "$DISK_FREE" -lt 5242880 ]; then  # Less than 5GB
        log_warn "Low disk space: $(numfmt --to=iec $DISK_FREE)"
    else
        log_success "Disk space OK: $(numfmt --to=iec $DISK_FREE) free"
    fi
    
    # Check RAM
    RAM_AVAILABLE=$(free | awk '/^Mem:/ {print $7}')
    if [ "$RAM_AVAILABLE" -lt 1048576 ]; then  # Less than 1GB
        log_warn "Low available RAM: $(numfmt --to=iec $RAM_AVAILABLE)"
    else
        log_success "RAM OK: $(numfmt --to=iec $RAM_AVAILABLE) available"
    fi
    
    # Check audio services
    if command -v jackd &> /dev/null; then
        log_success "JACK is installed"
    else
        log_warn "JACK not installed"
    fi
    
    # Check REAPER
    if command -v reaper &> /dev/null; then
        log_success "REAPER is installed"
    else
        log_warn "REAPER not installed"
    fi
}

jack_optimization() {
    log "Configuring JACK optimization..."
    
    # Create JACK startup script if it doesn't exist
    JACK_SCRIPT="$HOME/.config/jack-startup.sh"
    if [ ! -f "$JACK_SCRIPT" ]; then
        mkdir -p "$HOME/.config"
        cat > "$JACK_SCRIPT" << 'EOF'
#!/bin/bash
# JACK Optimal Startup

# Set CPU governor to performance
sudo cpupower frequency-set -g performance 2>/dev/null || true

# Start JACK with optimal settings
jackd -d alsa -d hw:0 -r 48000 -p 256 -n 3 &
EOF
        chmod +x "$JACK_SCRIPT"
        log_success "JACK startup script created"
    fi
    
    # Create limits configuration for real-time
    RT_LIMITS="/etc/security/limits.d/audio-rt.conf"
    if [ ! -f "$RT_LIMITS" ] && [ -w "/etc/security/limits.d/" ]; then
        sudo tee "$RT_LIMITS" > /dev/null << 'EOF'
@audio   soft    rtprio    99
@audio   hard    rtprio    99
@audio   soft    memlock   unlimited
@audio   hard    memlock   unlimited
EOF
        log_success "Real-time limits configured"
    else
        log "Real-time limits already configured or skipped"
    fi
}

plugin_scan() {
    log "Scanning for VST plugins..."
    
    if command -v reaper &> /dev/null; then
        # Create a plugin scan script for REAPER
        PLUGIN_SCRIPT="$HOME/.config/reaper-scan-plugins.sh"
        cat > "$PLUGIN_SCRIPT" << 'EOF'
#!/bin/bash
# Scans plugins and updates REAPER cache
reaper -script "scan_plugins.lua" 2>/dev/null || true
EOF
        chmod +x "$PLUGIN_SCRIPT"
        log "Plugin scan script created"
        log_success "Use REAPER UI to rescan: Options > Plugins > Re-scan VST plugins"
    else
        log_warn "REAPER not installed, skipping plugin scan"
    fi
}

view_log() {
    echo ""
    echo -e "${BLUE}=== Maintenance Log ===${NC}"
    echo ""
    if [ -f "$LOG_FILE" ]; then
        tail -50 "$LOG_FILE"  # Show last 50 lines
    else
        echo "No log file found yet"
    fi
    echo ""
}

# Main loop
while true; do
    show_menu
    case $choice in
        1)
            update_system
            ;;
        2)
            update_audio_tools
            ;;
        3)
            clean_cache
            ;;
        4)
            backup_projects
            ;;
        5)
            health_check
            ;;
        6)
            jack_optimization
            ;;
        7)
            plugin_scan
            ;;
        8)
            update_system
            update_audio_tools
            clean_cache
            backup_projects
            health_check
            log_success "Full maintenance completed"
            ;;
        9)
            view_log
            ;;
        0)
            echo "Goodbye!"
            exit 0
            ;;
        *)
            echo "Invalid option"
            ;;
    esac
done
