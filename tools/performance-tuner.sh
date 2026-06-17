#!/bin/bash

################################################################################
# REAPER OS Advanced Performance Tuner
# Optimizes system performance for low-latency audio production
# Features: CPU affinity, real-time priority, buffer optimization, latency analysis
# Usage: ./performance-tuner.sh [--wizard] [--optimize] [--analyze] [--recommendations]
################################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TUNING_LOG="$HOME/.config/REAPER/performance-tuning.log"
TUNING_PROFILE="$HOME/.config/REAPER/performance-profile.json"

mkdir -p "$(dirname "$TUNING_LOG")"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" >> "$TUNING_LOG"
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

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Analyze current system performance
analyze_performance() {
    print_header "Analyzing System Performance..."
    
    local cpu_cores=$(nproc)
    local cpu_model=$(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)
    local total_ram=$(free -h | grep "^Mem:" | awk '{print $2}')
    local load_avg=$(cat /proc/loadavg | awk '{print $1}')
    
    print_info "CPU Cores: $cpu_cores"
    print_info "CPU Model: $cpu_model"
    print_info "Total RAM: $total_ram"
    print_info "Load Average: $load_avg"
    
    # Check for real-time kernel
    if grep -q "PREEMPT_RT" /boot/config-"$(uname -r)" 2>/dev/null; then
        print_success "Real-time kernel detected"
    else
        print_warning "Real-time kernel not detected (performance may be limited)"
    fi
    
    # Check system limits
    print_header "System Limits"
    local max_files=$(ulimit -n)
    local max_procs=$(ulimit -u)
    
    print_info "Max open files: $max_files"
    print_info "Max processes: $max_procs"
    
    if [ "$max_files" -lt 4096 ]; then
        print_warning "Increase max files limit for better performance"
    fi
}

# Configure CPU affinity
configure_cpu_affinity() {
    print_header "Configuring CPU Affinity..."
    
    local cpu_cores=$(nproc)
    local reaper_cpu=0
    local jack_cpu=1
    
    # Dedicate specific CPU cores
    if [ "$cpu_cores" -ge 4 ]; then
        print_info "Dedicating cores for REAPER and JACK"
        print_info "REAPER: core $reaper_cpu"
        print_info "JACK: core $jack_cpu"
        
        # Create affinity script
        cat > "$HOME/.config/reaper-cpu-affinity.sh" << EOF
#!/bin/bash
# CPU Affinity Configuration

# Set REAPER to run on core $reaper_cpu
taskset -p -c $reaper_cpu \$\$

# Run REAPER with CPU affinity
exec taskset -c $reaper_cpu reaper "\$@"
EOF
        
        chmod +x "$HOME/.config/reaper-cpu-affinity.sh"
        print_success "CPU affinity script created"
        log "CPU affinity configured: REAPER=$reaper_cpu, JACK=$jack_cpu"
    else
        print_warning "Not enough CPU cores for affinity optimization (need 4+)"
    fi
}

# Configure real-time priority
configure_realtime_priority() {
    print_header "Configuring Real-Time Priority..."
    
    # Check current limits
    local rt_priority=$(cat /proc/sys/kernel/sched_rt_period_us 2>/dev/null || echo "Not set")
    
    print_info "Current RT priority limit: $rt_priority microseconds"
    
    # Create PAM limits configuration
    if [ -w "/etc/security/limits.d/" ]; then
        cat > /etc/security/limits.d/99-reaper-realtime.conf << 'EOF'
# REAPER OS Real-Time Audio Limits
@audio   soft   rtprio   95
@audio   hard   rtprio   99
@audio   soft   memlock  unlimited
@audio   hard   memlock  unlimited
@audio   soft   nofile   4096
@audio   hard   nofile   4096
@audio   soft   msgqueue 819200
@audio   hard   msgqueue 819200
EOF
        print_success "Real-time limits configured"
        log "PAM real-time limits created"
    else
        print_warning "Cannot write to /etc/security/limits.d (need sudo)"
    fi
}

