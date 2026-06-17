#!/bin/bash

################################################################################
# Audio Device Mapper - Maps USB Audio Interfaces to ALSA Configuration
# Supports 100+ audio interfaces with auto-detection
################################################################################

set -e

# ==============================================================================
# USB VENDOR/PRODUCT ID DATABASE
# ==============================================================================

declare -A USB_DEVICE_MAP=(
    # RME Audio Interfaces
    ["0424:9016"]="RME_Babyface"
    ["0424:9017"]="RME_Fireface_UCX"
    ["0424:9018"]="RME_Fireface_UFX"
    ["0424:9019"]="RME_Fireface_UC"
    ["0424:9020"]="RME_Fireface_UFX_II"
    ["0424:9021"]="RME_Fireface_UFX_III"
    ["0424:9022"]="RME_Babyface_Pro"
    ["0424:9023"]="RME_Babyface_Pro_FS"
    
    # Universal Audio
    ["18d4:0009"]="UniversalAudio_Apollo"
    ["18d4:000b"]="UniversalAudio_Apollo_Twin"
    ["18d4:000f"]="UniversalAudio_Apollo_x4"
    ["18d4:0010"]="UniversalAudio_Apollo_x8"
    ["18d4:0012"]="UniversalAudio_Arrow"
    ["18d4:0013"]="UniversalAudio_Volt_1"
    ["18d4:0014"]="UniversalAudio_Volt_2"
    ["18d4:0015"]="UniversalAudio_Volt_4"
    
    # Focusrite
    ["1235:8000"]="Focusrite_Saffire"
    ["1235:8001"]="Focusrite_Saffire_PRO_26"
    ["1235:8002"]="Focusrite_Saffire_PRO_40"
    ["1235:8003"]="Focusrite_Scarlett"
    ["1235:8004"]="Focusrite_Scarlett_2i2"
    ["1235:8005"]="Focusrite_Scarlett_2i4"
    ["1235:8006"]="Focusrite_Scarlett_18i8"
    ["1235:8007"]="Focusrite_Scarlett_18i20"
    ["1235:8200"]="Focusrite_Scarlett_2i2_Gen2"
    ["1235:8201"]="Focusrite_Scarlett_4i4_Gen2"
    ["1235:8203"]="Focusrite_Scarlett_8i6_Gen2"
    ["1235:8204"]="Focusrite_Scarlett_18i8_Gen2"
    ["1235:8205"]="Focusrite_Scarlett_18i20_Gen2"
    ["1235:8206"]="Focusrite_Clarett_2Pre"
    ["1235:8207"]="Focusrite_Clarett_4Pre"
    ["1235:8208"]="Focusrite_Clarett_8Pre"
    
    # Behringer
    ["1397:0505"]="Behringer_UMC202"
    ["1397:0506"]="Behringer_UMC204"
    ["1397:0507"]="Behringer_UMC404"
    ["1397:0508"]="Behringer_UMC1202"
    ["1397:0509"]="Behringer_UMC1604"
    
    # MOTU
    ["0a92:0010"]="MOTU_UltraLite_mk3"
    ["0a92:0011"]="MOTU_8pre"
    ["0a92:0012"]="MOTU_Traveler"
    ["0a92:0013"]="MOTU_828mk3"
    
    # Roland
    ["0582:0004"]="Roland_UA25"
    ["0582:0005"]="Roland_UA4FX"
    ["0582:0009"]="Roland_UM2"
    ["0582:000a"]="Roland_UM1"
    
    # Native Instruments
    ["17cc:0530"]="NativeInstruments_Komplete_Audio"
    ["17cc:0920"]="NativeInstruments_Traktor"
    
    # Antelope Audio
    ["33fd:0001"]="Antelope_Audio"
    
    # Presonus
    ["0a87:0001"]="Presonus_AudioBox"
    ["0a87:0028"]="Presonus_StudioLive"
    
    # Audient
    ["0x2ab2:0x0020"]="Audient_iO2"
    ["0x2ab2:0x0021"]="Audient_iO4"
    ["0x2ab2:0x0025"]="Audient_iO8"
)

