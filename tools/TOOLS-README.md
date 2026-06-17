# REAPER OS Tools & Utilities

This directory contains essential tools and utilities for managing, configuring, and optimizing your REAPER OS installation.

## 📋 Tools Overview

### System & Health

#### **reaper-diagnostics.sh**
Real-time system monitoring and diagnostics for REAPER OS.

**Features:**
- Audio system health checks
- JACK daemon status and configuration
- CPU usage and real-time kernel verification
- Disk space and RAM monitoring
- Audio interface detection
- Latency measurements

**Usage:**
```bash
bash reaper-diagnostics.sh
bash reaper-diagnostics.sh --detailed    # Full diagnostic report
bash reaper-diagnostics.sh --export      # Export results to file
```

#### **verify-all-systems.sh**
Comprehensive system verification for installation validation.

**Features:**
- Audio tool installation verification
- Dependencies check
- Configuration validation
- System resource validation
- Installation health assessment

**Usage:**
```bash
bash verify-all-systems.sh
```

### Audio Configuration

#### **audio-config-manager.sh**
Save and restore ALSA + JACK audio configurations per project.

**Features:**
- Create named audio profiles (Studio, Live, CPU-Limited, etc.)
- Save current audio setup as profile
- Switch between profiles instantly
- Profile backup and restoration
- Sample rate and buffer size management
- Audio interface configuration per profile

**Usage:**
```bash
bash audio-config-manager.sh list              # List all profiles
bash audio-config-manager.sh create studio     # Create new profile
bash audio-config-manager.sh save studio       # Save current config
bash audio-config-manager.sh load studio       # Load a profile
bash audio-config-manager.sh delete studio     # Delete a profile
bash audio-config-manager.sh restore           # Restore previous config
```

#### **audio-profile-manager-gui.py**
Graphical interface for managing audio profiles and settings.

**Features:**
- Visual profile browser
- Real-time audio settings adjustment
- Preset visualization
- Configuration graph
- One-click profile switching

**Usage:**
```bash
python3 audio-profile-manager-gui.py
```

### Hardware & Controllers

#### **hardware-controller-mapper.sh**
Map and configure hardware controllers (MIDI, MCU, Control Surfaces).

**Features:**
- Automatic controller detection
- MCU protocol configuration
- Custom MIDI mapping
- Control surface assignment
- Multi-controller setup
- Preset management

**Usage:**
```bash
bash hardware-controller-mapper.sh detect       # Find connected controllers
bash hardware-controller-mapper.sh config       # Configure detected devices
bash hardware-controller-mapper.sh list         # List all configured
bash hardware-controller-mapper.sh reset        # Reset all mappings
```

#### **test-controllers.sh**
Test and verify hardware controllers and MIDI devices.

**Features:**
- MIDI message monitoring
- Controller response testing
- MCU protocol verification
- Button and fader testing
- Latency measurement
- Troubleshooting diagnostics

**Usage:**
```bash
bash test-controllers.sh                 # Interactive testing mode
bash test-controllers.sh --monitor       # Monitor all MIDI input
bash test-controllers.sh --mcu-test      # Test MCU protocol
bash test-controllers.sh --latency       # Measure MIDI latency
```

#### **hardware-matrix.sh**
Comprehensive hardware compatibility matrix and lookup tool.

**Features:**
- Search audio interface compatibility
- Controller protocol support lookup
- Pre-configured device profiles
- Firmware version tracking
- Known issues database

**Usage:**
```bash
bash hardware-matrix.sh search UR22       # Find UR22 info
bash hardware-matrix.sh profiles          # Show all profiles
bash hardware-matrix.sh compatibility     # Show support matrix
```

### Plugins & VST

#### **vst-manager.sh**
Manage VST plugin installation, discovery, and loading.

**Features:**
- Plugin discovery and indexing
- Compatibility checking
- Wine/Proton VST bridging
- Plugin organization by category
- Dependency resolution
- Plugin database

**Usage:**
```bash
bash vst-manager.sh scan              # Scan for installed plugins
bash vst-manager.sh list              # List discovered plugins
bash vst-manager.sh info plugin-name  # Show plugin details
bash vst-manager.sh bridge wine       # Configure Wine bridging
```

