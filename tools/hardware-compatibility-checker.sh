#!/bin/bash

################################################################################
# REAPER OS - Hardware Compatibility Checker - v1.1.0
# Comprehensive hardware diagnostics for audio production systems
#
# Usage:
#   bash hardware-compatibility-checker.sh              # Interactive mode
#   bash hardware-compatibility-checker.sh --auto       # Automatic report
#   bash hardware-compatibility-checker.sh --json       # JSON output
#   bash hardware-compatibility-checker.sh --html       # HTML report
#   bash hardware-compatibility-checker.sh --help       # Show help
#
# Checks:
#   - CPU (cores, frequency, virtualization, real-time capability)
#   - RAM (size, speed, ECC, swap)
#   - Disk (type, speed, I/O scheduler)
#   - GPU (model, drivers, OpenGL/Vulkan)
#   - Audio interfaces (USB, FireWire, Thunderbolt, PCIe)
#   - USB subsystem (version, bandwidth, latency)
#   - Network (bandwidth, Dante/AES67 readiness)
#   - Real-time kernel (preemption, IRQ, timer freq)
#   - BIOS/UEFI (secure boot, power management)
################################################################################

set -euo pipefail

# ─── Colors ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

CHECK_PASS="${GREEN}✓${NC}"
CHECK_FAIL="${RED}✗${NC}"
CHECK_WARN="${YELLOW}⚠${NC}"
CHECK_INFO="${BLUE}ℹ${NC}"

# ─── Configuration ────────────────────────────────────────────────────────────
OUTPUT_MODE="text"
REPORT_FILE=""
SCORE=0
MAX_SCORE=0
RESULTS=()
ISSUES=()
PASSED=0
WARNINGS=0
FAILURES=0
AUDIO_INTERFACES_FOUND=0

# ─── Argument parsing ─────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case "$1" in
        --auto)       OUTPUT_MODE="auto"; shift ;;
        --json)       OUTPUT_MODE="json"; shift ;;
        --html)       OUTPUT_MODE="html"; shift ;;
        --output)     REPORT_FILE="$2"; shift 2 ;;
        --help|-h)
            echo "REAPER OS Hardware Compatibility Checker v1.1.0"
            echo ""
            echo "Usage: bash $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --auto            Automatic non-interactive report"
            echo "  --json            Output in JSON format"
            echo "  --html            Generate HTML report"
            echo "  --output FILE     Save report to FILE"
            echo "  --help            Show this help"
            echo ""
            echo "Examples:"
            echo "  bash $0                        # Interactive check"
            echo "  bash $0 --auto                 # Quick automatic check"
            echo "  bash $0 --json --output report.json"
            exit 0
            ;;
        *) echo -e "${RED}Unknown option: $1${NC}"; exit 1 ;;
    esac
done

# ─── Utility functions ────────────────────────────────────────────────────────
check_cmd() { command -v "$1" >/dev/null 2>&1; }

check_result() {
    local name="$1" result="$2" weight="$3" detail="$4"
    MAX_SCORE=$((MAX_SCORE + weight))
    RESULTS+=("$name|$result|$weight|$detail")
    case "$result" in
        pass) PASSED=$((PASSED + 1)); SCORE=$((SCORE + weight)) ;;
        warn) WARNINGS=$((WARNINGS + 1)); SCORE=$((SCORE + weight / 2)) ;;
        fail) FAILURES=$((FAILURES + 1)) ;;
    esac
}

print_result() {
    local name="$1" result="$2" detail="$3"
    local icon=""
    case "$result" in
        pass) icon="$CHECK_PASS" ;;
        warn) icon="$CHECK_WARN" ;;
        fail) icon="$CHECK_FAIL" ;;
    esac
    echo -e "$icon ${BOLD}${name}${NC}"
    if [[ -n "$detail" ]]; then
        echo -e "   ${detail}"
    fi
    echo ""
}

print_header() {
    echo ""
    echo -e "${CYAN}══════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════${NC}"
}

