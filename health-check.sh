#!/bin/bash
# REAPER OS Health Check - v1.0.0
# Verifies installation health and provides diagnostics

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
TOTAL=0
PASSED=0
FAILED=0
WARNINGS=0

# Functions
print_header() {
    echo -e "\n${BLUE}=== $1 ===${NC}\n"
}

print_pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((PASSED++))
    ((TOTAL++))
}

print_fail() {
    echo -e "${RED}✗${NC} $1"
    ((FAILED++))
    ((TOTAL++))
}

print_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((WARNINGS++))
}

print_info() {
    echo "  ℹ $1"
}

# Main checks
print_header "REAPER OS Health Check"

# System Information
print_header "System Information"
print_info "OS: $(lsb_release -d 2>/dev/null | cut -f2 || echo 'Unknown')"
print_info "Kernel: $(uname -r)"
print_info "Architecture: $(uname -m)"
print_info "CPU Cores: $(nproc)"
print_info "Total RAM: $(free -h | awk '/^Mem:/ {print $2}')"
print_info "Available RAM: $(free -h | awk '/^Mem:/ {print $7}')"
print_info "Disk Usage: $(df -h / | awk 'NR==2 {print $5 " of " $2}')"

# Required System Components
print_header "System Components"

# Check for Bash
if command -v bash &> /dev/null; then
    print_pass "Bash is installed ($(bash --version | head -1))"
else
    print_fail "Bash is not installed"
fi

# Check for audio tools
echo ""
print_header "Audio Tools"

AUDIO_TOOLS=("jackd" "reaper" "ardour" "audacity" "sox" "ffmpeg" "qjackctl" "timidity")

for tool in "${AUDIO_TOOLS[@]}"; do
    if command -v "$tool" &> /dev/null; then
        print_pass "$tool is installed"
    else
        print_info "$tool not found (optional)"
    fi
done

# Check JACK
echo ""
print_header "JACK Audio Connection Kit"

if command -v jackd &> /dev/null; then
    print_pass "JACK daemon installed"
    
    # Check if JACK is running
    if pgrep -x "jackd" > /dev/null; then
        print_pass "JACK is currently running"
        print_info "JACK PID: $(pgrep -x jackd)"
    else
        print_warn "JACK is installed but not running"
        print_info "Start with: jackd -d alsa or use qjackctl"
    fi
    
    # Check audio devices
    if arecord -l &> /dev/null; then
        print_pass "Audio input devices found"
        print_info "$(arecord -l | grep -c '^card'): audio interface(s)"
    else
        print_warn "No audio input devices detected"
    fi
    
    if aplay -l &> /dev/null; then
        print_pass "Audio output devices found"
    else
        print_warn "No audio output devices detected"
    fi
else
    print_fail "JACK is not installed"
fi

# Check REAPER
echo ""
print_header "REAPER DAW"

if command -v reaper &> /dev/null; then
    print_pass "REAPER is installed"
    if [ -d ~/.config/REAPER ]; then
        print_info "Configuration directory found"
    else
        print_warn "REAPER not yet configured"
    fi
else
    print_fail "REAPER is not installed"
    print_warn "Run: sudo apt install reaper"
fi

# Disk Space
echo ""
print_header "Disk Space"

DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -lt 80 ]; then
    print_pass "Disk space available ($DISK_USAGE% used)"
else
    print_warn "Low disk space ($DISK_USAGE% used)"
    print_info "Consider cleaning up or expanding storage"
fi

# Permissions
echo ""
print_header "File Permissions"

if [ -w /proc ] || [ -w /sys ]; then
    print_fail "Running with elevated privileges"
    print_info "Some tools work better as regular user"
else
    print_pass "Running as regular user"
fi

# Real-time Kernel
echo ""
print_header "Real-time Capabilities"

KERNEL_VERSION=$(uname -r)
if [[ $KERNEL_VERSION == *"-rt"* ]]; then
    print_pass "Real-time kernel detected"
else
    print_warn "Standard kernel detected (not real-time)"
    print_info "Better latency with RT kernel"
    print_info "Install with: sudo apt install linux-image-rt-amd64"
fi

# CPU Governor
if command -v cpupower &> /dev/null; then
    GOVERNOR=$(cpupower frequency-info 2>/dev/null | grep "current policy" | awk '{print $NF}')
    if [ "$GOVERNOR" = "performance" ]; then
        print_pass "CPU governor set to performance"
    else
        print_info "CPU governor: $GOVERNOR (consider 'performance' for audio)"
    fi
else
    print_info "cpupower not available (optional)"
fi

# Loaded Modules
echo ""
print_header "Kernel Modules"

if lsmod | grep -q "snd_"; then
    print_pass "Audio kernel modules loaded"
else
    print_fail "Audio kernel modules not loaded"
    print_info "Some audio features may not work"
fi

# Summary
echo ""
print_header "Summary"
echo "Total Checks: $TOTAL"
echo -e "Passed: ${GREEN}$PASSED${NC}"
echo -e "Failed: ${RED}$FAILED${NC}"
echo -e "Warnings: ${YELLOW}$WARNINGS${NC}"

if [ $FAILED -eq 0 ]; then
    echo -e "\n${GREEN}✓ All checks passed! REAPER OS is healthy.${NC}\n"
    exit 0
elif [ $FAILED -le 2 ]; then
    echo -e "\n${YELLOW}⚠ Some issues found, but REAPER OS should work.${NC}\n"
    exit 0
else
    echo -e "\n${RED}✗ Multiple issues found. Please check installation.${NC}\n"
    exit 1
fi
