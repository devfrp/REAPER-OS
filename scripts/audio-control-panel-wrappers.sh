#!/bin/bash

################################################################################
# Audio Interface Wine Wrapper Generator
# Automatically creates Wine wrappers for Control Panels
################################################################################

set -e

WINE_PREFIX="${WINE_PREFIX:-$HOME/.wine}"
WINEARCH="${WINEARCH:-win64}"
BIN_DIR="$HOME/.local/bin"
DESKTOP_DIR="$HOME/.local/share/applications"
CONFIG_DIR="$HOME/.config/audio-interfaces"

mkdir -p "$BIN_DIR" "$DESKTOP_DIR" "$CONFIG_DIR"

log_info() { echo "[AUDIO] $1"; }
log_err() { echo "[ERROR] $1"; exit 1; }

# ==============================================================================
# RME Control Panel Wrapper
# ==============================================================================

setup_rme_control_panel() {
    log_info "Setup RME Control Panel wrapper..."
    
    # Installer dépendances Wine
    winetricks vcrun2019 dotnet48 2>/dev/null || true
    
    # Launcher script
    cat > "$BIN_DIR/rme-control-panel" << 'LAUNCHER'
#!/bin/bash
export WINE_PREFIX="${WINE_PREFIX:-$HOME/.wine}"
export WINEARCH=win64

# Chemins possibles pour RME Control Panel
RME_PATHS=(
    "$WINE_PREFIX/drive_c/Program Files/RME/RME Control Panel/rme-control-panel.exe"
    "$WINE_PREFIX/drive_c/Program Files (x86)/RME/Control Panel/Control Panel.exe"
    "$WINE_PREFIX/drive_c/Program Files/RME/Control Panel/Control Panel.exe"
)

for exe in "${RME_PATHS[@]}"; do
    if [ -f "$exe" ]; then
        echo "🎛️ Launching RME Control Panel..."
        wine "$exe" &
        exit 0
    fi
done

echo "❌ RME Control Panel not found"
echo "Install RME Control Panel Windows version:"
echo "1. Download from RME website"
echo "2. Copy installer to: $WINE_PREFIX/drive_c/"
echo "3. Run: wine $WINE_PREFIX/drive_c/RME-Control-Panel-Setup.exe"
exit 1
LAUNCHER
    
    chmod +x "$BIN_DIR/rme-control-panel"
    
    # Desktop entry
    cat > "$DESKTOP_DIR/rme-control-panel.desktop" << 'DESKTOP'
[Desktop Entry]
Type=Application
Name=RME Control Panel
Comment=RME Audio Interface Control Panel
Exec=rme-control-panel
Icon=audio-card
Categories=Multimedia;Audio;
Terminal=false
DESKTOP
    
    log_info "✅ RME Control Panel wrapper created"
}

# ==============================================================================
# Universal Audio Console Wrapper
# ==============================================================================

setup_uad_console() {
    log_info "Setup Universal Audio Console wrapper..."
    
    # Installer dépendances
    winetricks vcrun2019 dotnet48 d3dx11 2>/dev/null || true
    
    # Launcher script
    cat > "$BIN_DIR/uad-console" << 'LAUNCHER'
#!/bin/bash
export WINE_PREFIX="${WINE_PREFIX:-$HOME/.wine}"
export WINEARCH=win64
export DXVK_ASYNC=1

# Chemins possibles
UAD_PATHS=(
    "$WINE_PREFIX/drive_c/Program Files/Universal Audio/UAD Console/uad-console.exe"
    "$WINE_PREFIX/drive_c/Program Files (x86)/Universal Audio/Console/uad.exe"
)

for exe in "${UAD_PATHS[@]}"; do
    if [ -f "$exe" ]; then
        echo "🎛️ Launching UAD Console..."
        wine "$exe" &
        exit 0
    fi
done

echo "❌ UAD Console not found"
echo "Install from Windows: Universal Audio Console installer"
exit 1
LAUNCHER
    
    chmod +x "$BIN_DIR/uad-console"
    
    cat > "$DESKTOP_DIR/uad-console.desktop" << 'DESKTOP'
[Desktop Entry]
Type=Application
Name=UAD Console
Comment=Universal Audio Interface Control
Exec=uad-console
Icon=audio-card
Categories=Multimedia;Audio;
Terminal=false
DESKTOP
    
    log_info "✅ UAD Console wrapper created"
}

# ==============================================================================
# Focusrite Control Wrapper
# ==============================================================================