print_section() {
    echo ""
    echo -e "${BLUE}── $1 ──${NC}"
}

# ─── System info gathering ────────────────────────────────────────────────────
get_cpu_name() {
    awk -F': ' '/model name/ {print $2; exit}' /proc/cpuinfo 2>/dev/null || echo "Unknown"
}

get_cpu_cores() { nproc 2>/dev/null || echo "0"; }
get_physical_cores() {
    grep -c "^processor" /proc/cpuinfo 2>/dev/null || echo "0"
}

get_ram_total() {
    awk '/MemTotal/ {printf "%.1f", $2/1024/1024}' /proc/meminfo 2>/dev/null || echo "0"
}

get_ram_speed() {
    local speed=""
    if check_cmd dmidecode; then
        speed=$(sudo dmidecode -t memory 2>/dev/null | awk -F': ' '/Speed:/ && /MHz/ {print $2; exit}' || echo "")
    fi
    echo "${speed:-Unknown}"
}

get_disk_info() {
    local disk="${1:-/dev/sda}"
    local size="" type_str="" model=""
    if check_cmd lsblk; then
        size=$(lsblk -ndo SIZE "$disk" 2>/dev/null || echo "Unknown")
        type_str=$(lsblk -ndo ROTA "$disk" 2>/dev/null)
        model=$(lsblk -ndo MODEL "$disk" 2>/dev/null || echo "Unknown")
        case "$type_str" in
            0) type_str="SSD" ;;
            1) type_str="HDD" ;;
            *) type_str="Unknown" ;;
        esac
    fi
    echo "${model:-Unknown}|${size:-Unknown}|${type_str:-Unknown}"
}

get_root_disk() {
    df / | tail -1 | awk '{print $1}' | sed 's/[0-9]*$//' || echo "/dev/sda"
}

# ─── CPU checks ───────────────────────────────────────────────────────────────
check_cpu() {
    print_section "CPU Analysis"

    local cores
    cores=$(get_cpu_cores)
    local cpu_name
    cpu_name=$(get_cpu_name)

    echo -e "  CPU: ${BOLD}${cpu_name}${NC}"
    echo -e "  Cores: ${cores} (logical)"
    echo ""

    if [[ "$cores" -ge 8 ]]; then
        check_result "CPU Core Count" "pass" 3 "≥8 cores (${cores}) - excellent for audio workloads"
    elif [[ "$cores" -ge 4 ]]; then
        check_result "CPU Core Count" "pass" 2 "≥4 cores (${cores}) - adequate for most audio tasks"
    else
        check_result "CPU Core Count" "fail" 3 "Only ${cores} cores - may struggle with complex projects"
    fi

    local cpu_freq
    cpu_freq=$(awk -F': ' '/cpu MHz/ {printf "%.0f", $2; exit}' /proc/cpuinfo 2>/dev/null || echo "0")
    if [[ "$cpu_freq" -ge 2500 ]]; then
        check_result "CPU Frequency" "pass" 2 "${cpu_freq} MHz - sufficient for real-time audio"
    elif [[ "$cpu_freq" -ge 1800 ]]; then
        check_result "CPU Frequency" "warn" 2 "${cpu_freq} MHz - acceptable but may limit plugin count"
    else
        check_result "CPU Frequency" "fail" 2 "${cpu_freq} MHz - too low for professional audio"
    fi

    if grep -qE '(vmx|svm)' /proc/cpuinfo 2>/dev/null; then
        check_result "Virtualization Support" "pass" 1 "VT-x/AMD-V available - good for AudioGridder/VM isolation"
    else
        check_result "Virtualization Support" "warn" 1 "No hardware virtualization - AudioGridder performance may suffer"
    fi

    local arch
    arch=$(uname -m)
    if [[ "$arch" == "x86_64" ]]; then
        check_result "CPU Architecture" "pass" 1 "x86_64 - fully supported"
    else
        check_result "CPU Architecture" "warn" 1 "$arch - limited VST plugin compatibility"
    fi
}

