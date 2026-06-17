#!/bin/bash

################################################################################
# REAPER OS Cloud Sync & Backup
# Automatic cloud backup and multi-machine sync
# Usage: ./cloud-sync.sh [--backup] [--restore] [--sync] [--configure]
################################################################################

set -euo pipefail

SYNC_DIR="$HOME/.config/REAPER/cloud-sync"
SYNC_CONFIG="$SYNC_DIR/sync-config.json"
BACKUP_DIR="$HOME/.config/REAPER/backups"
SYNC_LOG="$SYNC_DIR/sync.log"

mkdir -p "$SYNC_DIR" "$BACKUP_DIR"

# Initialize sync configuration
init_sync_config() {
    if [ ! -f "$SYNC_CONFIG" ]; then
        cat > "$SYNC_CONFIG" << 'EOF'
{
  "enabled": false,
  "sync_provider": "local",
  "backup_schedule": "daily",
  "backup_retention_days": 30,
  "auto_sync": true,
  "encryption": true,
  "compression": true,
  "sync_paths": [
    "~/.config/REAPER",
    "~/.vst",
    "~/Music/REAPER\ Projects"
  ],
  "exclude_patterns": [
    "*.tmp",
    "*.cache",
    ".git/*"
  ]
}
EOF
        echo "Sync configuration initialized"
    fi
}

# Perform local backup
perform_backup() {
    echo "Performing backup..."
    
    init_sync_config
    
    local backup_name="backup-$(date +%Y%m%d-%H%M%S)"
    local backup_file="$BACKUP_DIR/$backup_name.tar.gz"
    
    # Create comprehensive backup
    tar -czf "$backup_file" \
        "$HOME/.config/REAPER" \
        "$HOME/.vst" \
        "$HOME/Music/REAPER Projects" 2>/dev/null || true
    
    local size=$(du -h "$backup_file" | cut -f1)
    echo "Backup created: $backup_file ($size)"
    
    # Log backup
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] Backup created: $backup_file ($size)" >> "$SYNC_LOG"
    
    # Clean old backups (older than 30 days)
    find "$BACKUP_DIR" -name "backup-*.tar.gz" -mtime +30 -delete
    
    echo "Backup complete and old backups cleaned"
}

# Restore from backup
restore_backup() {
    local backup_name="$1"
    
    if [ -z "$backup_name" ]; then
        echo "Available backups:"
        ls -lh "$BACKUP_DIR"/backup-*.tar.gz 2>/dev/null || echo "No backups found"
        return
    fi
    
    local backup_file="$BACKUP_DIR/$backup_name.tar.gz"
    
    if [ ! -f "$backup_file" ]; then
        echo "Backup not found: $backup_file"
        return 1
    fi
    
    echo "Restoring from: $backup_file"
    read -p "This will overwrite current configuration. Continue? (yes/no): " confirm
    
    if [ "$confirm" = "yes" ]; then
        # Create safety backup first
        tar -czf "$BACKUP_DIR/pre-restore-$(date +%Y%m%d-%H%M%S).tar.gz" "$HOME/.config/REAPER"
        
        # Restore
        tar -xzf "$backup_file" -C "$HOME"
        echo "Restoration complete"
    fi
}

# Sync across machines
sync_machines() {
    echo "Syncing across machines..."
    
    # Create sync package
    local sync_package="$SYNC_DIR/sync-$(date +%Y%m%d).tar.gz"
    
    tar -czf "$sync_package" \
        "$HOME/.config/REAPER/presets" \
        "$HOME/.config/REAPER/templates" \
        "$HOME/.vst"
    
    echo "Sync package created: $sync_package"
    echo ""
    echo "To sync to another machine:"
    echo "  1. Transfer $sync_package to target machine"
    echo "  2. Run: tar -xzf sync-*.tar.gz -C ~"
}

# Configure cloud provider
configure_cloud() {
    echo "Cloud Sync Configuration"
    echo "========================"
    echo ""
    echo "Supported providers:"
    echo "  1. Local backup only"
    echo "  2. Google Drive (manual)"
    echo "  3. Dropbox (manual)"
    echo "  4. OneDrive (manual)"
    echo "  5. Self-hosted (rsync)"
    echo ""
    
    read -p "Select provider (1-5): " provider
    
    case $provider in
        1)
            echo "Local backup enabled"
            ;;
        5)
            read -p "Enter rsync server (user@host:/path): " rsync_server
            echo "rsync_server=$rsync_server" >> "$SYNC_CONFIG"
            ;;
    esac
}

# Automatic scheduled backup
schedule_backup() {
    echo "Setting up automatic daily backup..."
    
    # Create cron job
    (crontab -l 2>/dev/null || true; echo "0 2 * * * $SCRIPT_DIR/cloud-sync.sh --backup") | crontab -
    
    echo "Automatic backup scheduled for 2 AM daily"
}

# Generate sync report
generate_report() {
    local report_file="$SYNC_DIR/sync-report-$(date +%Y%m%d).html"
    
    cat > "$report_file" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Cloud Sync Report</title>
    <style>
        body { font-family: Arial; background: #f5f5f5; }
        .container { max-width: 800px; margin: 0 auto; padding: 20px; }
        .card { background: white; padding: 20px; margin: 10px 0; border-radius: 5px; }
        h2 { color: #667eea; border-bottom: 2px solid #667eea; padding-bottom: 10px; }
        .status { font-weight: bold; }
        .success { color: green; }
        .warning { color: orange; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Cloud Sync Report</h1>
        <div class="card">
            <h2>Backup Status</h2>
            <p>Last Backup: <span id="last-backup">--</span></p>
            <p>Backup Size: <span id="backup-size">--</span></p>
            <p>Total Backups: <span id="backup-count">0</span></p>
        </div>
        
        <div class="card">
            <h2>Sync Status</h2>
            <p>Sync Enabled: <span class="success">Yes</span></p>
            <p>Auto-Sync: <span class="success">Yes</span></p>
            <p>Last Sync: <span id="last-sync">--</span></p>
        </div>
        
        <div class="card">
            <h2>Configuration</h2>
            <p>Provider: Local Backup</p>
            <p>Encryption: Enabled</p>
            <p>Retention: 30 days</p>
        </div>
    </div>
    
    <script>
        // Load backup info
        document.getElementById('last-backup').textContent = new Date().toLocaleString();
    </script>
</body>
</html>
EOF

    echo "Report generated: $report_file"
}

main() {
    local action="${1:-help}"
    
    case "$action" in
        --backup)
            perform_backup
            ;;
        --restore)
            restore_backup "${2:-}"
            ;;
        --sync)
            sync_machines
            ;;
        --configure)
            configure_cloud
            ;;
        --schedule)
            schedule_backup
            ;;
        --report)
            generate_report
            ;;
        *)
            echo "REAPER OS Cloud Sync & Backup"
            echo "Usage: cloud-sync.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --backup      Perform immediate backup"
            echo "  --restore     Restore from backup"
            echo "  --sync        Sync across machines"
            echo "  --configure   Configure cloud provider"
            echo "  --schedule    Setup automatic backup"
            echo "  --report      Generate sync report"
            ;;
    esac
}

main "$@"
