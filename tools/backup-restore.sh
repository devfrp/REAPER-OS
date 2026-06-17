#!/bin/bash
#
# REAPER OS Backup & Restore System
# Backup and restore REAPER configuration, audio profiles, and VST settings
#

set -e

BACKUP_DIR="$HOME/.local/share/reaper-os/backups"
REAPER_CONFIG="$HOME/.config/REAPER"
REAPER_AUDIO="$HOME/.local/share/reaper-os/audio-profiles"
VST_DIR="$HOME/.wine/drive_c/Program Files/Common Files/VST"
AUDIO_CONFIG="$HOME/.jackrc"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

mkdir -p "$BACKUP_DIR"

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

# Create full backup
create_backup() {
    local backup_name="${1:-backup-$(date '+%Y%m%d-%H%M%S')}"
    local backup_path="$BACKUP_DIR/$backup_name"
    
    log_info "Creating backup: $backup_name"
    
    mkdir -p "$backup_path"
    
    # Backup REAPER config
    if [[ -d "$REAPER_CONFIG" ]]; then
        log_info "Backing up REAPER configuration..."
        cp -r "$REAPER_CONFIG" "$backup_path/reaper-config"
    fi
    
    # Backup audio profiles
    if [[ -d "$REAPER_AUDIO" ]]; then
        log_info "Backing up audio profiles..."
        cp -r "$REAPER_AUDIO" "$backup_path/audio-profiles"
    fi
    
    # Backup JACK config
    if [[ -f "$AUDIO_CONFIG" ]]; then
        log_info "Backing up JACK configuration..."
        cp "$AUDIO_CONFIG" "$backup_path/jackrc"
    fi
    
    # Create manifest
    {
        echo "REAPER OS Backup"
        echo "Created: $(date)"
        echo "System: $(uname -s)"
        echo "REAPER Version: $(reaper --version 2>/dev/null || echo 'Unknown')"
        echo "Included:"
        echo "  - REAPER configuration"
        echo "  - Audio profiles"
        echo "  - JACK configuration"
    } > "$backup_path/manifest.txt"
    
    # Compress backup
    log_info "Compressing backup..."
    tar -czf "$backup_path.tar.gz" -C "$BACKUP_DIR" "$backup_name"
    rm -rf "$backup_path"
    
    log_success "Backup created: $backup_path.tar.gz"
    du -h "$backup_path.tar.gz"
}

