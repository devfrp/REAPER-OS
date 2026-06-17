#!/bin/bash

################################################################################
# REAPER OS Installation Quick Reference
# Fast installation validation and setup commands
#
# This script provides a quick way to:
#   - Validate system compatibility before installation
#   - Run post-installation verification
#   - Set up audio configuration
#   - Test hardware controllers
#   - Create performance profiles
#
# Usage:
#   bash install-quick-ref.sh          # Interactive menu
#   bash install-quick-ref.sh validate  # Pre-install validation
#   bash install-quick-ref.sh verify    # Post-install verification
#   bash install-quick-ref.sh setup     # Run all setup steps
#
################################################################################

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
INSTALL_DIR="/opt/reaper-os"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Logging
log_info() { echo -e "${GREEN}✓${NC} $1"; }
log_error() { echo -e "${RED}✗${NC} $1"; }
log_header() { echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n  $1\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"; }

# Menu system
show_menu() {
    log_header "REAPER OS Installation Quick Reference"
    
    echo "1. Pre-Installation Validation"
    echo "   Check system compatibility before installing"
    echo ""
    echo "2. Post-Installation Verification"
    echo "   Verify everything installed correctly"
    echo ""
    echo "3. Audio Setup"
    echo "   Configure audio interfaces and JACK"
    echo ""
    echo "4. Hardware Controller Setup"
    echo "   Detect and configure MIDI controllers"
    echo ""
    echo "5. Performance Tuning"
    echo "   Optimize system for real-time audio"
    echo ""
    echo "6. Create Audio Profile"
    echo "   Save current audio configuration as profile"
    echo ""
    echo "7. Run Full Setup"
    echo "   Execute all setup steps in order"
    echo ""
    echo "0. Exit"
    echo ""
}

# Pre-installation validation
validate_system() {
    log_header "Pre-Installation Validation"
    
    local passed=0
    local failed=0
    
    # OS check
    if grep -q "Debian\|Ubuntu" /etc/os-release 2>/dev/null; then
        log_info "Operating System: Debian/Ubuntu ✓"
        passed=$((passed + 1))
    else
        log_error "Operating System: Unsupported (need Debian/Ubuntu)"
        failed=$((failed + 1))
    fi
    
    # Disk space check
    local avail=$(df / | awk 'NR==2 {print $4}')
    if [ "$avail" -gt $((20 * 1024 * 1024)) ]; then
        log_info "Disk Space: $((avail / 1024 / 1024))GB available ✓"
        passed=$((passed + 1))
    else
        log_error "Disk Space: Only $((avail / 1024 / 1024))GB available (need 20GB)"
        failed=$((failed + 1))
    fi
    
    # RAM check
    local ram=$(free -m | awk 'NR==2 {print $2}')
    if [ "$ram" -ge 8192 ]; then
        log_info "RAM: $((ram / 1024))GB ✓"
        passed=$((passed + 1))
    elif [ "$ram" -ge 4096 ]; then
        log_info "RAM: $((ram / 1024))GB (minimum supported, 8GB recommended)"
        passed=$((passed + 1))
    else
        log_error "RAM: Only $((ram / 1024))GB (minimum 4GB required)"
        failed=$((failed + 1))
    fi
    
    # Root permission check
    if [ "$EUID" -eq 0 ] 2>/dev/null || sudo -n true 2>/dev/null; then
        log_info "Root Permissions: Available ✓"
        passed=$((passed + 1))
    else
        log_error "Root Permissions: Not available"
        failed=$((failed + 1))
    fi
    
    # Network check
    if ping -c 1 8.8.8.8 &>/dev/null; then
        log_info "Internet Connection: Available (optional) ✓"
        passed=$((passed + 1))
    else
        log_info "Internet Connection: Not available (offline mode OK)"
        passed=$((passed + 1))
    fi
    
    # Required commands check
    local required=("bash" "apt-get" "python3")
    for cmd in "${required[@]}"; do
        if command -v "$cmd" &>/dev/null; then
            log_info "Command: $cmd ✓"
            passed=$((passed + 1))
        else
            log_error "Command: $cmd (missing)"
            failed=$((failed + 1))
        fi
    done
    
    echo ""
    log_info "Validation Results: $passed passed, $failed failed"
    
    if [ $failed -eq 0 ]; then
        echo ""
        echo "${GREEN}System ready for REAPER OS installation!${NC}"
        echo ""
        echo "Next steps:"
        echo "  1. Review GETTING-STARTED.md"
        echo "  2. Run: sudo bash installer/install-offline.sh"
        echo "  3. Follow the installation prompts"
        return 0
    else
        echo ""
        echo "${RED}System validation failed. Please resolve issues above.${NC}"
        return 1
    fi
}

# Post-installation verification
verify_installation() {
    log_header "Post-Installation Verification"
    
    local passed=0
    local failed=0
    
    # Installation directory check
    if [ -d "$INSTALL_DIR" ]; then
        log_info "Installation Directory: Found ✓"
        passed=$((passed + 1))
    else
        log_error "Installation Directory: Not found at $INSTALL_DIR"
        failed=$((failed + 1))
        return 1
    fi
    
    # Tools check
    if [ -d "$INSTALL_DIR/tools" ]; then
        local tool_count=$(find "$INSTALL_DIR/tools" -name "*.sh" 2>/dev/null | wc -l)
        log_info "Tools: $tool_count scripts found ✓"
        passed=$((passed + 1))
    else
        log_error "Tools: Not found"
        failed=$((failed + 1))
    fi
    
    # Docs check
    if [ -d "$INSTALL_DIR/docs" ]; then
        log_info "Documentation: Found ✓"
        passed=$((passed + 1))
    else
        log_error "Documentation: Not found"
        failed=$((failed + 1))
    fi
    
    # Python packages
    if python3 -c "import flask, numpy" 2>/dev/null; then
        log_info "Python Packages: Installed ✓"
        passed=$((passed + 1))
    else
        log_info "Python Packages: Some optional packages missing (not critical)"
        passed=$((passed + 1))
    fi
    
    # Audio tools
    if command -v ffmpeg &>/dev/null; then
        log_info "FFmpeg: Installed ✓"
        passed=$((passed + 1))
    else
        log_error "FFmpeg: Not installed"
        failed=$((failed + 1))
    fi
    
    # JACK tools
    if command -v jackd &>/dev/null; then
        log_info "JACK: Installed ✓"
        passed=$((passed + 1))
    else
        log_error "JACK: Not installed"
        failed=$((failed + 1))
    fi
    
    echo ""
    log_info "Verification Results: $passed passed, $failed failed"
    
    if [ $failed -eq 0 ]; then
        echo ""
        echo "${GREEN}Installation verified successfully!${NC}"
        return 0
    else
        echo ""
        echo "${YELLOW}Some components missing. Run setup to complete.${NC}"
        return 0
    fi
}

# Audio setup
setup_audio() {
    log_header "Audio Configuration"
    
    if [ ! -d "$INSTALL_DIR/tools" ]; then
        log_error "Tools directory not found. Please install REAPER OS first."
        return 1
    fi
    
    echo "Audio Setup Options:"
    echo ""
    echo "1. Auto-detect available audio interfaces"
    echo "2. Create custom audio profile"
    echo "3. Test current audio configuration"
    echo "4. Configure JACK settings"
    echo "0. Back to menu"
    echo ""
    read -p "Select option (0-4): " audio_choice
    
    case "$audio_choice" in
        1)
            log_header "Detecting Audio Interfaces"
            if [ -f "$INSTALL_DIR/tools/audio-config-manager.sh" ]; then
                bash "$INSTALL_DIR/tools/audio-config-manager.sh" list
            else
                log_error "audio-config-manager.sh not found"
            fi
            ;;
        2)
            read -p "Profile name: " profile_name
            if [ -f "$INSTALL_DIR/tools/audio-config-manager.sh" ]; then
                bash "$INSTALL_DIR/tools/audio-config-manager.sh" create "$profile_name"
            fi
            ;;
        3)
            log_info "Run: bash $INSTALL_DIR/tools/test-controllers.sh"
            ;;
        4)
            log_info "JACK configuration file: ~/.jack-settings/jackrc"
            ;;
        0)
            return 0
            ;;
    esac
}

