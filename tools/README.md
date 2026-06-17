# REAPER OS Tools Documentation

## Overview

REAPER OS includes three powerful diagnostic and management tools to help monitor, configure, and troubleshoot your audio setup without needing to launch REAPER.

## Tools Available

### 1. **reaper-diagnostics** - System Monitoring & Diagnostics

**Purpose**: Real-time monitoring of audio system health, latency, CPU load, and resource usage.

**Features**:
- JACK audio server status and latency monitoring
- Real-time CPU and memory usage tracking
- Audio device detection and status
- MIDI device enumeration
- OSC port monitoring
- REAPER process monitoring
- Detailed JACK, CPU, and memory views

**Usage**:
```bash
# Interactive mode (default)
reaper-diagnostics

# Continuous monitoring
reaper-diagnostics --continuous

# Single report
reaper-diagnostics --report

# Custom update interval (2 seconds)
reaper-diagnostics --continuous --interval 2
```

**Interactive Commands**:
- `[Enter]` - Refresh display
- `[j]` - Show JACK details
- `[c]` - Show CPU details
- `[m]` - Show memory details
- `[q]` - Quit

**Example Output**:
```
═══════════════════════════════════════════════════════════
     REAPER OS - System Diagnostics Report

📊 JACK AUDIO SERVER:
✓ JACK Status: ONLINE
✓ Latency: 5.33ms
✓ Active Ports: 24

💻 SYSTEM RESOURCES:
✓ CPU Load: 28.5%
✓ Memory Usage: 45.2%

🔊 AUDIO DEVICES:
✓ ALSA Status: OK
✓ Audio Cards Found: 2

🎛️  CONTROL SURFACES:
✓ MIDI Devices: 3
✓ OSC Port 8000: LISTENING

🎵 REAPER STATUS:
✓ REAPER: RUNNING
✓ Memory: 512MB
✓ CPU: 12.3%

✓ System Status: OPTIMAL
═══════════════════════════════════════════════════════════
```

---

### 2. **audio-config-manager** - Audio Profile Manager

**Purpose**: Save and restore complete audio configurations (ALSA, JACK, device routing) per project.

**Features**:
- Create named audio profiles
- Save current ALSA and JACK configuration
- Load profiles instantly
- Duplicate existing profiles
- Export/import profiles between systems
- Profile metadata tracking

**Usage**:
```bash
# Interactive menu (default)
audio-config-manager

# List all profiles
audio-config-manager list

# Create new profile
audio-config-manager create my-project

# Load profile
audio-config-manager load my-project

# Save current configuration to profile
audio-config-manager save my-project

# Delete profile
audio-config-manager delete old-profile

# Duplicate profile
audio-config-manager duplicate template my-copy

# Show profile details
audio-config-manager show my-project

# Export profile to file
audio-config-manager export my-project my-profile.tar.gz

# Import profile from file
audio-config-manager import my-profile.tar.gz
```

**Profile Structure**:
```
~/.config/reaper-audio-profiles/
├── my-project/
│   ├── metadata.conf          # Profile metadata
│   ├── jackrc                 # JACK configuration
│   ├── asoundrc               # ALSA configuration
│   ├── audio_settings.conf    # Audio settings snapshot
│   └── devices/
│       ├── playback.txt       # Available playback devices
│       ├── capture.txt        # Available capture devices
│       └── midi.txt           # MIDI devices at save time
```

**Example Workflow**:

1. **Set up audio for Studio Recording**:
   ```bash
   # Configure: 48kHz, 512-sample buffer, RME interface
   # Then save:
   audio-config-manager create studio-recording
   ```

2. **Set up audio for Live Performance**:
   ```bash
   # Configure: 48kHz, 256-sample buffer, low latency
   # Then save:
   audio-config-manager create live-performance
   ```

3. **Switch between profiles**:
   ```bash
   # Before starting a project:
   audio-config-manager load studio-recording
   
   # Before going live:
   audio-config-manager load live-performance
   ```

4. **Share configuration with team**:
   ```bash
   audio-config-manager export studio-recording studio.tar.gz
   # Send studio.tar.gz to team member
   # They import it:
   audio-config-manager import studio.tar.gz
   ```

---

### 3. **test-controllers** - Control Protocol Tester

**Purpose**: Test MIDI, OSC, and control surface connectivity without launching REAPER.

**Features**:
- MIDI device detection and enumeration
- MIDI event monitoring (listens for controller input)
- MCU (Mackie Control Universal) protocol testing
- HUI protocol testing (via MIDI Learn)
- OSC protocol testing (network/iPad support)
- Generic MIDI compatibility testing
- Port scanning and network diagnostics

**Usage**:
```bash
# Interactive menu (default)
test-controllers

# Detect MIDI devices
test-controllers detect-midi

# Monitor MIDI events for 30 seconds
test-controllers monitor-midi 30

# Test MCU protocol
test-controllers test-mcu

# Test HUI protocol
test-controllers test-hui

# Test OSC protocol (default port 8000)
test-controllers test-osc

# Test OSC on custom port
test-controllers test-osc 9000

# Test generic MIDI
test-controllers test-midi

# Run all tests
test-controllers test-all
```

