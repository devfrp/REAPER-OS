#!/bin/bash

################################################################################
# REAPER OS Audio Configuration Manager
# Save and restore ALSA + JACK audio configurations per project
# Quickly switch between different audio setups (sample rate, buffer, routing)
################################################################################

set -e

# Configuration
PROFILE_DIR="${HOME}/.config/reaper-audio-profiles"
ACTIVE_PROFILE_FILE="${PROFILE_DIR}/.active_profile"

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[AUDIO]${NC} $1"; }
log_success() { echo -e "${GREEN}✓${NC} $1"; }
log_error() { echo -e "${RED}✗${NC} $1"; }

# ==============================================================================
# INITIALIZE PROFILE DIRECTORY
# ==============================================================================

init_profile_dir() {
    mkdir -p "$PROFILE_DIR"
    
    if [ ! -f "$ACTIVE_PROFILE_FILE" ]; then
        echo "default" > "$ACTIVE_PROFILE_FILE"
    fi
}

# ==============================================================================
# CREATE NEW PROFILE
# ==============================================================================

create_profile() {
    local profile_name="$1"
    
    if [ -z "$profile_name" ]; then
        log_error "Profile name required"
        return 1
    fi
    
    if [ -d "$PROFILE_DIR/$profile_name" ]; then
        log_error "Profile '$profile_name' already exists"
        return 1
    fi
    
    log_info "Creating profile '$profile_name'..."
    
    mkdir -p "$PROFILE_DIR/$profile_name"
    
    # Capture current audio configuration
    save_audio_config "$profile_name"
    
    log_success "Profile '$profile_name' created"
    
    # Create metadata
    cat > "$PROFILE_DIR/$profile_name/metadata.conf" << EOF
[Profile]
name=$profile_name
created=$(date)
modified=$(date)
description=Audio configuration profile
EOF
}

# ==============================================================================
# SAVE AUDIO CONFIGURATION
# ==============================================================================

save_audio_config() {
    local profile_name="$1"
    local profile_dir="$PROFILE_DIR/$profile_name"
    
    mkdir -p "$profile_dir"
    
    log_info "Saving current audio configuration to '$profile_name'..."
    
    # Save JACK configuration
    if [ -f "$HOME/.jackrc" ]; then
        cp "$HOME/.jackrc" "$profile_dir/jackrc"
        log_success "JACK configuration saved"
    fi
    
    # Save ALSA configuration
    if [ -f "$HOME/.asoundrc" ]; then
        cp "$HOME/.asoundrc" "$profile_dir/asoundrc"
        log_success "ALSA configuration saved"
    fi
    
    # Save audio device mappings
    mkdir -p "$profile_dir/devices"
    aplay -l > "$profile_dir/devices/playback.txt" 2>/dev/null || true
    arecord -l > "$profile_dir/devices/capture.txt" 2>/dev/null || true
    aconnect -l > "$profile_dir/devices/midi.txt" 2>/dev/null || true
    
    # Save JACK daemon settings
    if command -v jack_control &> /dev/null; then
        jack_control status > "$profile_dir/jack_status.txt" 2>/dev/null || true
    fi
    
    # Capture current audio config as JSON-like format
    cat > "$profile_dir/audio_settings.conf" << 'EOF'
[AUDIO_CONFIG]
timestamp=$(date +%s)
hostname=$(hostname)
user=$(whoami)

[JACK_SETTINGS]
rate=$(grep -oP 'r \K[0-9]+' $HOME/.jackrc || echo "48000")
period=$(grep -oP 'p \K[0-9]+' $HOME/.jackrc || echo "256")
nperiods=$(grep -oP 'n \K[0-9]+' $HOME/.jackrc || echo "2")

[AUDIO_DEVICES]
count=$(aplay -l | grep -c "^card" || echo "0")

[MIDI_DEVICES]
count=$(aconnect -l | grep -c "client" || echo "0")
EOF
    
    log_success "Configuration saved to $profile_name"
}

# ==============================================================================
# LIST PROFILES
# ==============================================================================

