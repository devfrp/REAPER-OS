# REAPER OS v1.0.0 - Troubleshooting & FAQ

## Installation Issues

### Q: Installer says "Permission Denied"
**A:** The installer requires sudo privileges. Run:
```bash
sudo bash install-offline.sh
```

### Q: Installation fails with "Package not found"
**A:** For online installer, ensure internet connection is available:
```bash
# Check internet connection
ping google.com

# Then retry
sudo bash install-online.sh
```

### Q: Offline installer is missing files
**A:** Ensure all installer files are present:
```bash
ls -la installer/
# Should show: install-offline.sh, install-online.sh, etc.
```

### Q: Installation hangs during package download
**A:** This can happen with slow internet. Wait longer (5-10 minutes) or:
1. Cancel with Ctrl+C
2. Check internet speed
3. Retry the installer

## Audio & JACK Issues

### Q: JACK won't start
**A:** 
```bash
# Check JACK status
jackd -v

# Restart JACK service
sudo systemctl restart jackd

# Check for conflicts
sudo lsof | grep audio
```

### Q: No sound after installation
**A:**
1. Check if JACK is running: `jackd -v`
2. Verify audio device: `arecord -l`
3. Check volume levels: `amixer`
4. Review JACK connections: `qjackctl`

### Q: Audio is crackling/stuttering
**A:**
1. Increase JACK buffer size in JACK Control
2. Reduce system load (close other apps)
3. Check CPU usage: `top`
4. Update kernel drivers

### Q: REAPER shows no audio devices
**A:**
1. Verify JACK is running
2. Check PulseAudio isn't blocking JACK
3. Run: `sudo systemctl stop pulseaudio`
4. Restart REAPER

## System Issues

### Q: System is very slow after installation
**A:**
1. Check disk space: `df -h`
2. Check RAM usage: `free -m`
3. Check running processes: `top`
4. Uninstall unused tools if needed

### Q: Real-time performance isn't good
**A:**
1. Check if running RT kernel: `uname -r`
2. Check thread priority: `ps aux | grep jackd`
3. Set performance governor: `sudo cpupower frequency-set -g performance`

### Q: Installation broke my other applications
**A:**
1. Check if only audio tools are affected
2. Review installer logs: `~/.reaper-os-install.log`
3. Verify library versions didn't change
4. Try uninstalling problematic tools

## Uninstallation

### Q: How do I uninstall REAPER OS?
**A:** Currently, uninstall individual tools as needed:
```bash
sudo apt remove [package-name]
```

To clean all REAPER OS packages:
```bash
sudo apt autoremove
sudo apt autoclean
```

**Note:** v1.1.0 will include an uninstaller script.

## Upgrading & Updates

### Q: How do I update installed tools?
**A:**
```bash
# Update package lists
sudo apt update

# Upgrade specific tools
sudo apt upgrade [package-name]

# Or upgrade all
sudo apt upgrade
```

### Q: Will v1.1.0 upgrade automatically?
**A:** No, you'll need to download and run the new installer. See [ROADMAP.md](ROADMAP.md).

## Compatibility

### Q: Will this work on my Ubuntu version?
**A:** Supported versions:
- ✅ Ubuntu 22.04 LTS
- ✅ Ubuntu 20.04 LTS
- ✅ Debian 13 (Bookworm)
- ✅ WSL2 with Ubuntu

### Q: Can I use this on Fedora/Arch?
**A:** Not yet. v2.0.0 will add support. Currently Debian-based only.

### Q: Can I use this on older Debian versions?
**A:** Not recommended. Debian 13+ is required for dependency versions.

## Performance

### Q: How much disk space does REAPER OS need?
**A:** 
- Minimal: 10GB (just tools)
- Recommended: 20GB (tools + projects)
- Full: 50GB+ (tools + samples + archives)

### Q: What are the minimum hardware requirements?
**A:**
- CPU: 2+ cores @ 2.0+ GHz
- RAM: 4GB minimum, 8GB+ recommended
- Storage: 20GB SSD recommended
- Audio Interface: Any with Linux drivers

### Q: Can I run this on a Raspberry Pi?
**A:** Not currently. ARM architecture support planned for v2.0.0.

## Mobile App

### Q: Is the mobile app included?
**A:** Not in v1.0.0. Planned for v1.2.0.

### Q: Can I control REAPER remotely?
**A:** Yes, using:
- REAPER's built-in OSC support
- Third-party controllers (Lemur, etc.)
- Web browser interfaces (if configured)

## Contributing & Support

### Q: Where do I report bugs?
**A:** Create an issue on GitHub:
https://github.com/devfrp/REAPER-OS/issues

Include:
- OS version
- Installation method (online/offline)
- Error message
- Steps to reproduce

### Q: Can I contribute improvements?
**A:** Yes! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Q: Where can I ask questions?
**A:** Use GitHub Discussions:
https://github.com/devfrp/REAPER-OS/discussions

---

## Still Have Issues?

1. **Check logs:**
   ```bash
   cat ~/.reaper-os-install.log
   journalctl -xe
   ```

2. **Try reinstalling:**
   ```bash
   sudo bash install-offline.sh
   ```

3. **Report it:**
   - GitHub Issues: bugs and errors
   - GitHub Discussions: questions and help
   - Email: see CONTRIBUTORS.md

**REAPER OS Support** 🎵
