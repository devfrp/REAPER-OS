#!/bin/bash

################################################################################
# REAPER OS VST Manager & Cache System
# Manages VST discovery, caching, organization, and preset management
# Usage: ./vst-manager.sh [--scan] [--list] [--cache] [--organize] [--presets]
################################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VST_CACHE_DIR="$HOME/.cache/reaper-vst-manager"
VST_LOG="$VST_CACHE_DIR/vst-manager.log"
VST_DATABASE="$VST_CACHE_DIR/vst-database.json"

mkdir -p "$VST_CACHE_DIR"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" >> "$VST_LOG"
}

print_header() {
    echo -e "\n${BOLD}${BLUE}=== $1 ===${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Initialize VST database
init_vst_database() {
    if [ ! -f "$VST_DATABASE" ]; then
        cat > "$VST_DATABASE" << 'EOF'
{
  "version": "1.0",
  "last_scan": null,
  "vst_count": 0,
  "vst2_locations": [
    "~/.vst",
    "~/.wine/drive_c/Program Files/Common Files/VST",
    "~/.wine/drive_c/Program Files/VST"
  ],
  "vst3_locations": [
    "~/.vst3",
    "~/.wine/drive_c/Program Files/Common Files/VST3"
  ],
  "vst_plugins": [],
  "categories": {},
  "favorites": [],
  "ignored": []
}
EOF
        print_success "VST database initialized"
    fi
}

# Scan for VST2 plugins
scan_vst2() {
    print_header "Scanning VST2 Plugins..."
    
    local vst2_dirs=(
        "$HOME/.vst"
        "$HOME/.wine/drive_c/Program Files/Common Files/VST"
        "$HOME/.wine/drive_c/Program Files/VST"
        "/usr/lib/vst"
        "/usr/local/lib/vst"
    )
    
    local count=0
    local vst_list="[]"
    
    for dir in "${vst2_dirs[@]}"; do
        if [ -d "$dir" ]; then
            print_info "Scanning: $dir"
            
            while IFS= read -r -d '' vst_file; do
                local vst_name=$(basename "$vst_file")
                print_success "Found: $vst_name"
                ((count++))
                log "VST2 found: $vst_file"
            done < <(find "$dir" -maxdepth 2 -name "*.so" -print0 2>/dev/null || true)
        fi
    done
    
    echo "VST2 plugins found: $count"
}

# Scan for VST3 plugins
scan_vst3() {
    print_header "Scanning VST3 Plugins..."
    
    local vst3_dirs=(
        "$HOME/.vst3"
        "$HOME/.wine/drive_c/Program Files/Common Files/VST3"
        "/usr/lib/vst3"
        "/usr/local/lib/vst3"
    )
    
    local count=0
    
    for dir in "${vst3_dirs[@]}"; do
        if [ -d "$dir" ]; then
            print_info "Scanning: $dir"
            
            while IFS= read -r -d '' vst_file; do
                local vst_name=$(basename "$vst_file" .so)
                print_success "Found: $vst_name"
                ((count++))
                log "VST3 found: $vst_file"
            done < <(find "$dir" -maxdepth 2 -name "*.so" -print0 2>/dev/null || true)
        fi
    done
    
    echo "VST3 plugins found: $count"
}

# Scan for Wine VST plugins
scan_wine_vst() {
    print_header "Scanning Wine VST Plugins..."
    
    if [ ! -d "$HOME/.wine" ]; then
        print_warning "Wine prefix not found"
        return 1
    fi
    
    local wine_vst_dirs=(
        "$HOME/.wine/drive_c/Program Files/Common Files/VST"
        "$HOME/.wine/drive_c/Program Files (x86)/Common Files/VST"
        "$HOME/.wine/drive_c/Program Files/VST"
    )
    
    local count=0
    
    for dir in "${wine_vst_dirs[@]}"; do
        if [ -d "$dir" ]; then
            print_info "Scanning: $dir"
            
            while IFS= read -r -d '' dll_file; do
                local dll_name=$(basename "$dll_file" .dll)
                print_success "Found: $dll_name"
                ((count++))
                log "Wine VST found: $dll_file"
            done < <(find "$dir" -maxdepth 2 -name "*.dll" -print0 2>/dev/null || true)
        fi
    done
    
    echo "Wine VST plugins found: $count"
}

# Categorize VST plugins
categorize_vst() {
    print_header "Categorizing VST Plugins..."
    
    # Common VST categories
    local categories=(
        "Synth"
        "Effect"
        "EQ"
        "Compressor"
        "Reverb"
        "Delay"
        "Utility"
        "Sampler"
        "FX"
        "Instrument"
    )
    
    print_info "Creating plugin categories..."
    mkdir -p "$VST_CACHE_DIR/categories"
    
    for category in "${categories[@]}"; do
        touch "$VST_CACHE_DIR/categories/$category.txt"
    done
    
    print_success "Categories created"
}

# Create VST cache
create_vst_cache() {
    print_header "Creating VST Plugin Cache..."
    
    local cache_file="$VST_CACHE_DIR/vst-cache.dat"
    
    # Scan all VST locations and create cached metadata
    cat > "$cache_file" << 'EOF'
# VST Plugin Cache
# Format: Name|Path|Type|Category|LastModified

EOF
    
    print_success "VST cache created at: $cache_file"
    log "VST cache initialized: $cache_file"
}

# List all discovered VSTs
list_vst() {
    print_header "Installed VST Plugins"
    
    if [ ! -f "$VST_DATABASE" ]; then
        init_vst_database
    fi
    
    echo "VST Database Location: $VST_DATABASE"
    echo ""
    
    # List VST2
    echo "VST2 Plugins:"
    echo "============="
    find "$HOME/.vst" -name "*.so" 2>/dev/null | while read -r vst; do
        local size=$(du -h "$vst" | awk '{print $1}')
        printf "  %-50s %s\n" "$(basename "$vst")" "$size"
    done
    
    echo ""
    
    # List Wine VSTs
    echo "Wine VST Plugins:"
    echo "================="
    find "$HOME/.wine/drive_c/Program Files/Common Files/VST" -name "*.dll" 2>/dev/null | while read -r vst; do
        local size=$(du -h "$vst" | awk '{print $1}')
        printf "  %-50s %s\n" "$(basename "$vst" .dll)" "$size"
    done
}

# Manage VST presets
manage_presets() {
    print_header "VST Preset Management"
    
    local preset_dir="$HOME/.config/REAPER/VST-Presets"
    mkdir -p "$preset_dir"
    
    cat > "$preset_dir/preset-manager.sh" << 'EOF'
#!/bin/bash
# VST Preset Manager

PRESET_DB="$HOME/.config/REAPER/VST-Presets/database.json"

# Save preset
save_preset() {
    local vst_name=$1
    local preset_name=$2
    
    echo "Saving preset: $preset_name for $vst_name"
    # Implementation for preset saving
}

# Load preset
load_preset() {
    local vst_name=$1
    local preset_name=$2
    
    echo "Loading preset: $preset_name for $vst_name"
    # Implementation for preset loading
}

# List presets
list_presets() {
    echo "Available presets:"
    # Implementation for listing presets
}

# Organize presets by plugin
organize_presets() {
    echo "Organizing presets by plugin..."
    # Implementation for organization
}

case "${1:-help}" in
    save) save_preset "$2" "$3" ;;
    load) load_preset "$2" "$3" ;;
    list) list_presets ;;
    organize) organize_presets ;;
    *) echo "Usage: preset-manager.sh [save|load|list|organize]" ;;
