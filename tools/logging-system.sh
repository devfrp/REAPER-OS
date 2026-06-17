#!/bin/bash
#
# REAPER OS Centralized Logging System
# Manage system logs, events, and diagnostics
#

set -e

LOG_DIR="$HOME/.local/share/reaper-os/logs"
EVENT_LOG="$LOG_DIR/events.log"
SYSTEM_LOG="$LOG_DIR/system.log"
ERROR_LOG="$LOG_DIR/errors.log"
MAX_LOG_SIZE=10485760  # 10MB
MAX_LOG_FILES=10

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Initialize logging
init_logging() {
    mkdir -p "$LOG_DIR"
    touch "$EVENT_LOG" "$SYSTEM_LOG" "$ERROR_LOG"
}

# Log event
log_event() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "[$timestamp] [$level] $message" >> "$EVENT_LOG"
    
    # Also echo to console based on level
    case "$level" in
        ERROR)
            echo -e "${RED}[ERROR]${NC} $message" >&2
            ;;
        WARNING)
            echo -e "${YELLOW}[WARNING]${NC} $message"
            ;;
        SUCCESS)
            echo -e "${GREEN}[✓]${NC} $message"
            ;;
        INFO)
            echo -e "${BLUE}[INFO]${NC} $message"
            ;;
    esac
}

# Log system event
log_system() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "[$timestamp] SYSTEM: $message" >> "$SYSTEM_LOG"
}

# Log error with context
log_error() {
    local message="$1"
    local context="${2:-unknown}"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    {
        echo "[$timestamp] ERROR in $context"
        echo "Message: $message"
        echo "User: $(whoami)"
        echo "PWD: $(pwd)"
        echo "Shell: $SHELL"
        echo "---"
    } >> "$ERROR_LOG"
    
    echo -e "${RED}[ERROR]${NC} $message" >&2
}

# Rotate logs
rotate_logs() {
    for log_file in "$EVENT_LOG" "$SYSTEM_LOG" "$ERROR_LOG"; do
        if [[ -f "$log_file" ]]; then
            local size=$(stat -f%z "$log_file" 2>/dev/null || stat -c%s "$log_file" 2>/dev/null)
            
            if [[ $size -gt $MAX_LOG_SIZE ]]; then
                local timestamp=$(date '+%Y%m%d-%H%M%S')
                local backup="${log_file}.${timestamp}"
                
                mv "$log_file" "$backup"
                gzip "$backup" &
                touch "$log_file"
                
                log_event "INFO" "Rotated log file: $(basename "$log_file")"
                
                # Clean old backups
                find "$(dirname "$log_file")" -name "$(basename "$log_file").*" -mtime +30 -delete
            fi
        fi
    done
}

# View logs
view_logs() {
    local log_type="${1:-event}"
    
    case "$log_type" in
        event)
            tail -100 "$EVENT_LOG"
            ;;
        system)
            tail -100 "$SYSTEM_LOG"
            ;;
        error)
            tail -100 "$ERROR_LOG"
            ;;
        all)
            echo "=== EVENTS ===" && tail -50 "$EVENT_LOG"
            echo -e "\n=== SYSTEM ===" && tail -50 "$SYSTEM_LOG"
            echo -e "\n=== ERRORS ===" && tail -50 "$ERROR_LOG"
            ;;
        *)
            log_event "ERROR" "Unknown log type: $log_type"
            exit 1
            ;;
    esac
}

# Search logs
search_logs() {
    local query="$1"
    
    log_event "INFO" "Searching logs for: $query"
    
    echo "=== Event Log ==="
    grep -i "$query" "$EVENT_LOG" || echo "No matches"
    
    echo -e "\n=== System Log ==="
    grep -i "$query" "$SYSTEM_LOG" || echo "No matches"
    
    echo -e "\n=== Error Log ==="
    grep -i "$query" "$ERROR_LOG" || echo "No matches"
}

