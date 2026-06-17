#!/bin/bash

################################################################################
# REAPER OS Installation Validation Script
# Tests installation integrity and functionality
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[TEST]${NC} $1"; }
log_success() { echo -e "${GREEN}✓${NC} $1"; }
log_warn() { echo -e "${YELLOW}⚠${NC} $1"; }
log_error() { echo -e "${RED}✗${NC} $1"; }

FAILED_TESTS=0
PASSED_TESTS=0
TOTAL_TESTS=0

# ==============================================================================
# TEST HELPERS
# ==============================================================================

test_start() {
    local test_name="$1"
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Testing:${NC} $test_name"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    ((TOTAL_TESTS++))
}

test_pass() {
    local msg="$1"
    log_success "$msg"
    ((PASSED_TESTS++))
}

test_fail() {
    local msg="$1"
    log_error "$msg"
    ((FAILED_TESTS++))
}

# ==============================================================================
# 1. ENVIRONMENT TESTS
# ==============================================================================

test_environment() {
    test_start "System Environment"
    
    # Check OS
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        log_info "Detected: $PRETTY_NAME"
        test_pass "Linux environment detected"
    else
        test_fail "Not a Linux system"
    fi
    
    # Check CPU
    if [ -f /proc/cpuinfo ]; then
        cpu_count=$(grep -c "^processor" /proc/cpuinfo || echo 1)
        log_info "CPUs: $cpu_count"
        test_pass "CPU info available"
    fi
    
    # Check memory
    if [ -f /proc/meminfo ]; then
        mem_total=$(grep MemTotal /proc/meminfo | awk '{print int($2/1024/1024) "GB"}')
        log_info "Memory: $mem_total"
        test_pass "Memory info available"
    fi
    
    # Check disk space
    if command -v df &> /dev/null; then
        root_space=$(df -h / | tail -1 | awk '{print $4}')
        log_info "Root space available: $root_space"
        test_pass "Disk space available"
    fi
}

# ==============================================================================
# 2. PROJECT STRUCTURE TESTS
# ==============================================================================

test_project_structure() {
    test_start "Project Structure"
    
    required_dirs=(
        "scripts"
        "config"
        "docs"
        "reaper-config"
        "tools"
        "wine-config"
    )
    
    for dir in "${required_dirs[@]}"; do
        if [ -d "$dir" ]; then
            test_pass "Directory exists: $dir"
        else
            test_fail "Missing directory: $dir"
        fi
    done
    
    required_files=(
        "README.md"
        "GETTING-STARTED.md"
    )
    
    for file in "${required_files[@]}"; do
        if [ -f "$file" ]; then
            test_pass "File exists: $file"
        else
            test_fail "Missing file: $file"
        fi
    done
}

# ==============================================================================
# 3. SCRIPT VALIDATION TESTS
# ==============================================================================

test_script_validation() {
    test_start "Script Validation"
    
    # Check bash syntax
    log_info "Checking bash syntax..."
    
    shell_scripts=0
    syntax_errors=0
    
    while IFS= read -r script; do
        ((shell_scripts++)) || true
        if bash -n "$script" 2>/dev/null; then
            echo "✓ $(basename "$script")"
        else
            echo "✗ $(basename "$script") - SYNTAX ERROR"
            ((syntax_errors++)) || true
        fi
    done < <(find . -name "*.sh" -type f)
    
    if [ "$syntax_errors" -eq 0 ]; then
        test_pass "All $shell_scripts scripts have valid syntax"
    else
        test_fail "$syntax_errors/$shell_scripts scripts have syntax errors"
    fi
}

# ==============================================================================
# 4. DEPENDENCY TESTS
# ==============================================================================