setup_focusrite_control() {
    log_info "Setup Focusrite Control wrapper..."
    
    winetricks vcrun2019 2>/dev/null || true
    
    cat > "$BIN_DIR/focusrite-control" << 'LAUNCHER'
#!/bin/bash
export WINE_PREFIX="${WINE_PREFIX:-$HOME/.wine}"
export WINEARCH=win64

FOCUSRITE_PATHS=(
    "$WINE_PREFIX/drive_c/Program Files/Focusrite/Focusrite Control/focusrite-control.exe"
    "$WINE_PREFIX/drive_c/Program Files (x86)/Focusrite/Control/Focusrite Control.exe"
)

for exe in "${FOCUSRITE_PATHS[@]}"; do
    if [ -f "$exe" ]; then
        echo "🎛️ Launching Focusrite Control..."
        wine "$exe" &
        exit 0
    fi
done

echo "❌ Focusrite Control not found"
exit 1
LAUNCHER
    
    chmod +x "$BIN_DIR/focusrite-control"
    
    cat > "$DESKTOP_DIR/focusrite-control.desktop" << 'DESKTOP'
[Desktop Entry]
Type=Application
Name=Focusrite Control
Comment=Focusrite Audio Interface Control
Exec=focusrite-control
Icon=audio-card
Categories=Multimedia;Audio;
Terminal=false
DESKTOP
    
    log_info "✅ Focusrite Control wrapper created"
}

# ==============================================================================
# Presonus Studio One Control Wrapper
# ==============================================================================

setup_presonus_control() {
    log_info "Setup Presonus Control wrapper..."
    
    winetricks vcrun2019 2>/dev/null || true
    
    cat > "$BIN_DIR/presonus-control" << 'LAUNCHER'
#!/bin/bash
export WINE_PREFIX="${WINE_PREFIX:-$HOME/.wine}"
export WINEARCH=win64

PRESONUS_PATHS=(
    "$WINE_PREFIX/drive_c/Program Files/PreSonus/StudioLive Control/StudioLiveControl.exe"
    "$WINE_PREFIX/drive_c/Program Files (x86)/PreSonus/AudioBox Control/AudioBoxControl.exe"
)

for exe in "${PRESONUS_PATHS[@]}"; do
    if [ -f "$exe" ]; then
        echo "🎛️ Launching Presonus Control..."
        wine "$exe" &
        exit 0
    fi
done

echo "❌ Presonus Control not found"
exit 1
LAUNCHER
    
    chmod +x "$BIN_DIR/presonus-control"
    
    cat > "$DESKTOP_DIR/presonus-control.desktop" << 'DESKTOP'
[Desktop Entry]
Type=Application
Name=Presonus Control
Comment=Presonus Audio Interface Control
Exec=presonus-control
Icon=audio-card
Categories=Multimedia;Audio;
Terminal=false
DESKTOP
    
    log_info "✅ Presonus Control wrapper created"
}

# ==============================================================================
# Behringer Control Wrapper
# ==============================================================================

setup_behringer_control() {
    log_info "Setup Behringer Control wrapper..."
    
    winetricks vcrun2019 2>/dev/null || true
    
    cat > "$BIN_DIR/behringer-control" << 'LAUNCHER'
#!/bin/bash
export WINE_PREFIX="${WINE_PREFIX:-$HOME/.wine}"
export WINEARCH=win64

BEHRINGER_PATHS=(
    "$WINE_PREFIX/drive_c/Program Files/Behringer/X32 Control/x32control.exe"
    "$WINE_PREFIX/drive_c/Program Files (x86)/Behringer/Control/behringer-control.exe"
)

for exe in "${BEHRINGER_PATHS[@]}"; do
    if [ -f "$exe" ]; then
        echo "🎛️ Launching Behringer Control..."
        wine "$exe" &
        exit 0
    fi
done

echo "❌ Behringer Control not found"
exit 1
LAUNCHER
    
    chmod +x "$BIN_DIR/behringer-control"
    
    cat > "$DESKTOP_DIR/behringer-control.desktop" << 'DESKTOP'
[Desktop Entry]
Type=Application
Name=Behringer Control
Comment=Behringer Audio Interface Control
Exec=behringer-control
Icon=audio-card
Categories=Multimedia;Audio;
Terminal=false
DESKTOP
    
    log_info "✅ Behringer Control wrapper created"
}

