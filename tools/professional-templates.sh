#!/bin/bash

################################################################################
# REAPER OS Professional Templates
# Pre-configured templates for different professional use cases
# Usage: ./professional-templates.sh [--list] [--create] [--export]
################################################################################

set -euo pipefail

TEMPLATES_DIR="$HOME/.config/REAPER/professional-templates"
mkdir -p "$TEMPLATES_DIR"

# Create all professional templates
create_all_templates() {
    mkdir -p "$TEMPLATES_DIR"/{studio,live,podcast,mixing,electronic,film}
    
    echo "Creating professional templates..."
    
    # Studio Recording Template
    cat > "$TEMPLATES_DIR/studio/config.json" << 'EOF'
{
  "name": "Studio Recording",
  "version": "1.0",
  "settings": {
    "sample_rate": 48000,
    "bit_depth": 24,
    "buffer": 256
  },
  "vst_chain": [
    "Input Limiter", "Compressor", "EQ"
  ],
  "presets": [
    "Vocal Recording", "Guitar Recording", "Drums"
  ]
}
EOF

    # Live Performance Template
    cat > "$TEMPLATES_DIR/live/config.json" << 'EOF'
{
  "name": "Live Performance",
  "version": "1.0",
  "settings": {
    "sample_rate": 48000,
    "buffer": 128,
    "latency_target": "< 10ms"
  },
  "quick_access": [
    "Program 1", "Program 2", "Program 3",
    "Effect 1", "Effect 2"
  ]
}
EOF

    # Podcast Template
    cat > "$TEMPLATES_DIR/podcast/config.json" << 'EOF'
{
  "name": "Podcast Production",
  "version": "1.0",
  "settings": {
    "sample_rate": 44100,
    "buffer": 1024,
    "format": "MP3 @ 192kbps"
  },
  "recording_chain": [
    "Noise Gate", "Voice Processor", "Compressor", "Limiter"
  ]
}
EOF

    # Mixing/Mastering Template
    cat > "$TEMPLATES_DIR/mixing/config.json" << 'EOF'
{
  "name": "Mixing & Mastering",
  "version": "1.0",
  "settings": {
    "sample_rate": 96000,
    "bit_depth": 32,
    "buffer": 512
  },
  "metering": [
    "Spectrum Analyzer", "Loudness Meter", "Phase Meter"
  ]
}
EOF

    # Electronic Music Template
    cat > "$TEMPLATES_DIR/electronic/config.json" << 'EOF'
{
  "name": "Electronic Music Production",
  "version": "1.0",
  "synths": [
    "Massive X", "Serum", "Wavetable"
  ],
  "effects": [
    "Reverb", "Delay", "Distortion", "Chorus"
  ]
}
EOF

    # Film Scoring Template
    cat > "$TEMPLATES_DIR/film/config.json" << 'EOF'
{
  "name": "Film Scoring",
  "version": "1.0",
  "settings": {
    "sample_rate": 48000,
    "timecode": "24fps",
    "format": "WAV @ 24-bit"
  },
  "instruments": [
    "Orchestral Strings", "Brass", "Woodwinds", "Percussion"
  ]
}
EOF

    echo "All templates created successfully"
}

# List templates
list_templates() {
    echo "Available Professional Templates:"
    echo "=================================="
    
    for template_dir in "$TEMPLATES_DIR"/*/; do
        if [ -d "$template_dir" ]; then
            template_name=$(basename "$template_dir")
            if [ -f "$template_dir/config.json" ]; then
                echo "  ✓ $template_name"
            fi
        fi
    done
}

# Export template
export_template() {
    local template="$1"
    local output="${2:-$template.tar.gz}"
    
    if [ -d "$TEMPLATES_DIR/$template" ]; then
        tar -czf "$output" -C "$TEMPLATES_DIR" "$template"
        echo "Template exported: $output"
    else
        echo "Template not found: $template"
    fi
}

# Generate HTML template browser
generate_template_browser() {
    cat > "$TEMPLATES_DIR/template-browser.html" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>REAPER OS Professional Templates</title>
    <style>
        body { font-family: Arial; background: #1a1a1a; color: #fff; }
        .header { background: linear-gradient(135deg, #667eea, #764ba2); padding: 30px; }
        .container { max-width: 1000px; margin: 0 auto; padding: 20px; }
        .template-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; }
        .template-card {
            background: #2a2a2a;
            padding: 20px;
            border-radius: 10px;
            border: 1px solid #3a3a3a;
            cursor: pointer;
            transition: border-color 0.3s;
        }
        .template-card:hover { border-color: #667eea; }
        .template-icon { font-size: 40px; margin-bottom: 10px; }
        .template-name { font-weight: bold; font-size: 20px; margin: 10px 0; }
        .template-desc { color: #aaa; margin: 10px 0; }
        button { background: #667eea; color: white; border: none; padding: 10px 20px; border-radius: 5px; cursor: pointer; width: 100%; margin-top: 10px; }
        button:hover { background: #764ba2; }
    </style>
</head>
<body>
    <div class="header">
        <h1>REAPER OS Professional Templates</h1>
        <p>Pre-configured setups for your workflow</p>
    </div>
    
    <div class="container">
        <div class="template-grid">
            <div class="template-card">
                <div class="template-icon">🎙️</div>
                <div class="template-name">Studio Recording</div>
                <div class="template-desc">Professional vocal and instrument recording</div>
                <button onclick="loadTemplate('studio')">Load</button>
            </div>
            
            <div class="template-card">
                <div class="template-icon">🎸</div>
                <div class="template-name">Live Performance</div>
                <div class="template-desc">Low-latency live performance rig</div>
                <button onclick="loadTemplate('live')">Load</button>
            </div>
            
            <div class="template-card">
                <div class="template-icon">🎙️</div>
                <div class="template-name">Podcast Production</div>
                <div class="template-desc">Podcast recording and editing setup</div>
                <button onclick="loadTemplate('podcast')">Load</button>
            </div>
            
            <div class="template-card">
                <div class="template-icon">🎚️</div>
                <div class="template-name">Mixing & Mastering</div>
                <div class="template-desc">Professional mixing and mastering</div>
                <button onclick="loadTemplate('mixing')">Load</button>
            </div>
            
            <div class="template-card">
                <div class="template-icon">🎹</div>
                <div class="template-name">Electronic Music</div>
                <div class="template-desc">Electronic and dance music production</div>
                <button onclick="loadTemplate('electronic')">Load</button>
            </div>
            
            <div class="template-card">
                <div class="template-icon">🎬</div>
                <div class="template-name">Film Scoring</div>
                <div class="template-desc">Film and video game scoring</div>
                <button onclick="loadTemplate('film')">Load</button>
            </div>
        </div>
    </div>
    
    <script>
        function loadTemplate(name) {
            alert('Loading template: ' + name);
            // Would load template
        }
    </script>
</body>
</html>
EOF

    echo "Template browser created"
}

main() {
    local action="${1:-help}"
    
    case "$action" in
        --create)
            create_all_templates
            ;;
        --list)
            list_templates
            ;;
        --export)
            export_template "${2:-studio}" "${3:-}"
            ;;
        --browser)
            generate_template_browser
            ;;
        *)
            echo "REAPER OS Professional Templates"
            echo "Usage: professional-templates.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --create      Create all templates"
            echo "  --list        List available templates"
            echo "  --export NAME Export a template"
            echo "  --browser     Generate template browser"
            ;;
    esac
}

main "$@"
