#!/bin/bash

################################################################################
# REAPER OS System Information Tool
# Displays comprehensive system, audio, and REAPER information
# Usage: ./system-info.sh [--json] [--export FILE]
################################################################################

set -euo pipefail

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Format functions
print_header() {
    echo -e "\n${BOLD}${BLUE}=== $1 ===${NC}\n"
}

print_item() {
    printf "  %-30s: ${GREEN}%s${NC}\n" "$1" "$2"
}

print_warning() {
    printf "  ${YELLOW}⚠ %s${NC}\n" "$1"
}

print_error() {
    printf "  ${RED}✗ %s${NC}\n" "$1"
}

# Get system information
get_system_info() {
    print_header "SYSTEM INFORMATION"
    
    local hostname=$(hostname)
    local kernel=$(uname -r)
    local os=$(lsb_release -ds 2>/dev/null || echo "Unknown")
    local uptime=$(uptime -p)
    local arch=$(uname -m)
    
    print_item "Hostname" "$hostname"
    print_item "OS" "$os"
    print_item "Kernel" "$kernel"
    print_item "Architecture" "$arch"
    print_item "Uptime" "$uptime"
    print_item "Current User" "$(whoami)"
}

# Get CPU information
get_cpu_info() {
    print_header "CPU INFORMATION"
    
    local model=$(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)
    local cores=$(nproc)
    local freq=$(grep "cpu MHz" /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)
    local load=$(cat /proc/loadavg | awk '{print $1, $2, $3}')
    
    print_item "Model" "$model"
    print_item "Cores" "$cores"
    print_item "Frequency" "${freq} MHz"
    print_item "Load Average" "$load"
}

# Get memory information
get_memory_info() {
    print_header "MEMORY INFORMATION"
    
    local mem_total=$(free -h | grep "^Mem:" | awk '{print $2}')
    local mem_used=$(free -h | grep "^Mem:" | awk '{print $3}')
    local mem_free=$(free -h | grep "^Mem:" | awk '{print $4}')
    local swap_total=$(free -h | grep "^Swap:" | awk '{print $2}')
    local swap_used=$(free -h | grep "^Swap:" | awk '{print $3}')
    
    print_item "Total RAM" "$mem_total"
    print_item "Used RAM" "$mem_used"
    print_item "Free RAM" "$mem_free"
    print_item "Total Swap" "$swap_total"
    print_item "Used Swap" "$swap_used"
}

# Get disk information
get_disk_info() {
    print_header "DISK INFORMATION"
    
    df -h | tail -n +2 | while read line; do
        local device=$(echo "$line" | awk '{print $1}')
        local size=$(echo "$line" | awk '{print $2}')
        local used=$(echo "$line" | awk '{print $3}')
        local avail=$(echo "$line" | awk '{print $4}')
        local percent=$(echo "$line" | awk '{print $5}')
        
        printf "  %-30s: ${GREEN}%s${NC} (Used: %s, Free: %s) %s\n" \
            "$device" "$size" "$used" "$avail" "$percent"
    done
}

# Get audio stack information
get_audio_info() {
    print_header "AUDIO STACK INFORMATION"
    
    # JACK
    if systemctl is-active --quiet jackd; then
        print_item "JACK Status" "${GREEN}Running${NC}"
        local jack_info=$(jack_lsp -p 2>/dev/null | head -1 || echo "Unknown")
        print_item "JACK Version" "$jack_info"
    else
        print_item "JACK Status" "${YELLOW}Not Running${NC}"
    fi
    
    # ALSA
    if command -v aplay &> /dev/null; then
        local alsa_version=$(aplay --version 2>/dev/null | head -1 || echo "Unknown")
        print_item "ALSA" "$alsa_version"
    fi
    
    # PulseAudio/PipeWire
    if systemctl is-active --quiet pulseaudio; then
        print_item "PulseAudio" "Running"
    elif systemctl is-active --quiet pipewire; then
        print_item "PipeWire" "Running"
    fi
    
    # Audio devices
    print_item "Audio Devices" "$(aplay -l 2>/dev/null | grep "card" | wc -l) detected"
}