# ==============================================================================
# MOTU Control Panel Wrapper
# ==============================================================================

setup_motu_control() {
    log_info "Setup MOTU Control wrapper..."
    
    winetricks vcrun2019 2>/dev/null || true
    
    cat > "$BIN_DIR/motu-control" << 'LAUNCHER'
#!/bin/bash
export WINE_PREFIX="${WINE_PREFIX:-$HOME/.wine}"
export WINEARCH=win64

MOTU_PATHS=(
    "$WINE_PREFIX/drive_c/Program Files/MOTU/Audio Control/motucontrol.exe"
    "$WINE_PREFIX/drive_c/Program Files (x86)/MOTU/Control/motu-control.exe"
)

for exe in "${MOTU_PATHS[@]}"; do
    if [ -f "$exe" ]; then
        echo "🎛️ Launching MOTU Control..."
        wine "$exe" &
        exit 0
    fi
done

echo "❌ MOTU Control not found"
exit 1
LAUNCHER
    
    chmod +x "$BIN_DIR/motu-control"
    
    cat > "$DESKTOP_DIR/motu-control.desktop" << 'DESKTOP'
[Desktop Entry]
Type=Application
Name=MOTU Control
Comment=MOTU Audio Interface Control
Exec=motu-control
Icon=audio-card
Categories=Multimedia;Audio;
Terminal=false
DESKTOP
    
    log_info "✅ MOTU Control wrapper created"
}

# ==============================================================================
# Native Instruments Traktor Wrapper
# ==============================================================================

setup_native_instruments_control() {
    log_info "Setup Native Instruments Control wrapper..."
    
    winetricks vcrun2019 2>/dev/null || true
    
    cat > "$BIN_DIR/native-instruments-control" << 'LAUNCHER'
#!/bin/bash
export WINE_PREFIX="${WINE_PREFIX:-$HOME/.wine}"
export WINEARCH=win64

NI_PATHS=(
    "$WINE_PREFIX/drive_c/Program Files/Native Instruments/Traktor/Traktor.exe"
    "$WINE_PREFIX/drive_c/Program Files/Native Instruments/Komplete/Komplete.exe"
)

for exe in "${NI_PATHS[@]}"; do
    if [ -f "$exe" ]; then
        echo "🎛️ Launching Native Instruments Control..."
        wine "$exe" &
        exit 0
    fi
done

echo "❌ Native Instruments Control not found"
exit 1
LAUNCHER
    
    chmod +x "$BIN_DIR/native-instruments-control"
    
    log_info "✅ Native Instruments Control wrapper created"
}

# ==============================================================================
# Test Wine Setup
# ==============================================================================

test_wine_setup() {
    log_info "Testing Wine environment..."
    
    if ! command -v wine &> /dev/null; then
        log_err "Wine not found! Install Wine first"
    fi
    
    log_info "Wine version: $(wine --version)"
    log_info "WINE_PREFIX: $WINE_PREFIX"
    log_info "WINEARCH: $WINEARCH"
    log_info "✅ Wine environment OK"
}

# ==============================================================================
# MAIN
# ==============================================================================

main() {
    echo "╔════════════════════════════════════════╗"
    echo "║ Audio Control Panel Wine Wrappers      ║"
    echo "╚════════════════════════════════════════╝"
    echo ""
    
    # Test Wine setup
    test_wine_setup
    echo ""
    
    # Create all wrappers
    log_info "Creating Wine wrappers for all interfaces..."
    echo ""
    
    setup_rme_control_panel
    setup_uad_console
    setup_focusrite_control
    setup_presonus_control
    setup_behringer_control
    setup_motu_control
    setup_native_instruments_control
    
    echo ""
    echo "╔════════════════════════════════════════╗"
    echo "║ ✅ All wrappers created!               ║"
    echo "╚════════════════════════════════════════╝"
    echo ""
    
    log_info "Available commands:"
    log_info "  rme-control-panel"
    log_info "  uad-console"
    log_info "  focusrite-control"
    log_info "  presonus-control"
    log_info "  behringer-control"
    log_info "  motu-control"
    log_info "  native-instruments-control"
    echo ""
    
    log_info "To install a Control Panel:"
    log_info "1. Download Windows installer (.exe)"
    log_info "2. Copy to: $WINE_PREFIX/drive_c/"
    log_info "3. Run: wine $WINE_PREFIX/drive_c/installer.exe"
    log_info "4. Use the command above to launch"
}

main "$@"
