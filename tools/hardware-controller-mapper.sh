#!/bin/bash

################################################################################
# REAPER OS Hardware Controller Auto-Mapper v0.5.0
# Automatic detection and mapping of MIDI controllers
# Usage: ./hardware-controller-mapper.sh [--detect] [--auto-map] [--save]
################################################################################

set -euo pipefail

MAPPER_DIR="$HOME/.config/REAPER/controller-mapper"
MAPPER_DB="$MAPPER_DIR/controllers.json"
MAPPER_LOG="$MAPPER_DIR/mapper.log"

mkdir -p "$MAPPER_DIR"

# Initialize controller database
init_controller_db() {
    if [ ! -f "$MAPPER_DB" ]; then
        cat > "$MAPPER_DB" << 'EOF'
{
  "controllers": [
    {
      "id": "novation-launchpad",
      "name": "Novation Launchpad Pro",
      "type": "grid",
      "input_device": "Launchpad Pro",
      "preset": "drum_pad",
      "mapping": {
        "note_range": "36-99",
        "cc_controls": "120-127",
        "fader_count": 8
      }
    },
    {
      "id": "behringer-fcb1010",
      "name": "Behringer FCB1010",
      "type": "footpedal",
      "input_device": "FCB1010",
      "preset": "live_control",
      "mapping": {
        "pedals": 2,
        "switches": 10,
        "expression_range": "0-127"
      }
    },
    {
      "id": "korg-nanokontrol2",
      "name": "Korg nanoKONTROL2",
      "type": "fader",
      "input_device": "nanoKONTROL2",
      "preset": "channel_mixer",
      "mapping": {
        "faders": 8,
        "knobs": 8,
        "buttons": 16,
        "cc_base": 2
      }
    },
    {
      "id": "native-instruments-s88",
      "name": "Native Instruments Komplete Kontrol S88",
      "type": "keyboard",
      "input_device": "Komplete Kontrol",
      "preset": "synth_control",
      "mapping": {
        "keys": 88,
        "faders": 8,
        "encoder_rings": 8,
        "light_guide": true
      }
    }
  ],
  "presets": {
    "drum_pad": {
      "name": "Drum Pad Setup",
      "description": "For drum pads and MPCs",
      "track_selection": "automatic",
      "plugin_control": "enabled",
      "macros": ["mute_unmute", "solo", "record_arm", "pan", "volume"]
    },
    "live_control": {
      "name": "Live Performance",
      "description": "For live foot control",
      "pedal_mapping": "sustain_expression",
      "footswitch_mapping": "bypass_tap_tempo",
      "expression_range": "velocity"
    },
    "channel_mixer": {
      "name": "Channel Faders",
      "description": "Linear fader mixer",
      "fader_count": 8,
      "fader_mode": "volume",
      "button_mode": "mute_solo",
      "rotary_mode": "pan_eq"
    },
    "synth_control": {
      "name": "Synth Controller",
      "description": "For keyboard synthesis",
      "key_mode": "note_velocity",
      "fader_mode": "filter_envelope",
      "encoder_mode": "synth_parameters",
      "light_guide": true
    }
  }
}
EOF
        echo "Controller database initialized" >> "$MAPPER_LOG"
    fi
}

# Detect connected MIDI controllers
detect_controllers() {
    echo "Detecting MIDI controllers..." | tee -a "$MAPPER_LOG"
    
    python3 << 'PYTHON'
import subprocess
import json

# List all MIDI devices
try:
    result = subprocess.run(['aconnect', '-i'], capture_output=True, text=True)
    
    detected = []
    for line in result.stdout.split('\n'):
        if 'client' in line:
            client_name = line.split()[1:3]
            detected.append(' '.join(client_name))
    
    print(json.dumps({
        'detected_devices': detected,
        'count': len(detected),
        'timestamp': str(__import__('datetime').datetime.now())
    }, indent=2))
except Exception as e:
    print(json.dumps({'error': str(e)}))
PYTHON
}

# Auto-map controller based on detection
auto_map_controller() {
    local device_name="$1"
    
    echo "Auto-mapping: $device_name" | tee -a "$MAPPER_LOG"
    
    python3 << PYTHON
import json

with open("$MAPPER_DB") as f:
    db = json.load(f)

# Match device to known controllers
for controller in db['controllers']:
    if controller['input_device'].lower() in "$device_name".lower():
        print(f"Found preset: {controller['preset']}")
        print(f"Applying configuration: {controller['name']}")
        
        # Get preset details
        preset = db['presets'].get(controller['preset'])
        if preset:
            print(f"Preset: {preset['name']}")
            print(f"Description: {preset['description']}")
            
            # Auto-apply mapping
            print(f"Auto-mapping {controller['mapping']}")
        break
else:
    print(f"No preset found for {device_name}")
PYTHON
}

# Save custom mapping
save_mapping() {
    local controller_id="$1"
    local mapping_file="$2"
    
    echo "Saving mapping for $controller_id" | tee -a "$MAPPER_LOG"
    
    cp "$mapping_file" "$MAPPER_DIR/${controller_id}.mapping.json"
    echo "Mapping saved: $MAPPER_DIR/${controller_id}.mapping.json" | tee -a "$MAPPER_LOG"
}

# List all mapped controllers
list_mappings() {
    echo "Mapped Controllers:" | tee -a "$MAPPER_LOG"
    echo "==================" | tee -a "$MAPPER_LOG"
    
    python3 << PYTHON
import json
import os

with open("$MAPPER_DB") as f:
    db = json.load(f)

print(f"Total controllers in database: {len(db['controllers'])}\n")

for controller in db['controllers']:
    print(f"✓ {controller['name']}")
    print(f"  Type: {controller['type']}")
    print(f"  Device: {controller['input_device']}")
    print(f"  Preset: {controller['preset']}")
    print()
PYTHON
}

# Export mapping for backup
export_mapping() {
    local backup_dir="$MAPPER_DIR/backups"
    mkdir -p "$backup_dir"
    
    cp "$MAPPER_DB" "$backup_dir/controllers-$(date +%Y%m%d-%H%M%S).json"
    echo "Mapping exported to $backup_dir"
}

main() {
    init_controller_db
    
    case "${1:-help}" in
        --detect)
            detect_controllers
            ;;
        --auto-map)
            auto_map_controller "${2:-unknown}"
            ;;
        --save)
            save_mapping "${2:-custom}" "${3:-mapping.json}"
            ;;
        --list)
            list_mappings
            ;;
        --export)
            export_mapping
            ;;
        *)
            echo "REAPER OS Hardware Controller Auto-Mapper"
            echo "Usage: controller-mapper.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --detect           Detect connected MIDI controllers"
            echo "  --auto-map NAME    Auto-map controller by name"
            echo "  --save ID FILE     Save custom mapping"
            echo "  --list             List all mappable controllers"
            echo "  --export           Export mappings for backup"
            ;;
    esac
}

main "$@"
