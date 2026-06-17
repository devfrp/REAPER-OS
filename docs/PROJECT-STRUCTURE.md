# REAPER OS - Project Structure & Architecture

Complete guide to REAPER OS directory organization and file purposes.

---

## 📁 Directory Structure

```
REAPER OS/
├── README.md                          ← Main project documentation
├── CHANGELOG.md                       ← Version history & roadmap
├── LICENSE                           ← License information
│
├── docs/                              ← 📚 User & Developer Documentation
│   ├── DOWNLOAD-INSTALLATION.md       ← How to download & install
│   ├── CI-CD-PIPELINE.md              ← GitHub Actions & releases
│   ├── GITHUB-ACTIONS-STATUS.md       ← Check workflow status
│   ├── PRE-RELEASE-CHECKLIST.md       ← Release verification
│   ├── GETTING-STARTED.md             ← Quick start guide
│   ├── AUDIO-INTERFACE-SUPPORT.md     ← Audio device setup
│   ├── CONTROL-PROTOCOLS.md           ← Control surface setup
│   ├── VST-SETUP.md                   ← VST plugin configuration
│   ├── VST-WINDOWS-SUPPORT.md         ← Windows VST info
│   ├── WINDOWS-AUDIO-CONTROL-PANELS.md ← Wine audio apps
│   ├── WINE-SETUP.md                  ← Wine/Proton setup
│   ├── REAPER-CONFIG.md               ← REAPER customization
│   ├── TROUBLESHOOTING.md             ← Detailed troubleshooting
│   ├── FAQ.md                         ← Frequently asked questions
│   ├── CONTRIBUTING.md                ← How to contribute
│   └── PROJECT-STRUCTURE.md           ← This file!
│
├── scripts/                           ← 🔧 Core Installation Scripts
│   ├── reaper-os-first-boot.sh        ← First-boot setup (entry point)
│   ├── audio-interface-setup.sh       ← Audio device detection & config
│   ├── audio-device-mapper.sh         ← USB device mappings
│   ├── wine-setup.sh                  ← Wine/Proton installation
│   ├── vst-setup.sh                   ← VST plugin configuration
│   └── system-optimization.sh         ← Performance tuning
│
├── reaper-config/                     ← ⚙️ REAPER Configuration
│   ├── control-protocols-setup.sh     ← MCU/Eucon/HUI/OSC setup
│   ├── initial-reaper.ini             ← Default REAPER settings
│   ├── default-action-list.txt        ← REAPER default actions
│   └── control-mappings/              ← Control surface mappings
│       ├── mcu-default.txt
│       ├── eucon-default.txt
│       └── osc-config.txt
│
├── tools/                             ← 🛠️ Diagnostic & Management Tools
│   ├── README.md                      ← Tools documentation
│   ├── install-tools.sh               ← Install all tools
│   ├── reaper-diagnostics.sh          ← System monitoring tool
│   ├── audio-config-manager.sh        ← Audio profile manager
│   ├── test-controllers.sh            ← MIDI/OSC testing tool
│   └── bin/                           ← Symlinks for command line
│       ├── reaper-diagnostics
│       ├── audio-config-manager
│       └── test-controllers
│
├── installer/                         ← 📦 ISO Building & Distribution
│   ├── build-debian-iso.sh             ← Build ISO locally
│   ├── iso-contents/                  ← Files to include in ISO
│   │   ├── preseed.cfg                ← Debian preseed config
│   │   └── isolinux/                  ← Boot configuration
│   ├── grub-config/                   ← GRUB bootloader config
│   └── post-install/                  ← Post-install scripts
│
├── tests/                             ← ✅ Test & Validation Scripts
│   ├── validate-installation.sh       ← Comprehensive validation suite
│   ├── test-suite-1-environment.sh    ← Environment tests
│   ├── test-suite-2-structure.sh      ← Project structure tests
│   ├── test-suite-3-syntax.sh         ← Bash syntax validation
│   ├── test-suite-4-dependencies.sh   ← Dependency verification
│   ├── test-suite-5-configuration.sh  ← Config file validation
│   ├── test-suite-6-tools.sh          ← Tools functionality tests
│   ├── test-suite-7-documentation.sh  ← Doc completeness checks
│   ├── test-suite-8-audio-system.sh   ← ALSA/JACK tests
│   ├── test-suite-9-wine-vst.sh       ← Wine/VST verification
│   ├── test-suite-10-reaper.sh        ← REAPER config tests
│   └── test-suite-11-integration.sh   ← Integration tests
│
├── .github/                           ← 🔄 GitHub & CI/CD Configuration
│   └── workflows/                     ← GitHub Actions Workflows
│       ├── test.yml                   ← Code quality tests
│       ├── build-iso.yml              ← ISO building automation
│       └── release.yml                ← Release creation automation
│
└── .gitignore                         ← Git ignore rules
```

---

## 🎯 Section Purposes

### `/docs/` - Documentation

