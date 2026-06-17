# REAPER OS Installation Guide

Complete instructions for installing and configuring REAPER OS.

## Quick Start (5 minutes)

### For New Users

```bash
# 1. Validate system compatibility
sudo bash installer/install-offline.sh --validate

# 2. Install REAPER OS
sudo bash installer/install-offline.sh

# 3. Verify installation
bash installer/install-quick-ref.sh verify

# 4. Configure audio
bash installer/install-quick-ref.sh
```

## Installation Methods

### Method 1: Offline Installation (Recommended)

**Best for:** Clean Linux installations, limited internet, ISO-based setup

```bash
# Validate system before installing
sudo bash installer/install-offline.sh --validate

# Run offline installer with verbose output
sudo bash installer/install-offline.sh --verbose

# Verify the installation
bash installer/install-quick-ref.sh verify
```

**What gets installed:**
- Core REAPER OS files and tools (36+ utilities)
- System dependencies (ffmpeg, JACK, audio libraries)
- Python packages for audio analysis
- Audio configuration tools
- Hardware controller support
- Documentation and guides

**Time required:** 30-45 minutes depending on system speed

### Method 2: Online Installation

**Best for:** Fresh systems with good internet, automatic updates enabled

```bash
# Run online installer
sudo bash installer/install-online.sh

# The online installer will:
# - Download latest packages
# - Install all dependencies
# - Configure system for production use
```

### Method 3: Quick Reference Setup

**Best for:** Post-installation configuration and verification

```bash
# Launch interactive setup menu
bash installer/install-quick-ref.sh

# Or run specific checks:
bash installer/install-quick-ref.sh validate  # Pre-flight checks
bash installer/install-quick-ref.sh verify    # Post-install verification
bash installer/install-quick-ref.sh setup     # Run full setup
```

## System Requirements

### Minimum Requirements
- **OS:** Debian 13 (Bookworm) or Ubuntu 20.04 LTS+
- **RAM:** 4GB (8GB recommended)
- **Disk:** 20GB free space
- **CPU:** Dual-core processor
- **Connection:** Internet for online installer (offline mode available)

### Recommended Setup
- **OS:** Ubuntu 22.04 LTS or Debian 13 Bookworm
- **RAM:** 16GB+ (for large projects)
- **Disk:** SSD with 50GB+ free space
- **CPU:** 6-core processor or better
- **Audio:** USB audio interface with low-latency drivers

### Audio Interface Recommendations
- **Budget:** Behringer U-Phoria UMC202HD
- **Professional:** MOTU 828 mk3, RME Babyface
- **Mastering:** Lynx Aurora N, Antares Mastering
- **Live:** PreSonus StudioLive AR series

## Pre-Installation Checks

### System Compatibility

```bash
# Check if system is compatible before installing
sudo bash installer/install-offline.sh --validate
```

This checks:
- ✓ Operating system (Debian/Ubuntu)
- ✓ Disk space (minimum 20GB free)
- ✓ RAM availability (minimum 4GB)
- ✓ Root permissions
- ✓ Required commands (bash, apt-get, python3)
- ✓ Network connectivity (optional)

### Dependency Check

```bash
# List all dependencies that will be installed
bash installer/install-quick-ref.sh
```

## Installation Steps

### Step 1: Prepare System

```bash
# Update system
sudo apt-get update
sudo apt-get upgrade -y

# Check available space
df -h /

# Check RAM
free -h
```

### Step 2: Run Installation

```bash
# With default settings
sudo bash installer/install-offline.sh

# With verbose output (see detailed progress)
sudo bash installer/install-offline.sh --verbose

# Without network (offline mode)
# Installer automatically detects if offline
sudo bash installer/install-offline.sh
```

### Step 3: Verify Installation

```bash
# Quick verification
bash installer/install-quick-ref.sh verify

# Detailed verification
bash health-check.sh

# Full system diagnostics
bash tools/reaper-diagnostics.sh --detailed
```

### Step 4: Initial Configuration

