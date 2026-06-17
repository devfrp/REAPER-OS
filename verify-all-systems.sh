#!/bin/bash

################################################################################
# REAPER OS v1.0.0 - Complete System Verification
# Validates all tools, dependencies, and integrations
# Usage: ./verify-all-systems.sh
################################################################################

set -euo pipefail

TOOLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/tools" && pwd)"
DOCS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/docs" && pwd)"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Counters
PASS=0
FAIL=0
WARN=0

# Test results
declare -a RESULTS

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║     REAPER OS v0.4.0 - Complete System Verification          ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Function: Test result
test_result() {
    local test_name="$1"
    local status="$2"
    local message="${3:-}"
    
    if [ "$status" = "PASS" ]; then
        echo -e "${GREEN}✓${NC} $test_name"
        PASS=$((PASS + 1))
    elif [ "$status" = "FAIL" ]; then
        echo -e "${RED}✗${NC} $test_name: $message"
        FAIL=$((FAIL + 1))
    elif [ "$status" = "WARN" ]; then
        echo -e "${YELLOW}⚠${NC} $test_name: $message"
        WARN=$((WARN + 1))
    fi
    
    RESULTS+=("$test_name: $status - $message")
}

echo -e "${BLUE}[1] CHECKING TOOL FILES${NC}"
echo ""

# Check all tool files exist and have correct shebang
TOOLS=(
    "hardware-matrix.sh:bash"
    "advanced-dashboard.py:python3"
    "preset-manager-advanced.sh:bash"
    "vst-plugin-store.sh:bash"
    "professional-templates.sh:bash"
    "cloud-sync.sh:bash"
    "mobile-companion.py:python3"
    "video-sync-tools.sh:bash"
    "community-marketplace.sh:bash"
)

for tool_spec in "${TOOLS[@]}"; do
    IFS=':' read -r tool type <<< "$tool_spec"
    
    if [ -f "$TOOLS_DIR/$tool" ]; then
        test_result "File exists: $tool" "PASS"
        
        # Check shebang
        read -r shebang < "$TOOLS_DIR/$tool"
        if [[ "$type" == "bash" && "$shebang" == "#!/bin/bash" ]] || \
           [[ "$type" == "python3" && "$shebang" == "#!/usr/bin/env python3" ]]; then
            test_result "Shebang correct: $tool" "PASS"
        else
            test_result "Shebang incorrect: $tool" "FAIL" "Expected: #!/bin/$type or #!/usr/bin/env $type"
        fi
    else
        test_result "File exists: $tool" "FAIL" "File not found"
    fi
done

echo ""
echo -e "${BLUE}[2] CHECKING PYTHON SYNTAX${NC}"
echo ""