# Hardware setup
setup_hardware() {
    log_header "Hardware Controller Setup"
    
    if [ ! -d "$INSTALL_DIR/tools" ]; then
        log_error "Tools directory not found. Please install REAPER OS first."
        return 1
    fi
    
    echo "Hardware Setup Options:"
    echo ""
    echo "1. Auto-detect controllers"
    echo "2. Test MCU protocol"
    echo "3. Configure controller mapping"
    echo "0. Back to menu"
    echo ""
    read -p "Select option (0-3): " hw_choice
    
    case "$hw_choice" in
        1)
            log_header "Detecting Controllers"
            if [ -f "$INSTALL_DIR/tools/hardware-controller-mapper.sh" ]; then
                bash "$INSTALL_DIR/tools/hardware-controller-mapper.sh" detect
            fi
            ;;
        2)
            if [ -f "$INSTALL_DIR/tools/test-controllers.sh" ]; then
                bash "$INSTALL_DIR/tools/test-controllers.sh" --mcu-test
            fi
            ;;
        3)
            if [ -f "$INSTALL_DIR/tools/hardware-controller-mapper.sh" ]; then
                bash "$INSTALL_DIR/tools/hardware-controller-mapper.sh" config
            fi
            ;;
        0)
            return 0
            ;;
    esac
}

