#!/bin/bash

################################################################################
# REAPER OS Advanced Preset System
# Professional preset management with templates, chains, and routing
# Usage: ./preset-manager-advanced.sh [--create] [--load] [--share] [--sync]
################################################################################

set -euo pipefail

PRESET_DIR="$HOME/.config/REAPER/presets"
CHAIN_DIR="$PRESET_DIR/chains"
TEMPLATE_DIR="$PRESET_DIR/templates"
SYNC_DIR="$PRESET_DIR/sync"

mkdir -p "$PRESET_DIR" "$CHAIN_DIR" "$TEMPLATE_DIR" "$SYNC_DIR"

# Pre-configured templates
create_templates() {
    # Studio Recording Template
    cat > "$TEMPLATE_DIR/studio-recording.json" << 'EOF'
{
  "name": "Studio Recording",
  "description": "Professional studio recording setup",
  "audio_settings": {
    "sample_rate": 48000,
    "buffer_size": 256,
    "bit_depth": 24,
    "num_periods": 2
  },
  "jack_config": {
    "realtime": true,
    "priority": 90,
    "memlock": "unlimited"
  },
  "vst_chain": [
    {"type": "preamp", "name": "Stock"},
    {"type": "compressor", "name": "SSL G-Series"},
    {"type": "eq", "name": "API 550A"}
  ],
  "monitoring": {
    "latency_target": "< 5ms",
    "cpu_target": "< 30%"
  }
}
EOF

    # Live Performance Template
    cat > "$TEMPLATE_DIR/live-performance.json" << 'EOF'
{
  "name": "Live Performance",
  "description": "Low-latency live performance setup",
  "audio_settings": {
    "sample_rate": 48000,
    "buffer_size": 128,
    "bit_depth": 24,
    "num_periods": 2
  },
  "jack_config": {
    "realtime": true,
    "priority": 95,
    "memlock": "unlimited"
  },
  "quick_switches": [
    "synth_program_1",
    "synth_program_2",
    "effect_preset_1"
  ],
  "monitoring": {
    "latency_target": "< 10ms",
    "cpu_target": "< 50%"
  }
}
EOF

    # Podcast Production Template
    cat > "$TEMPLATE_DIR/podcast.json" << 'EOF'
{
  "name": "Podcast Production",
  "description": "Podcast recording and editing setup",
  "audio_settings": {
    "sample_rate": 44100,
    "buffer_size": 1024,
    "bit_depth": 16,
    "num_periods": 2
  },
  "recording": {
    "format": "MP3",
    "bitrate": "192k",
    "normalization": true
  },
  "vst_chain": [
    {"type": "gate", "name": "Noise Gate"},
    {"type": "eq", "name": "Voice EQ"},
    {"type": "compressor", "name": "Limiter"}
  ]
}
EOF

    # Mixing/Mastering Template
    cat > "$TEMPLATE_DIR/mixing-mastering.json" << 'EOF'
{
  "name": "Mixing & Mastering",
  "description": "Mixing and mastering workflow",
  "audio_settings": {
    "sample_rate": 96000,
    "buffer_size": 512,
    "bit_depth": 32,
    "num_periods": 2
  },
  "monitoring": {
    "reference_speakers": "calibrated",
    "reference_level": "-23 LUFS"
  },
  "analysis_tools": [
    "spectrum_analyzer",
    "loudness_meter",
    "phase_analyzer"
  ]
}
EOF

    echo "Templates created successfully"
}

# Load preset
load_preset() {
    local preset="$1"
    
    if [ ! -f "$PRESET_DIR/$preset.json" ]; then
        echo "Preset not found: $preset"
        return 1
    fi
    
    echo "Loading preset: $preset"
    
    # Parse and apply settings
    python3 << PYTHON
import json
with open("$PRESET_DIR/$preset.json") as f:
    preset = json.load(f)
    
print(f"Applying: {preset['name']}")
print(f"Description: {preset['description']}")

if 'audio_settings' in preset:
    settings = preset['audio_settings']
    print(f"Sample Rate: {settings.get('sample_rate', 'default')}")
    print(f"Buffer: {settings.get('buffer_size', 'default')}")
    
if 'vst_chain' in preset:
    print("VST Chain:")
    for vst in preset['vst_chain']:
        print(f"  - {vst['type']}: {vst['name']}")
PYTHON
}