```bash
# Launch interactive setup menu
bash installer/install-quick-ref.sh

# Or configure manually:

# 1. Setup audio
bash tools/audio-config-manager.sh list
bash tools/audio-config-manager.sh create default

# 2. Detect controllers
bash tools/hardware-controller-mapper.sh detect

# 3. Optimize performance
sudo bash tools/performance-tuner.sh optimize

# 4. Run system health check
bash health-check.sh
```

## Installation Logs

All installation progress is logged to:

```
/var/log/reaper-os-install.log
```

### View Installation Log

```bash
# View last 50 lines
tail -50 /var/log/reaper-os-install.log

# View entire log
cat /var/log/reaper-os-install.log

# Search for errors
grep "ERROR\|error" /var/log/reaper-os-install.log

# Monitor installation (while running)
tail -f /var/log/reaper-os-install.log
```

## Troubleshooting Installation

### Issue: Insufficient Disk Space

**Error:** `Disk space insufficient (20GB required)`

**Solution:**
```bash
# Check current disk usage
df -h

# Clean system
sudo apt-get clean
sudo apt-get autoclean

# Remove old kernels
sudo apt-get autoremove

# Check available space again
df -h
```

### Issue: Package Installation Failed

**Error:** `Unable to install package: ffmpeg`

**Solution:**
```bash
# Try manual installation
sudo apt-get install -y ffmpeg

# If that fails, check repository
sudo apt-cache search ffmpeg

# Install alternative
sudo apt-get install -y libav-tools
```

### Issue: Permission Denied

**Error:** `Permission denied: /opt/reaper-os`

**Solution:**
```bash
# Run with sudo
sudo bash installer/install-offline.sh

# Or fix permissions
sudo chown $USER /opt/reaper-os
```

### Issue: Python Packages Failed

**Error:** `Unable to install: flask`

**Solution:**
```bash
# Upgrade pip
sudo pip3 install --upgrade pip

# Install packages manually
pip3 install flask flask-socketio numpy scipy

# Check installation
python3 -c "import flask; print('Flask OK')"
```

### Issue: JACK Installation Failed

**Error:** `Unable to install: jackd2`

**Solution:**
```bash
# Install audio packages
sudo apt-get install jackd2 jack-tools alsa-utils pulseaudio

# Verify JACK
jackd --version

# Test JACK
jackd -dalsa &
sleep 2
jack_lsp
killall jackd
```

## Post-Installation Setup

### 1. Audio Interface Configuration

```bash
# List available audio devices
aplay -l
arecord -l

# Create JACK configuration for your interface
bash tools/audio-config-manager.sh create "My Audio Interface"

# Load the configuration
bash tools/audio-config-manager.sh load "My Audio Interface"
```

### 2. MIDI Controller Setup

```bash
# Detect controllers
bash tools/hardware-controller-mapper.sh detect

# Configure MCU protocol
bash tools/hardware-controller-mapper.sh config

# Test controller
bash tools/test-controllers.sh --mcu-test
```

### 3. Performance Optimization

```bash
# Optimize system for real-time audio
sudo bash tools/performance-tuner.sh optimize

# Measure latency
bash tools/benchmarking-tool.sh latency

# Run performance test
bash tools/benchmarking-tool.sh report
```

### 4. Backup Configuration

```bash
# Backup current configuration
bash tools/backup-restore.sh backup

# List available backups
bash tools/backup-restore.sh list
```

## Verification Checklist

After installation, verify all components:

- [ ] Installation directory exists: `/opt/reaper-os`
- [ ] Tools directory has shell scripts: `ls /opt/reaper-os/tools/*.sh`
- [ ] FFmpeg installed: `ffmpeg -version`
- [ ] Python 3 installed: `python3 --version`
- [ ] JACK available: `jackd --version`
- [ ] Audio interface detected: `aplay -l`
- [ ] Logs created: `/var/log/reaper-os-install.log`
- [ ] Documentation present: `ls /opt/reaper-os/docs/`
- [ ] Tools validator passes: `bash tools/tools-validator.sh`
- [ ] Health check passes: `bash health-check.sh`

## Getting Help

### Installation Support

```bash
# Show installation help
sudo bash installer/install-offline.sh --help

# Show quick reference menu
bash installer/install-quick-ref.sh

# Run diagnostics
bash tools/reaper-diagnostics.sh --detailed
```

### Documentation