# ─── RAM checks ───────────────────────────────────────────────────────────────
check_ram() {
    print_section "Memory Analysis"

    local ram_gb
    ram_gb=$(get_ram_total)

    echo -e "  Total RAM: ${BOLD}${ram_gb} GB${NC}"
    echo ""

    if awk -v ram="$ram_gb" 'BEGIN {exit !(ram >= 16)}'; then
        check_result "RAM Capacity" "pass" 3 "${ram_gb} GB - excellent for large sample libraries"
    elif awk -v ram="$ram_gb" 'BEGIN {exit !(ram >= 8)}'; then
        check_result "RAM Capacity" "pass" 2 "${ram_gb} GB - adequate for most projects"
    elif awk -v ram="$ram_gb" 'BEGIN {exit !(ram >= 4)}'; then
        check_result "RAM Capacity" "warn" 3 "${ram_gb} GB - may limit sample-based instruments"
    else
        check_result "RAM Capacity" "fail" 3 "${ram_gb} GB - insufficient for REAPER OS"
    fi

    if check_cmd dmidecode; then
        local ram_type
        ram_type=$(sudo dmidecode -t memory 2>/dev/null | awk -F': ' '/Type: / && !/Type Detail/ {print $2; exit}' || echo "Unknown")
        local ecc
        ecc=$(sudo dmidecode -t memory 2>/dev/null | awk -F': ' '/Error Correction Type: / {print $2; exit}' || echo "None")
        if [[ "$ram_type" =~ DDR4|DDR5 ]]; then
            check_result "RAM Type" "pass" 1 "${ram_type} - modern memory"
        else
            check_result "RAM Type" "warn" 1 "${ram_type} - older memory technology"
        fi
        if [[ "$ecc" != "None" ]] && [[ -n "$ecc" ]]; then
            check_result "ECC Memory" "pass" 1 "ECC available - data integrity protection"
        fi
    fi

    local swaptotal
    swaptotal=$(awk '/SwapTotal/ {printf "%.1f", $2/1024/1024}' /proc/meminfo 2>/dev/null || echo "0")
    if awk -v swap="$swaptotal" 'BEGIN {exit !(swap >= 4)}'; then
        check_result "Swap Space" "pass" 1 "${swaptotal} GB swap"
    else
        check_result "Swap Space" "warn" 1 "Only ${swaptotal} GB swap - consider increasing"
    fi
}

# ─── Disk checks ──────────────────────────────────────────────────────────────
check_disk() {
    print_section "Storage Analysis"

    local root_disk
    root_disk=$(get_root_disk)
    local disk_info
    disk_info=$(get_disk_info "$root_disk")
    local disk_model disk_size disk_type
    disk_model=$(echo "$disk_info" | cut -d'|' -f1)
    disk_size=$(echo "$disk_info" | cut -d'|' -f2)
    disk_type=$(echo "$disk_info" | cut -d'|' -f3)

    echo -e "  Disk: ${BOLD}${disk_model}${NC} (${disk_size}, ${disk_type})"
    echo ""

    if [[ "$disk_type" == "SSD" ]]; then
        check_result "Storage Type" "pass" 3 "SSD - fast read/write for audio streaming"
    elif [[ "$disk_type" == "HDD" ]] && [[ -n "$disk_size" ]]; then
        check_result "Storage Type" "warn" 2 "HDD - adequate but SSD recommended for large projects"
    else
        check_result "Storage Type" "warn" 2 "Unknown storage type"
    fi

    local disk_free
    disk_free=$(df / | tail -1 | awk '{printf "%.1f", $4/1024/1024}')
    if awk -v free="$disk_free" 'BEGIN {exit !(free >= 100)}'; then
        check_result "Free Disk Space" "pass" 2 "${disk_free} GB free - plenty of room"
    elif awk -v free="$disk_free" 'BEGIN {exit !(free >= 20)}'; then
        check_result "Free Disk Space" "warn" 2 "Only ${disk_free} GB free - consider cleanup"
    else
        check_result "Free Disk Space" "fail" 2 "Only ${disk_free} GB free - critically low"
    fi

    local scheduler
    scheduler=$(cat /sys/block/"$(basename "$root_disk")"/queue/scheduler 2>/dev/null | grep -oP '\[.*?\]' | tr -d '[]' || echo "unknown")
    if [[ "$scheduler" =~ noop|none|bfq|kyber ]]; then
        check_result "I/O Scheduler" "pass" 1 "${scheduler} - optimized for low latency"
    elif [[ "$scheduler" == "mq-deadline" ]]; then
        check_result "I/O Scheduler" "pass" 1 "${scheduler} - good for audio"
    else
        check_result "I/O Scheduler" "warn" 1 "${scheduler} - consider switching to deadline/bfq"
    fi
}