test_dependencies() {
    test_start "System Dependencies"
    
    # Critical dependencies
    critical_deps=(
        "bash"
        "grep"
        "sed"
        "awk"
    )
    
    for dep in "${critical_deps[@]}"; do
        if command -v "$dep" &> /dev/null; then
            test_pass "Critical: $dep installed"
        else
            test_fail "CRITICAL: $dep not found"
        fi
    done
    
    # Audio dependencies
    audio_deps=(
        "aplay"
        "arecord"
        "jackd"
        "alsamixer"
    )
    
    for dep in "${audio_deps[@]}"; do
        if command -v "$dep" &> /dev/null; then
            test_pass "Audio: $dep installed"
        else
            log_warn "Audio: $dep not installed (optional)"
        fi
    done
    
    # Wine/VST dependencies
    vst_deps=(
        "wine"
        "winetricks"
    )
    
    for dep in "${vst_deps[@]}"; do
        if command -v "$dep" &> /dev/null; then
            test_pass "VST: $dep installed"
        else
            log_warn "VST: $dep not installed (optional)"
        fi
    done
}

# ==============================================================================
# 5. CONFIGURATION TESTS
# ==============================================================================

test_configurations() {
    test_start "Configuration Files"
    
    # Check ALSA config
    if [ -f "config/asoundrc.template" ]; then
        test_pass "ALSA template found"
        
        if grep -q "pcm\|ctl" config/asoundrc.template; then
            test_pass "ALSA configuration appears valid"
        else
            test_fail "ALSA configuration may be incomplete"
        fi
    else
        test_fail "ALSA template missing"
    fi
    
    # Check REAPER config
    if [ -f "reaper-config/README.md" ]; then
        test_pass "REAPER config documentation found"
    fi
    
    # Check control protocol setup
    if [ -f "reaper-config/control-protocols-setup.sh" ]; then
        test_pass "Control protocol setup script found"
    else
        test_fail "Control protocol setup missing"
    fi
}

# ==============================================================================
# 6. TOOLS TESTS
# ==============================================================================

test_tools() {
    test_start "Tools Functionality"
    
    tools=(
        "tools/reaper-diagnostics.sh"
        "tools/audio-config-manager.sh"
        "tools/test-controllers.sh"
        "tools/install-tools.sh"
    )
    
    for tool in "${tools[@]}"; do
        if [ -f "$tool" ]; then
            test_pass "Tool exists: $(basename $tool)"
            
            # Check if executable or shell script
            if [ -x "$tool" ] || grep -q "#!/bin/bash\|#!/bin/sh" "$tool"; then
                test_pass "Tool is executable: $(basename $tool)"
            else
                log_warn "Tool may need chmod +x: $(basename $tool)"
            fi
            
            # Check for help text
            if grep -q "help\|--help\|-h" "$tool"; then
                test_pass "Tool has help documentation: $(basename $tool)"
            else
                log_warn "Tool missing help text: $(basename $tool)"
            fi
        else
            test_fail "Tool missing: $tool"
        fi
    done
}

# ==============================================================================
# 7. DOCUMENTATION TESTS
# ==============================================================================

test_documentation() {
    test_start "Documentation"
    
    doc_files=(
        "README.md"
        "GETTING-STARTED.md"
        "docs/AUDIO-INTERFACE-SUPPORT.md"
        "docs/CONTROL-PROTOCOLS.md"
        "tools/README.md"
    )
    
    for doc in "${doc_files[@]}"; do
        if [ -f "$doc" ]; then
            size=$(stat -f%z "$doc" 2>/dev/null || stat -c%s "$doc" 2>/dev/null || echo 0)
            if [ "$size" -gt 100 ]; then
                test_pass "Documentation complete: $doc ($size bytes)"
            else
                test_fail "Documentation too small: $doc"
            fi
        else
            test_fail "Documentation missing: $doc"
        fi
    done
}

# ==============================================================================
# 8. AUDIO SYSTEM TESTS
# ==============================================================================