#### **vst-plugin-store.sh**
Access curated VST plugin store and installation helper.

**Features:**
- Free plugin recommendations
- Plugin dependency management
- One-click installation
- Compatibility verification
- Update checking
- Backup management

**Usage:**
```bash
bash vst-plugin-store.sh browse           # Browse available plugins
bash vst-plugin-store.sh install plugin   # Install a plugin
bash vst-plugin-store.sh updates          # Check for updates
bash vst-plugin-store.sh backup           # Backup plugin data
```

### System Maintenance

#### **package-manager.sh**
Unified package management for audio tools and dependencies.

**Features:**
- Audio package installation
- Dependency resolution
- System package updates
- Tool compatibility checking
- Cleanup and optimization
- Configuration management

**Usage:**
```bash
bash package-manager.sh install audio-tools    # Install tools
bash package-manager.sh update                 # Update packages
bash package-manager.sh cleanup                # Clean cache
bash package-manager.sh verify                 # Verify installation
```

#### **update-manager.sh**
Automated update management for REAPER OS components.

**Features:**
- Check for updates
- Safe update installation
- Rollback capability
- Change log display
- Scheduled updates
- Dependency checking

**Usage:**
```bash
bash update-manager.sh check              # Check for updates
bash update-manager.sh install            # Install available updates
bash update-manager.sh schedule            # Set automatic updates
bash update-manager.sh rollback            # Rollback to previous version
```

#### **backup-restore.sh**
Backup and restore REAPER configurations, projects, and settings.

**Features:**
- Full system backup
- Project backup
- Settings backup
- Incremental backups
- Restore wizard
- Backup verification

**Usage:**
```bash
bash backup-restore.sh backup           # Create full backup
bash backup-restore.sh projects          # Backup projects only
bash backup-restore.sh list              # List available backups
bash backup-restore.sh restore backup-id # Restore from backup
```

#### **logging-system.sh**
Comprehensive logging for system events and troubleshooting.

**Features:**
- Audio event logging
- Error tracking
- Performance monitoring
- Debug output capture
- Log rotation
- Analysis tools

**Usage:**
```bash
bash logging-system.sh start          # Start logging
bash logging-system.sh stop           # Stop logging
bash logging-system.sh view           # View recent logs
bash logging-system.sh analyze        # Analyze for issues
bash logging-system.sh export         # Export for support
```

### Optimization & Performance

#### **performance-tuner.sh**
System performance optimization and real-time tuning.

**Features:**
- Real-time priority configuration
- CPU governor optimization
- Thermal management
- I/O scheduling optimization
- Memory management
- Latency reduction

**Usage:**
```bash
bash performance-tuner.sh optimize       # Apply recommended settings
bash performance-tuner.sh profile        # Show current profile
bash performance-tuner.sh realtime       # Enable real-time mode
bash performance-tuner.sh measure        # Measure latency
```

#### **benchmarking-tool.sh**
Benchmark system audio performance and capabilities.

**Features:**
- Latency testing
- CPU load testing
- Memory usage profiling
- Audio quality testing
- Multi-track stress test
- Report generation

**Usage:**
```bash
bash benchmarking-tool.sh latency        # Measure audio latency
bash benchmarking-tool.sh cpu            # CPU stress test
bash benchmarking-tool.sh full           # Complete benchmark
bash benchmarking-tool.sh report          # Generate report
```

#### **system-info.sh**
Detailed system information and specifications.

**Features:**
- Hardware inventory
- Kernel information
- Audio subsystem details
- Configuration summary
- Specification report
- Export to file

**Usage:**
```bash
bash system-info.sh              # Display system info
bash system-info.sh --export     # Export to text file
bash system-info.sh --json       # Export to JSON
bash system-info.sh --compare    # Compare with baseline
```

### Advanced Features

#### **streaming-integration.py**
Streaming setup and management (OBS, Restream, etc.).

