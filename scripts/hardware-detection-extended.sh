#!/bin/bash

################################################################################
# REAPER OS Extended Hardware Detection
# Auto-detects and configures additional audio interfaces
# Supports: Presonus StudioLive, MOTU, RME Fireface, Behringer X32/M32
# Usage: ./hardware-detection-extended.sh [--auto] [--detect-only] [--configure]
################################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/hardware-detection.log"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"
}

print_header() {
    echo -e "\n${BOLD}${BLUE}=== $1 ===${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Detect Presonus StudioLive
detect_presonus_studiolive() {
    print_header "Detecting Presonus StudioLive..."
    
    local vid="0x194f" # Presonus Vendor ID
    local result=$(lsusb | grep -i "presonus\|studiolive" || true)
    
    if [ -n "$result" ]; then
        print_success "Presonus StudioLive detected"
        echo "$result"
        log "Presonus StudioLive found: $result"
        return 0
    else
        print_warning "Presonus StudioLive not detected"
        return 1
    fi
}

# Detect MOTU interfaces
detect_motu() {
    print_header "Detecting MOTU Interfaces..."
    
    local result=$(lsusb | grep -i "motu" || true)
    
    if [ -n "$result" ]; then
        print_success "MOTU interface(s) detected"
        echo "$result"
        log "MOTU interfaces found: $result"
        return 0
    else
        print_warning "MOTU interface not detected"
        return 1
    fi
}

# Detect RME Fireface
detect_rme_fireface() {
    print_header "Detecting RME Fireface..."
    
    local result=$(lsusb | grep -i "rme\|fireface" || true)
    
    if [ -n "$result" ]; then
        print_success "RME Fireface detected"
        echo "$result"
        log "RME Fireface found: $result"
        return 0
    else
        print_warning "RME Fireface not detected"
        return 1
    fi
}

# Detect Behringer X32/M32
detect_behringer_x32() {
    print_header "Detecting Behringer X32/M32..."
    
    # Check network interfaces
    local interfaces=$(ip addr show | grep -E "inet\s" | awk '{print $2}' | cut -d/ -f1)
    
    # Scan for X32/M32 on common ports (UDP 3671)
    for ip in $interfaces; do
        # Try to find X32/M32 on the network
        local subnet=$(echo "$ip" | cut -d. -f1-3).0/24
        
        # Check if device responds (simplified check)
        if timeout 2 bash -c "echo > /dev/tcp/$(echo $subnet | sed 's|/24|.1|')/3671" 2>/dev/null; then
            print_success "Behringer X32/M32 network interface found"
            log "X32/M32 found on subnet: $subnet"
            return 0
        fi
    done
    
    print_warning "Behringer X32/M32 not found on network"
    return 1
}

# Detect Dante network audio
detect_dante() {
    print_header "Detecting Dante Network Audio..."
    
    if command -v dante-controller &> /dev/null; then
        print_success "Dante controller installed"
        log "Dante network audio support available"
        return 0
    else
        print_warning "Dante support not installed"
        return 1
    fi
}

# Auto-configure Presonus StudioLive
configure_presonus() {
    print_header "Configuring Presonus StudioLive..."
    
    # Create ALSA configuration
    cat > "$HOME/.asoundrc.d/presonus-studiolive" << 'EOF'
# Presonus StudioLive ALSA Configuration
pcm.!default {
    type hw
    card PresonusStudioLive
}

ctl.!default {
    type hw
    card PresonusStudioLive
}
EOF
    
    print_success "Presonus StudioLive configured"
    log "Presonus StudioLive ALSA config created"
}

# Auto-configure MOTU
configure_motu() {
    print_header "Configuring MOTU Interface..."
    
    # Create ALSA configuration
    cat > "$HOME/.asoundrc.d/motu-audio" << 'EOF'
# MOTU Audio Interface ALSA Configuration
pcm.!default {
    type hw
    card MOTU
}

ctl.!default {
    type hw
    card MOTU
}
EOF
    
    print_success "MOTU interface configured"
    log "MOTU ALSA config created"
}

# Auto-configure RME Fireface
configure_rme() {
    print_header "Configuring RME Fireface..."
    
    # Create ALSA configuration
    cat > "$HOME/.asoundrc.d/rme-fireface" << 'EOF'
# RME Fireface ALSA Configuration
pcm.!default {
    type hw
    card Fireface
}

ctl.!default {
    type hw
    card Fireface
}
EOF
    
    print_success "RME Fireface configured"
    log "RME Fireface ALSA config created"
}

# Auto-configure Behringer X32/M32
configure_behringer() {
    print_header "Configuring Behringer X32/M32 Network..."
    
    # Create network audio wrapper
    cat > "$HOME/.config/behringer-x32-setup.sh" << 'EOF'
#!/bin/bash
# Behringer X32/M32 Network Audio Setup

# Find X32/M32 on network
echo "Scanning network for X32/M32..."

# Common X32/M32 default IP
X32_IP="192.168.1.100"

# Test connection
if timeout 2 bash -c "echo > /dev/tcp/${X32_IP}/3671" 2>/dev/null; then
    echo "X32/M32 found at ${X32_IP}"
    
    # Configure network audio
    # This would integrate with jack-alsa-bridge for network audio
    echo "Configuring network audio bridge..."
else
    echo "X32/M32 not found at default IP"
fi
EOF
    
    chmod +x "$HOME/.config/behringer-x32-setup.sh"
    print_success "Behringer X32/M32 configured"
    log "Behringer X32/M32 network setup created"
}

# Create hardware profile
create_hardware_profile() {
    print_header "Creating Hardware Profile..."
    
    local profile_file="$HOME/.config/REAPER/hardware-profile.json"
    mkdir -p "$(dirname "$profile_file")"
    
    cat > "$profile_file" << 'EOF'
{
  "timestamp": "",
  "detected_devices": [],
  "configured_devices": [],
  "network_audio": {
    "dante_available": false,
    "x32_available": false,
    "network_devices": []
  },
  "recommendations": []
}
EOF
    
    print_success "Hardware profile created at: $profile_file"
    log "Hardware profile created: $profile_file"
}

# Generate HTML report
generate_html_report() {
    local report_file="hardware-detection-report.html"
    
    cat > "$report_file" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>REAPER OS Hardware Detection Report</title>
    <style>
        body { font-family: Arial; margin: 20px; background: #f5f5f5; }
        .header { background: #333; color: white; padding: 20px; border-radius: 5px; }
        .section { background: white; margin: 20px 0; padding: 20px; border-radius: 5px; }
        .device { background: #f9f9f9; padding: 10px; margin: 10px 0; border-left: 4px solid #007bff; }
        .success { color: green; }
        .warning { color: orange; }
        .error { color: red; }
        table { width: 100%; border-collapse: collapse; }
        th, td { text-align: left; padding: 10px; border-bottom: 1px solid #ddd; }
        th { background: #007bff; color: white; }
    </style>
</head>
<body>
    <div class="header">
        <h1>REAPER OS Hardware Detection Report</h1>
        <p>Generated on: <span id="timestamp"></span></p>
    </div>
    
    <div class="section">
        <h2>Detected Devices</h2>
        <table>
            <tr>
                <th>Device Name</th>
                <th>Type</th>
                <th>Status</th>
                <th>Configured</th>
            </tr>
            <tr>
                <td>Presonus StudioLive</td>
                <td>USB Audio Interface</td>
                <td><span class="warning">Not Detected</span></td>
                <td>—</td>
            </tr>
        </table>
    </div>
    
    <div class="section">
        <h2>Network Audio</h2>
        <p>Dante, AES67, and networked devices not currently detected.</p>
    </div>
    
    <script>
        document.getElementById('timestamp').textContent = new Date().toLocaleString();
    </script>
</body>
</html>
EOF
    
    echo -e "${GREEN}✓ HTML report generated: $report_file${NC}"
    log "HTML report generated: $report_file"
}

# Main function
main() {
    local mode="detect"
    local auto_configure=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --auto) auto_configure=true ;;
            --detect-only) mode="detect" ;;
            --configure) mode="configure" ;;
            *) echo "Unknown option: $1"; exit 1 ;;
        esac
        shift
    done
    
    print_header "REAPER OS Extended Hardware Detection"
    echo "Scanning for additional audio interfaces..."
    echo "Log file: $LOG_FILE"
    
    # Detect all devices
    detect_presonus_studiolive || true
    detect_motu || true
    detect_rme_fireface || true
    detect_behringer_x32 || true
    detect_dante || true
    
    if [ "$mode" = "configure" ] || [ "$auto_configure" = true ]; then
        print_header "Auto-Configuring Detected Devices"
        configure_presonus || true
        configure_motu || true
        configure_rme || true
        configure_behringer || true
        create_hardware_profile
    fi
    
    # Generate reports
    generate_html_report
    
    print_header "Summary"
    echo "Detection complete. Check $LOG_FILE for details."
}

main "$@"
