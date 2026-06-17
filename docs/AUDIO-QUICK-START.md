# Audio Integration Quick Start

## 🚀 5-Minute Setup: Complete Audio System on REAPER OS

### Step 1: One-Command Setup (Automatic)

```bash
# This single command sets up EVERYTHING:
bash scripts/audio-setup-all.sh

# What this does:
# ✓ Installs Wine dependencies for VST
# ✓ Auto-detects your audio interface (RME, UAD, Focusrite, etc.)
# ✓ Installs ALSA drivers
# ✓ Configures JACK for low-latency audio
# ✓ Creates Wine wrappers for Control Panels (RME Control, UAD Console, etc.)
# ✓ Sets up AudioGridder for VST isolation
# ✓ Initializes REAPER
```

**Time**: ~5-10 minutes (depending on internet speed)

### Step 2: Launch Your System

```bash
# Terminal 1: Start JACK audio server
jackd -d alsa &

# Terminal 2: Launch REAPER
reaper-start

# Terminal 3 (Optional): Open your control panel
rme-control-panel    # RME
uad-console         # Universal Audio
focusrite-control   # Focusrite
```

### Step 3: Configure REAPER

```
Preferences → Audio → Device
├─ Audio device: JACK
├─ Sample rate: 48000 Hz
├─ Buffer size: 256 samples
└─ Realtime: Enabled
```

### Done! ✅

You now have:
- ✅ Your audio interface working natively
- ✅ Windows VST plugins (both Wine and AudioGridder)
- ✅ Low latency audio (<2ms with RME, <5ms with most interfaces)
- ✅ Control Panel for your interface running
- ✅ Professional JACK audio routing

---

## 🎛️ Your Audio Interface is Supported

### Auto-Detected Interfaces Include:

**Professional Interfaces:**
- RME Babyface Pro, UFX II/III
- Universal Audio Apollo, Arrow, Volt
- Focusrite Scarlett, Clarett
- MOTU UltraLite, Traveler
- PreSonus StudioLive

**Budget Interfaces:**
- Behringer UMC, X32
- Audient iO2, iO4, iO8
- Roland AudioCapture
- Antelope Audio

**50+ More Brands Supported**

### Not on the list?
Most USB audio interfaces work automatically via ALSA. Even if not in our database, they'll still function with JACK.

---

## 📋 Control Panels Available

After setup, these commands work:

```bash
rme-control-panel       # RME Audio Interface Control
uad-console            # Universal Audio Console
focusrite-control      # Focusrite Control
presonus-control       # PreSonus StudioLive/AudioBox Control
behringer-control      # Behringer Control
motu-control           # MOTU Control Panel
native-instruments-control  # NI Komplete/Traktor
```

---

## 🎵 VST Workflow

### Load Windows VST Plugins in REAPER

After setup is complete, your VST plugins work TWO ways:

### Method 1: Wine Direct (Performance)
```
REAPER → Load VST.dll → Wine → Audio
Latency: 3-5ms
Performance: Excellent
```

### Method 2: AudioGridder (Stability)
```
REAPER → AudioGridder Plugin → Wine Server → VST.dll → Audio
Latency: 1-3ms
Stability: Excellent
Isolation: Crash-proof
```

**Recommendation**: Use AudioGridder for important sessions.

---

## ⚡ Low-Latency Tips

### Optimize for Performance

```bash
# 1. Reduce JACK buffer (if your interface supports it)
jackd -p 128  # Default is 256

# 2. Check your JACK status
jack_delay   # Measure actual latency

# 3. Use fewer VST plugins
# Each plugin adds ~0.5ms latency with Wine

# 4. Disable unnecessary background processes
killall -9 pulseaudio  # Use JACK exclusively
```

### Measure Latency

```bash
# Test your actual latency
jack_latent

# Expected results:
# RME interfaces: 1-2ms
# Most USB interfaces: 2-5ms
# With AudioGridder: 1-3ms
```

---

## 🐛 Troubleshooting

### Audio Interface Not Detected

```bash
# Check if interface is connected
lsusb | grep -i audio

# List all audio devices
aplay -l

# Force re-detection
bash scripts/audio-interface-setup.sh --scan

# Restart ALSA
sudo systemctl restart alsa-utils
```

### Control Panel Not Found

```bash
# Download from manufacturer website:
# - RME: https://www.rme-audio.de/
# - UAD: https://www.uaudio.com/
# - Focusrite: https://focusrite.com/

# Copy installer to Wine
cp Installer.exe ~/.wine/drive_c/

# Install via Wine
wine ~/.wine/drive_c/Installer.exe

# Launch
rme-control-panel  # (or your control panel)
```

### No Audio from REAPER

```bash
# 1. Verify JACK is running
jack_lsp

# 2. Verify REAPER is connected to JACK
# Preferences → Audio → Check device = JACK

# 3. Verify your interface
jackd -d alsa -d hw:1  # Try card 1 instead of default

# 4. Check volume levels
alsamixer
```

---

## 📚 More Information

See the complete documentation:

- **[AUDIO-INTERFACE-SUPPORT.md](AUDIO-INTERFACE-SUPPORT.md)** - 50+ interfaces detailed
- **[WINDOWS-AUDIO-CONTROL-PANELS.md](WINDOWS-AUDIO-CONTROL-PANELS.md)** - Control panel setup
- **[VST-SETUP.md](VST-SETUP.md)** - VST installation and troubleshooting
- **[REAPER-CONFIG.md](REAPER-CONFIG.md)** - REAPER audio optimization

---

## 🎵 You're Ready!

```bash
# Final checklist:
# ✓ Audio interface detected
# ✓ JACK running
# ✓ REAPER launched
# ✓ Control panel available
# ✓ VST plugins working
# ✓ Latency optimized

# Start creating music! 🎵
```

---

**REAPER OS: Professional Audio on Linux** 🎧✨
