#!/bin/bash

################################################################################
# Install REAPER OS Tools
# Installs custom tools to system PATH
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TOOLS_DIR="$PROJECT_ROOT/tools"

# Installation paths
BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"

log_info() { echo "[INSTALL] $1"; }
log_success() { echo "✓ $1"; }

log_info "Installing REAPER OS Tools..."
echo ""

# 1. Install reaper-diagnostics
if [ -f "$TOOLS_DIR/reaper-diagnostics.sh" ]; then
    cp "$TOOLS_DIR/reaper-diagnostics.sh" "$BIN_DIR/reaper-diagnostics"
    chmod +x "$BIN_DIR/reaper-diagnostics"
    log_success "reaper-diagnostics installed"
else
    echo "⚠ reaper-diagnostics.sh not found"
fi

# 2. Install audio-config-manager
if [ -f "$TOOLS_DIR/audio-config-manager.sh" ]; then
    cp "$TOOLS_DIR/audio-config-manager.sh" "$BIN_DIR/audio-config-manager"
    chmod +x "$BIN_DIR/audio-config-manager"
    log_success "audio-config-manager installed"
else
    echo "⚠ audio-config-manager.sh not found"
fi

# 3. Install test-controllers
if [ -f "$TOOLS_DIR/test-controllers.sh" ]; then
    cp "$TOOLS_DIR/test-controllers.sh" "$BIN_DIR/test-controllers"
    chmod +x "$BIN_DIR/test-controllers"
    log_success "test-controllers installed"
else
    echo "⚠ test-controllers.sh not found"
fi

echo ""

# Check if PATH includes $BIN_DIR
if [[ ":$PATH:" == *":$BIN_DIR:"* ]]; then
    log_success "$BIN_DIR is in PATH"
else
    log_info "Adding $BIN_DIR to PATH"
    
    # Add to .bashrc if not already there
    if ! grep -q "$BIN_DIR" "$HOME/.bashrc" 2>/dev/null; then
        echo "" >> "$HOME/.bashrc"
        echo "# Add REAPER OS tools to PATH" >> "$HOME/.bashrc"
        echo "export PATH=\"$BIN_DIR:\$PATH\"" >> "$HOME/.bashrc"
        log_success "Added to ~/.bashrc"
    fi
    
    # Add to .profile if not already there
    if ! grep -q "$BIN_DIR" "$HOME/.profile" 2>/dev/null; then
        echo "" >> "$HOME/.profile"
        echo "# Add REAPER OS tools to PATH" >> "$HOME/.profile"
        echo "export PATH=\"$BIN_DIR:\$PATH\"" >> "$HOME/.profile"
        log_success "Added to ~/.profile"
    fi
    
    # Export for current session
    export PATH="$BIN_DIR:$PATH"
fi

echo ""
echo "╔════════════════════════════════════════╗"
echo "║ Tools Installed Successfully! ✓        ║"
echo "╚════════════════════════════════════════╝"
echo ""

echo "Available commands:"
echo "  • reaper-diagnostics     - System monitoring & diagnostics"
echo "  • audio-config-manager   - Audio profile manager"
echo "  • test-controllers       - Control protocol tester"
echo ""

echo "Usage:"
echo "  reaper-diagnostics --help"
echo "  audio-config-manager --help"
echo "  test-controllers --help"
echo ""

log_success "Installation complete!"
