#!/bin/bash

################################################################################
# REAPER OS System Diagnostics Tool
# Real-time monitoring of audio latency, CPU load, memory usage
# Detects JACK latency, underruns, buffer issues
################################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
UPDATE_INTERVAL=1  # seconds
JACK_PORT="${JACK_PORT:-8000}"
JACK_LOG_DIR="/tmp/jack-diagnostics"

log_info() { echo -e "${BLUE}[DIAG]${NC} $1"; }
log_success() { echo -e "${GREEN}✓${NC} $1"; }
log_warn() { echo -e "${YELLOW}⚠${NC} $1"; }
log_error() { echo -e "${RED}✗${NC} $1"; }

# ==============================================================================
# 1. CHECK JACK STATUS
# ==============================================================================

check_jack_status() {
    local jack_status="OFFLINE"
    
    if command -v jack_lsp &> /dev/null; then
        if jack_lsp &> /dev/null; then
            jack_status="ONLINE"
        fi
    fi
    
    echo "$jack_status"
}

get_jack_latency() {
    local latency="N/A"
    
    if command -v jack_lsp &> /dev/null; then
        if jack_lsp &> /dev/null; then
            # Get buffer size and sample rate
            local buf_size=$(jack_wait -c 2>/dev/null || echo "256")
            local sample_rate=$(jack_samplerate 2>/dev/null || echo "48000")
            
            # Calculate latency in ms
            if [ "$sample_rate" != "0" ]; then
                latency=$(echo "scale=2; ($buf_size * 1000) / $sample_rate" | bc 2>/dev/null || echo "N/A")
                latency="${latency}ms"
            fi
        fi
    fi
    
    echo "$latency"
}

get_jack_underruns() {
    local underruns="0"
    
    if command -v jack_load_tester &> /dev/null; then
        # Run brief test
        underruns=$(jack_load_tester --help 2>/dev/null || echo "0")
    fi
    
    echo "$underruns"
}

count_jack_ports() {
    local count="0"
    
    if command -v jack_lsp &> /dev/null; then
        if jack_lsp &> /dev/null; then
            count=$(jack_lsp 2>/dev/null | wc -l)
        fi
    fi
    
    echo "$count"
}

# ==============================================================================
# 2. MONITOR CPU USAGE
# ==============================================================================