**User-Facing**:
- Installation & download guides
- Troubleshooting & FAQ
- Audio interface & control setup

**Developer-Facing**:
- Contributing guidelines
- Project structure (this file)
- CI/CD pipeline details

**Release-Focused**:
- Pre-release checklist
- GitHub Actions status guide

### `/scripts/` - Installation & Setup

**Purpose**: Core system configuration during installation

**Flow**:
1. `reaper-os-first-boot.sh` (entry point)
2. Calls individual setup scripts:
   - Audio interface detection
   - Wine/Proton setup
   - VST configuration
   - System optimization
3. Installs diagnostic tools

**Execution**: Once during first boot, then tools manage ongoing config

### `/reaper-config/` - REAPER Settings

**Purpose**: Default REAPER configuration

**Files**:
- `control-protocols-setup.sh`: Interactive setup wizard
- `initial-reaper.ini`: Default REAPER settings
- `control-mappings/`: Protocol-specific mappings

**Execution**: Run by first-boot script, then user customizable

### `/tools/` - Diagnostic & Management Tools

**Purpose**: Post-installation system management

**Tools**:
1. **reaper-diagnostics** (540 lines)
   - Real-time system monitoring
   - JACK latency checking
   - CPU/memory tracking
   - Mode: Interactive menu or continuous reporting

2. **audio-config-manager** (450 lines)
   - Save/restore ALSA+JACK configs
   - Create audio profiles (Studio/Live/Podcast)
   - Profile switching
   - Storage: `~/.config/reaper-audio-profiles/`

3. **test-controllers** (420 lines)
   - Test MIDI/OSC without REAPER
   - Detect USB controllers
   - Monitor MIDI events
   - Protocol testing

**Installation**: Via `install-tools.sh` during first boot

**Access**: Command line after installation:
```bash
reaper-diagnostics --report
audio-config-manager --list
test-controllers detect-midi
```

### `/installer/` - ISO Building

**Purpose**: Create bootable REAPER OS ISO image

**Components**:
- `build-debian-iso.sh`: Local ISO builder
- `iso-contents/`: Files to include
- `preseed.cfg`: Automated installer config
- GRUB/isolinux: Boot configuration

**Execution**:
- Manual: `cd installer && ./build-debian-iso.sh`
- CI/CD: GitHub Actions `build-iso.yml`

**Output**: ISO image (~2-4GB)

### `/tests/` - Validation & Testing

**Purpose**: Ensure code quality and functionality

**11 Test Suites**:
1. Environment (OS, CPU, memory)
2. Project structure validation
3. Bash syntax checking
4. Dependency verification
5. Configuration validation
6. Tools functionality
7. Documentation completeness
8. Audio system (ALSA, JACK)
9. Wine/VST setup
10. REAPER configuration
11. Integration testing

**Master Script**: `validate-installation.sh`

**Execution**:
- Manual: `bash tests/validate-installation.sh`
- CI/CD: GitHub Actions on every push

**Coverage**: ~400+ lines of test code

### `/.github/workflows/` - CI/CD Automation

**Purpose**: Automated testing, building, releasing

**Three Workflows**:

1. **test.yml** (2-5 minutes)
   - Trigger: Every push & PR
   - Jobs: ShellCheck, syntax, docs, scripts, config, integration
   - Status: See `GITHUB-ACTIONS-STATUS.md`

2. **build-iso.yml** (10-15 minutes)
   - Trigger: Push to main, new tags, manual
   - Jobs: Validate, build ISO, test content, generate checksums
   - Output: Artifact for download

3. **release.yml** (5-10 minutes)
   - Trigger: New version tag (v*), manual
   - Jobs: Build artifacts, create GitHub Release
   - Output: Downloadable source & release notes

**Access**: GitHub → Actions tab

---

## 🔄 Data Flow & Execution

### Installation (First Time)

```
ISO Boot
  ↓
Debian Installer (preseed.cfg)
  ↓
System Configuration Begins
  ↓
reaper-os-first-boot.sh runs:
  ├─ audio-interface-setup.sh (detect hardware)
  ├─ audio-device-mapper.sh (configure ALSA)
  ├─ wine-setup.sh (install Wine/Proton)
  ├─ vst-setup.sh (configure VST support)
  ├─ system-optimization.sh (performance tuning)
  ├─ control-protocols-setup.sh (interactive wizard)
  ├─ install-tools.sh (install diagnostic tools)
  └─ Launch REAPER
  ↓
System Ready for Use!
```

### Post-Installation (Tools Usage)

```
User runs tool:

reaper-diagnostics
  → monitors JACK/CPU/memory
  → generates reports
  ↓
audio-config-manager
  → saves audio profiles
  → switches between configs
  ↓
test-controllers
  → tests MIDI/OSC
  → detects devices
  ↓
User configures REAPER manually
```

### Development & Release

