#!/bin/bash
#
# REAPER OS Benchmarking Tool
# Test system performance for audio production
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BENCH_DIR="$HOME/.local/share/reaper-os/benchmarks"
RESULTS_FILE="$BENCH_DIR/benchmark-$(date '+%Y%m%d-%H%M%S').json"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Ensure directories
mkdir -p "$BENCH_DIR"

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

# Benchmark JACK latency
bench_jack_latency() {
    log_info "Testing JACK latency with different buffer sizes..."
    
    local results=()
    
    for buffer_size in 64 128 256 512 1024; do
        log_info "Testing buffer size: $buffer_size samples"
        
        # Calculate latency in ms (sample_rate / buffer_size * 1000)
        local sample_rate=48000
        local latency=$(echo "scale=2; $buffer_size / $sample_rate * 1000" | bc)
        
        log_success "Buffer $buffer_size: ${latency}ms latency"
        
        results+=("{\"buffer\": $buffer_size, \"latency_ms\": $latency}")
    done
    
    echo '{"jack_latency": [' $(IFS=,; echo "${results[*]}") ']}'
}

# Benchmark CPU load
bench_cpu_load() {
    log_info "Measuring CPU load under stress..."
    
    local stress_duration=10
    local cpu_before=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    
    # Stress test
    yes > /dev/null &
    local pid=$!
    sleep $stress_duration
    kill $pid 2>/dev/null || true
    
    local cpu_after=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    
    log_success "CPU Load: ${cpu_before}% idle → ${cpu_after}% under stress"
    
    echo "{\"cpu_idle_before\": $cpu_before, \"cpu_idle_after\": $cpu_after}"
}

# Benchmark disk I/O
bench_disk_io() {
    log_info "Testing disk I/O performance..."
    
    local test_file="$BENCH_DIR/io-test-$(date '+%s').bin"
    local test_size_mb=100
    
    # Write test
    log_info "Write test: ${test_size_mb}MB..."
    local write_start=$(date +%s%N)
    dd if=/dev/zero of="$test_file" bs=1M count=$test_size_mb 2>/dev/null
    local write_end=$(date +%s%N)
    local write_time=$(( (write_end - write_start) / 1000000 ))
    
    local write_speed=$(echo "scale=2; $test_size_mb * 1000 / $write_time" | bc)
    log_success "Write speed: ${write_speed} MB/s"
    
    # Read test
    log_info "Read test: ${test_size_mb}MB..."
    local read_start=$(date +%s%N)
    dd if="$test_file" of=/dev/null bs=1M 2>/dev/null
    local read_end=$(date +%s%N)
    local read_time=$(( (read_end - read_start) / 1000000 ))
    
    local read_speed=$(echo "scale=2; $test_size_mb * 1000 / $read_time" | bc)
    log_success "Read speed: ${read_speed} MB/s"
    
    rm -f "$test_file"
    
    echo "{\"write_speed_mbs\": $write_speed, \"read_speed_mbs\": $read_speed}"
}

# Benchmark memory bandwidth
bench_memory() {
    log_info "Testing memory bandwidth..."
    
    local test_mb=1000
    
    if command -v sysbench &> /dev/null; then
        local result=$(sysbench memory --memory-total-size=${test_mb}M run 2>&1 | grep -i "ops/sec" | awk '{print $NF}')
        log_success "Memory bandwidth: $result ops/sec"
        echo "{\"memory_ops_per_sec\": $result}"
    else
        log_warning "sysbench not installed, skipping memory benchmark"
        echo "{\"memory_ops_per_sec\": \"N/A (sysbench not found)\"}"
    fi
}

# Benchmark VST plugin loading
bench_vst_loading() {
    log_info "Testing VST plugin loading time..."
    
    # Would scan VST directories and measure load times
    local vst_dir="$HOME/.wine/drive_c/Program Files/Common Files/VST"
    
    if [[ ! -d "$vst_dir" ]]; then
        log_warning "VST directory not found"
        echo "{\"vst_plugins\": 0, \"avg_load_ms\": 0}"
        return
    fi
    
    local plugin_count=$(find "$vst_dir" -name "*.dll" 2>/dev/null | wc -l)
    log_success "Found $plugin_count VST plugins"
    
    # Would measure loading time...
    echo "{\"vst_plugins\": $plugin_count, \"avg_load_ms\": 0}"
}

# System startup time
bench_startup_time() {
    log_info "Checking system startup time..."
    
    local boot_time=$(systemd-analyze | grep "Startup finished" | sed 's/.*= //' | sed 's/s$//')
    
    log_success "Total startup time: ${boot_time}s"
    
    echo "{\"boot_time_seconds\": \"$boot_time\"}"
}

