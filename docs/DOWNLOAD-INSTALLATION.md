# REAPER OS - Download & Installation Guide

## 📥 Download

### Latest Release

Download the latest REAPER OS release from GitHub:

**[→ Download REAPER OS from GitHub Releases](https://github.com/devfrp/REAPER-OS/releases)**

### What to Download

```
reaper-os-X.X.X-amd64.iso          ← Main ISO image (use this)
SHA256SUMS                           ← Checksums for verification
INSTALLATION.txt                    ← Installation instructions
RELEASE_NOTES.md                    ← What's included
```

### System Requirements

- **RAM**: 4GB minimum (8GB recommended)
- **Disk**: 20GB free space
- **USB**: USB 3.0 drive (4GB+)
- **Audio Interface**: Optional but recommended
- **Internet**: For first-boot setup

---

## 🔐 Verify Download

### Why Verify?

Checksums verify that:
- ✓ File wasn't corrupted during download
- ✓ File wasn't tampered with
- ✓ Your download completed successfully

### How to Verify

**Linux / macOS**:
```bash
# Download SHA256SUMS
# Download reaper-os-X.X.X-amd64.iso
# Run verification:

sha256sum -c SHA256SUMS

# Should output:
# reaper-os-X.X.X-amd64.iso: OK
```

**Windows (PowerShell)**:
```powershell
# Download SHA256SUMS and ISO to same directory
# Open PowerShell and run:

Get-FileHash reaper-os-X.X.X-amd64.iso -Algorithm SHA256 | Format-List

# Compare hash with SHA256SUMS file manually
```

**Windows (WSL)**:
```bash
# Open WSL terminal:
sha256sum -c SHA256SUMS
```

---

## 💾 Create Bootable USB

### Linux

```bash
# Find USB device:
lsblk

# Unmount if mounted:
sudo umount /dev/sdX*

# Write ISO:
sudo dd if=reaper-os-*.iso of=/dev/sdX bs=4M status=progress
sudo sync

# Eject:
sudo eject /dev/sdX
```

**⚠️ WARNING**: Replace `sdX` with your USB device (e.g., `sdb`)!

### macOS

```bash
# Find USB device:
diskutil list

# Unmount:
diskutil unmountDisk /dev/diskX

# Write ISO:
sudo dd if=reaper-os-*.iso of=/dev/rdiskX bs=4m

# Eject:
diskutil ejectDisk /dev/diskX
```

### Windows

**Option 1: Rufus** (Recommended)
1. Download [Rufus](https://rufus.ie/)
2. Run Rufus
3. Select ISO file
4. Select USB drive
5. Click "Start"
6. Wait for completion

**Option 2: Balena Etcher**
1. Download [Balena Etcher](https://balena.io/etcher)
2. Run Etcher
3. Select ISO
4. Select USB drive
5. Click "Flash"

---

## 🚀 Installation

### Step 1: Boot from USB

1. **Insert USB drive** into computer
2. **Restart** computer
3. **Enter boot menu**:
   - Press **F2** or **F12** (varies by manufacturer)
   - Alternative: **Del**, **ESC**, **Esc**
4. **Select USB drive** from boot menu
5. **Wait** for REAPER OS to load

### Step 2: Follow Installer

1. **Language**: Select your language
2. **Region**: Choose timezone and keyboard layout
3. **Disk**: Select installation disk (usually `/dev/sda`)
4. **Partition**: Choose automatic or manual partitioning
5. **User**: Create user account
6. **Install**: Confirm and wait for installation

**Typical installation time**: 10-20 minutes

### Step 3: First Boot

After installation:

1. **System starts** → REAPER OS boots
2. **Automatic setup** → Audio and tools are configured
3. **REAPER launches** → DAW opens automatically
4. **First run** → Configure audio interface and controls

---

## ✅ Post-Installation Setup

### Verify Installation

```bash
# Open terminal and run:
reaper-diagnostics --report

# Should show:
# ✓ JACK Status: ONLINE
# ✓ Audio devices detected
# ✓ REAPER: RUNNING
```

### Configure Audio

```bash
# Launch audio configuration manager:
audio-config-manager

# Options:
# 1. List existing profiles
# 2. Create profile for your audio setup
# 3. Load profile
```

### Test Controllers

```bash
# Test MIDI and OSC controllers:
test-controllers

# Options:
# - Detect MIDI devices
# - Monitor MIDI events
# - Test OSC network
# - Test MCU/Eucon protocols
```

---

## 🎛️ First Audio Setup

### 1. Connect Audio Interface

```bash
# Detect connected interfaces:
test-controllers detect-midi

# Should show your interface detected
```

### 2. Open Audio Settings

In REAPER:
- **Preferences** → **Audio** → **Device**
- Select your audio interface
- Set **Sample Rate**: 48kHz (or your interface preference)
- Set **Buffer Size**: 256 samples (4ms latency)

### 3. Test Audio

```bash
# Test latency:
reaper-diagnostics

# You should see <5ms latency with proper setup
```

---

## 🎮 Control Surface Setup

### MCU (Behringer X-Touch)

```bash
# Test MCU device:
test-controllers test-mcu

# In REAPER:
# - Preferences → Control Surfaces
# - Add → Mackie Control
# - Device: Auto-detected
# - Success!
```

### iPad/Mobile (OSC)

```bash
# Check OSC is listening:
test-controllers test-osc 8000

# On iPad:
# 1. Download Lemur or Controlly app
# 2. Enter IP address: [Your computer IP]
# 3. Port: 8000
# 4. Connect
```

### Generic MIDI

```bash
# Monitor MIDI input:
test-controllers monitor-midi

# Move faders, press buttons
# You'll see MIDI events in real-time
```

---

## 🛠️ Troubleshooting

### JACK Won't Start

```bash
# Check status:
systemctl --user status jack

# Start manually:
jackd -d alsa &

# Check logs:
journalctl --user-unit=jack.service
```

**Solutions**:
- Install JACK: `sudo apt-get install jack2`
- Check audio device: `aplay -l`
- Try different sample rate: `jackd -d alsa -r 44100`

### No Audio Devices Detected

```bash
# List audio devices:
aplay -l
arecord -l

# Check ALSA:
alsactl init

# Check USB:
lsusb | grep -i audio
```

**Solutions**:
- Connect audio interface
- Install firmware: `sudo apt-get install firmware-linux-nonfree`
- Load USB audio module: `sudo modprobe snd_usb_audio`

### MIDI Devices Not Detected

```bash
# Check MIDI:
aconnect -l

# Check USB:
lsusb | grep -i midi

# Load MIDI modules:
sudo modprobe snd_seq
sudo modprobe snd_usb_midi
```

### VST Plugins Not Found

```bash
# Rescan VST plugins:
# In REAPER → Preferences → VST

# Check Wine paths:
ls "$HOME/.wine/drive_c/Program Files/Common Files/VST/"
```

---

## 📚 Documentation

- **[README.md](README.md)** - Project overview
- **[GETTING-STARTED.md](GETTING-STARTED.md)** - Quick start
- **[docs/AUDIO-INTERFACE-SUPPORT.md](docs/AUDIO-INTERFACE-SUPPORT.md)** - Audio setup
- **[docs/CONTROL-PROTOCOLS.md](docs/CONTROL-PROTOCOLS.md)** - Control surfaces
- **[tools/README.md](tools/README.md)** - Tools documentation
- **[docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)** - Detailed help

---

## ❓ Support

### Getting Help

1. **Check Documentation** - Most questions answered in docs/
2. **Run Diagnostics** - `reaper-diagnostics` shows system status
3. **Check Logs** - `journalctl` for system errors
4. **GitHub Issues** - Report bugs: [Issues](https://github.com/devfrp/REAPER-OS/issues)

### Common Questions

**Q: Can I dual-boot with Windows?**
A: Yes! Install REAPER OS on separate partition

**Q: Is my VST plugin supported?**
A: Check [VST-SETUP.md](docs/VST-SETUP.md) for compatibility

**Q: How do I backup my REAPER settings?**
A: Use `audio-config-manager` to save profiles

**Q: Can I use my hardware controllers?**
A: Yes! See [CONTROL-PROTOCOLS.md](docs/CONTROL-PROTOCOLS.md)

---

## 🔄 Updates

### Check for Updates

```bash
# Check current version:
cat /etc/reaper-os-release

# Update system:
sudo apt update
sudo apt upgrade -y

# Update REAPER:
# Built-in REAPER updater or download from cockos.com
```

### Get Latest Release

New releases are available at:
**[GitHub Releases](https://github.com/devfrp/REAPER-OS/releases)**

Subscribe to notifications to be alerted of new versions.

---

## ✨ Next Steps

1. ✅ Download and verify ISO
2. ✅ Create bootable USB
3. ✅ Install REAPER OS
4. ✅ Configure audio interface
5. ✅ Set up control surface
6. ✅ Start creating music!

---

## 📞 Contact

- **Issues**: [GitHub Issues](https://github.com/devfrp/REAPER-OS/issues)
- **Documentation**: See `docs/` directory
- **Email**: support@reaper-os.dev

---

**Welcome to REAPER OS!** 🎵
