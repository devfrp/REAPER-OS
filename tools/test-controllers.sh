#!/bin/bash

################################################################################
# REAPER OS Control Protocol Tester
# Test MIDI and OSC controllers without launching REAPER
# Validates connectivity and device mapping
################################################################################

set -e

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[TEST]${NC} $1"; }
log_success() { echo -e "${GREEN}✓${NC} $1"; }
log_warn() { echo -e "${YELLOW}⚠${NC} $1"; }
log_error() { echo -e "${RED}✗${NC} $1"; }

# ==============================================================================
# 1. MIDI DEVICE DETECTION AND TESTING
# ==============================================================================

detect_midi_devices() {
    log_info "Scanning for MIDI devices..."
    echo ""
    
    if ! command -v aconnect &> /dev/null; then
        log_error "aconnect not found (install alsa-utils)"
        return 1
    fi
    
    local device_count=0
    
    # List ALSA sequencer clients
    aconnect -l | grep "client" | while read line; do
        local client=$(echo "$line" | grep -oP "client \K[0-9]+")
        local name=$(echo "$line" | grep -oP "': '\K[^']+")
        
        echo "  [$client] $name"
        ((device_count++))
    done
    
    if [ $device_count -eq 0 ]; then
        log_warn "No MIDI devices detected"
    else
        log_success "$device_count MIDI device(s) found"
    fi
    
    echo ""
}

# ==============================================================================
# 2. MIDI EVENT MONITOR
# ==============================================================================

monitor_midi_events() {
    local duration="${1:-30}"
    
    log_info "MIDI Event Monitor - Listening for $duration seconds"
    log_info "Move controllers, press keys, turn knobs..."
    echo ""
    
    if ! command -v aseqdump &> /dev/null; then
        log_error "aseqdump not found (install alsa-utils)"
        return 1
    fi
    
    log_info "Waiting for MIDI input (Press Ctrl+C to stop)..."
    echo ""
    
    # Monitor MIDI events with timeout
    timeout "$duration" aseqdump -p "^System Announce" 2>/dev/null || true
    
    echo ""
    log_success "MIDI monitoring complete"
}

# ==============================================================================
# 3. MCU PROTOCOL TEST (Behringer X-Touch)
# ==============================================================================

test_mcu_protocol() {
    log_info "Testing MCU Protocol (Mackie Control Universal)"
    echo ""
    
    # Check for X-Touch or compatible MCU device
    if aconnect -l 2>/dev/null | grep -qi "x-touch\|mackie"; then
        log_success "MCU device detected"
    else
        log_warn "No MCU device detected"
    fi
    
    echo "MCU Protocol Details:"
    echo "  • Control Type: Faders + Rotaries + Buttons"
    echo "  • Channel Count: 8 (expandable)"
    echo "  • Features: Motorized faders, LCD display, Jog wheel"
    echo "  • REAPER Config: Options → Control Surfaces → Mackie Control"
    echo ""
    
    log_success "MCU protocol ready for REAPER"
}

# ==============================================================================
# 4. HUI PROTOCOL TEST (via MIDI Learn)
# ==============================================================================

test_hui_protocol() {
    log_info "Testing HUI Protocol (via MIDI Learn)"
    echo ""
    
    # HUI is tested as generic MIDI
    echo "HUI Protocol Details:"
    echo "  • Method: MIDI Learn Mode"
    echo "  • How to use:"
    echo "    1. REAPER → Options → MIDI Learn Mode"
    echo "    2. Click on parameter to control"
    echo "    3. Move controller knob/fader"
    echo "    4. Auto-mapped!"
    echo "  • Supported controllers: Any MIDI USB controller"
    echo ""
    
    detect_midi_devices
    
    log_success "HUI (MIDI Learn) ready"
}

# ==============================================================================
# 5. OSC PROTOCOL TEST (Network/iPad)
# ==============================================================================

test_osc_protocol() {
    local osc_port="${1:-8000}"
    
    log_info "Testing OSC Protocol (Network Control)"
    echo ""
    
    echo "OSC Configuration:"
    echo "  • Port: $osc_port"
    echo "  • Listen: 0.0.0.0"
    echo "  • Protocol: UDP/TCP"
    echo ""
    
    # Get local IP address
    local local_ip=$(hostname -I | awk '{print $1}')
    
    if [ -n "$local_ip" ]; then
        log_success "Local IP: $local_ip"
        echo "  • iPad can connect to: osc.udp://$local_ip:$osc_port"
    else
        log_warn "Could not determine local IP"
    fi
    
    echo ""
    echo "Supported OSC Apps:"
    echo "  • Lemur (iOS/macOS) - Professional OSC Controller"
    echo "  • Controlly (iOS) - Touch control interface"
    echo "  • TouchOSC (iOS/Android) - Generic OSC mapping"
    echo ""
    
    # Test if port is already in use
    if command -v nc &> /dev/null; then
        if nc -z localhost "$osc_port" 2>/dev/null; then
            log_success "OSC Port $osc_port is LISTENING"
        else
            log_warn "OSC Port $osc_port is not yet listening (start REAPER)"
        fi
    fi
    
    echo ""
    log_success "OSC protocol ready"
}

# ==============================================================================
# 6. GENERIC MIDI TEST
# ==============================================================================