# ─── GPU checks ───────────────────────────────────────────────────────────────
check_gpu() {
    print_section "GPU Analysis"

    local gpu_info=""
    if check_cmd lspci; then
        gpu_info=$(lspci -v -nn 2>/dev/null | grep -iE 'VGA|3D|Display' | head -1 | sed 's/.*: //' || echo "None detected")
    fi
    echo -e "  GPU: ${BOLD}${gpu_info:-Unknown}${NC}"
    echo ""

    if echo "$gpu_info" | grep -qi "nvidia"; then
        if check_cmd nvidia-smi; then
            check_result "GPU Drivers" "pass" 2 "NVIDIA proprietary drivers active"
        else
            check_result "GPU Drivers" "warn" 2 "NVIDIA GPU detected but nvidia-smi not found. Install drivers for GPU acceleration"
        fi
    elif echo "$gpu_info" | grep -qi "amd\|radeon"; then
        if check_cmd rocminfo; then
            check_result "GPU Drivers" "pass" 2 "AMD ROCm drivers active"
        else
            check_result "GPU Drivers" "pass" 1 "AMD GPU - open source drivers active"
        fi
    elif echo "$gpu_info" | grep -qi "intel"; then
        check_result "GPU Drivers" "pass" 1 "Intel iGPU - basic GPU acceleration"
    else
        check_result "GPU Drivers" "warn" 1 "Unknown GPU - may need driver configuration"
    fi

    if check_cmd glxinfo; then
        local opengl
        opengl=$(glxinfo 2>/dev/null | grep "OpenGL version" | awk '{print $4}' || echo "N/A")
        check_result "OpenGL Support" "pass" 1 "OpenGL ${opengl}"
    fi
}