```
Developer makes changes
  ↓
git push origin main
  ↓
GitHub Actions test.yml runs:
  ├─ ShellCheck validation
  ├─ Bash syntax check
  ├─ Tests validation
  └─ Report results
  ↓
If OK: Ready for release
  ↓
git tag -a v0.X.X
git push origin v0.X.X
  ↓
GitHub Actions release.yml runs:
  ├─ Build source artifacts
  ├─ Generate release notes
  ├─ Create GitHub Release
  └─ Upload files
  ↓
Release published on GitHub!
```

---

## 📊 File Statistics

| Section | Files | Lines | Purpose |
|---------|-------|-------|---------|
| Scripts | 6 | 2000+ | Installation & setup |
| REAPER Config | 4+ | 1500+ | Default settings |
| Tools | 4 | 1400+ | Diagnostics & management |
| Tests | 12 | 2000+ | Validation & quality |
| Docs | 15+ | 5000+ | User & developer guides |
| CI/CD | 3 | 500+ | Automation workflows |
| **TOTAL** | **~50** | **~12,000+** | **Complete distro** |

---

## 🔐 Security & Permissions

### Script Execution

- All scripts: `chmod 755` (executable)
- Tools: Installed to `/usr/local/bin`
- Installation scripts: Run as root during first boot
- Diagnostic tools: Run as regular user

### File Permissions

```bash
# Installation scripts (run once)
scripts/*.sh          → 755 (executable)

# Tools (run by users)
tools/*.sh            → 755 (executable)
tools/bin/*           → 755 (symlinked)

# Documentation (reference)
docs/*.md             → 644 (readable)

# Configuration
reaper-config/        → 755 (dirs), 644 (files)
```

---

## 🛠️ Adding New Components

### New Installation Script

1. Create in `/scripts/`: `my-new-script.sh`
2. Add shebang: `#!/bin/bash`
3. Add to `reaper-os-first-boot.sh`:
   ```bash
   bash "$PROJECT_ROOT/scripts/my-new-script.sh"
   ```
4. Add test in `/tests/`: `test-suite-X-myfeature.sh`
5. Update documentation in `/docs/`

### New Diagnostic Tool

1. Create in `/tools/`: `my-new-tool.sh`
2. Create symlink in `/tools/bin/`: `ln -s ../my-new-tool.sh my-new-tool`
3. Add to `tools/install-tools.sh`
4. Document in `/tools/README.md`

### New Documentation

1. Create in `/docs/`: `MY-TOPIC.md`
2. Add link to `/docs/PROJECT-STRUCTURE.md`
3. Add link to main `/README.md`
4. Link from related docs

### New Test Suite

1. Create in `/tests/`: `test-suite-X-feature.sh`
2. Source common functions from `validate-installation.sh`
3. Call from `validate-installation.sh`
4. Test during CI/CD (included in test.yml)

---

## 📝 Naming Conventions

### Scripts
- Lowercase with hyphens: `my-script.sh`
- Descriptive names: `audio-interface-setup.sh`
- Avoid abbreviations: Good: `audio-config-manager`, Bad: `acm`

### Functions
- Lowercase with underscores: `my_function_name()`
- Descriptive: `check_jack_status()`, `detect_audio_devices()`
- Helper functions: Prefix with underscore: `_helper_function()`

### Variables
- UPPERCASE for constants: `PROJECT_ROOT="/home/user/REAPER OS"`
- lowercase for local: `local audio_device="hw:0"`
- Avoid abbreviations: Good: `sample_rate`, Bad: `sr`

### Documentation
- UPPERCASE.md for main docs: `README.md`, `CHANGELOG.md`
- descriptive-names.md for subsections
- Link format: `[Text](file.md)` not `[file.md](file.md)`

---

## 🚀 Getting Started for Contributors

### First Time Setup

```bash
# Clone repository
git clone https://github.com/devfrp/REAPER-OS.git
cd REAPER\ OS/

# Review structure
cat README.md
ls -la scripts/
ls -la docs/

# Run validation
bash tests/validate-installation.sh

# Check shell scripts
shellcheck scripts/*.sh
```

### Making Changes

1. **Create feature branch**:
   ```bash
   git checkout -b feature/my-feature
   ```

2. **Make changes**:
   - Add scripts to `/scripts/` or `/tools/`
   - Add documentation to `/docs/`
   - Add tests to `/tests/`

3. **Validate before push**:
   ```bash
   bash tests/validate-installation.sh
   shellcheck scripts/*.sh
   ```

4. **Push & wait for CI/CD**:
   ```bash
   git push origin feature/my-feature
   ```

5. **Review results** in GitHub Actions

6. **Create Pull Request** when tests pass

---

## 📚 Learn More

- **Installation**: [DOWNLOAD-INSTALLATION.md](DOWNLOAD-INSTALLATION.md)
- **CI/CD**: [CI-CD-PIPELINE.md](CI-CD-PIPELINE.md)
- **Contributing**: [CONTRIBUTING.md](CONTRIBUTING.md)
- **Tools**: [tools/README.md](tools/README.md)

---

**Happy exploring! 🚀**