list_profiles() {
    init_profile_dir
    
    local active=$(cat "$ACTIVE_PROFILE_FILE")
    
    echo ""
    echo -e "${BLUE}Available Audio Profiles:${NC}"
    echo ""
    
    if [ -z "$(ls -A "$PROFILE_DIR" 2>/dev/null)" ]; then
        log_error "No profiles found"
        return 1
    fi
    
    local i=1
    for profile_dir in "$PROFILE_DIR"/*; do
        if [ -d "$profile_dir" ]; then
            local profile_name=$(basename "$profile_dir")
            
            if [ "$profile_name" = ".active_profile" ]; then
                continue
            fi
            
            local created=$(grep "created=" "$profile_dir/metadata.conf" 2>/dev/null | cut -d= -f2- || echo "Unknown")
            local mark=""
            
            if [ "$profile_name" = "$active" ]; then
                mark=" ✓ (ACTIVE)"
            fi
            
            printf "  %2d) %-20s [%s]%s\n" "$i" "$profile_name" "$created" "$mark"
            ((i++))
        fi
    done
    
    echo ""
}

# ==============================================================================
# LOAD PROFILE
# ==============================================================================

load_profile() {
    local profile_name="$1"
    local profile_dir="$PROFILE_DIR/$profile_name"
    
    if [ ! -d "$profile_dir" ]; then
        log_error "Profile '$profile_name' not found"
        return 1
    fi
    
    log_info "Loading audio profile '$profile_name'..."
    
    # Check if JACK is running - if so, stop it first
    if command -v jack_control &> /dev/null; then
        if jack_lsp &> /dev/null; then
            log_info "Stopping JACK..."
            jack_control stop 2>/dev/null || true
            sleep 2
        fi
    fi
    
    # Restore JACK configuration
    if [ -f "$profile_dir/jackrc" ]; then
        cp "$profile_dir/jackrc" "$HOME/.jackrc"
        chmod +x "$HOME/.jackrc"
        log_success "JACK configuration restored"
    fi
    
    # Restore ALSA configuration
    if [ -f "$profile_dir/asoundrc" ]; then
        cp "$profile_dir/asoundrc" "$HOME/.asoundrc"
        log_success "ALSA configuration restored"
    fi
    
    # Update active profile marker
    echo "$profile_name" > "$ACTIVE_PROFILE_FILE"
    
    log_success "Profile '$profile_name' loaded"
    
    # Try to restart JACK if it was running
    if command -v jack_control &> /dev/null; then
        log_info "Starting JACK with new configuration..."
        if [ -f "$HOME/.jackrc" ]; then
            bash "$HOME/.jackrc" &
            sleep 3
            
            if jack_lsp &> /dev/null; then
                log_success "JACK started successfully"
            else
                log_error "JACK failed to start"
            fi
        fi
    fi
}

# ==============================================================================
# DELETE PROFILE
# ==============================================================================

delete_profile() {
    local profile_name="$1"
    local profile_dir="$PROFILE_DIR/$profile_name"
    
    if [ ! -d "$profile_dir" ]; then
        log_error "Profile '$profile_name' not found"
        return 1
    fi
    
    if [ "$profile_name" = "default" ]; then
        log_error "Cannot delete 'default' profile"
        return 1
    fi
    
    read -p "Delete profile '$profile_name'? (y/N): " confirm
    
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        log_info "Cancelled"
        return 0
    fi
    
    rm -rf "$profile_dir"
    log_success "Profile '$profile_name' deleted"
}

# ==============================================================================
# DUPLICATE PROFILE
# ==============================================================================

duplicate_profile() {
    local source="$1"
    local target="$2"
    
    if [ -z "$source" ] || [ -z "$target" ]; then
        log_error "Usage: duplicate SOURCE TARGET"
        return 1
    fi
    
    local source_dir="$PROFILE_DIR/$source"
    local target_dir="$PROFILE_DIR/$target"
    
    if [ ! -d "$source_dir" ]; then
        log_error "Source profile '$source' not found"
        return 1
    fi
    
    if [ -d "$target_dir" ]; then
        log_error "Target profile '$target' already exists"
        return 1
    fi
    
    cp -r "$source_dir" "$target_dir"
    
    # Update metadata
    sed -i "s/name=.*/name=$target/" "$target_dir/metadata.conf" 2>/dev/null || true
    sed -i "s/created=.*/modified=$(date)/" "$target_dir/metadata.conf" 2>/dev/null || true
    
    log_success "Profile '$source' duplicated to '$target'"
}

# ==============================================================================
# SHOW PROFILE DETAILS
# ==============================================================================

show_profile_details() {
    local profile_name="$1"
    local profile_dir="$PROFILE_DIR/$profile_name"
    
    if [ ! -d "$profile_dir" ]; then
        log_error "Profile '$profile_name' not found"
        return 1
    fi
    
    echo ""
    echo -e "${BLUE}Profile Details: $profile_name${NC}"
    echo ""
    
    if [ -f "$profile_dir/metadata.conf" ]; then
        echo "Metadata:"
        cat "$profile_dir/metadata.conf"
        echo ""
    fi
    
    if [ -f "$profile_dir/audio_settings.conf" ]; then
        echo "Audio Settings:"
        cat "$profile_dir/audio_settings.conf"
        echo ""
    fi
    
    if [ -f "$profile_dir/devices/playback.txt" ]; then
        echo "Playback Devices:"
        head -5 "$profile_dir/devices/playback.txt"
        echo ""
    fi
    
    if [ -f "$profile_dir/devices/capture.txt" ]; then
        echo "Capture Devices:"
        head -5 "$profile_dir/devices/capture.txt"
        echo ""
    fi
}