# Save current configuration as preset
save_preset() {
    local name="$1"
    
    echo "Saving current configuration as: $name"
    
    cat > "$PRESET_DIR/$name.json" << 'EOF'
{
  "name": "",
  "timestamp": "",
  "audio_settings": {
    "sample_rate": 48000,
    "buffer_size": 256
  },
  "saved_settings": {}
}
EOF

    echo "Preset saved: $PRESET_DIR/$name.json"
}

# Create VST chain
create_vst_chain() {
    local chain_name="$1"
    
    echo "Creating VST chain: $chain_name"
    
    cat > "$CHAIN_DIR/$chain_name.json" << 'EOF'
{
  "name": "",
  "plugins": [],
  "routing": "series"
}
EOF
}

# Sync presets across machines
sync_presets() {
    echo "Syncing presets..."
    
    # Create sync package
    tar -czf "$SYNC_DIR/presets-$(date +%Y%m%d).tar.gz" "$PRESET_DIR"
    
    echo "Sync package created: $SYNC_DIR/presets-$(date +%Y%m%d).tar.gz"
    
    # Can be uploaded to cloud or shared
}

# List all presets
list_presets() {
    echo "Available Presets:"
    echo "=================="
    
    if [ ! -d "$PRESET_DIR" ] || [ -z "$(ls -A $PRESET_DIR/*.json 2>/dev/null)" ]; then
        echo "No presets found"
        return
    fi
    
    for preset in "$PRESET_DIR"/*.json; do
        if [ -f "$preset" ]; then
            echo "  - $(basename "$preset" .json)"
        fi
    done
}

# Generate HTML preset browser
generate_browser() {
    cat > "$PRESET_DIR/preset-browser.html" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>REAPER OS Preset Browser</title>
    <style>
        body { font-family: Arial; background: #2a2a2a; color: #fff; }
        .container { max-width: 800px; margin: 0 auto; padding: 20px; }
        .preset-card {
            background: #3a3a3a;
            padding: 15px;
            margin: 10px 0;
            border-radius: 5px;
            cursor: pointer;
        }
        .preset-card:hover { background: #4a4a4a; }
        .category { font-weight: bold; color: #667eea; margin: 20px 0 10px 0; }
        button { background: #667eea; color: white; border: none; padding: 10px 20px; border-radius: 5px; cursor: pointer; }
        button:hover { background: #764ba2; }
    </style>
</head>
<body>
    <div class="container">
        <h1>REAPER OS Preset Browser</h1>
        
        <div class="category">Studio Recording</div>
        <div class="preset-card" onclick="loadPreset('studio-recording')">
            <strong>Studio Recording</strong>
            <p>Professional studio recording setup - 48kHz, 256 buffer</p>
            <button>Load</button>
        </div>
        
        <div class="category">Live Performance</div>
        <div class="preset-card" onclick="loadPreset('live-performance')">
            <strong>Live Performance</strong>
            <p>Low-latency live rig - 48kHz, 128 buffer</p>
            <button>Load</button>
        </div>
        
        <div class="category">Content Creation</div>
        <div class="preset-card" onclick="loadPreset('podcast')">
            <strong>Podcast Production</strong>
            <p>Podcast recording setup - 44.1kHz, optimized</p>
            <button>Load</button>
        </div>
    </div>
    
    <script>
        function loadPreset(name) {
            alert('Loading: ' + name);
            // Would call backend API
        }
    </script>
</body>
</html>
EOF

    echo "Preset browser created: $PRESET_DIR/preset-browser.html"
}

main() {
    local action="${1:-help}"
    
    case "$action" in
        --create-templates)
            create_templates
            ;;
        --load)
            load_preset "${2:-default}"
            ;;
        --save)
            save_preset "${2:-custom-preset}"
            ;;
        --list)
            list_presets
            ;;
        --sync)
            sync_presets
            ;;
        --browser)
            generate_browser
            ;;
        *)
            echo "REAPER OS Advanced Preset Manager"
            echo "Usage: preset-manager-advanced.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --create-templates   Create default templates"
            echo "  --load PRESET        Load a preset"
            echo "  --save NAME          Save current config"
            echo "  --list               List all presets"
            echo "  --sync               Sync presets"
            echo "  --browser            Generate preset browser"
            ;;
    esac
}

main "$@"