**Features:**
- OBS integration
- Streaming configuration
- RTMP management
- Multi-platform streaming
- Recording integration
- Stream quality optimization

**Usage:**
```bash
python3 streaming-integration.py setup        # Configure streaming
python3 streaming-integration.py preview      # Preview stream
python3 streaming-integration.py record       # Recording setup
```

#### **network-audio-control.py**
Remote audio control over network (OSC, API).

**Features:**
- OSC endpoint setup
- Network remote control
- iPad/Mobile app integration
- Control message routing
- Latency monitoring
- Custom scripting

**Usage:**
```bash
python3 network-audio-control.py start        # Start server
python3 network-audio-control.py test         # Test connectivity
python3 network-audio-control.py config       # Configure controls
```

#### **collaboration-server.py**
Collaborative audio production features.

**Features:**
- Real-time session sharing
- Multi-user mixing
- Project synchronization
- Remote monitoring
- Chat integration
- Recording synchronization

**Usage:**
```bash
python3 collaboration-server.py start        # Start server
python3 collaboration-server.py invite url   # Create invite
python3 collaboration-server.py list         # List sessions
```

#### **video-sync-tools.sh**
Timecode sync, video analysis, and synchronization.

**Features:**
- Video file analysis
- Audio-to-video synchronization
- Timecode support
- Frame rate detection
- Sync offset calculation
- Metadata preservation

**Usage:**
```bash
bash video-sync-tools.sh analyze video.mp4                    # Analyze video
bash video-sync-tools.sh sync video.mp4 audio.wav            # Sync audio
bash video-sync-tools.sh timecode video.mp4 --fps 24         # Setup timecode
bash video-sync-tools.sh extract-audio video.mp4 -o audio.wav # Extract audio
```

### Community & AI

#### **community-marketplace.sh**
Browse and manage community-shared resources.

**Features:**
- Preset browsing
- Plugin recommendations
- Configuration sharing
- Community ratings
- Version management
- Review system

**Usage:**
```bash
bash community-marketplace.sh browse          # Browse community
bash community-marketplace.sh search term     # Search resources
bash community-marketplace.sh install item    # Install item
bash community-marketplace.sh publish         # Share preset
```

#### **community-integration.sh**
Collaborate and integrate with community platforms.

**Features:**
- GitHub integration
- Community forums
- Resource sharing
- Feedback submission
- Bug reporting
- Feature suggestions

**Usage:**
```bash
bash community-integration.sh report-issue    # Report bug
bash community-integration.sh suggest         # Suggest feature
bash community-integration.sh share           # Share config
bash community-integration.sh get-help        # Get community help
```

### Advanced Tools

#### **iso-comparison.sh**
Compare REAPER OS versions and configurations.

**Features:**
- Version comparison
- Feature comparison
- Changelog display
- Upgrade path planning
- Configuration migration
- Compatibility checking

**Usage:**
```bash
bash iso-comparison.sh compare v0.9.0 v1.0.0
bash iso-comparison.sh features v1.0.0
bash iso-comparison.sh migration v0.9.0
```

#### **approval-checklist.sh**
Pre-release approval checklist and quality assurance.

**Features:**
- Release readiness verification
- Testing checklists
- Documentation review
- Quality gates
- Sign-off workflow
- Release notes generation

**Usage:**
```bash
bash approval-checklist.sh check              # Start checklist
bash approval-checklist.sh status             # View current status
bash approval-checklist.sh complete           # Mark as complete
```

#### **project-version-control.sh**
Advanced version control for REAPER projects.

**Features:**
- Project versioning
- Diff visualization
- Branching support
- Merge tools
- History browser
- Automatic versioning

**Usage:**
```bash
bash project-version-control.sh init          # Initialize version control
bash project-version-control.sh create-version  # Create new version
bash project-version-control.sh diff          # Compare versions
bash project-version-control.sh merge         # Merge versions
```

#### **preset-manager-advanced.sh**
Advanced preset management with categories and organizations.

**Features:**
- Preset organization
- Tag system
- Search and filter
- Backup management
- Import/Export
- Versioning
- Sharing