# ==============================================================================
# EXPORT PROFILE
# ==============================================================================

export_profile() {
    local profile_name="$1"
    local output_file="$2"
    
    if [ -z "$output_file" ]; then
        output_file="${profile_name}_profile.tar.gz"
    fi
    
    local profile_dir="$PROFILE_DIR/$profile_name"
    
    if [ ! -d "$profile_dir" ]; then
        log_error "Profile '$profile_name' not found"
        return 1
    fi
    
    log_info "Exporting profile to '$output_file'..."
    
    tar -czf "$output_file" -C "$PROFILE_DIR" "$profile_name" 2>/dev/null
    
    log_success "Profile exported to $output_file"
}

# ==============================================================================
# IMPORT PROFILE
# ==============================================================================

import_profile() {
    local input_file="$1"
    
    if [ ! -f "$input_file" ]; then
        log_error "File '$input_file' not found"
        return 1
    fi
    
    log_info "Importing profile from '$input_file'..."
    
    tar -xzf "$input_file" -C "$PROFILE_DIR" 2>/dev/null
    
    local profile_name=$(basename "$(tar -tzf "$input_file" | head -1 | cut -d/ -f1)")
    
    log_success "Profile '$profile_name' imported"
}

# ==============================================================================
# INTERACTIVE MENU
# ==============================================================================

interactive_menu() {
    init_profile_dir
    
    while true; do
        echo ""
        echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
        echo -e "${BLUE}║  Audio Configuration Manager           ║${NC}"
        echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
        echo ""
        echo "1) List profiles"
        echo "2) Create new profile"
        echo "3) Load profile"
        echo "4) Save current configuration"
        echo "5) Delete profile"
        echo "6) Duplicate profile"
        echo "7) Show profile details"
        echo "8) Export profile"
        echo "9) Import profile"
        echo "0) Exit"
        echo ""
        
        read -p "Choice [0-9]: " choice
        
        case "$choice" in
            1)
                list_profiles
                ;;
            2)
                read -p "Profile name: " profile_name
                create_profile "$profile_name"
                ;;
            3)
                list_profiles
                read -p "Profile name to load: " profile_name
                load_profile "$profile_name"
                ;;
            4)
                read -p "Profile name to save to: " profile_name
                save_audio_config "$profile_name"
                ;;
            5)
                list_profiles
                read -p "Profile name to delete: " profile_name
                delete_profile "$profile_name"
                ;;
            6)
                list_profiles
                read -p "Source profile: " source
                read -p "Target profile name: " target
                duplicate_profile "$source" "$target"
                ;;
            7)
                list_profiles
                read -p "Profile name to view: " profile_name
                show_profile_details "$profile_name"
                ;;
            8)
                list_profiles
                read -p "Profile name to export: " profile_name
                read -p "Output file (press Enter for default): " output_file
                export_profile "$profile_name" "$output_file"
                ;;
            9)
                read -p "Input file to import: " input_file
                import_profile "$input_file"
                ;;
            0)
                echo "Exiting..."
                exit 0
                ;;
            *)
                log_error "Invalid choice"
                ;;
        esac
    done
}

# ==============================================================================
# MAIN
# ==============================================================================

main() {
    init_profile_dir
    
    if [ $# -eq 0 ]; then
        # Interactive mode
        interactive_menu
    else
        # Command line mode
        local cmd="$1"
        shift
        
        case "$cmd" in
            list)
                list_profiles
                ;;
            create)
                create_profile "$1"
                ;;
            load)
                load_profile "$1"
                ;;
            save)
                save_audio_config "$1"
                ;;
            delete)
                delete_profile "$1"
                ;;
            duplicate)
                duplicate_profile "$1" "$2"
                ;;
            show)
                show_profile_details "$1"
                ;;
            export)
                export_profile "$1" "$2"
                ;;
            import)
                import_profile "$1"
                ;;
            --help|-h)
                echo "REAPER OS Audio Configuration Manager"
                echo ""
                echo "Usage: audio-config-manager [COMMAND] [OPTIONS]"
                echo ""
                echo "Commands:"
                echo "  list                    List all profiles"
                echo "  create NAME             Create new profile"
                echo "  load NAME               Load profile"
                echo "  save NAME               Save current config to profile"
                echo "  delete NAME             Delete profile"
                echo "  duplicate SRC TGT       Copy profile"
                echo "  show NAME               Show profile details"
                echo "  export NAME [FILE]      Export profile to file"
                echo "  import FILE             Import profile from file"
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