# Restore from backup
restore_backup() {
    local backup_file="${1:?Backup file required}"
    
    if [[ ! -f "$backup_file" ]]; then
        log_error "Backup file not found: $backup_file"
        exit 1
    fi
    
    log_warning "This will overwrite current REAPER configuration!"
    read -p "Continue? (y/N) " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Restore cancelled"
        return
    fi
    
    log_info "Extracting backup..."
    local temp_dir=$(mktemp -d)
    tar -xzf "$backup_file" -C "$temp_dir"
    
    local backup_name=$(basename "$backup_file" .tar.gz)
    
    # Restore REAPER config
    if [[ -d "$temp_dir/$backup_name/reaper-config" ]]; then
        log_info "Restoring REAPER configuration..."
        rm -rf "$REAPER_CONFIG"
        cp -r "$temp_dir/$backup_name/reaper-config" "$REAPER_CONFIG"
    fi
    
    # Restore audio profiles
    if [[ -d "$temp_dir/$backup_name/audio-profiles" ]]; then
        log_info "Restoring audio profiles..."
        mkdir -p "$REAPER_AUDIO"
        cp -r "$temp_dir/$backup_name/audio-profiles"/* "$REAPER_AUDIO"
    fi
    
    # Restore JACK config
    if [[ -f "$temp_dir/$backup_name/jackrc" ]]; then
        log_info "Restoring JACK configuration..."
        cp "$temp_dir/$backup_name/jackrc" "$AUDIO_CONFIG"
    fi
    
    rm -rf "$temp_dir"
    log_success "Restore complete!"
}

# Incremental backup (only changed files)
create_incremental_backup() {
    local backup_name="incremental-$(date '+%Y%m%d-%H%M%S')"
    local backup_path="$BACKUP_DIR/$backup_name"
    
    log_info "Creating incremental backup: $backup_name"
    
    mkdir -p "$backup_path"
    
    # Find files modified in last day
    local reaper_files=$(find "$REAPER_CONFIG" -type f -mtime -1 2>/dev/null || true)
    
    if [[ -n "$reaper_files" ]]; then
        log_info "Found $(echo "$reaper_files" | wc -l) modified files"
        mkdir -p "$backup_path/reaper-config"
        echo "$reaper_files" | while read -r file; do
            local rel_path="${file#$REAPER_CONFIG/}"
            mkdir -p "$(dirname "$backup_path/reaper-config/$rel_path")"
            cp "$file" "$backup_path/reaper-config/$rel_path"
        done
    fi
    
    tar -czf "$backup_path.tar.gz" -C "$BACKUP_DIR" "$backup_name"
    rm -rf "$backup_path"
    
    log_success "Incremental backup created: $backup_path.tar.gz"
}

# List backups
list_backups() {
    log_info "Available backups:\n"
    
    if [[ ! -d "$BACKUP_DIR" ]] || [[ -z "$(ls -A "$BACKUP_DIR")" ]]; then
        log_warning "No backups found"
        return
    fi
    
    ls -lht "$BACKUP_DIR"/*.tar.gz | awk '{print $9, "("$5")"}' | while read -r file size; do
        printf "  %s %s\n" "$(basename "$file")" "$size"
    done
}

# Automatic scheduled backup
setup_scheduled_backup() {
    local cron_entry="0 2 * * * bash $0 create > /tmp/reaper-backup.log 2>&1"
    
    log_info "Setting up daily backup at 2 AM..."
    
    # Add to crontab if not already present
    (crontab -l 2>/dev/null | grep -v "$0 create" || true; echo "$cron_entry") | crontab -
    
    log_success "Scheduled backup enabled"
}

# Verify backup integrity
verify_backup() {
    local backup_file="${1:?Backup file required}"
    
    log_info "Verifying backup: $(basename "$backup_file")"
    
    if tar -tzf "$backup_file" > /dev/null 2>&1; then
        log_success "Backup is valid"
        local size=$(du -h "$backup_file" | cut -f1)
        echo "Size: $size"
        echo "Files:"
        tar -tzf "$backup_file" | head -10
    else
        log_error "Backup is corrupted or invalid"
        exit 1
    fi
}

# Export backup for external storage
export_backup() {
    local backup_file="${1:?Backup file required}"
    local export_path="${2:-~/Downloads}"
    
    log_info "Exporting backup to: $export_path"
    
    cp "$backup_file" "$export_path/"
    log_success "Backup exported: $export_path/$(basename "$backup_file")"
}

# Clean old backups
cleanup_old_backups() {
    local days="${1:-30}"
    
    log_info "Removing backups older than $days days..."
    
    find "$BACKUP_DIR" -name "*.tar.gz" -mtime +$days -delete
    
    log_success "Cleanup complete"
}

# Show help
show_help() {
    cat << EOF
REAPER OS Backup & Restore System

Usage: $(basename "$0") <command> [options]

Commands:
  create [name]        Create full backup
  restore <file>       Restore from backup
  incremental          Create incremental backup
  list                 List available backups
  verify <file>        Verify backup integrity
  export <file> <path> Export backup to external storage
  schedule             Setup automatic daily backups
  cleanup [days]       Remove backups older than N days
  help                 Show this help

Examples:
  $(basename "$0") create                    # Create named backup
  $(basename "$0") restore backup-*.tar.gz   # Restore
  $(basename "$0") list                      # Show backups
  $(basename "$0") verify backup-*.tar.gz    # Check backup
  $(basename "$0") schedule                  # Enable auto-backup
  $(basename "$0") cleanup 30                # Remove old backups

Backup Location: $BACKUP_DIR
EOF
}

main() {
    case "${1:-help}" in
        create)
            create_backup "${2:-}"
            ;;
        restore)
            restore_backup "$2"
            ;;
        incremental)
            create_incremental_backup
            ;;
        list)
            list_backups
            ;;
        verify)
            verify_backup "$2"
            ;;
        export)
            export_backup "$2" "$3"
            ;;
        schedule)
            setup_scheduled_backup
            ;;
        cleanup)
            cleanup_old_backups "${2:-30}"
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