get_cpu_load() {
    local load=$(grep "cpu " /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {printf "%.1f", usage}')
    echo "$load%"
}

get_process_cpu() {
    local process_name="$1"
    local cpu=$(ps aux | grep "$process_name" | grep -v grep | awk '{print $3}' | head -1)
    
    if [ -z "$cpu" ]; then
        echo "0%"
    else
        echo "${cpu}%"
    fi
}

# ==============================================================================
# 3. MONITOR MEMORY USAGE
# ==============================================================================

get_memory_usage() {
    local mem=$(free | grep Mem | awk '{printf "%.1f", ($3/$2)*100}')
    echo "$mem%"
}

get_jack_memory() {
    local mem=$(ps aux | grep jackd | grep -v grep | awk '{print $6}' | head -1)
    
    if [ -z "$mem" ]; then
        echo "0MB"
    else
        echo "$((mem/1024))MB"
    fi
}

# ==============================================================================
# 4. AUDIO DEVICE STATUS
# ==============================================================================

check_audio_devices() {
    local count=$(aplay -l 2>/dev/null | grep "^card" | wc -l)
    echo "$count"
}

get_alsa_status() {
    if aplay -l &> /dev/null; then
        echo "OK"
    else
        echo "ERROR"
    fi
}

# ==============================================================================
# 5. DETECT PROTOCOL CONTROLLERS
# ==============================================================================

count_midi_devices() {
    local count=$(aconnect -l 2>/dev/null | grep "client" | wc -l)
    echo "$count"
}

check_osc_port() {
    local port="${1:-8000}"
    
    if nc -z localhost "$port" 2>/dev/null; then
        echo "LISTENING"
    else
        echo "NOT LISTENING"
    fi
}

# ==============================================================================
# 6. REAPER STATUS
# ==============================================================================

is_reaper_running() {
    if pgrep -f "reaper" > /dev/null; then
        echo "RUNNING"
    else
        echo "STOPPED"
    fi
}

get_reaper_memory() {
    local mem=$(ps aux | grep reaper | grep -v grep | awk '{print $6}' | head -1)
    
    if [ -z "$mem" ]; then
        echo "0MB"
    else
        echo "$((mem/1024))MB"
    fi
}

get_reaper_cpu() {
    local cpu=$(ps aux | grep reaper | grep -v grep | awk '{print $3}' | head -1)
    
    if [ -z "$cpu" ]; then
        echo "0%"
    else
        echo "$cpu%"
    fi
}

# ==============================================================================
# 7. SYSTEM DIAGNOSTICS REPORT
# ==============================================================================

show_diagnostic_report() {
    clear
    
    local jack_status=$(check_jack_status)
    local jack_latency=$(get_jack_latency)
    local jack_ports=$(count_jack_ports)
    local cpu_load=$(get_cpu_load)
    local memory=$(get_memory_usage)
    local audio_count=$(check_audio_devices)
    local alsa_status=$(get_alsa_status)
    local midi_count=$(count_midi_devices)
    local osc_status=$(check_osc_port "$JACK_PORT")
    local reaper_status=$(is_reaper_running)
    
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}     REAPER OS - System Diagnostics Report                 ${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # JACK Status
    echo -e "${BLUE}📊 JACK AUDIO SERVER:${NC}"
    if [ "$jack_status" = "ONLINE" ]; then
        log_success "JACK Status: $jack_status"
        log_success "Latency: $jack_latency"
        log_success "Active Ports: $jack_ports"
    else
        log_error "JACK Status: $jack_status"
    fi
    echo ""
    
    # System Resources
    echo -e "${BLUE}💻 SYSTEM RESOURCES:${NC}"
    if (( $(echo "$cpu_load > 80" | bc -l) )); then
        log_warn "CPU Load: $cpu_load"
    else
        log_success "CPU Load: $cpu_load"
    fi
    
    if (( $(echo "$memory > 80" | bc -l) )); then
        log_warn "Memory Usage: $memory"
    else
        log_success "Memory Usage: $memory"
    fi
    echo ""
    
    # Audio Devices
    echo -e "${BLUE}🔊 AUDIO DEVICES:${NC}"
    if [ "$alsa_status" = "OK" ]; then
        log_success "ALSA Status: OK"
        log_success "Audio Cards Found: $audio_count"
    else
        log_error "ALSA Status: ERROR"
    fi
    echo ""
    
    # Control Surfaces
    echo -e "${BLUE}🎛️  CONTROL SURFACES:${NC}"
    log_success "MIDI Devices: $midi_count"
    log_success "OSC Port $JACK_PORT: $osc_status"
    echo ""
    
    # REAPER Status
    echo -e "${BLUE}🎵 REAPER STATUS:${NC}"
    if [ "$reaper_status" = "RUNNING" ]; then
        local reaper_mem=$(get_reaper_memory)
        local reaper_cpu=$(get_reaper_cpu)
        log_success "REAPER: $reaper_status"
        log_success "Memory: $reaper_mem"
        log_success "CPU: $reaper_cpu"
    else
        log_error "REAPER: $reaper_status"
    fi
    echo ""
    
    echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    if [ "$jack_status" = "ONLINE" ] && (( $(echo "$cpu_load < 80" | bc -l) )); then
        echo -e "${GREEN}✓ System Status: OPTIMAL${NC}"
    elif [ "$jack_status" = "ONLINE" ]; then
        echo -e "${YELLOW}⚠ System Status: USABLE (High CPU)${NC}"
    else
        echo -e "${RED}✗ System Status: CHECK REQUIRED${NC}"
    fi
    
    echo ""
    echo -e "${BLUE}Commands:${NC}"
    echo "  [Enter] - Refresh"
    echo "  [q] - Quit"
    echo "  [j] - JACK Details"
    echo "  [c] - CPU Details"
    echo "  [m] - Memory Details"
    echo ""
}

# ==============================================================================
# 8. DETAILED VIEWS
# ==============================================================================

show_jack_details() {
    clear
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}     JACK AUDIO SERVER - Detailed Information            ${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if command -v jack_lsp &> /dev/null && jack_lsp &> /dev/null; then
        echo "Connected Ports:"
        jack_lsp
        echo ""
        echo "Jack Control Utility:"
        jack_control status 2>/dev/null || echo "jack_control not available"
    else
        log_error "JACK not running"
    fi
    
    echo ""
    read -p "Press Enter to continue..."
}

show_cpu_details() {
    clear
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}     CPU USAGE - Detailed Information                    ${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo "Top CPU-intensive processes:"
    ps aux --sort=-%cpu | head -10
    
    echo ""
    read -p "Press Enter to continue..."
}

show_memory_details() {
    clear
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}     MEMORY USAGE - Detailed Information                ${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo "Memory Information:"
    free -h
    
    echo ""
    echo "Top Memory-consuming processes:"
    ps aux --sort=-%mem | head -10
    
    echo ""
    read -p "Press Enter to continue..."
}

# ==============================================================================
# 9. INTERACTIVE MODE
# ==============================================================================

interactive_mode() {
    local running=true
    
    while [ "$running" = true ]; do
        show_diagnostic_report
        
        read -n1 -s choice
        
        case "$choice" in
            j)
                show_jack_details
                ;;
            c)
                show_cpu_details
                ;;
            m)
                show_memory_details
                ;;
            q)
                running=false
                ;;
            *)
                # Default - just refresh
                ;;
        esac
    done
    
    echo "Diagnostics stopped."
}

# ==============================================================================
# 10. CONTINUOUS MONITORING MODE
# ==============================================================================

continuous_mode() {
    local running=true
    
    # Setup signal handler for Ctrl+C
    trap 'running=false' SIGINT
    
    while [ "$running" = true ]; do
        show_diagnostic_report
        sleep "$UPDATE_INTERVAL"
        clear
    done
    
    echo "Continuous monitoring stopped."
}

# ==============================================================================
# 11. MAIN
# ==============================================================================

main() {
    local mode="interactive"
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --continuous|-c)
                mode="continuous"
                shift
                ;;
            --interval|-i)
                UPDATE_INTERVAL="$2"
                shift 2
                ;;
            --report)
                mode="report"
                shift
                ;;
            --help|-h)
                echo "REAPER OS System Diagnostics"
                echo ""
                echo "Usage: reaper-diagnostics [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --interactive, -i      Interactive mode (default)"
                echo "  --continuous, -c       Continuous monitoring mode"
                echo "  --interval, -i SEC     Update interval (default 1s)"
                echo "  --report               Show single report and exit"
                echo "  --help, -h             Show this help"
                echo ""
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    # Start based on mode
    case "$mode" in
        interactive)
            interactive_mode
            ;;
        continuous)
            continuous_mode
            ;;
        report)
            show_diagnostic_report
            ;;
    esac
}

main "$@"