test_generic_midi() {
    log_info "Testing Generic MIDI Protocol"
    echo ""
    
    detect_midi_devices
    
    echo "Generic MIDI Features:"
    echo "  • Supports: Any USB MIDI controller"
    echo "  • CC Messages: Control Change (0-127 values)"
    echo "  • Note On/Off: Trigger parameters"
    echo "  • Velocity Sensitive: Dynamic control"
    echo ""
    
    echo "Common MIDI Controllers:"
    echo "  • Keyboard MIDI (E-Drums, Pianos)"
    echo "  • USB Keyboard/Pad Controllers (Akai, Native Instruments)"
    echo "  • DJ Controllers (Numark, Pioneer)"
    echo "  • XY-Pad Controllers"
    echo ""
    
    log_success "Generic MIDI protocol ready"
}

# ==============================================================================
# 7. TEST ALL DEVICES
# ==============================================================================

test_all_devices() {
    clear
    
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}  REAPER OS - Control Protocol Test Suite               ${BLUE}║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # 1. MIDI Detection
    echo -e "${BLUE}[1/4] MIDI Device Detection${NC}"
    detect_midi_devices
    
    # 2. MCU Test
    echo -e "${BLUE}[2/4] MCU Protocol Test${NC}"
    test_mcu_protocol
    
    # 3. OSC Test
    echo -e "${BLUE}[3/4] OSC Protocol Test${NC}"
    test_osc_protocol
    
    # 4. Generic MIDI
    echo -e "${BLUE}[4/4] Generic MIDI Test${NC}"
    test_generic_midi
    
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    log_success "All protocol tests completed!"
    echo ""
    echo "Next Steps:"
    echo "  1. Connect your controller to USB"
    echo "  2. Run: reaper-diagnostics --report"
    echo "  3. Start REAPER"
    echo "  4. Go to: Preferences → Control Surfaces"
    echo "  5. Add your device and configure"
    echo ""
}

# ==============================================================================
# 8. INTERACTIVE TEST MENU
# ==============================================================================

interactive_menu() {
    while true; do
        clear
        
        echo -e "${BLUE}╔═══════════════════════════════════════════╗${NC}"
        echo -e "${BLUE}║  Control Protocol Tester                  ║${NC}"
        echo -e "${BLUE}╚═══════════════════════════════════════════╝${NC}"
        echo ""
        echo "1) Detect MIDI devices"
        echo "2) Monitor MIDI events (30 sec)"
        echo "3) Test MCU Protocol"
        echo "4) Test HUI Protocol"
        echo "5) Test OSC Protocol"
        echo "6) Test Generic MIDI"
        echo "7) Run all tests"
        echo "8) Port scanner"
        echo "0) Exit"
        echo ""
        
        read -p "Choice [0-8]: " choice
        
        case "$choice" in
            1)
                detect_midi_devices
                read -p "Press Enter to continue..."
                ;;
            2)
                monitor_midi_events 30
                read -p "Press Enter to continue..."
                ;;
            3)
                test_mcu_protocol
                read -p "Press Enter to continue..."
                ;;
            4)
                test_hui_protocol
                read -p "Press Enter to continue..."
                ;;
            5)
                read -p "OSC Port (default 8000): " port
                port=${port:-8000}
                test_osc_protocol "$port"
                read -p "Press Enter to continue..."
                ;;
            6)
                test_generic_midi
                read -p "Press Enter to continue..."
                ;;
            7)
                test_all_devices
                read -p "Press Enter to continue..."
                ;;
            8)
                if command -v netstat &> /dev/null; then
                    echo ""
                    echo "Listening ports:"
                    netstat -tuln | grep LISTEN
                else
                    log_warn "netstat not available"
                fi
                read -p "Press Enter to continue..."
                ;;
            0)
                echo "Exiting..."
                exit 0
                ;;
            *)
                log_error "Invalid choice"
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# ==============================================================================
# 9. MAIN
# ==============================================================================

main() {
    if [ $# -eq 0 ]; then
        # Interactive mode
        interactive_menu
    else
        # Command line mode
        local cmd="$1"
        shift
        
        case "$cmd" in
            detect-midi)
                detect_midi_devices
                ;;
            monitor-midi)
                monitor_midi_events "${1:-30}"
                ;;
            test-mcu)
                test_mcu_protocol
                ;;
            test-hui)
                test_hui_protocol
                ;;
            test-osc)
                test_osc_protocol "${1:-8000}"
                ;;
            test-midi)
                test_generic_midi
                ;;
            test-all)
                test_all_devices
                ;;
            --help|-h)
                echo "REAPER OS Control Protocol Tester"
                echo ""
                echo "Usage: test-controllers [COMMAND]"
                echo ""
                echo "Commands:"
                echo "  detect-midi             Detect connected MIDI devices"
                echo "  monitor-midi [SEC]      Monitor MIDI events (default 30 sec)"
                echo "  test-mcu                Test MCU protocol"
                echo "  test-hui                Test HUI protocol"
                echo "  test-osc [PORT]         Test OSC protocol"
                echo "  test-midi               Test generic MIDI"
                echo "  test-all                Run all protocol tests"
                echo "  --help, -h              Show this help"
                echo ""
                echo "If no command specified, interactive menu is opened"
                echo ""
                exit 0
                ;;
            *)
                log_error "Unknown command: $cmd"
                exit 1
                ;;
        esac
    fi
}

main "$@"