- **Quick Start:** [QUICK-START.md](../QUICK-START.md)
- **Getting Started:** [GETTING-STARTED.md](../GETTING-STARTED.md)
- **Troubleshooting:** [TROUBLESHOOTING.md](../TROUBLESHOOTING.md)
- **Advanced Setup:** [ADVANCED-GUIDES.md](../ADVANCED-GUIDES.md)
- **Tools Guide:** [tools/TOOLS-README.md](../tools/TOOLS-README.md)

### Community Support

- **GitHub Issues:** https://github.com/devfrp/REAPER-OS/issues
- **Discussions:** https://github.com/devfrp/REAPER-OS/discussions
- **Community Tools:** `bash tools/community-marketplace.sh`

## Advanced Installation

### Installing from Source

```bash
# Clone repository
git clone https://github.com/devfrp/REAPER-OS.git
cd REAPER-OS

# Validate and install
sudo bash installer/install-offline.sh --verbose
```

### Custom Installation Path

```bash
# Edit installer to use custom path
sudo INSTALL_DIR="/home/user/reaper-os" bash installer/install-offline.sh
```

### Installation with Logging

```bash
# Run installation with full logging
LOG_FILE="/home/user/install-log.txt" \
  sudo bash installer/install-offline.sh --verbose

# View logs
less /home/user/install-log.txt
```

### Headless Installation (No Interactive Prompts)

```bash
# Run with automated responses
echo | sudo bash installer/install-offline.sh
```

## Uninstallation

### Remove REAPER OS

```bash
# Remove installation
sudo rm -rf /opt/reaper-os

# Remove launchers
sudo rm -f /usr/local/bin/reaper-os
sudo rm -f /usr/local/bin/reaper-dashboard

# Remove logs
sudo rm -f /var/log/reaper-os-install.log

# Remove configuration
rm -rf ~/.config/REAPER
rm -rf ~/.jack-settings
```

### Keep Configuration, Remove Installation

```bash
# Keep your settings but remove the software
sudo rm -rf /opt/reaper-os

# You can reinstall anytime and keep your configs
sudo bash installer/install-offline.sh
```

## Installation Statistics

### Default Installation

- **Time:** 30-45 minutes (offline), 15-20 minutes (online)
- **Disk usage:** ~8GB (including all dependencies)
- **Downloaded:** ~500MB-1GB (depends on cached packages)
- **Packages:** 15+ system packages
- **Python modules:** 9 packages
- **Tools installed:** 36+ shell scripts
- **Documentation:** 15+ guides

### Post-Installation

- **Total size:** ~8-10GB
- **Configuration files:** 5+ config files
- **Log files:** Automatic rotation enabled
- **Backup space:** Configurable (default 2GB)

## What Gets Installed

### System Packages
- **Audio:** JACK2, ALSA utils, PulseAudio
- **Tools:** FFmpeg, SoX, Git, Curl, Wget
- **Development:** GCC, Python3, Python3-dev, Build-essential
- **Libraries:** OpenSSL, LibFFI, Python3-pip

### Python Packages
- **Web:** Flask, Flask-SocketIO, Flask-CORS
- **Audio:** NumPy, SciPy
- **System:** psutil, requests
- **Config:** PyYAML
- **UI:** Colorama

### REAPER OS Tools (36+)
- Audio configuration and management
- Hardware controller support
- Video sync and timecode tools
- Streaming integration
- System diagnostics and monitoring
- Backup and restore utilities
- Performance tuning
- Community marketplace

### Documentation
- Installation guides
- Advanced guides
- Tools reference
- Troubleshooting guide
- Best practices
- Video player with timecode

## Next Steps

After installation:

1. **Read the Guide:** [QUICK-START.md](../QUICK-START.md)
2. **Configure Audio:** `bash tools/audio-config-manager.sh`
3. **Test System:** `bash health-check.sh`
4. **Explore Tools:** `bash tools/tools-validator.sh`
5. **Learn Advanced:** [ADVANCED-GUIDES.md](../ADVANCED-GUIDES.md)

## Additional Resources

### Installer Scripts
- `install-offline.sh` - Main offline installer with validation
- `install-online.sh` - Online installer with updates
- `install-quick-ref.sh` - Interactive setup and configuration