# ─── Audio interface checks ───────────────────────────────────────────────────
check_audio_interfaces() {
    print_section "Audio Interface Detection"

    if check_cmd aplay; then
        echo -e "  ${BOLD}ALSA Sound Cards:${NC}"
        aplay -l 2>/dev/null | grep 'card' | while read -r line; do
            echo "    ${line}"
        done
    fi
    echo ""

    local audio_count=0

    # Check USB audio devices
    if check_cmd lsusb; then
        local usb_audio
        usb_audio=$(lsusb 2>/dev/null | grep -iE "audio|sound|midi|mixer|interface|controller|dac|amp" || echo "")
        if [[ -n "$usb_audio" ]]; then
            audio_count=$((audio_count + $(echo "$usb_audio" | wc -l)))
            echo -e "  ${BOLD}USB Audio Devices:${NC}"
            echo "$usb_audio" | while read -r line; do
                echo "    ${line}"
            done
            echo ""
        fi
    fi

    # Check known audio interface vendors
    local vendor_count=0
    local vendors=(
        "RME|Focusrite" "Universal Audio|Presonus" "Behringer|MOTU"
        "Steinberg|Yamaha" "Roland|TASCAM" "Native Instruments|Arturia"
        "Zoom|ZOOM" "M-Audio|Avid" "Antelope|Apogee" "Audient|SSL"
        "Allen.*Heath|Mackie" "Soundcraft|DiGiCo"
    )

    if check_cmd lsusb; then
        for vendor_group in "${vendors[@]}"; do
            IFS='|' read -ra vnds <<< "$vendor_group"
            for vendor in "${vnds[@]}"; do
                if lsusb 2>/dev/null | grep -qi "$vendor"; then
                    vendor_count=$((vendor_count + 1))
                    break
                fi
            done
        done
    fi

    if check_cmd lspci; then
        local pci_audio
        pci_audio=$(lspci 2>/dev/null | grep -iE "audio|multimedia" || echo "")
        if [[ -n "$pci_audio" ]]; then
            audio_count=$((audio_count + $(echo "$pci_audio" | wc -l)))
        fi
    fi

    AUDIO_INTERFACES_FOUND=$audio_count

    if [[ "$audio_count" -gt 0 ]]; then
        check_result "Audio Interfaces" "pass" 3 "${audio_count} audio device(s) detected${vendor_count:+, ${vendor_count} known vendor(s)}"
    else
        check_result "Audio Interfaces" "fail" 3 "No audio devices detected. Check connections"
    fi

    # Check JACK compatibility
    if check_cmd jackd; then
        check_result "JACK Server" "pass" 2 "JACK installed - ready for low-latency audio"
    else
        check_result "JACK Server" "warn" 2 "JACK not installed - required for low-latency audio. Will be installed by REAPER OS"
    fi

    # Check USB subsystem
    if [[ -d "/sys/bus/usb" ]]; then
        local usb_version
        usb_version=$(lsusb -v 2>/dev/null | grep -i "bcdUSB" | head -1 | awk '{print $2}' || echo "unknown")
        if echo "$usb_version" | grep -q "3."; then
            check_result "USB Version" "pass" 1 "USB 3.x - high bandwidth audio support"
        else
            check_result "USB Version" "warn" 1 "USB 2.0 - sufficient for most interfaces, USB 3.0 recommended"
        fi
    fi
}

# ─── Kernel / Real-time checks ────────────────────────────────────────────────
check_kernel() {
    print_section "Kernel & Real-Time Analysis"

    local kernel
    kernel=$(uname -r)
    echo -e "  Kernel: ${BOLD}${kernel}${NC}"
    echo ""

    if echo "$kernel" | grep -qE "rt|realtime|PREEMPT_RT"; then
        check_result "Real-Time Kernel" "pass" 4 "PREEMPT_RT kernel active - optimal for audio"
    elif echo "$kernel" | grep -q "lowlatency"; then
        check_result "Real-Time Kernel" "pass" 3 "Low-latency kernel - good for audio production"
    else
        local preempt
        preempt=$(uname -a | grep -oP "PREEMPT\S*" || echo "NONE")
        if [[ "$preempt" == "PREEMPT" ]] || [[ "$preempt" == "PREEMPT_DYNAMIC" ]]; then
            check_result "Real-Time Kernel" "warn" 3 "Standard kernel with PREEMPT. Consider installing linux-image-rt for best performance"
        else
            check_result "Real-Time Kernel" "fail" 4 "No real-time kernel. REAPER OS requires PREEMPT_RT for <6ms latency"
        fi
    fi

    local timer_freq
    timer_freq=$(grep CONFIG_HZ= /boot/config-"$(uname -r)" 2>/dev/null | cut -d= -f2 || echo "unknown")
    if [[ "$timer_freq" -ge 1000 ]]; then
        check_result "Timer Frequency" "pass" 2 "${timer_freq}Hz - excellent for MIDI timing"
    elif [[ "$timer_freq" -ge 250 ]]; then
        check_result "Timer Frequency" "warn" 2 "${timer_freq}Hz - acceptable. 1000Hz recommended"
    else
        check_result "Timer Frequency" "warn" 2 "Unknown timer frequency"
    fi

    if [[ -f "/proc/irq/default_smp_affinity" ]]; then
        check_result "IRQ Balancing" "pass" 1 "SMP IRQ affinity supported"
    fi

    if check_cmd rtirq; then
        check_result "RTIRQ" "pass" 1 "rtirq-init available for IRQ prioritization"
    fi
}

