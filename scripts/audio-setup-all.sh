#!/bin/bash

################################################################################
# Quick Audio Setup Script for REAPER OS
# Complete audio interface and VST setup in one command
################################################################################

set -e

PROJECT_ROOT="${1:-.}"
SCRIPTS_DIR="$PROJECT_ROOT/scripts"
WINE_CONFIG_DIR="$PROJECT_ROOT/wine-config"

log_info() { echo "[AUDIO-SETUP] $1"; }
log_success() { echo "[✓] $1"; }

main() {
    log_info "╔════════════════════════════════════════════════════════╗"
    log_info "║  REAPER OS Audio Setup - Complete Integration          ║"
    log_info "╚════════════════════════════════════════════════════════╝"
    echo ""
    
    # Step 1: Setup Wine for VST
    log_info "Step 1: Setting up Wine for VST Windows..."
    if [ -f "$WINE_CONFIG_DIR/wine-vst-setup.sh" ]; then
        bash "$WINE_CONFIG_DIR/wine-vst-setup.sh"
        log_success "Wine VST setup completed"
    fi
    echo ""
    
    # Step 2: Detect and setup audio interfaces
    log_info "Step 2: Detecting audio interfaces..."
    if [ -f "$SCRIPTS_DIR/audio-interface-setup.sh" ]; then
        bash "$SCRIPTS_DIR/audio-interface-setup.sh"
        log_success "Audio interface setup completed"
    fi
    echo ""
    
    # Step 3: Map devices
    log_info "Step 3: Mapping audio devices..."
    if [ -f "$SCRIPTS_DIR/audio-device-mapper.sh" ]; then
        bash "$SCRIPTS_DIR/audio-device-mapper.sh"
        log_success "Device mapping completed"
    fi
    echo ""
    
    # Step 4: Create control panel wrappers
    log_info "Step 4: Creating Windows control panel wrappers..."
    if [ -f "$SCRIPTS_DIR/audio-control-panel-wrappers.sh" ]; then
        bash "$SCRIPTS_DIR/audio-control-panel-wrappers.sh"
        log_success "Control panel wrappers created"
    fi
    echo ""
    
    # Step 5: Setup AudioGridder (optional)
    log_info "Step 5: Setting up AudioGridder..."
    if [ -f "$WINE_CONFIG_DIR/audiogridder-setup.sh" ]; then
        bash "$WINE_CONFIG_DIR/audiogridder-setup.sh"
        log_success "AudioGridder setup completed"
    fi
    echo ""
    
    # Step 6a: Setup ASNUX (low-latency engine)
    log_info "Step 6a: Setting up ASNUX low-latency audio engine..."
    if [ -f "$SCRIPTS_DIR/setup-asnux.sh" ]; then
        bash "$SCRIPTS_DIR/setup-asnux.sh"
        log_success "ASNUX configured"
    fi
    echo ""
    
    # Step 6b: Setup JACK
    log_info "Step 6b: Configuring JACK audio server..."
    if [ -f "$SCRIPTS_DIR/setup-jack.sh" ]; then
        bash "$SCRIPTS_DIR/setup-jack.sh"
        log_success "JACK configured"
    fi
    echo ""
    
    # Step 7: Setup REAPER
    log_info "Step 7: Initializing REAPER..."
    if [ -f "$PROJECT_ROOT/reaper-config/reaper-config-init.sh" ]; then
        bash "$PROJECT_ROOT/reaper-config/reaper-config-init.sh"
        log_success "REAPER initialized"
    fi
    echo ""
    
    # Final status
    log_info "╔════════════════════════════════════════════════════════╗"
    log_info "║  ✅ REAPER OS Audio Setup Complete!                    ║"
    log_info "╚════════════════════════════════════════════════════════╝"
    echo ""
    
    log_info "Available Commands:"
    log_info "  ├─ reaper-start              Start REAPER with audio"
    log_info "  ├─ jackd -d alsa &           Start JACK audio server"
    log_info "  ├─ audio-interface-manager   Manage audio settings"
    log_info "  ├─ rme-control-panel         RME Control Panel"
    log_info "  ├─ uad-console               Universal Audio Console"
    log_info "  ├─ focusrite-control         Focusrite Control"
    log_info "  └─ aplay -l                  List audio devices"
    echo ""
    
    log_info "Next Steps:"
    log_info "1. Run: jackd -d alsa &"
    log_info "2. Run: reaper-start"
    log_info "3. Configure in REAPER: Preferences → Audio → Device = JACK"
    log_info "4. Load VST plugins (Wine or AudioGridder)"
    echo ""
}

main "$@"