# Generate debug report
generate_debug_report() {
    local report_file="$LOG_DIR/debug-report-$(date '+%Y%m%d-%H%M%S').txt"
    
    {
        echo "REAPER OS Debug Report"
        echo "Generated: $(date)"
        echo "================================"
        echo ""
        echo "System Information:"
        echo "- Kernel: $(uname -r)"
        echo "- Hostname: $(hostname)"
        echo "- Uptime: $(uptime -p)"
        echo "- CPU Cores: $(nproc)"
        echo "- RAM: $(free -h | grep Mem)"
        echo ""
        echo "Audio System:"
        echo "- JACK Status: $(jackd -v 2>&1 | head -1)"
        echo "- ALSA: $(aplay -l | wc -l) devices"
        echo ""
        echo "Recent Events:"
        tail -50 "$EVENT_LOG"
        echo ""
        echo "Recent Errors:"
        tail -20 "$ERROR_LOG"
        echo ""
        echo "Running Processes (REAPER/Audio):"
        ps aux | grep -E 'reaper|jack|wine|qemu|pulse' | grep -v grep
        echo ""
        echo "Audio Devices:"
        aplay -l
        echo ""
        echo "MIDI Devices:"
        aconnect -l
        
    } > "$report_file"
    
    log_event "SUCCESS" "Debug report generated: $report_file"
    echo "$report_file"
}

# Show log statistics
show_stats() {
    echo "=== Log Statistics ==="
    
    echo "Event Log:"
    wc -l "$EVENT_LOG"
    du -h "$EVENT_LOG"
    
    echo ""
    echo "System Log:"
    wc -l "$SYSTEM_LOG"
    du -h "$SYSTEM_LOG"
    
    echo ""
    echo "Error Log:"
    wc -l "$ERROR_LOG"
    du -h "$ERROR_LOG"
    
    echo ""
    echo "Error Summary:"
    grep -o '\[ERROR\]' "$EVENT_LOG" | wc -l
    echo "Total errors logged"
    
    echo ""
    echo "Recent Errors:"
    grep '\[ERROR\]' "$EVENT_LOG" | tail -5
}

# Clean logs
clean_logs() {
    local older_than="${1:-30}"  # days
    
    log_event "WARNING" "Cleaning logs older than $older_than days"
    
    find "$LOG_DIR" -name "*.log" -mtime +$older_than -delete
    find "$LOG_DIR" -name "*.gz" -mtime +$older_than -delete
    
    log_event "SUCCESS" "Logs cleaned"
}

# Export logs
export_logs() {
    local export_file="${1:-reaper-os-logs-$(date '+%Y%m%d').tar.gz}"
    
    log_event "INFO" "Exporting logs to: $export_file"
    
    tar -czf "$export_file" -C "$(dirname "$LOG_DIR")" "$(basename "$LOG_DIR")"
    
    log_event "SUCCESS" "Logs exported: $export_file"
    echo "$export_file"
}

# Show help
show_help() {
    cat << EOF
REAPER OS Logging System

Usage: $(basename "$0") <command> [options]

Commands:
  event <message>      Log an event
  error <message>      Log an error with context
  system <message>     Log a system event
  view [type]          View logs (event|system|error|all)
  search <query>       Search logs for query
  stats                Show log statistics
  rotate               Rotate log files
  clean [days]         Clean logs older than N days
  export [file]        Export logs to tar.gz
  debug                Generate debug report
  follow               Follow log file in real-time
  help                 Show this help

Examples:
  $(basename "$0") event "User loaded REAPER"
  $(basename "$0") error "Failed to initialize JACK" "jack-setup"
  $(basename "$0") view all
  $(basename "$0") search "jack"
  $(basename "$0") stats
  $(basename "$0") export backup.tar.gz

Log Location: $LOG_DIR
EOF
}

# Main
main() {
    init_logging
    
    case "${1:-help}" in
        event)
            log_event "INFO" "${2:-Empty message}"
            ;;
        error)
            log_error "${2:-Empty error}" "${3:-unknown}"
            ;;
        system)
            log_system "${2:-Empty system event}"
            ;;
        view)
            view_logs "${2:-event}"
            ;;
        search)
            search_logs "${2:-.}"
            ;;
        stats)
            show_stats
            ;;
        rotate)
            rotate_logs
            ;;
        clean)
            clean_logs "${2:-30}"
            ;;
        export)
            export_logs "${2:-reaper-os-logs-$(date '+%Y%m%d').tar.gz}"
            ;;
        debug)
            generate_debug_report
            ;;
        follow)
            tail -f "$EVENT_LOG"
            ;;
        help|-h|--help)
            show_help
            ;;
        *)
            log_event "ERROR" "Unknown command: $1"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