# ─── Network checks ───────────────────────────────────────────────────────────
check_network() {
    print_section "Network Analysis"

    local interfaces
    interfaces=$(ip -o link show 2>/dev/null | grep -v "lo:" | awk -F': ' '{print $2}' | paste -sd ',' - || echo "none")
    echo -e "  Interfaces: ${interfaces}"
    echo ""

    if check_cmd ethtool; then
        local first_iface
        first_iface=$(ip -o link show 2>/dev/null | grep -v "lo:" | awk -F': ' '{print $2; exit}' || echo "")
        if [[ -n "$first_iface" ]]; then
            local speed
            speed=$(ethtool "$first_iface" 2>/dev/null | grep "Speed:" | awk '{print $2}' || echo "Unknown")
            if echo "$speed" | grep -qi "1000"; then
                check_result "Network Speed" "pass" 2 "Gigabit Ethernet - sufficient for Dante/AES67"
            elif echo "$speed" | grep -qi "100"; then
                check_result "Network Speed" "warn" 2 "100Mbps - limited for network audio"
            else
                check_result "Network Speed" "warn" 1 "Unknown speed - check interface"
            fi
        fi
    fi

    # PTP (Precision Time Protocol) check for Dante
    if check_cmd ptp4l; then
        check_result "PTP Support" "pass" 1 "PTP available - required for Dante/AES67 sync"
    else
        check_result "PTP Support" "warn" 1 "PTP not installed - needed for Dante/AES67. Install: linuxptp"
    fi
}

# ─── System tuning checks ─────────────────────────────────────────────────────
check_system_tuning() {
    print_section "System Tuning"

    # Check audio group membership
    if groups "$USER" 2>/dev/null | grep -q "audio"; then
        check_result "Audio Group" "pass" 1 "User in audio group"
    else
        check_result "Audio Group" "warn" 1 "User NOT in audio group. Run: sudo usermod -a -G audio \$USER"
    fi

    # Check memlock limits
    local memlock
    memlock=$(ulimit -l 2>/dev/null || echo "0")
    if [[ "$memlock" == "unlimited" ]] || [[ "$memlock" -ge 999999 ]]; then
        check_result "Memory Lock Limit" "pass" 1 "Unlimited memlock - required for JACK real-time"
    else
        check_result "Memory Lock Limit" "fail" 2 "Limited memlock (${memlock}). Set ulimit -l unlimited in /etc/security/limits.d/99-audio.conf"
    fi

    # Check rtprio
    local rtprio
    rtprio=$(ulimit -r 2>/dev/null || echo "0")
    if [[ "$rtprio" -ge 95 ]]; then
        check_result "Real-Time Priority" "pass" 1 "RT priority available (${rtprio})"
    else
        check_result "Real-Time Priority" "fail" 2 "RT priority limited (${rtprio}). Set @audio - rtprio 99 in /etc/security/limits.d/99-audio.conf"
    fi

    # CPU governor
    if [[ -f "/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor" ]]; then
        local governor
        governor=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null)
        if [[ "$governor" == "performance" ]]; then
            check_result "CPU Governor" "pass" 1 "Performance governor - recommended for audio"
        else
            check_result "CPU Governor" "warn" 1 "${governor} - consider switching to 'performance' for stable audio"
        fi
    fi

    # Power management
    if [[ -d "/sys/devices/system/cpu/intel_pstate" ]] || [[ -d "/sys/devices/system/cpu/amd_pstate" ]]; then
        check_result "Power Management" "warn" 1 "P-state driver active - may cause latency. Consider disabling for audio use"
    fi

    # Swappiness
    local swappiness
    swappiness=$(cat /proc/sys/vm/swappiness 2>/dev/null || echo "60")
    if [[ "$swappiness" -le 10 ]]; then
        check_result "Swappiness" "pass" 1 "Low swappiness (${swappiness}) - good for audio"
    else
        check_result "Swappiness" "warn" 1 "Swappiness is ${swappiness}. Lower to 10 for audio: sysctl vm.swappiness=10"
    fi
}