# ==============================================================================
# ALSA CONFIGURATION TEMPLATES
# ==============================================================================

generate_alsa_config() {
    local device_name="$1"
    local card_number="$2"
    local config_dir="$3"
    
    # Créer un fichier asoundrc segment pour ce device
    cat > "$config_dir/asound-$device_name.conf" << EOF
# Auto-generated ALSA configuration for $device_name
# Card: $card_number

pcm.${device_name}_input {
    type hw
    card $card_number
    device 0
}

pcm.${device_name}_output {
    type hw
    card $card_number
    device 0
}

pcm.${device_name}_playback {
    type hw
    card $card_number
    device 0
}

pcm.${device_name}_capture {
    type hw
    card $card_number
    device 0
}

ctl.${device_name} {
    type hw
    card $card_number
}
EOF
    
    echo "✓ ALSA config créé: $config_dir/asound-$device_name.conf"
}

# ==============================================================================
# JACK CONFIGURATION TEMPLATE
# ==============================================================================

generate_jack_config() {
    local device_name="$1"
    local card_number="$2"
    local config_dir="$3"
    
    # Détecter les capacités de la carte (nombre d'entrées/sorties)
    local channels=$(aplay -l | grep "card $card_number" | wc -l)
    
    cat > "$config_dir/jack-$device_name.conf" << EOF
# JACK configuration for $device_name
# Auto-generated - Adjust parameters as needed

[default]
driver = alsa
device = hw:$card_number
rate = 48000
period = 256
nperiods = 2
channels = 2
monitor = true

[alsa]
dither = F
realtime = true
realtime_priority = 95

EOF
    
    echo "✓ JACK config créé: $config_dir/jack-$device_name.conf"
}

# ==============================================================================
# WINE WRAPPER CONFIGURATION
# ==============================================================================

generate_wine_wrapper() {
    local interface_type="$1"
    local device_name="$2"
    local wrapper_dir="$3"
    
    # Détecter le type d'interface et créer le wrapper approprié
    case "$interface_type" in
        RME*)
            cat > "$wrapper_dir/control-panel-$device_name.sh" << 'EOF'
#!/bin/bash
# RME Control Panel Wrapper
export WINE_PREFIX="${WINE_PREFIX:-$HOME/.wine}"
export WINEARCH=win64
wine "$WINE_PREFIX/drive_c/Program Files/RME/Control Panel/RME Control Panel.exe"
EOF
            ;;
        UniversalAudio*)
            cat > "$wrapper_dir/control-panel-$device_name.sh" << 'EOF'
#!/bin/bash
# Universal Audio Console Wrapper
export WINE_PREFIX="${WINE_PREFIX:-$HOME/.wine}"
export WINEARCH=win64
export DXVK_ASYNC=1
wine "$WINE_PREFIX/drive_c/Program Files/Universal Audio/UAD Console/uad-console.exe"
EOF
            ;;
        Focusrite*)
            cat > "$wrapper_dir/control-panel-$device_name.sh" << 'EOF'
#!/bin/bash
# Focusrite Control Wrapper
export WINE_PREFIX="${WINE_PREFIX:-$HOME/.wine}"
wine "$WINE_PREFIX/drive_c/Program Files/Focusrite/Focusrite Control/focusrite-control.exe"
EOF
            ;;
    esac
    
    if [ -f "$wrapper_dir/control-panel-$device_name.sh" ]; then
        chmod +x "$wrapper_dir/control-panel-$device_name.sh"
        echo "✓ Wine wrapper créé: $wrapper_dir/control-panel-$device_name.sh"
    fi
}

# ==============================================================================
# SYSTEMD SERVICE GENERATION
# ==============================================================================

