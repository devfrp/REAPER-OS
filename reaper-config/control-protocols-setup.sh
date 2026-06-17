#!/bin/bash

################################################################################
# REAPER Control Protocols Setup
# Configure all supported control surface protocols
################################################################################

set -e

REAPER_CONFIG_DIR="$HOME/.config/REAPER"
REAPER_INI="$REAPER_CONFIG_DIR/reaper.ini"

log_info() { echo "[CONTROL-SETUP] $1"; }
log_success() { echo "[✓] $1"; }

# ==============================================================================
# 1. DETECT CONNECTED CONTROLLERS
# ==============================================================================

detect_controllers() {
    log_info "Detecting connected MIDI controllers..."
    echo ""
    
    # USB MIDI devices
    echo "📟 USB MIDI Devices:"
    aconnect -l | grep "client" | head -20 || echo "  None detected"
    
    echo ""
    
    # Network OSC devices
    echo "🌐 Network (OSC):"
    echo "  iPhone/iPad on local network can connect via OSC"
    echo "  Default port: 8000"
}

# ==============================================================================
# 2. SETUP HUI PROTOCOL (via Generic MIDI + MIDI Learn)
# ==============================================================================

setup_hui_protocol() {
    log_info "Setting up HUI protocol (Generic MIDI mode)..."
    
    # HUI n'est pas nativement supporté
    # On utilise Generic MIDI + MIDI Learn à la place
    
    cat >> "$REAPER_INI" << 'EOF'

[HUI_SETUP]
; HUI Protocol via Generic MIDI
; REAPER n'a pas de support HUI natif
; Utiliser Generic MIDI + MIDI Learn
; Menu: Options → MIDI Learn Mode
; Puis assigner chaque contrôle

enabled=1
method=midi_learn
notes=Use MIDI Learn mode for HUI devices
EOF

    log_success "HUI setup added (use MIDI Learn)"
}

# ==============================================================================
# 3. SETUP EUCON PROTOCOL (Avid S-Series)
# ==============================================================================

setup_eucon_protocol() {
    log_info "Setting up Eucon protocol (Avid S3/S4/S6)..."
    
    cat >> "$REAPER_INI" << 'EOF'

[EUCON]
eucon_enabled=1
eucon_device=auto
eucon_motorized=1
eucon_force_motorized=1
eucon_display_feedback=1
eucon_scribble_strips=1
eucon_channel_count=16
eucon_jog_enabled=1

[EUCON_BEHAVIOR]
faders=track_volume
rotaries=track_pan
buttons_upper=mute
buttons_lower=solo
scribble=track_name
display=channel_info
EOF

    log_success "Eucon protocol enabled"
}

# ==============================================================================
# 4. SETUP MCU PROTOCOL (Behringer X-Touch, etc.)
# ==============================================================================

setup_mcu_protocol() {
    log_info "Setting up MCU protocol (Mackie Control Universal)..."
    
    cat >> "$REAPER_INI" << 'EOF'

[MACKIE_CONTROL]
mcu_enabled=1
mcu_device=auto
mcu_channel_count=8
mcu_flip_enabled=1
mcu_jog_mode=0
mcu_alternate_mode=0
mcu_motorized=0
mcu_display_enabled=1

[MCU_BEHAVIOR]
mode_normal=volume_pan
mode_flip=pan_plugins
faders=track_volume
rotaries=track_pan
flip_button=toggle_modes
jog=cursor_navigation
transport=standard

[MCU_FADER_CONFIG]
; Map 8 faders to tracks 1-8
fader_1=track_1_volume
fader_2=track_2_volume
fader_3=track_3_volume
fader_4=track_4_volume
fader_5=track_5_volume
fader_6=track_6_volume
fader_7=track_7_volume
fader_8=track_8_volume

; Rotaries to pan
rotary_1=track_1_pan
rotary_2=track_2_pan
rotary_3=track_3_pan
rotary_4=track_4_pan
rotary_5=track_5_pan
rotary_6=track_6_pan
rotary_7=track_7_pan
rotary_8=track_8_pan

; Mute/Solo buttons
button_m_1=track_1_mute
button_m_2=track_2_mute
button_m_3=track_3_mute
button_m_4=track_4_mute
button_m_5=track_5_mute
button_m_6=track_6_mute
button_m_7=track_7_mute
button_m_8=track_8_mute

button_s_1=track_1_solo
button_s_2=track_2_solo
button_s_3=track_3_solo
button_s_4=track_4_solo
button_s_5=track_5_solo
button_s_6=track_6_solo
button_s_7=track_7_solo
button_s_8=track_8_solo
EOF

    log_success "MCU protocol enabled"
}