# ─── BIOS/UEFI checks ─────────────────────────────────────────────────────────
check_bios() {
    print_section "BIOS / UEFI Analysis"

    if [[ -d "/sys/firmware/efi" ]]; then
        check_result "Boot Mode" "pass" 1 "UEFI boot - modern firmware"
    else
        check_result "Boot Mode" "warn" 1 "Legacy BIOS boot"
    fi

    if check_cmd mokutil; then
        if mokutil --sb-state 2>/dev/null | grep -q "SecureBoot enabled"; then
            check_result "Secure Boot" "warn" 1 "Secure Boot enabled - may block unsigned kernel modules (nvidia, wineasio)"
        else
            check_result "Secure Boot" "pass" 1 "Secure Boot disabled"
        fi
    fi
}

# ─── Generate recommendations ─────────────────────────────────────────────────
generate_recommendations() {
    print_section "Recommendations"

    if [[ "$SCORE" -ge $((MAX_SCORE * 85 / 100)) ]]; then
        echo -e "${GREEN}${BOLD}Excellent! Your system is well-suited for REAPER OS.${NC}"
        echo "You can expect optimal audio performance with minimal latency."
    elif [[ "$SCORE" -ge $((MAX_SCORE * 60 / 100)) ]]; then
        echo -e "${YELLOW}${BOLD}Good system. Some optimizations recommended for best results.${NC}"
        echo "Review the warnings above and apply suggested fixes."
    else
        echo -e "${RED}${BOLD}Your system needs attention before installing REAPER OS.${NC}"
        echo "Address the failures above before proceeding with installation."
    fi

    echo ""
    echo "Key recommendations for audio production:"
    echo "  1. Install PREEMPT_RT kernel: sudo apt install linux-image-rt-amd64"
    echo "  2. Add user to audio group: sudo usermod -a -G audio \$USER"
    echo "  3. Set real-time limits: configure /etc/security/limits.d/99-audio.conf"
    echo "  4. Use SSD for project files and sample libraries"
    echo "  5. Disable CPU frequency scaling during sessions"
    echo "  6. Use a dedicated USB port for audio interface (avoid hubs)"
}

# ─── JSON output ──────────────────────────────────────────────────────────────
output_json() {
    local json_results="["
    local first=true
    for r in "${RESULTS[@]}"; do
        IFS='|' read -r name result weight detail <<< "$r"
        if $first; then first=false; else json_results+=","; fi
        json_results+="{\"name\":\"$name\",\"result\":\"$result\",\"detail\":\"$detail\"}"
    done
    json_results+="]"

    cat <<JSONEOF
{
  "reaper_os_hardware_check": {
    "version": "1.1.0",
    "timestamp": "$(date -Iseconds)",
    "system": {
      "hostname": "$(hostname)",
      "cpu": "$(get_cpu_name)",
      "cores": $(get_cpu_cores),
      "ram_gb": $(get_ram_total),
      "kernel": "$(uname -r)",
      "arch": "$(uname -m)"
    },
    "summary": {
      "score": $SCORE,
      "max_score": $MAX_SCORE,
      "percentage": $((SCORE * 100 / MAX_SCORE)),
      "passed": $PASSED,
      "warnings": $WARNINGS,
      "failures": $FAILURES,
      "audio_interfaces": $AUDIO_INTERFACES_FOUND
    },
    "results": $json_results
  }
}
JSONEOF
}