# Get REAPER information
get_reaper_info() {
    print_header "REAPER INFORMATION"
    
    if [ -d "$HOME/.config/REAPER" ]; then
        print_item "REAPER Config" "${GREEN}Found${NC}"
        
        local reaper_version=$(find "$HOME/.config/REAPER" -name "reaper.ini" 2>/dev/null | head -1)
        if [ -f "$reaper_version" ]; then
            print_item "Config Location" "$reaper_version"
        fi
        
        local vst_count=$(find "$HOME/.config/REAPER" -name "*.ini" | wc -l)
        print_item "Config Files" "$vst_count"
    else
        print_warning "REAPER configuration not found"
    fi
    
    # Check if REAPER is installed
    if command -v reaper &> /dev/null; then
        print_item "REAPER Binary" "${GREEN}Available${NC}"
    else
        print_warning "REAPER binary not found in PATH"
    fi
}

# Get installed tools
get_tools_info() {
    print_header "REAPER OS TOOLS"
    
    local tools_dir="$(dirname "$0")"
    local tools=()
    
    [[ -f "$tools_dir/reaper-diagnostics.sh" ]] && tools+=("Diagnostics")
    [[ -f "$tools_dir/audio-config-manager.sh" ]] && tools+=("Audio Config Manager")
    [[ -f "$tools_dir/package-manager.sh" ]] && tools+=("Package Manager")
    [[ -f "$tools_dir/system-dashboard.py" ]] && tools+=("System Dashboard")
    [[ -f "$tools_dir/logging-system.sh" ]] && tools+=("Logging System")
    [[ -f "$tools_dir/benchmarking-tool.sh" ]] && tools+=("Benchmarking")
    [[ -f "$tools_dir/backup-restore.sh" ]] && tools+=("Backup & Restore")
    [[ -f "$tools_dir/update-manager.sh" ]] && tools+=("Update Manager")
    [[ -f "$tools_dir/vst-manager.sh" ]] && tools+=("VST Manager")
    [[ -f "$tools_dir/performance-tuner.sh" ]] && tools+=("Performance Tuner")
    
    if [ ${#tools[@]} -eq 0 ]; then
        print_warning "No tools found"
    else
        for tool in "${tools[@]}"; do
            print_item "✓" "$tool"
        done
    fi
}

# Get network information
get_network_info() {
    print_header "NETWORK INFORMATION"
    
    local hostname=$(hostname)
    local ip=$(hostname -I | awk '{print $1}')
    local gateway=$(ip route | grep default | awk '{print $3}')
    local dns=$(cat /etc/resolv.conf | grep nameserver | head -1 | awk '{print $2}')
    
    print_item "Hostname" "$hostname"
    print_item "Local IP" "$ip"
    print_item "Gateway" "$gateway"
    print_item "DNS" "$dns"
}

# Export as JSON
export_json() {
    local output_file="$1"
    
    cat > "$output_file" << 'EOF'
{
  "system": {
    "hostname": "",
    "os": "",
    "kernel": "",
    "architecture": ""
  },
  "cpu": {
    "model": "",
    "cores": 0,
    "frequency_mhz": 0
  },
  "memory": {
    "total_gb": 0,
    "used_gb": 0,
    "free_gb": 0
  },
  "audio": {
    "jack_running": false,
    "audio_devices": 0
  },
  "reaper": {
    "installed": false,
    "configured": false
  },
  "tools": []
}
EOF
    
    echo -e "${GREEN}✓ Exported to: $output_file${NC}"
}

# Main execution
main() {
    local mode="text"
    local export_file=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --json) mode="json" ;;
            --export) export_file="$2"; shift ;;
            *) echo "Unknown option: $1"; exit 1 ;;
        esac
        shift
    done
    
    if [ "$mode" = "json" ] || [ -n "$export_file" ]; then
        export_json "${export_file:-.system-info.json}"
        return
    fi
    
    # Display system information
    get_system_info
    get_cpu_info
    get_memory_info
    get_disk_info
    get_network_info
    get_audio_info
    get_reaper_info
    get_tools_info
    
    echo -e "\n${BOLD}Report generated: $(date)${NC}\n"
}

main "$@"