**MIDI Monitoring**:
```bash
# Monitor for 60 seconds and watch for events
test-controllers monitor-midi 60

# Move faders, press buttons, turn knobs
# You'll see events like:
# 176:0   90   50   64    # CC event: controller 50 = 64
# 144:0   60   100  0     # Note on: note 60, velocity 100
# 128:0   60   0    0     # Note off: note 60
```

**Supported Protocols**:

| Protocol | Device Examples | Status |
|----------|-----------------|--------|
| **MCU** | Behringer X-Touch, Mackie Control | ✓ Full support |
| **Eucon** | Avid S6, S4, S3 | ✓ Full support (REAPER native) |
| **HUI** | Mackie HUI (via MIDI Learn) | ✓ Via MIDI Learn |
| **OSC** | iPad (Lemur, Controlly), Network | ✓ UDP/TCP |
| **Generic MIDI** | Any USB MIDI controller | ✓ Full support |
| **Keyboard** | Standard keyboard shortcuts | ✓ Built-in |

**Example Workflow**:

1. **Test MCU device before REAPER**:
   ```bash
   # Connect Behringer X-Touch
   test-controllers detect-midi
   # Should show: "Behringer X-Touch" 
   
   test-controllers test-mcu
   # Shows MCU protocol details and status
   ```

2. **Monitor MIDI input**:
   ```bash
   # Connect keyboard MIDI controller
   test-controllers monitor-midi
   # Move sliders, press buttons
   # See real-time MIDI events in output
   ```

3. **Test OSC network control**:
   ```bash
   # Check OSC is listening on port 8000
   test-controllers test-osc 8000
   
   # On iPad:
   # 1. Open Lemur or Controlly
   # 2. Connect to: osc.udp://192.168.1.100:8000
   # 3. Should see connection established
   ```

4. **Run full diagnostic**:
   ```bash
   # Test all controllers before session
   test-controllers test-all
   
   # Shows:
   # - MIDI devices detected
   # - MCU status
   # - OSC listening ports
   # - MIDI capabilities
   ```

---

## Tool Installation

Tools are automatically installed during first boot:

```bash
# Manual installation if needed:
cd /path/to/REAPER-OS
bash tools/install-tools.sh

# This installs tools to: ~/.local/bin/
# And updates PATH in ~/.bashrc and ~/.profile
```

## Integration Points

### First Boot
- `scripts/reaper-os-first-boot.sh` calls `tools/install-tools.sh` automatically

### Desktop Environment
Tools can be launched from terminal or added to:
- Application menu
- Desktop shortcuts
- System tray/panel applets

### Keyboard Shortcuts (can be configured)
- Alt+D - Open diagnostics
- Alt+A - Open audio manager
- Alt+T - Open controller tester

---

## Troubleshooting

### "Command not found"
```bash
# Tools are in ~/.local/bin
# Make sure PATH is set correctly:
echo $PATH

# Should contain: /home/username/.local/bin

# If not, add to ~/.bashrc:
export PATH="$HOME/.local/bin:$PATH"

# Then:
source ~/.bashrc
```

### JACK not detected
```bash
# Make sure JACK is installed:
which jackd

# If not found:
sudo apt-get install jack2

# Then start JACK:
jackd -d alsa &
```

### MIDI devices not detected
```bash
# Check ALSA MIDI is working:
aconnect -l

# If no devices, may need to load kernel modules:
sudo modprobe snd_usb_midi
sudo modprobe snd_seq
```

### OSC port already in use
```bash
# Find what's using port 8000:
sudo lsof -i :8000

# Change REAPER OSC port to 8001:
reaper-config/reaper.ini
[OSC]
osc_port=8001

# Or test on different port:
test-controllers test-osc 8001
```

---

## Performance Metrics

### Expected JACK Latency
- **256-sample buffer @ 48kHz**: ~5.3ms
- **512-sample buffer @ 48kHz**: ~10.7ms
- **256-sample buffer @ 44.1kHz**: ~5.8ms

### CPU Usage
- **Baseline (idle)**: 2-5%
- **REAPER + 5 tracks**: 15-25%
- **REAPER + 20 tracks + VSTs**: 40-60%
- **Warning threshold**: >80% CPU

### Memory Usage
- **JACK**: 50-100MB
- **REAPER baseline**: 200-300MB
- **Per VST instance**: 20-50MB (varies by plugin)
- **System total**: <80% of RAM recommended

---

## Advanced Usage

### Continuous System Monitoring
```bash
# Monitor system in separate terminal while recording:
reaper-diagnostics --continuous --interval 0.5
```

### Audio Configuration for Different Projects
```bash
# Recording (high buffer, low CPU)
audio-config-manager load recording

# Mixing (balanced)
audio-config-manager load mixing

# Mastering (low latency)
audio-config-manager load mastering

# Live Performance (minimal latency)
audio-config-manager load live
```

### Controller Setup Workflow
```bash
# 1. Test all controllers
test-controllers test-all

# 2. Start REAPER
reaper &

# 3. Monitor diagnostics in parallel
reaper-diagnostics --continuous &

# 4. Configure controllers in REAPER
# Options → Control Surfaces → Add
```

---

## See Also

- [docs/CONTROL-PROTOCOLS.md](../docs/CONTROL-PROTOCOLS.md) - Detailed protocol documentation
- [docs/AUDIO-QUICK-START.md](../docs/AUDIO-QUICK-START.md) - Audio setup guide
- [reaper-config/README.md](../reaper-config/README.md) - REAPER configuration details