for py_file in "$TOOLS_DIR"/*.py; do
    filename=$(basename "$py_file")
    if python3 -m py_compile "$py_file" 2>/dev/null; then
        test_result "Python syntax: $filename" "PASS"
    else
        test_result "Python syntax: $filename" "FAIL" "Syntax error detected"
    fi
done

echo ""
echo -e "${BLUE}[3] CHECKING BASH SYNTAX${NC}"
echo ""

for bash_file in "$TOOLS_DIR"/*.sh; do
    filename=$(basename "$bash_file")
    if bash -n "$bash_file" 2>/dev/null; then
        test_result "Bash syntax: $filename" "PASS"
    else
        test_result "Bash syntax: $filename" "FAIL" "Syntax error detected"
    fi
done

echo ""
echo -e "${BLUE}[4] CHECKING DOCUMENTATION${NC}"
echo ""

DOCS=(
    "AUDIO-INTERFACE-SUPPORT.md"
    "CONTROL-PROTOCOLS.md"
    "VST-SETUP.md"
    "WINE-SETUP.md"
)

for doc in "${DOCS[@]}"; do
    if [ -f "$DOCS_DIR/$doc" ]; then
        test_result "Documentation: $doc" "PASS"
        
        # Check file is not empty
        if [ -s "$DOCS_DIR/$doc" ]; then
            test_result "Documentation not empty: $doc" "PASS"
        else
            test_result "Documentation not empty: $doc" "FAIL" "File is empty"
        fi
    else
        test_result "Documentation: $doc" "FAIL" "File not found"
    fi
done

echo ""
echo -e "${BLUE}[5] CHECKING PORT CONFIGURATION${NC}"
echo ""

# Expected ports
declare -A PORT_MAP=(
    ["system-dashboard.py"]="5000"
    ["advanced-dashboard.py"]="5001"
    ["mobile-companion.py"]="5002"
)

for tool in "${!PORT_MAP[@]}"; do
    port="${PORT_MAP[$tool]}"
    if grep -q "$port" "$TOOLS_DIR/$tool" 2>/dev/null; then
        test_result "Port config: $tool uses port $port" "PASS"
    else
        # Check if port is in environment variable
        if grep -q "DASHBOARD_PORT\|MOBILE_PORT" "$TOOLS_DIR/$tool" 2>/dev/null; then
            test_result "Port config: $tool uses env variable" "PASS"
        else
            test_result "Port config: $tool" "WARN" "Port configuration not verified"
        fi
    fi
done

echo ""
echo -e "${BLUE}[6] CHECKING PYTHON IMPORTS${NC}"
echo ""

# Check required packages
PYTHON_DEPS=(
    "flask"
    "psutil"
    "json"
    "subprocess"
    "socket"
    "os"
)

for package in "${PYTHON_DEPS[@]}"; do
    if python3 -c "import $package" 2>/dev/null; then
        test_result "Python package: $package" "PASS"
    else
        test_result "Python package: $package" "WARN" "Package not installed (optional)"
    fi
done

echo ""
echo -e "${BLUE}[7] CHECKING FOR CONFLICTS${NC}"
echo ""

# Check for duplicate function names (excluding common standalone utilities)
bash_functions=$(grep -h "^[a-zA-Z_][a-zA-Z0-9_]*() {" "$TOOLS_DIR"/*.sh 2>/dev/null | sed 's/() {//' | sort || true)
common_funcs="log_info|log_success|log_warning|log_error|log_warn|show_help|main|print_header|print_info|print_success|print_warning|print_error"
real_dups=$(echo "$bash_functions" | sort | uniq -d | grep -v -E "^($common_funcs)$" || true)
if [ -z "$real_dups" ]; then
    test_result "No duplicate bash functions" "PASS"
else
    duplicates=$(echo "$real_dups" | tr '\n' ', ' | sed 's/,$//')
    test_result "No duplicate bash functions" "WARN" "Found non-utility duplicates: $duplicates"
fi

# Check for directory conflicts
declare -A DIR_MAP
for script in "$TOOLS_DIR"/*.sh "$TOOLS_DIR"/*.py; do
    filename=$(basename "$script")
    while IFS= read -r line; do
        if [[ $line =~ DIR=\".*\" ]] || [[ $line =~ _DIR=.*expanduser ]]; then
            dir=$(echo "$line" | grep -oP '(?<=")\$\{HOME\}/[^"]*|(?<=")/[^"]*')
            if [ -n "$dir" ]; then
                if [ -n "${DIR_MAP[$dir]}" ]; then
                    echo -e "${YELLOW}⚠${NC} Directory conflict: $dir used by both $filename and ${DIR_MAP[$dir]}"
                    ((WARN++))
                else
                    DIR_MAP[$dir]="$filename"
                fi
            fi
        fi
    done < "$script"
done

test_result "Checked for directory conflicts" "PASS"

echo ""
echo -e "${BLUE}[8] CHECKING INTEGRATION POINTS${NC}"
echo ""

# Check if tools properly call each other
tools_called_in_scripts=$(grep -h "tools/\|\.sh\|\.py" "$TOOLS_DIR"/*.sh "$TOOLS_DIR"/*.py 2>/dev/null | grep -v "^#" | wc -l)
if [ "$tools_called_in_scripts" -gt 0 ]; then
    test_result "Tools integration calls found" "PASS"
else
    test_result "Tools integration calls found" "WARN" "No cross-tool calls detected"
fi

# Check REAPER configuration docs
if grep -q "REAPER\|control\|protocol" "$DOCS_DIR/CONTROL-PROTOCOLS.md" 2>/dev/null; then
    test_result "Control protocols documented" "PASS"
else
    test_result "Control protocols documented" "WARN" "CONTROL-PROTOCOLS.md not found or empty"
fi

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                    VERIFICATION SUMMARY                        ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo -e "${GREEN}Passed:${NC}  $PASS"
echo -e "${RED}Failed:${NC}  $FAIL"
echo -e "${YELLOW}Warnings:${NC} $WARN"
echo ""

if [ $FAIL -eq 0 ]; then
    if [ $WARN -eq 0 ]; then
        echo -e "${GREEN}✓ All systems verified successfully!${NC}"
        exit 0
    else
        echo -e "${YELLOW}⚠ Systems verified with $WARN warnings${NC}"
        exit 0
    fi
else
    echo -e "${RED}✗ Verification failed with $FAIL errors${NC}"
    exit 1
fi