### System Files
- Installation logs: `/var/log/reaper-os-install.log`
- Main directory: `/opt/reaper-os`
- Configuration: `~/.config/REAPER/`
- JACK settings: `~/.jack-settings/`

### Support Resources
- Installation troubleshooting guide included
- Automatic diagnostics tools available
- Community support and examples
- Professional documentation

---

**Last Updated:** May 18, 2026  
**REAPER OS Version:** 1.0.0  
**Installation Guide Status:** ✅ Complete & Production Ready

For issues or questions, see [TROUBLESHOOTING.md](../TROUBLESHOOTING.md) or open an issue on GitHub.

```

**Étapes:**
1. ✅ Vérifie les prérequis (sudo, Debian/Ubuntu)
2. ✅ Installe les paquets système (déjà sur ISO)
3. ✅ Installe les dépendances Python
4. ✅ Crée la structure de dossiers
5. ✅ Copie tous les fichiers du projet
6. ✅ Configure JACK Audio
7. ✅ Configure REAPER
8. ✅ Crée les launchers
9. ✅ Initialise les bases de données

**Résultat:**
```
/opt/reaper-os/
├── tools/          ← Outils et services
├── scripts/        ← Scripts d'automation
├── docs/           ← Documentation
├── config/         ← Fichiers de configuration
├── data/           ← Données utilisateur
└── logs/           ← Fichiers de logs
```

### 2️⃣ En Ligne (Online)

```bash
# Installation sur un système Debian/Ubuntu existant

sudo bash /opt/reaper-os/installer/install-online.sh
```

**Étapes:**
1. ✅ Vérifie la connexion Internet
2. ✅ Crée un dossier temporaire
3. ✅ Met à jour les dépôts APT
4. ✅ Installe les paquets système (dernière version)
5. ✅ Installe les dépendances Python (dernière version)
6. ✅ **Télécharge depuis GitHub** (dernière version)
7. ✅ Crée la structure de dossiers
8. ✅ Copie les fichiers téléchargés
9. ✅ Installe les requirements du projet
10. ✅ Configure JACK, REAPER, launchers
11. ✅ Exécute les tests (optionnel)
12. ✅ Nettoie les fichiers temporaires

**Avantages:**
- ✨ Toujours la dernière version
- 📦 Dépendances Python récentes
- 🔄 Peut être réexécuté pour mettre à jour
- 💾 Plus petit à télécharger initialement

---

## 📦 Processus de construction

### Compiler l'ISO avec les deux installeurs

```bash
# Via WSL Debian
wsl -d Debian

cd /mnt/c/Users/admin/Documents/GitHub/REAPER\ OS

# Compiler l'ISO complète
bash installer/build-iso-with-installers.sh
```

**Résultat:**
```
build/iso-output/
├── reaper-os-debian-13-v1.0.0.iso          ← ISO bootable complète
└── reaper-os-debian-13-v1.0.0.iso.sha256   ← Checksum
```

### L'ISO contient

- 🐧 Debian 13 (Bookworm) complet
- 📦 Tous les paquets essentiels pré-installés
- 🛠️ REAPER OS v1.0.0 complet dans `/opt/reaper-os/`
- 📝 **Deux installeurs:**
  - `installer/install-offline.sh` - Configuration hors ligne
  - `installer/install-online.sh` - Configuration avec mises à jour
- 🎯 Script de bienvenue: `/root/INSTALL.sh`
- 🔨 Point d'entrée: `/root/startup.sh`

---

## 🚀 Utilisation de l'ISO

### Créer une clé USB bootable

```bash
# Identifier le périphérique USB
lsblk
# Exemple: /dev/sdb (NOT /dev/sdb1)

# Créer le USB bootable
sudo dd if=reaper-os-debian-13-v1.0.0.iso of=/dev/sdb bs=4M status=progress sync
```

### Démarrer depuis l'ISO

1. **Insérer la clé USB**
2. **Redémarrer l'ordinateur**
3. **Appuyer sur F12 (ou autre touche de boot)**
4. **Sélectionner le périphérique USB**
5. **Attendre le démarrage Debian**

### Une fois démarré

```bash
# Login: root (pas de mot de passe par défaut)