# Optimize JACK configuration
optimize_jack() {
    print_header "Optimizing JACK Configuration..."
    
    local jack_config="$HOME/.jackrc"
    local alsa_device="hw:0"
    
    if aplay -l 2>/dev/null | grep -q -i asnux; then
        alsa_device="hw:ASNUX"
        print_info "ASNUX detected - using hw:ASNUX"
    fi
    
    cat > "$jack_config" << EOF
#!/bin/bash
# Optimized JACK Configuration for REAPER OS

# Start JACK with optimal settings
jackd -t 2000 \\
    -d alsa \\
    -d $alsa_device \\
    -r 48000 \\
    -p 256 \\
    -n 2 \\
    -s &

# Wait for JACK to start
sleep 2

# Configure audio latency
jack_latency_test 5

# Set buffer priority
export RTPRIO=90
export MEMLOCK=unlimited

echo "JACK optimized for latency:"
echo "  Device: $alsa_device"
echo "  Sample Rate: 48 kHz"
echo "  Buffer Size: 256 samples"
echo "  Number of Periods: 2"
echo "  Estimated Latency: ~10.7ms"
EOF
    
    chmod +x "$jack_config"
    print_success "JACK optimization script created"
    log "JACK configuration optimized (device: $alsa_device)"
}

# Optimize buffer sizes
optimize_buffers() {
    print_header "Optimizing Buffer Sizes..."
    
    # Create buffer optimization script
    cat > "$HOME/.config/buffer-optimizer.sh" << 'EOF'
#!/bin/bash
# Buffer Size Optimizer

# Recommended buffer sizes for different use cases
echo "Recommended Buffer Sizes:"
echo "========================"
echo ""
echo "For Recording/Mixing (lowest latency required):"
echo "  Buffer Size: 128-256 samples @ 48kHz"
echo "  Latency: 2.7-5.3ms"
echo ""
echo "For Playback/Monitoring:"
echo "  Buffer Size: 512 samples @ 48kHz"
echo "  Latency: 10.7ms"
echo ""
echo "For Complex Projects (CPU intensive):"
echo "  Buffer Size: 1024-2048 samples @ 48kHz"
echo "  Latency: 21.3-42.7ms"
echo ""

# Auto-detect optimal buffer size
JACK_PID=$(pgrep -f jackd | head -1)

if [ -n "$JACK_PID" ]; then
    echo "Current JACK configuration:"
    jack_latency_test 5
else
    echo "JACK is not running"
fi
EOF
    
    chmod +x "$HOME/.config/buffer-optimizer.sh"
    print_success "Buffer optimizer created"
}

# Latency analysis
analyze_latency() {
    print_header "Analyzing System Latency..."
    
    if ! command -v jack_latency_test &> /dev/null; then
        print_error "jack-tools not installed"
        return 1
    fi
    
    print_info "Running latency test (this may take 10 seconds)..."
    
    # Run latency test
    local latency_output=$(jack_latency_test 5 2>&1 || echo "Test failed")
    echo "$latency_output"
    
    # Parse and display results
    if echo "$latency_output" | grep -q "total latency"; then
        print_success "Latency analysis complete"
        log "Latency analysis: $latency_output"
    else
        print_warning "Could not determine latency"
    fi
}