test_audio_system() {
    test_start "Audio System"
    
    # Check ALSA
    if command -v aplay &> /dev/null; then
        test_pass "ALSA tools available"
        
        if aplay -l &> /dev/null; then
            card_count=$(aplay -l 2>/dev/null | grep -c "^card" || echo 0)
            log_info "Audio cards detected: $card_count"
            
            if [ "$card_count" -gt 0 ]; then
                test_pass "Audio card(s) detected"
            else
                log_warn "No audio cards detected (may be normal on VM)"
            fi
        fi
    else
        log_warn "ALSA tools not available"
    fi
    
    # Check JACK
    if command -v jackd &> /dev/null; then
        test_pass "JACK installed"
        
        # Try to check JACK status (may fail if not running)
        if jack_lsp &> /dev/null; then
            test_pass "JACK is running"
        else
            log_warn "JACK not currently running (normal)"
        fi
    else
        log_warn "JACK not installed"
    fi
}

# ==============================================================================
# 9. WINE/VST TESTS
# ==============================================================================

test_wine_vst() {
    test_start "Wine/VST Support"
    
    # Check Wine
    if command -v wine &> /dev/null; then
        test_pass "Wine installed"
        
        wine_version=$(wine --version 2>/dev/null || echo "unknown")
        log_info "Wine version: $wine_version"
    else
        log_warn "Wine not installed (needed for VST support)"
    fi
    
    # Check winetricks
    if command -v winetricks &> /dev/null; then
        test_pass "Winetricks installed"
    else
        log_warn "Winetricks not installed (needed for dependencies)"
    fi
    
    # Check Wine prefix
    if [ -d "$HOME/.wine" ]; then
        test_pass "Wine prefix exists"
    else
        log_warn "Wine prefix not initialized"
    fi
}

# ==============================================================================
# 10. REAPER TESTS
# ==============================================================================

test_reaper() {
    test_start "REAPER DAW"
    
    # Check if REAPER config structure exists
    if [ -d "$HOME/.config/REAPER" ] || [ -f "$HOME/.wine/drive_c/Program Files/REAPER/reaper.exe" ]; then
        test_pass "REAPER appears to be installed"
    else
        log_warn "REAPER not yet installed (normal on fresh system)"
    fi
    
    # Check reaper.ini
    if [ -f "$HOME/.config/REAPER/reaper.ini" ]; then
        test_pass "REAPER configuration found"
    else
        log_warn "REAPER not yet configured (normal)"
    fi
}

# ==============================================================================
# 11. INTEGRATION TESTS
# ==============================================================================

test_integration() {
    test_start "System Integration"
    
    # Check if audio config manager can be sourced
    if bash -n tools/audio-config-manager.sh &> /dev/null; then
        test_pass "Audio manager script is valid bash"
    else
        test_fail "Audio manager script has errors"
    fi
    
    # Check if boot script exists and is valid
    if [ -f "scripts/reaper-os-first-boot.sh" ]; then
        test_pass "First boot script found"
        
        if bash -n "scripts/reaper-os-first-boot.sh" &> /dev/null; then
            test_pass "First boot script syntax valid"
        else
            test_fail "First boot script has syntax errors"
        fi
    fi
}

# ==============================================================================
# MAIN TEST SUITE
# ==============================================================================

main() {
    clear
    
    echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}  REAPER OS Installation Validation Test Suite        ${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Run all tests
    test_environment
    test_project_structure
    test_script_validation
    test_dependencies
    test_configurations
    test_tools
    test_documentation
    test_audio_system
    test_wine_vst
    test_reaper
    test_integration
    
    # Print summary
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}  TEST SUMMARY                                        ${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${GREEN}Passed:${NC} $PASSED_TESTS / $TOTAL_TESTS"
    echo -e "${RED}Failed:${NC} $FAILED_TESTS / $TOTAL_TESTS"
    
    if [ $FAILED_TESTS -eq 0 ]; then
        echo ""
        echo -e "${GREEN}✓ ALL TESTS PASSED!${NC}"
        echo ""
        echo "System is ready for REAPER OS installation."
        exit 0
    else
        echo ""
        echo -e "${YELLOW}⚠ SOME TESTS FAILED${NC}"
        echo ""
        echo "Check the errors above and address any critical failures."
        exit 1
    fi
}

main "$@"