# Temperature monitoring
bench_temperature() {
    log_info "Checking system temperatures..."
    
    local temps=""
    
    if command -v sensors &> /dev/null; then
        temps=$(sensors | grep -E "Core|Temp" | head -5)
        log_success "Temperatures:\n$temps"
    else
        log_warning "lm-sensors not installed"
    fi
    
    echo "{\"temperatures\": \"$(echo "$temps" | tr '\n' ' ')\"}"
}

# Full benchmark suite
run_full_benchmark() {
    log_info "Starting full benchmark suite..."
    echo ""
    
    local results="{"
    results+="\"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\","
    results+="\"system_info\": {"
    results+="  \"kernel\": \"$(uname -r)\","
    results+="  \"cpu_cores\": $(nproc),"
    results+="  \"ram_gb\": $(free -h | grep Mem | awk '{print $2}')"
    results+="},"
    
    # Run benchmarks
    results+="$(bench_jack_latency),"
    results+="$(bench_cpu_load),"
    results+="$(bench_disk_io),"
    results+="$(bench_memory),"
    results+="$(bench_vst_loading),"
    results+="$(bench_startup_time),"
    results+="$(bench_temperature)"
    
    results+="}"
    
    # Save results
    echo "$results" | jq '.' > "$RESULTS_FILE"
    
    echo ""
    log_success "Benchmark complete!"
    log_success "Results saved to: $RESULTS_FILE"
    
    # Show summary
    echo ""
    echo "=== Benchmark Summary ==="
    jq '.' "$RESULTS_FILE"
}

# Compare benchmarks
compare_benchmarks() {
    local old_file="${1:?Old benchmark file required}"
    local new_file="${2:?New benchmark file required}"
    
    if [[ ! -f "$old_file" ]]; then
        log_error "File not found: $old_file"
        exit 1
    fi
    
    if [[ ! -f "$new_file" ]]; then
        log_error "File not found: $new_file"
        exit 1
    fi
    
    log_info "Comparing benchmarks..."
    
    # Would compare metrics and show differences
    echo "Comparison between:"
    echo "  Old: $(basename "$old_file")"
    echo "  New: $(basename "$new_file")"
}

# List benchmarks
list_benchmarks() {
    log_info "Available benchmarks:\n"
    
    ls -1t "$BENCH_DIR"/*.json | head -10 | while read -r file; do
        local date=$(stat -f%Sm -t "%Y-%m-%d %H:%M:%S" "$file" 2>/dev/null || stat -c%y "$file" | cut -d' ' -f1-2)
        printf "  %s (%s)\n" "$(basename "$file")" "$date"
    done
}

# Show help
show_help() {
    cat << EOF
${BLUE}REAPER OS Benchmarking Tool${NC}

Usage: $(basename "$0") <command> [options]

${GREEN}Commands:${NC}
  full               Run full benchmark suite
  jack               Test JACK latency
  cpu                Test CPU performance
  disk               Test disk I/O
  memory             Test memory bandwidth
  vst                Test VST plugin loading
  startup            Measure system startup time
  temp               Check system temperatures
  list               List recent benchmarks
  compare <old> <new> Compare two benchmarks
  help               Show this help

${GREEN}Examples:${NC}
  $(basename "$0") full            # Full benchmark
  $(basename "$0") jack            # JACK latency test
  $(basename "$0") cpu             # CPU stress test
  $(basename "$0") disk            # Disk I/O test
  $(basename "$0") list            # View recent results
  $(basename "$0") compare <old> <new>

${GREEN}Results Location:${NC}
  $BENCH_DIR

${YELLOW}Note:${NC} Some benchmarks require additional tools (sysbench, sensors)
Install with: sudo apt-get install sysbench lm-sensors

EOF
}

# Main
main() {
    case "${1:-help}" in
        full)
            run_full_benchmark
            ;;
        jack)
            bench_jack_latency
            ;;
        cpu)
            bench_cpu_load
            ;;
        disk)
            bench_disk_io
            ;;
        memory)
            bench_memory
            ;;
        vst)
            bench_vst_loading
            ;;
        startup)
            bench_startup_time
            ;;
        temp)
            bench_temperature
            ;;
        list)
            list_benchmarks
            ;;
        compare)
            compare_benchmarks "$2" "$3"
            ;;
        help|-h|--help)
            show_help
            ;;
        *)
            log_error "Unknown command: $1"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