# ─── HTML output ──────────────────────────────────────────────────────────────
output_html() {
    cat <<HTMLEOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <title>REAPER OS Hardware Compatibility Report</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; max-width: 900px; margin: 40px auto; padding: 20px; background: #1a1a2e; color: #eee; }
        h1 { color: #e94560; border-bottom: 2px solid #e94560; padding-bottom: 10px; }
        h2 { color: #533483; margin-top: 30px; }
        .summary { background: #16213e; border-radius: 10px; padding: 20px; margin: 20px 0; display: flex; gap: 30px; flex-wrap: wrap; }
        .score { font-size: 3rem; font-weight: bold; color: #e94560; }
        .pass { color: #4caf50; } .warn { color: #ff9800; } .fail { color: #f44336; }
        .result { display: flex; align-items: center; gap: 10px; padding: 10px; border-bottom: 1px solid #333; }
        .result .icon { font-size: 1.2rem; width: 24px; }
        .result .detail { color: #888; font-size: 0.9rem; }
        .progress { background: #333; height: 10px; border-radius: 5px; margin: 10px 0; }
        .progress-fill { background: linear-gradient(90deg, #e94560, #533483); height: 100%; border-radius: 5px; }
    </style>
</head>
<body>
    <h1>REAPER OS Hardware Compatibility Report</h1>
    <p>Generated: $(date)</p>
    <p>System: $(hostname) - $(get_cpu_name) - $(get_ram_total) GB RAM</p>

    <div class="summary">
        <div><div class="score">$((SCORE * 100 / MAX_SCORE))%</div>Compatibility Score</div>
        <div><span class="pass">$PASSED ✓ Passed</span></div>
        <div><span class="warn">$WARNINGS ⚠ Warnings</span></div>
        <div><span class="fail">$FAILURES ✗ Failed</span></div>
    </div>
    <div class="progress"><div class="progress-fill" style="width: $((SCORE * 100 / MAX_SCORE))%"></div></div>

    <h2>Check Results</h2>
HTMLEOF

    for r in "${RESULTS[@]}"; do
        IFS='|' read -r name result weight detail <<< "$r"
        local icon=""
        case "$result" in
            pass) icon="✓" ;;
            warn) icon="⚠" ;;
            fail) icon="✗" ;;
        esac
        echo "<div class=\"result\"><span class=\"icon ${result}\">${icon}</span><strong>${name}</strong><span class=\"detail\"> - ${detail}</span></div>"
    done

    echo "</body></html>"
}

# ─── Main ─────────────────────────────────────────────────────────────────────
main() {
    print_header "REAPER OS Hardware Compatibility Checker v1.1.0"
    echo -e "  System: $(hostname) ($(uname -m))"
    echo -e "  Date:   $(date)"
    echo ""

    check_cpu
    check_ram
    check_disk
    check_gpu
    check_audio_interfaces
    check_kernel
    check_network
    check_system_tuning
    check_bios

    # Score summary
    print_header "Results Summary"
    local pct=$((SCORE * 100 / MAX_SCORE))
    echo -e "  Score:    ${BOLD}${SCORE}/${MAX_SCORE} (${pct}%)${NC}"
    echo -e "  Passed:   ${GREEN}${PASSED}${NC}"
    echo -e "  Warnings: ${YELLOW}${WARNINGS}${NC}"
    echo -e "  Failures: ${RED}${FAILURES}${NC}"
    echo -e "  Audio:    ${AUDIO_INTERFACES_FOUND} interface(s) found"
    echo ""

    generate_recommendations

    # Output to file if requested
    if [[ -n "$REPORT_FILE" ]]; then
        case "$OUTPUT_MODE" in
            json) output_json > "$REPORT_FILE" ;;
            html) output_html > "$REPORT_FILE" ;;
            *)    exec > >(tee "$REPORT_FILE") 2>&1; main_text || true ;;
        esac
        echo -e "\n${GREEN}Report saved to: $REPORT_FILE${NC}"
        return
    fi

    # Output mode
    case "$OUTPUT_MODE" in
        json) output_json ;;
        html) output_html ;;
    esac
}

main