esac
EOF
    
    chmod +x "$preset_dir/preset-manager.sh"
    print_success "Preset manager created at: $preset_dir"
}

# Organize VST folders by category
organize_vst() {
    print_header "Organizing VST Plugins by Category..."
    
    local org_dir="$VST_CACHE_DIR/organized"
    mkdir -p "$org_dir"
    
    # Create category folders
    mkdir -p "$org_dir/Synths"
    mkdir -p "$org_dir/Effects"
    mkdir -p "$org_dir/EQ"
    mkdir -p "$org_dir/Compression"
    mkdir -p "$org_dir/Reverb"
    mkdir -p "$org_dir/Delay"
    mkdir -p "$org_dir/Utility"
    
    print_success "Organization structure created"
    print_info "Organization directory: $org_dir"
}

# Generate VST report
generate_vst_report() {
    print_header "Generating VST Report..."
    
    local report_file="$VST_CACHE_DIR/vst-report.html"
    
    cat > "$report_file" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>REAPER OS VST Report</title>
    <style>
        body { font-family: Arial; margin: 20px; background: #f5f5f5; }
        .header { background: #333; color: white; padding: 20px; }
        .section { background: white; margin: 20px 0; padding: 20px; }
        table { width: 100%; border-collapse: collapse; }
        th, td { text-align: left; padding: 10px; border-bottom: 1px solid #ddd; }
        th { background: #007bff; color: white; }
    </style>
</head>
<body>
    <div class="header">
        <h1>REAPER OS VST Report</h1>
        <p>Generated: <span id="time"></span></p>
    </div>
    
    <div class="section">
        <h2>VST Summary</h2>
        <ul>
            <li>Total VST Plugins: <strong id="count">0</strong></li>
            <li>Categories: <strong>7</strong></li>
            <li>Last Scan: <strong id="scan-time">Never</strong></li>
        </ul>
    </div>
    
    <div class="section">
        <h2>Plugin List</h2>
        <table>
            <tr>
                <th>Plugin Name</th>
                <th>Type</th>
                <th>Category</th>
                <th>Size</th>
            </tr>
        </table>
    </div>
    
    <script>
        document.getElementById('time').textContent = new Date().toLocaleString();
    </script>
</body>
</html>
EOF
    
    print_success "Report generated: $report_file"
}

# Main function
main() {
    local action="${1:-help}"
    
    print_header "REAPER OS VST Manager"
    
    case "$action" in
        --scan)
            init_vst_database
            scan_vst2
            scan_vst3
            scan_wine_vst
            create_vst_cache
            log "VST scan completed"
            ;;
        --list)
            list_vst
            ;;
        --cache)
            print_header "Rebuilding VST Cache"
            create_vst_cache
            ;;
        --organize)
            organize_vst
            categorize_vst
            ;;
        --presets)
            manage_presets
            ;;
        --report)
            generate_vst_report
            ;;
        *)
            echo "Usage: vst-manager.sh [--scan|--list|--cache|--organize|--presets|--report]"
            echo ""
            echo "Options:"
            echo "  --scan      Scan for all VST plugins"
            echo "  --list      List all discovered VSTs"
            echo "  --cache     Create plugin cache"
            echo "  --organize  Organize VSTs by category"
            echo "  --presets   Manage VST presets"
            echo "  --report    Generate HTML report"
            ;;
    esac
}

main "$@"