# Performance tuning
setup_performance() {
    log_header "Performance Tuning"
    
    if [ ! -d "$INSTALL_DIR/tools" ]; then
        log_error "Tools directory not found. Please install REAPER OS first."
        return 1
    fi
    
    echo "Performance Options:"
    echo ""
    echo "1. Run system optimization"
    echo "2. Measure latency"
    echo "3. View system info"
    echo "4. Run benchmarks"
    echo "0. Back to menu"
    echo ""
    read -p "Select option (0-4): " perf_choice
    
    case "$perf_choice" in
        1)
            if [ -f "$INSTALL_DIR/tools/performance-tuner.sh" ]; then
                log_info "Run: sudo bash $INSTALL_DIR/tools/performance-tuner.sh optimize"
            fi
            ;;
        2)
            if [ -f "$INSTALL_DIR/tools/benchmarking-tool.sh" ]; then
                bash "$INSTALL_DIR/tools/benchmarking-tool.sh" latency
            fi
            ;;
        3)
            if [ -f "$INSTALL_DIR/tools/system-info.sh" ]; then
                bash "$INSTALL_DIR/tools/system-info.sh"
            fi
            ;;
        4)
            if [ -f "$INSTALL_DIR/tools/benchmarking-tool.sh" ]; then
                bash "$INSTALL_DIR/tools/benchmarking-tool.sh" report
            fi
            ;;
        0)
            return 0
            ;;
    esac
}

# Run all setup
run_full_setup() {
    log_header "Running Full Setup"
    
    echo "This will run all setup steps in sequence."
    read -p "Continue? (y/n): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        return 0
    fi
    
    validate_system && \
    verify_installation && \
    setup_audio && \
    setup_hardware && \
    setup_performance
    
    log_header "Setup Complete"
    log_info "REAPER OS is ready for use!"
}

# Main menu
main() {
    while true; do
        show_menu
        read -p "Select option (0-7): " choice
        
        case "$choice" in
            1) validate_system ;;
            2) verify_installation ;;
            3) setup_audio ;;
            4) setup_hardware ;;
            5) setup_performance ;;
            6) 
                read -p "Profile name: " profile_name
                if [ -f "$INSTALL_DIR/tools/audio-config-manager.sh" ]; then
                    bash "$INSTALL_DIR/tools/audio-config-manager.sh" create "$profile_name"
                fi
                ;;
            7) run_full_setup ;;
            0) 
                echo ""
                log_info "Exiting..."
                exit 0
                ;;
            *)
                log_error "Invalid option"
                ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
    done
}

# Command-line argument handling
case "${1:-}" in
    validate)
        validate_system
        exit $?
        ;;
    verify)
        verify_installation
        exit $?
        ;;
    setup)
        run_full_setup
        exit $?
        ;;
    *)
        main
        ;;
esac
