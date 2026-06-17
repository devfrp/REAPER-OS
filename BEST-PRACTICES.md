# REAPER OS v1.0.0 - Best Practices & Tips

## Installation & Setup

### 1. Choose the Right Installation Method

**Use Offline Installation If:**
- Unreliable internet connection
- Want maximum control over packages
- Prefer known, tested configurations
- Have bandwidth limitations

**Use Online Installation If:**
- Stable, fast internet connection
- Want latest package versions
- Have limited disk space for installer
- Prefer automatic dependency resolution

### 2. Pre-Installation Checks

Before installing, ensure:
```bash
# Check disk space (minimum 20GB)
df -h /

# Check RAM (minimum 4GB)
free -h

# Update system
sudo apt update
sudo apt upgrade

# Backup important data
sudo cp -r ~ ~/backup-$(date +%Y%m%d)
```

### 3. Post-Installation Verification

After installation:
```bash
# Run health check
bash health-check.sh

# Verify JACK installation
jackd -v

# Test audio devices
arecord -l
aplay -l
```

## Audio Workflow Optimization

### 1. JACK Configuration

**For Studio Recording:**
```bash
# Settings in JACK Control / qjackctl:
# Sample Rate: 48000 Hz
# Buffer Size: 256 samples
# Periods/Buffer: 3
# Latency: ~16ms
```

**For Live Performance:**
```bash
# Settings for minimal latency:
# Sample Rate: 48000 Hz
# Buffer Size: 128 samples
# Periods/Buffer: 2
# Latency: ~8ms
```

**For CPU-Limited Systems:**
```bash
# Settings for stability:
# Sample Rate: 44100 Hz
# Buffer Size: 512 samples
# Periods/Buffer: 3
# Latency: ~35ms
```

### 2. Real-time Performance

**Enable Real-time Priority:**
```bash
# Edit /etc/security/limits.conf
@audio   soft    rtprio    99
@audio   hard    rtprio    99
@audio   soft    memlock   unlimited
@audio   hard    memlock   unlimited

# Apply changes
sudo systemctl restart

# Add user to audio group
sudo usermod -a -G audio $USER
```

**Monitor CPU Usage:**
```bash
# Watch real-time CPU load
watch -n1 'ps aux | grep -E "reaper|ardour|jackd"'

# Check JACK CPU usage
jackd -d alsa | grep CPU
```

### 3. Plugin Management

**Organize Your Plugins:**
```bash
# Plugin directories:
~/.vst              # VST plugins
~/.vst3             # VST3 plugins
~/.lv2              # LV2 plugins
/usr/lib/lv2        # System LV2 plugins

# Scan for new plugins in REAPER:
# Options > Plugins > Re-scan VST plugins
```

## Troubleshooting Tips

### 1. Audio Dropout Issues

Common causes and solutions:
```bash
# 1. Check CPU load
top

# 2. Reduce background processes
killall dropbox         # If running
killall spotify         # If running
killall chrome          # Resource hog

# 3. Increase JACK buffer
qjackctl > Setup > Buffer Size > 512

# 4. Check disk I/O
iostat -x 1

# 5. Monitor JACK
jackd -d alsa -v       # Verbose output
```

### 2. MIDI Connectivity

**Enable MIDI Devices:**
```bash
# Connect physical MIDI controllers
aconnect -l          # List all ports

# In REAPER:
# Connections > MIDI Devices > Refresh
```

### 3. Plugin Compatibility

**Test Individual Plugins:**
```bash
# Create test project
# Insert single plugin
# Record audio
# Check for crashes

# If plugin crashes:
# Move from ~/.vst/
# Restart REAPER
# Re-scan plugins
```

## Security Best Practices

### 1. System Updates

Keep everything current:
```bash
# Weekly updates
sudo apt update && sudo apt upgrade

# Check for security updates
sudo apt list --upgradable

# Auto-update critical packages
sudo apt install unattended-upgrades
```

### 2. Audio File Backup

**Backup Strategy:**
```bash
# Daily local backup
rsync -av ~/ReaperProjects/ ~/backups/reaper-daily/

# Weekly cloud backup
aws s3 sync ~/ReaperProjects/ s3://my-audio-backup/

# Version control for projects
git init ~/ReaperProjects
git add -A
git commit -m "Project backup $(date)"
```

### 3. Secure Collaboration

When sharing projects:
```bash
# Remove personal data
find . -name ".git" -exec rm -rf {} \;
find . -name "*.log" -exec rm {} \;

# Compress for sharing
tar -czf reaper-project.tar.gz ReaperProjects/

# Verify authenticity
sha256sum reaper-project.tar.gz
```

## Performance Tuning

### 1. System Optimization

```bash
# Disable unnecessary services
sudo systemctl disable cups      # Printer daemon
sudo systemctl disable bluetooth # If not needed

# Set swappiness for audio work
sudo sysctl vm.swappiness=10

# Increase max open files
ulimit -n 65536
```

### 2. Network Optimization

For network audio streaming:
```bash
# Enable jumbo frames (if supported)
sudo ip link set dev eth0 mtu 9000

# Monitor network latency
ping -c 100 audio-server | tail -1

# Buffer for network streams
qjackctl > Setup > Periods/Buffer > 4
```

### 3. Memory Management

```bash
# Monitor RAM usage
free -m

# Enable swap if needed
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

## Workflow Tips

### 1. Project Organization

```
ReaperProjects/
├── 2026-05-Recording-Session/
│   ├── Project.RPP
│   ├── Audio/
│   ├── MIDI/
│   └── Rendered/
├── 2026-04-Mastering/
└── Templates/
    ├── Studio-Recording.RTP
    ├── Live-Performance.RTP
    └── Mixing.RTP
```

### 2. Template Creation

**Create Reusable Templates:**
```
In REAPER:
1. Set up tracks, routing, plugins
2. File > Save as... > Select "Project Template"
3. Name descriptively
4. File > New > From Template
```

### 3. Backup Workflow

```bash
# Before major changes
cp -r ReaperProjects ReaperProjects.backup-$(date +%Y%m%d)

# After finished projects
tar -czf reaper-$(date +%Y%m%d).tar.gz ReaperProjects/
```

## Common Workflows

### Studio Recording
1. Create project in template
2. Set input levels
3. Enable JACK monitoring
4. Record tracks
5. Organize & label
6. Save project copies
7. Export stems
8. Archive session

### Live Performance
1. Load template for venue
2. Check all MIDI/Audio connections
3. Test cue mixes
4. Do soundcheck
5. Record performance
6. Export immediately after
7. Backup to external drive

### Music Production
1. Start with template
2. Record/compose
3. Arrange sections
4. Create guide mix
5. Build instrumental
6. Record vocals
7. Mix tracks
8. Master

---

## More Resources

- **REAPER Manual**: https://www.reaper.fm/userguide.php
- **JACK Documentation**: https://jackaudio.org/documentation/
- **Audio Engineering**: https://wiki.debian.org/JACK
- **Linux Audio**: https://www.linuxaudio.org/

**REAPER OS** - Professional Audio for Everyone 🎵
