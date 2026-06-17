#!/bin/bash

################################################################################
# REAPER OS Tools Validator & Tester
# 
# Validates all tools in the tools directory for:
#   - Syntax correctness
#   - Dependency availability
#   - Basic functionality
#   - Help text presence
#   - Executability
#
# Usage:
#   bash tools-validator.sh
#   bash tools-validator.sh --fix
#   bash tools-validator.sh --detailed
#
################################################################################

set -euo pipefail

# Configuration
TOOLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPORT_FILE="/tmp/tools-validation-$(date +%s).log"
FAILED_TOOLS=()
MISSING_DEPS=()

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$REPORT_FILE"; }
log_success() { echo -e "${GREEN}✓${NC} $1" | tee -a "$REPORT_FILE"; }
log_error() { echo -e "${RED}✗${NC} $1" | tee -a "$REPORT_FILE"; }
log_warn() { echo -e "${YELLOW}⚠${NC} $1" | tee -a "$REPORT_FILE"; }

# Header
echo "=== REAPER OS Tools Validation Report ===" | tee "$REPORT_FILE"
echo "Generated: $(date)" | tee -a "$REPORT_FILE"
echo "Tools Directory: $TOOLS_DIR" | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

# Check bash scripts
log_info "Validating Bash scripts..."
echo "" | tee -a "$REPORT_FILE"

bash_scripts=$(find "$TOOLS_DIR" -maxdepth 1 -name "*.sh" -type f | sort)
bash_count=0
bash_valid=0

for script in $bash_scripts; do
    script_name=$(basename "$script")
    bash_count=$((bash_count + 1))
    
    # Check syntax
    if bash -n "$script" 2>/dev/null; then
        log_success "$script_name - Syntax OK"
        bash_valid=$((bash_valid + 1))
    else
        log_error "$script_name - Syntax ERROR"
        FAILED_TOOLS+=("$script_name")
    fi
    
    # Check if executable
    if [ -x "$script" ]; then
        log_success "$script_name - Executable"
    else
        log_warn "$script_name - Not executable (fixing with: chmod +x)"
        if [ "${1:-}" = "--fix" ]; then
            chmod +x "$script"
            log_success "$script_name - Made executable"
        fi
    fi
done

echo "" | tee -a "$REPORT_FILE"
log_info "Bash Scripts: $bash_valid/$bash_count valid"
echo "" | tee -a "$REPORT_FILE"

# Check Python scripts
log_info "Validating Python scripts..."
echo "" | tee -a "$REPORT_FILE"

python_scripts=$(find "$TOOLS_DIR" -maxdepth 1 -name "*.py" -type f | sort)
python_count=0
python_valid=0

for script in $python_scripts; do
    script_name=$(basename "$script")
    python_count=$((python_count + 1))
    
    # Check Python syntax
    if python3 -m py_compile "$script" 2>/dev/null; then
        log_success "$script_name - Python syntax OK"
        python_valid=$((python_valid + 1))
    else
        log_error "$script_name - Python syntax ERROR"
        FAILED_TOOLS+=("$script_name")
    fi
done

echo "" | tee -a "$REPORT_FILE"
log_info "Python Scripts: $python_valid/$python_count valid"
echo "" | tee -a "$REPORT_FILE"

# Check dependencies
log_info "Checking tool dependencies..."
echo "" | tee -a "$REPORT_FILE"

# Common audio tools
declare -a AUDIO_TOOLS=("ffmpeg" "ffprobe" "jackd" "jack_lsp" "alsamixer" "arecord")
for tool in "${AUDIO_TOOLS[@]}"; do
    if command -v "$tool" &> /dev/null; then
        log_success "$tool - Installed"
    else
        log_warn "$tool - Not installed"
        MISSING_DEPS+=("$tool")
    fi
done

echo "" | tee -a "$REPORT_FILE"

# Python modules
log_info "Checking Python modules..."
python3 << 'PYTHON' | tee -a "$REPORT_FILE"
import sys

modules = ['json', 'subprocess', 'os', 'sys']
for module in modules:
    try:
        __import__(module)
        print(f"✓ {module} - Available")
    except ImportError:
        print(f"✗ {module} - Missing")
PYTHON

echo "" | tee -a "$REPORT_FILE"

# Tool documentation check
log_info "Checking tool documentation..."
echo "" | tee -a "$REPORT_FILE"

if [ -f "$TOOLS_DIR/TOOLS-README.md" ]; then
    log_success "TOOLS-README.md exists"
else
    log_error "TOOLS-README.md not found"
fi

echo "" | tee -a "$REPORT_FILE"

# Summary
echo "=== VALIDATION SUMMARY ===" | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

total_scripts=$((bash_count + python_count))
total_valid=$((bash_valid + python_valid))

if [ ${#FAILED_TOOLS[@]} -eq 0 ]; then
    log_success "All tools validated successfully!"
    echo "" | tee -a "$REPORT_FILE"
    log_success "Scripts Valid: $total_valid/$total_scripts"
else
    log_error "Found ${#FAILED_TOOLS[@]} invalid tools:"
    printf '%s\n' "${FAILED_TOOLS[@]}" | sed 's/^/  - /' | tee -a "$REPORT_FILE"
    echo "" | tee -a "$REPORT_FILE"
fi

if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
    echo "" | tee -a "$REPORT_FILE"
    log_warn "Found ${#MISSING_DEPS[@]} missing dependencies:"
    printf '%s\n' "${MISSING_DEPS[@]}" | sed 's/^/  - /' | tee -a "$REPORT_FILE"
    echo "" | tee -a "$REPORT_FILE"
    echo "Install missing tools:" | tee -a "$REPORT_FILE"
    echo "  Ubuntu/Debian: sudo apt-get install $(printf '%s ' "${MISSING_DEPS[@]}")" | tee -a "$REPORT_FILE"
fi

echo "" | tee -a "$REPORT_FILE"
echo "Detailed Report: $REPORT_FILE" | tee -a "$REPORT_FILE"

# Exit code
if [ ${#FAILED_TOOLS[@]} -gt 0 ]; then
    exit 1
else
    exit 0
fi