**Usage:**
```bash
bash preset-manager-advanced.sh list          # List presets
bash preset-manager-advanced.sh create        # Create preset
bash preset-manager-advanced.sh export        # Export preset
bash preset-manager-advanced.sh backup        # Backup all
bash preset-manager-advanced.sh search tag    # Search by tag
```

#### **professional-templates.sh**
Access and manage professional project templates.

**Features:**
- Industry-standard templates
- Workflow presets
- Mixing templates
- Mastering templates
- Genre templates
- Custom template creation

**Usage:**
```bash
bash professional-templates.sh list           # List templates
bash professional-templates.sh new template   # Create from template
bash professional-templates.sh categories     # Show categories
bash professional-templates.sh create custom  # Create custom template
```

#### **mastering-suite.py**
Professional mastering tools and automation.

**Features:**
- Metering tools
- EQ presets
- Compression templates
- Limiting strategies
- Loudness standards (LUFS)
- Finishing tools

**Usage:**
```bash
python3 mastering-suite.py open               # Open interface
python3 mastering-suite.py measure            # Measure loudness
python3 mastering-suite.py standard spotify   # Apply streaming standard
```

#### **mixing-analytics.py**
Analytics and visualization for mixing decisions.

**Features:**
- Frequency analysis
- Level tracking
- Mix automation
- Reference comparison
- Loudness standards
- Export analytics

**Usage:**
```bash
python3 mixing-analytics.py analyze           # Analyze mix
python3 mixing-analytics.py compare ref.wav   # Compare with reference
python3 mixing-analytics.py export            # Export analysis
```

#### **professional-templates.sh**
Access and manage professional project templates.

**Features:**
- Industry-standard templates
- Genre-specific templates
- Format templates (Stereo, 5.1, etc.)
- Effect chains
- Mixing approaches

**Usage:**
```bash
bash professional-templates.sh list           # List templates
bash professional-templates.sh new template   # Create from template
```

#### **mobile-companion.py**
Mobile companion app utilities and setup.

**Features:**
- iPad app integration
- Android app setup
- Remote control
- Mobile mixer interface
- Network configuration
- Latency optimization

**Usage:**
```bash
python3 mobile-companion.py setup             # Configure app
python3 mobile-companion.py pair              # Pair device
python3 mobile-companion.py test              # Test connection
```

## 🛠️ Quick Reference

### By Task

**Setting up audio:**
```bash
bash audio-config-manager.sh create myprofile
bash hardware-controller-mapper.sh detect
bash test-controllers.sh
```

**Troubleshooting:**
```bash
bash reaper-diagnostics.sh --detailed
bash health-check.sh
```

**Performance tuning:**
```bash
bash performance-tuner.sh optimize
bash benchmarking-tool.sh latency
bash system-info.sh --export
```

**Project management:**
```bash
bash backup-restore.sh backup
bash project-version-control.sh create-version
bash preset-manager-advanced.sh backup
```

**For content creators:**
```bash
python3 streaming-integration.py setup
bash video-sync-tools.sh sync
bash professional-templates.sh list
```

## 📚 Tool Documentation

Each tool includes inline help:
```bash
tool-name.sh --help
tool-name.sh help
tool-name.py --help
```

## 🐛 Troubleshooting Tools

**Tools won't run?**
1. Check permissions: `chmod +x *.sh *.py`
2. Check dependencies: `bash reaper-diagnostics.sh`
3. View logs: `bash logging-system.sh view`

**Scripts hanging?**
```bash
bash logging-system.sh start
# Run tool
bash logging-system.sh analyze
```

**Performance issues?**
```bash
bash benchmarking-tool.sh full
bash performance-tuner.sh optimize
bash reaper-diagnostics.sh
```

## 📖 More Information

- [REAPER OS Main Documentation](../DOCUMENTATION-INDEX.md)
- [Best Practices Guide](../BEST-PRACTICES.md)
- [Troubleshooting Guide](../TROUBLESHOOTING.md)
- [Quick Start Guide](../QUICK-START.md)

---

**Last Updated:** May 18, 2026  
**REAPER OS Version:** 1.0.0