# Afficher les options d'installation
/root/INSTALL.sh

# Choisir la méthode
# Hors ligne:  sudo bash /opt/reaper-os/installer/install-offline.sh
# En ligne:    sudo bash /opt/reaper-os/installer/install-online.sh
```

---

## 📊 Comparaison détaillée

### Hors Ligne (offline)

**Avantages:**
- ⚡ Installation rapide (tout est préinstallé)
- ✅ Fonctionne sans Internet
- 📦 REAPER OS complet et testé
- 🔒 Versions figées et stables

**Inconvénients:**
- 📀 Fichier ISO volumineux (~8-12 GB)
- 📌 Dépendances Python potentiellement obsolètes
- 🔄 Nécessite recompilation pour mise à jour majeure

**Cas d'usage:**
- 🎵 Musiciens sans Internet stable
- ⏱️ Besoin d'installation rapide
- 🏠 Installation sur plusieurs machines (cloner la clé USB)
- 🔒 Environnements sécurisés/sans Internet

### En Ligne (Online)

**Avantages:**
- ✨ Dernière version de tous les paquets
- 📦 Mises à jour faciles (`git pull`)
- 💾 Téléchargement initial plus petit
- 🔄 Toujours à jour

**Inconvénients:**
- 🌐 Requiert une connexion Internet stable
- ⏳ Installation plus lente (téléchargements)
- 🔄 Dépend du réseau GitHub

**Cas d'usage:**
- 💻 Systèmes Debian/Ubuntu existants
- 🔄 Mises à jour régulières
- 🌐 Environnements connectés
- 📦 Installation en production

---

## 🛠️ Troubleshooting

### L'ISO ne démarre pas

```bash
# Vérifier le checksum
sha256sum reaper-os-debian-13-v1.0.0.iso
# Comparer avec le .sha256

# Recréer la clé USB
sudo dd if=reaper-os-debian-13-v1.0.0.iso of=/dev/sdX bs=4M status=progress sync
```

### Installation hors ligne échoue

```bash
# Vérifier les droits root
sudo id

# Vérifier la distribution
cat /etc/os-release

# Consulter les logs
cat /var/log/reaper-os-install.log
```

### Installation en ligne échoue

```bash
# Vérifier Internet
ping github.com

# Vérifier le dépôt GitHub
curl -I https://api.github.com

# Installer manuellement si nécessaire
cd /opt/reaper-os
pip3 install -r requirements.txt
```

---

## 📚 Fichiers de logs

### Hors ligne
```bash
cat /var/log/reaper-os-install.log
```

### En ligne
```bash
cat /var/log/reaper-os-install.log
cat /tmp/install.log
```

---

## 🔐 Sécurité

### Vérifier l'intégrité de l'ISO

```bash
# Après téléchargement
sha256sum reaper-os-debian-13-v1.0.0.iso > check.txt

# Comparer avec le .sha256 officiel
diff check.txt reaper-os-debian-13-v1.0.0.iso.sha256
# Doit être vide (pas de différence)
```

### Installer depuis des sources sécurisées

- ✅ Télécharger depuis [GitHub REAPER OS](https://github.com/devfrp/REAPER-OS)
- ✅ Vérifier le checksum SHA256
- ✅ Utiliser HTTPS pour les téléchargements
- ❌ Ne pas modifier les scripts d'installation

---

## 🎯 Prochaines étapes

Après installation (hors ligne ou en ligne):

```bash
# 1. Vérifier l'installation
reaper-os --version

# 2. Lancer le tableau de bord
reaper-dashboard

# 3. Consulter la documentation
less /opt/reaper-os/README.md

# 4. Tester les outils
cd /opt/reaper-os
python3 tools/system-dashboard.py
```

---

## 📞 Support

- 📖 Documentation: `/opt/reaper-os/docs/`
- 🐛 Bugs: GitHub Issues
- 💬 Questions: GitHub Discussions
- 🔐 Sécurité: `security@reaper-os.dev`

---

**REAPER OS v1.0.0**  
🎵 Distribution audio professionnelle pour Linux  
✨ Deux méthodes d'installation • Flexible • Robuste