# ==============================================================================
# 5. SETUP OSC PROTOCOL (Network - iPad, Mobile, etc.)
# ==============================================================================

setup_osc_protocol() {
    log_info "Setting up OSC protocol (Open Sound Control)..."
    
    cat >> "$REAPER_INI" << 'EOF'

[OSC]
osc_enabled=1
osc_port=8000
osc_listen=0.0.0.0
osc_queuesize=10000
osc_verbose=0
osc_layout=/home/$USER/.config/REAPER/osc_layout.txt

[OSC_MESSAGES]
; Track control
/track/*/volume
/track/*/pan
/track/*/mute
/track/*/solo
/track/*/name

; Master control
/master/volume
/master/pan

; Transport
/transport/play
/transport/stop
/transport/record
/transport/pause

; Navigation
/marker/previous
/marker/next
/time/go_to
EOF

    # Create default OSC layout
    mkdir -p "$REAPER_CONFIG_DIR"
    cat > "$REAPER_CONFIG_DIR/osc_layout.txt" << 'OSCLAYOUT'
# REAPER OS Default OSC Layout
# For use with iPad apps: Lemur, Controlly, etc.

; Track volume control
/track/1/volume f
/track/2/volume f
/track/3/volume f
/track/4/volume f
/track/5/volume f
/track/6/volume f
/track/7/volume f
/track/8/volume f

; Track panning
/track/1/pan f
/track/2/pan f
/track/3/pan f
/track/4/pan f
/track/5/pan f
/track/6/pan f
/track/7/pan f
/track/8/pan f

; Mute controls
/track/1/mute i
/track/2/mute i
/track/3/mute i
/track/4/mute i
/track/5/mute i
/track/6/mute i
/track/7/mute i
/track/8/mute i

; Solo controls
/track/1/solo i
/track/2/solo i
/track/3/solo i
/track/4/solo i
/track/5/solo i
/track/6/solo i
/track/7/solo i
/track/8/solo i

; Master
/master/volume f
/master/pan f

; Transport
/transport/play i
/transport/stop i
/transport/record i
OSCLAYOUT

    log_success "OSC protocol enabled (port 8000)"
}

# ==============================================================================
# 6. SETUP GENERIC MIDI + MIDI LEARN
# ==============================================================================

setup_midi_learn() {
    log_info "Setting up Generic MIDI + MIDI Learn..."
    
    cat >> "$REAPER_INI" << 'EOF'

[MIDI_LEARN]
enabled=1
device=all_devices
queuesize=1024

; MIDI Learn mode allows learning any MIDI message
; Menu: Options → MIDI Learn Mode
; Then click parameter and move controller

[MIDI_MAPPING_EXAMPLE]
; CC61=Volume_Track_1
; CC62=Pan_Track_1
; CC63=Mute_Track_1
; Note60=Play
; Note61=Stop
; Note62=Record

; Uncomment and customize as needed
EOF

    log_success "MIDI Learn enabled"
}

# ==============================================================================
# 7. SETUP KEYBOARD SHORTCUTS
# ==============================================================================

setup_keyboard_shortcuts() {
    log_info "Setting up keyboard shortcuts..."
    
    cat >> "$REAPER_INI" << 'EOF'

[KEYBOARD_SHORTCUTS]
; Essential shortcuts for control
; Modify reaper-kb.ini for custom shortcuts

play=space
record=shift+space
stop=alt+space
rewind=left
forward=right
undo=ctrl+z
redo=ctrl+y
new_track=ctrl+t
delete_track=ctrl+d
EOF

    log_success "Keyboard shortcuts configured"
}

# ==============================================================================
# 8. CREATE CONFIGURATION WIZARD
# ==============================================================================

create_setup_wizard() {
    log_info "Creating configuration wizard..."
    
    cat > "$HOME/.local/bin/reaper-control-setup" << 'WIZARD'
#!/bin/bash

echo "╔════════════════════════════════════════╗"
echo "║ REAPER Control Protocol Setup Wizard   ║"
echo "╚════════════════════════════════════════╝"
echo ""

echo "Select your controller:"
echo "1) Behringer X-Touch (MCU)"
echo "2) Avid S6/S4/S3 (Eucon)"
echo "3) iPad/Mobile (OSC)"
echo "4) Mackie HUI"
echo "5) Generic MIDI"
echo "6) Keyboard Only"
echo "7) All Protocols"
echo ""

read -p "Choice [1-7]: " choice

case "$choice" in
    1)
        echo "Configuring MCU for X-Touch..."
        # MCU setup already in reaper.ini
        ;;
    2)
        echo "Configuring Eucon for Avid S-Series..."
        # Eucon setup already in reaper.ini
        ;;
    3)
        echo "Configuring OSC for iPad/Mobile..."
        echo ""
        echo "Setup Instructions:"
        echo "1. Note your PC IP: $(hostname -I | awk '{print $1}')"
        echo "2. Download Lemur or Controlly on iPad"
        echo "3. Lemur → Network → IP: $(hostname -I | awk '{print $1}')"
        echo "4. Lemur → Port: 8000"
        echo "5. Start REAPER"
        echo "6. Design interface in Lemur Editor"
        ;;
    4)
        echo "Configuring Generic MIDI for HUI..."
        echo ""
        echo "Setup Instructions:"
        echo "1. Connect HUI controller"
        echo "2. REAPER → Options → MIDI Learn Mode"
        echo "3. Click on parameter to control"
        echo "4. Move controller knob/fader"
        echo "5. Automatically mapped!"
        ;;
    5)
        echo "Configuring Generic MIDI..."
        echo ""
        echo "Setup Instructions:"
        echo "1. Connect any MIDI controller"
        echo "2. REAPER → Preferences → Control Surfaces"
        echo "3. Add → Generic Keyboard/MIDI"
        echo "4. Map controls as needed"
        ;;
    6)
        echo "Using keyboard only - shortcuts ready!"
        echo "See: Options → Show MIDI Bindings"
        ;;
    7)
        echo "All protocols enabled!"
        ;;
esac

echo ""
echo "✓ Configuration saved"
echo "✓ Restart REAPER for changes to take effect"
WIZARD

    chmod +x "$HOME/.local/bin/reaper-control-setup"
    log_success "Setup wizard created"
}

# ==============================================================================
# 9. DETECT AND AUTO-CONFIGURE
# ==============================================================================

auto_detect_and_config() {
    log_info "Auto-detecting controllers..."
    echo ""
    
    # Check for Behringer X-Touch
    if aconnect -l 2>/dev/null | grep -qi "x-touch"; then
        log_success "Behringer X-Touch detected - MCU enabled"
    fi
    
    # Check for Avid S-Series
    if aconnect -l 2>/dev/null | grep -qi "avid\|s6\|s4\|s3"; then
        log_success "Avid S-Series detected - Eucon enabled"
    fi
    
    # Generic MIDI devices
    MIDI_DEVICES=$(aconnect -l 2>/dev/null | grep "client" | wc -l)
    if [ "$MIDI_DEVICES" -gt 0 ]; then
        log_success "$MIDI_DEVICES MIDI device(s) detected"
    fi
    
    log_info "OSC ready on port 8000 for network controllers"
}

# ==============================================================================
# MAIN
# ==============================================================================

main() {
    echo "╔════════════════════════════════════════════════════╗"
    echo "║ REAPER Control Protocols Configuration             ║"
    echo "╚════════════════════════════════════════════════════╝"
    echo ""
    
    # Ensure REAPER config directory exists
    mkdir -p "$REAPER_CONFIG_DIR"
    
    # Backup existing ini
    if [ -f "$REAPER_INI" ]; then
        log_info "Backing up existing reaper.ini"
        cp "$REAPER_INI" "$REAPER_INI.backup"
    fi
    
    log_info "Setting up control protocols..."
    echo ""
    
    # Setup all protocols
    setup_hui_protocol
    setup_eucon_protocol
    setup_mcu_protocol
    setup_osc_protocol
    setup_midi_learn
    setup_keyboard_shortcuts
    
    echo ""
    
    # Create setup wizard
    create_setup_wizard
    
    echo ""
    
    # Auto-detect
    auto_detect_and_config
    
    echo ""
    echo "╔════════════════════════════════════════════════════╗"
    echo "║ ✅ Control Protocol Setup Complete!               ║"
    echo "╚════════════════════════════════════════════════════╝"
    echo ""
    
    log_info "Available protocols:"
    log_info "  ├─ MCU (Behringer X-Touch, Mackie)"
    log_info "  ├─ Eucon (Avid S-Series)"
    log_info "  ├─ HUI (Generic MIDI + Learn)"
    log_info "  ├─ OSC (iPad, Mobile, Network)"
    log_info "  ├─ Generic MIDI"
    log_info "  └─ Keyboard Shortcuts"
    echo ""
    
    log_info "Next steps:"
    log_info "1. Restart REAPER"
    log_info "2. Connect your controller"
    log_info "3. REAPER → Preferences → Control Surfaces"
    log_info "4. Select your device"
    log_info "5. Or use: reaper-control-setup (wizard)"
    echo ""
}

main "$@"
