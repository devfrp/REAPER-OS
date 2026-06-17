# REAPER OS v1.0.0 - Quick Start Guide (5 Minutes)

## ⚡ Installation in 3 Steps (5 minutes)

### Step 1: Download
```bash
# The installer is part of the release
# Download from: https://github.com/devfrp/REAPER-OS/releases/tag/v1.0.0
```

### Step 2: Run Installer
```bash
# Choose one method:

# OFFLINE (Recommended - all tools included)
sudo bash install-offline.sh

# ONLINE (Downloads from repos)
sudo bash install-online.sh
```

### Step 3: Verify
```bash
# Check installation
bash health-check.sh

# You should see ✓ checks passing
```

**That's it! REAPER OS is installed!** 🎉

---

## 🎵 First Audio Project (10 minutes)

### 1. Start REAPER
```bash
# Launch REAPER
reaper &

# Or use the applications menu
```

### 2. Create New Project
```
File > New Project
```

### 3. Record Audio
```
1. Click "Record" button (red dot)
2. Speak/play into microphone
3. Click "Stop"
4. Listen back on playback
```

### 4. Save Project
```
File > Save Project As...
Select a name and location
```

**Your first REAPER project is ready!** 🎧

---

## 🔊 Enable JACK Audio (Optional but Recommended)

### Quick JACK Setup
```bash
# Install JACK controller (if not already included)
sudo apt install qjackctl

# Start JACK
# Method 1: Terminal
jackd -d alsa -r 48000 -p 256 &

# Method 2: GUI (recommended)
qjackctl &  # Click "Start" button
```

### Connect Devices
```
In qjackctl:
1. Click "Connections" button
2. Connect your audio interface
3. Route to REAPER in Audio tab
```

---

## 🎤 Included Tools

**34 Professional Audio Tools:**

| Category | Tools |
|----------|-------|
| **DAW** | REAPER, Ardour, Patchage |
| **Recording** | Audacity, Ardour, RecordMyDesktop |
| **Synthesis** | Calf Studio Gear, Linux Multimedia Studio |
| **Effects** | JACK Rack, SoX, Audacity Effects |
| **MIDI** | MuseScore, TiMidity++, QMidiArp |
| **Analysis** | Spectacle, JAAA, Audacity Analyzer |
| **Tools** | JACK, FFmpeg, SoX, ImageMagick |

**Access Tools:**
```bash
# From application menu or terminal
reaper          # REAPER DAW
ardour          # Ardour DAW  
audacity        # Audio editor
musescore       # Music notation
qjackctl        # JACK controller
timidity        # MIDI player
sox             # Sound converter
ffmpeg          # Video/audio converter
```

---

## 📚 Essential Workflows

### Workflow 1: Record Podcast
```
1. Launch REAPER
2. Create new track
3. Set input to microphone
4. Click Record
5. Speak into microphone
6. Stop when done
7. File > Export > WAV/MP3
```

### Workflow 2: Edit Audio
```
1. Open Audacity or REAPER
2. Open existing audio file
3. Select portion to edit
4. Apply effects or cut
5. Export as new file
```

### Workflow 3: Compose Music
```
1. Open MuseScore or REAPER
2. Add musical notation/MIDI tracks
3. Record or enter notes
4. Arrange composition
5. Export as MIDI or audio
```

### Workflow 4: Convert Audio Format
```
# Terminal method (fastest)
ffmpeg -i input.wav output.mp3

# Or use GUI tool
# Open file in Audacity
# File > Export > Select format
```

---

## 🆘 Quick Troubleshooting

### "No sound output"
```bash
# Check JACK is running
jackd -v

# Check audio devices
aplay -l

# Restart JACK
killall jackd
sleep 1
jackd -d alsa -r 48000 &
```

### "REAPER won't start"
```bash
# Try from terminal for error messages
reaper

# Or check installation
sudo apt install --reinstall reaper
```

### "Permission denied on installer"
```bash
# Make sure you're using sudo
sudo bash install-offline.sh

# Not
bash install-offline.sh
```

### "Installer says package not found"
```bash
# Update package lists first
sudo apt update

# Then run installer again
sudo bash install-online.sh
```

---

## 🎯 Next Steps

### To Learn More
1. **Beginner**: Watch [REAPER tutorials](https://www.reaper.fm/videos.php)
2. **Tips**: Read [BEST-PRACTICES.md](BEST-PRACTICES.md)
3. **Issues**: Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
4. **Advanced**: Explore [docs/](docs/) folder

### Useful Commands
```bash
# Health check
bash health-check.sh

# Update packages
sudo apt update && sudo apt upgrade

# Run maintenance
bash maintenance.sh

# View documentation
make docs
```

### Key Files
- 📖 [README.md](README.md) - Full documentation
- 🔧 [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Problem solving
- 💡 [BEST-PRACTICES.md](BEST-PRACTICES.md) - Optimization tips
- 📚 [DOCUMENTATION-INDEX.md](DOCUMENTATION-INDEX.md) - All docs

---

## 🎉 You're Ready!

You now have:
- ✅ REAPER and Ardour (professional DAWs)
- ✅ 34 audio tools pre-configured
- ✅ JACK audio connection kit
- ✅ Complete MIDI support
- ✅ Professional mastering tools

**Start creating music! 🎵**

---

## 💪 Getting Help

| Issue | Solution |
|-------|----------|
| Installation failed | Read [TROUBLESHOOTING.md](TROUBLESHOOTING.md) |
| No sound | Run `bash health-check.sh` |
| Performance issues | Check [BEST-PRACTICES.md](BEST-PRACTICES.md) |
| Feature request | Open [GitHub issue](https://github.com/devfrp/REAPER-OS/issues) |

---

**REAPER OS v1.0.0** - Professional Audio for Linux
Visit: https://github.com/devfrp/REAPER-OS