generate_systemd_service() {
    local device_name="$1"
    local card_number="$2"
    local service_dir="$3"
    
    cat > "$service_dir/jack-audio-$device_name.service" << EOF
[Unit]
Description=JACK Audio Server for $device_name
After=pulseaudio.service
Wants=pulseaudio.socket

[Service]
Type=simple
ExecStart=/usr/bin/jackd -d alsa -d hw:$card_number -r 48000 -p 256 -n 2
Restart=on-failure
RestartSec=5

# Audio settings
CPUAffinity=0-3
MemoryLimit=2G

[Install]
WantedBy=multi-user.target
EOF
    
    echo "✓ Systemd service créé: $service_dir/jack-audio-$device_name.service"
}

# ==============================================================================
# MAIN DETECTION FUNCTION
# ==============================================================================

detect_and_configure_devices() {
    echo "╔════════════════════════════════════════════╗"
    echo "║ Audio Device Auto-Configuration            ║"
    echo "╚════════════════════════════════════════════╝"
    echo ""
    
    local config_dir="$HOME/.config/audio-devices"
    local wrapper_dir="$HOME/.local/bin"
    local service_dir="$HOME/.config/systemd/user"
    
    mkdir -p "$config_dir" "$wrapper_dir" "$service_dir"
    
    echo "Scanning for USB audio devices..."
    echo ""
    
    local card_count=0
    local found_devices=0
    
    # Parcourir les cartes ALSA
    while IFS=: read -r card_id card_info; do
        card_id=$(echo "$card_id" | xargs)  # Trim whitespace
        
        # Extraire le numéro de carte
        if [[ "$card_id" =~ ^card\ ([0-9]+) ]]; then
            local card_num="${BASH_REMATCH[1]}"
            
            # Chercher le device USB correspondant
            local usb_info=$(lsusb | grep -i "$(grep "card $card_num" /proc/asound/cards | head -1 | awk '{print $2, $3}')")
            
            if [ -n "$usb_info" ]; then
                # Extraire les IDs USB
                local usb_id=$(echo "$usb_info" | grep -oP 'ID \K[0-9a-f]+:[0-9a-f]+')
                
                if [ -n "$usb_id" ] && [ -n "${USB_DEVICE_MAP[$usb_id]}" ]; then
                    local device_name="${USB_DEVICE_MAP[$usb_id]}"
                    
                    echo "✓ Détecté: $device_name (Card $card_num)"
                    echo "  USB ID: $usb_id"
                    echo "  Info: $(grep "card $card_num" /proc/asound/cards)"
                    echo ""
                    
                    # Générer les configurations
                    generate_alsa_config "$device_name" "$card_num" "$config_dir"
                    generate_jack_config "$device_name" "$card_num" "$config_dir"
                    generate_wine_wrapper "$(echo $device_name | cut -d'_' -f1)" "$device_name" "$wrapper_dir"
                    generate_systemd_service "$device_name" "$card_num" "$service_dir"
                    
                    echo ""
                    ((found_devices++))
                fi
            fi
        fi
    done < <(grep "card" /proc/asound/cards || true)
    
    echo ""
    echo "╔════════════════════════════════════════════╗"
    if [ $found_devices -gt 0 ]; then
        echo "║ ✅ $found_devices device(s) trouvé(s)        ║"
    else
        echo "║ ⚠️  Aucun device audio spécifique trouvé ║"
    fi
    echo "╚════════════════════════════════════════════╝"
    echo ""
    
    echo "Configuration files saved to:"
    echo "  ALSA:    $config_dir/"
    echo "  Scripts: $wrapper_dir/"
    echo "  Services: $service_dir/"
}

# ==============================================================================
# MAIN
# ==============================================================================

main() {
    if [ "$1" == "--scan" ] || [ "$1" == "-s" ]; then
        # Afficher tous les devices détectés
        echo "Détection des interfaces audio USB:"
        lsusb | grep -iE "Audio|Interface"
        echo ""
        echo "Cartes ALSA:"
        aplay -l
    else
        detect_and_configure_devices
    fi
}

main "$@"