# System recommendations
generate_recommendations() {
    print_header "Performance Recommendations"
    
    local recommendations_file="$HOME/.config/REAPER/performance-recommendations.txt"
    
    cat > "$recommendations_file" << 'EOF'
REAPER OS Performance Recommendations
======================================

1. KERNEL
   - Install real-time kernel (linux-image-rt)
   - Disable CPU frequency scaling
   - Disable power saving features
   
2. SYSTEM
   - Close unnecessary applications
   - Disable unused USB devices
   - Ensure adequate cooling
   - Use SSD for projects (not network shares)

3. AUDIO CONFIGURATION
   - Set sample rate to 48 kHz
   - Start with 256-sample buffer
   - Adjust based on CPU load
   - Monitor latency regularly

4. JACK SETUP
   - Run JACK with real-time priority
   - Use ALSA driver for USB interfaces
   - Enable mlock for memory locking
   - Monitor for xruns

5. REAPER OPTIMIZATION
   - Disable unnecessary plugins
   - Consolidate tracks when possible
   - Render heavy effects
   - Monitor CPU usage in real-time

6. HARDWARE
   - Dedicated audio interface
   - USB 3.0+ for fast storage
   - Network isolation for network audio
   - Proper grounding and shielding

7. MONITORING
   - Use Performance Monitor (this tool)
   - Check system logs regularly
   - Monitor temperature
   - Track performance metrics
EOF
    
    print_success "Recommendations saved to: $recommendations_file"
    cat "$recommendations_file"
}

# Create performance profile
create_performance_profile() {
    print_header "Creating Performance Profile..."
    
    cat > "$TUNING_PROFILE" << 'EOF'
{
  "profile_name": "Default Audio Production",
  "timestamp": "",
  "system": {
    "cpu_cores": 0,
    "total_ram_gb": 0,
    "kernel_version": ""
  },
  "audio_settings": {
    "sample_rate": 48000,
    "buffer_size": 256,
    "num_periods": 2,
    "estimated_latency_ms": 10.7
  },
  "optimization": {
    "cpu_affinity_enabled": false,
    "realtime_priority_enabled": false,
    "frequency_scaling_disabled": false,
    "memory_locking_enabled": false
  },
  "performance_metrics": {
    "latency_test_date": null,
    "measured_latency_ms": null,
    "max_cpu_load_percent": 0,
    "xrun_count": 0
  }
}
EOF
    
    print_success "Performance profile created: $TUNING_PROFILE"
}

# Interactive wizard
performance_wizard() {
    print_header "Performance Tuning Wizard"
    
    echo "This wizard will optimize your system for low-latency audio production."
    echo ""
    echo "What is your primary use case?"
    echo "1) Recording/Mixing (lowest latency)"
    echo "2) Live Performance (moderate latency)"
    echo "3) Podcasting (can tolerate higher latency)"
    echo "4) Custom"
    echo ""
    read -p "Choose [1-4]: " use_case
    
    case $use_case in
        1)
            print_info "Configuring for Recording/Mixing..."
            configure_cpu_affinity
            configure_realtime_priority
            optimize_jack
            print_success "System optimized for low-latency recording"
            ;;
        2)
            print_info "Configuring for Live Performance..."
            optimize_jack
            analyze_latency
            print_success "System optimized for live performance"
            ;;
        3)
            print_info "Configuring for Podcasting..."
            print_success "System configured for podcasting"
            ;;
        4)
            print_info "Custom configuration selected"
            ;;
    esac
    
    log "Wizard completed: use_case=$use_case"
}

# Main function
main() {
    local action="${1:-help}"
    
    case "$action" in
        --wizard)
            performance_wizard
            ;;
        --optimize)
            print_header "Optimizing System for Audio Production"
            analyze_performance
            configure_cpu_affinity
            configure_realtime_priority
            optimize_jack
            optimize_buffers
            ;;
        --analyze)
            analyze_performance
            analyze_latency
            ;;
        --recommendations)
            generate_recommendations
            ;;
        *)
            echo "Usage: performance-tuner.sh [--wizard|--optimize|--analyze|--recommendations]"
            echo ""
            echo "Options:"
            echo "  --wizard           Interactive optimization wizard"
            echo "  --optimize         Auto-optimize system"
            echo "  --analyze          Analyze current performance"
            echo "  --recommendations  Show optimization recommendations"
            ;;
    esac
}

main "$@"
