# 🎵 REAPER OS - Linux Distribution pour la Musique

[![Tests](https://github.com/devfrp/REAPER-OS/actions/workflows/test.yml/badge.svg)](https://github.com/devfrp/REAPER-OS/actions/workflows/test.yml)
[![Build ISO](https://github.com/devfrp/REAPER-OS/actions/workflows/build-iso.yml/badge.svg)](https://github.com/devfrp/REAPER-OS/actions/workflows/build-iso.yml)
[![Release](https://github.com/devfrp/REAPER-OS/actions/workflows/release.yml/badge.svg)](https://github.com/devfrp/REAPER-OS/actions/workflows/release.yml)
[![Pages](https://github.com/devfrp/REAPER-OS/actions/workflows/pages.yml/badge.svg)](https://github.com/devfrp/REAPER-OS/actions/workflows/pages.yml)
[![License](https://img.shields.io/badge/license-GPL-blue.svg)](LICENSE)

**[📥 Download Latest Release](https://github.com/devfrp/REAPER-OS/releases)** | **[📚 Documentation](docs/)** | **[🐛 Report Issues](https://github.com/devfrp/REAPER-OS/issues)**

---

REAPER OS est une distribution Linux basée sur **Debian 13** spécialement conçue pour les musiciens et producteurs audio. Elle combine la puissance de **REAPER** (DAW complet) comme interface principale avec un support natif des **VST Windows** et des **interfaces audio Windows**.

## 🎯 Objectifs

- **Base solide**: Debian 13 stable et performant
- **Interface professionnelle**: REAPER comme shell système
- **Gestion de fichiers**: Dolphin intégré
- **Compatibilité VST**: Support 100% des plugins VST Windows
- **Interfaces audio**: Support transparent 100+ cartes audio Windows
- **Softwares de contrôle**: RME Control Panel, UAD Console, Focusrite Control, etc. sur Linux
- **Installation simple**: Installateur en quelques clics (langue + localisation)
- **Optimisé audio**: Latence minimale, audio prioritaire

## 🎛️ Caractéristiques Clés

- **REAPER comme interface principale**: DAW complet avec support Linux natif
- **Support 100% interfaces audio Windows**: Auto-détection et configuration pour:
  - RME (Babyface Pro, UFX, Fireface)
  - Universal Audio (Apollo, Arrow, Volt)
  - Focusrite (Scarlett, Clarett)
  - Behringer, MOTU, Roland, PreSonus, et 50+ marques
  - Softwares Windows (RME Control, UAD Console, etc.) transparents via Wine
- **Compatibilité VST Windows 100%**: Deux solutions intégrées:
  - **Wine/Proton Direct**: VST Windows exécutés via Wine (performance maximale)
  - **AudioGridder (Recommandé)**: Serveur VST isolé (1-3ms latence, stabilité excellente)
- **Installateur multilingue**: Sélection langue + localisation (FR, EN, ES, DE)
- **Stack audio professionnel**: JACK audio server <6ms latence avec interfaces auto-détectées
- **Gestionnaire de fichiers**: Dolphin moderne intégré

## 🚀 Caractéristiques Principales

### Système
- Distribution Linux Debian 13
- Kernel optimisé pour l'audio (PREEMPT_RT optionnel)
- Services minimaux (focus performance audio)
- Configuration automatique du matériel audio

### Logiciels
- **REAPER**: DAW principal + interface système
- **Dolphin**: Explorateur de fichiers KDE
- **Wine/Proton**: Support des VST Windows 64-bit et 32-bit
- **Jack**: Routage audio professionnel
- **PulseAudio/PipeWire**: Audio moderne

### Développement
- GCC, Clang, Make
- Git
- VSCode (optionnel)
- Build tools nécessaires

## 📦 Composants du Projet

```
REAPER-OS/
├── installer/              # Scripts d'installation ISO
├── config/                # Fichiers de configuration système
├── scripts/               # Scripts utilitaires
├── wine-config/           # Configuration Wine/Proton pour VST
├── reaper-config/         # Configuration REAPER
├── docs/                  # Documentation complète
└── README.md             # Ce fichier
```

## 💾 Installation

### Prérequis
- USB 4GB minimum
- Connexion Internet
- Matériel audio compatible Linux

### Étapes
1. Télécharger l'ISO REAPER OS
2. Créer une clé USB bootable
3. Booter et lancer l'installateur
4. Sélectionner:
   - Langue
   - Localisation
   - Partitionnement disque
   - Nom d'utilisateur
5. Installation automatique
6. Redémarrage dans REAPER OS

## 🔧 Architecture Système

### Workflow Audio
```
Entrée Audio → JACK → REAPER → VST Plugins (Wine/AudioGridder) → JACK → Sortie Audio
```

### VST Windows Support (Deux Méthodes)

**Méthode 1: Wine Direct (Recommandé pour latence)**
```
VST Windows → Wine/Proton (In-Process) → REAPER
Latence: 3-5ms | Stabilité: Bonne
```

**Méthode 2: AudioGridder (Recommandé pour stabilité)**
```
REAPER → AudioGridder Plugin → Serveur (Processus séparé) → VST Windows
Latence: 1-3ms | Stabilité: Excellente | Isolation: Complète
```

**Résultat:** VST Windows utilisables de facto nativement!

### Démarrage
1. Debian boots
2. Services minimaux
3. JACK démarre
4. REAPER se lance automatiquement
5. Dolphin accessible via interface REAPER

## 🎛️ Configuration VST Windows

REAPER OS utilise **Proton/Wine** pour exécuter les VST Windows:
- Support 64-bit et 32-bit
- Latence optimisée
- Cache de shader GPU
- Support MIDI natif

## 🎧 Configuration Interfaces Audio

### Démarrage Automatique (Recommandé)

```bash
# Auto-détection et configuration pour toutes les interfaces audio
bash scripts/audio-interface-setup.sh

# Crée les wrappers Wine pour les Control Panels Windows
bash scripts/audio-control-panel-wrappers.sh

# Résultats disponibles:
rme-control-panel       # Pour RME
uad-console            # Pour Universal Audio
focusrite-control      # Pour Focusrite
presonus-control       # Pour PreSonus
behringer-control      # Pour Behringer
motu-control           # Pour MOTU
```

### Interfaces Supportées (50+)

- ✅ **RME**: Babyface Pro, UFX II/III, Fireface series
- ✅ **Universal Audio**: Apollo, Arrow, Volt series
- ✅ **Focusrite**: Scarlett, Clarett series
- ✅ **Behringer**: UMC, X32, AMP800 series
- ✅ **MOTU**: UltraLite, Traveler, 828, 8pre
- ✅ **PreSonus**: StudioLive, AudioBox series
- ✅ **Roland**: TR, Fantom, Interface series
- ✅ **Native Instruments**: Komplete Audio, Traktor
- ✅ **Antelope Audio**, **Audient**, **Soundcraft** + 40 more

### Workflow Audio Optimisé

```bash
# 1. Démarrer JACK (auto-détecte votre interface)
jackd -d alsa &

# 2. Lancer REAPER (utilise JACK automatiquement)
reaper-start

# 3. Ouvrir Control Panel si besoin
rme-control-panel  # (ou votre interface)

# 4. Configurer dans REAPER: Preferences → Audio → Device = JACK
# 5. Enregistrer/Playback avec <2ms latence!
```

## 🎛️ Protocoles de Contrôle Supportés

REAPER OS supporte **TOUS les protocoles de contrôle audio**:

| Protocole | Contrôleurs | Latence | Support |
|---|---|---|---|
| **MCU** | Behringer X-Touch, Mackie, Soundcraft | Ultra-bas | Native ✅ |
| **Eucon** | Avid S3/S4/S6, Euphonix | Ultra-bas | Native ✅ |
| **HUI** | Mackie HUI, Behringer FCB1010 | Ultra-bas | MIDI Learn ✅ |
| **OSC** | iPad (Lemur), Mobile, Réseau | 5-50ms | Native ✅ |
| **Generic MIDI** | Tous contrôleurs MIDI | Ultra-bas | Native ✅ |
| **Keyboard** | Clavier USB/Bluetooth | Instant | Native ✅ |
| **MIDI Learn** | N'importe quel contrôleur | Ultra-bas | Native ✅ |

### Setup Protocoles de Contrôle

```bash
# Wizard interactif de configuration
bash reaper-config/control-protocols-setup.sh

# Ou dans REAPER:
# Preferences → Control Surfaces → Add Device
```

### Exemples Rapides

**Behringer X-Touch (MCU)**:
```bash
# Setup automatique en MCU mode
# 8 faders → volumes tracks 1-8
# Rotaries → pan/params
# Buttons → mute/solo
# Tous synchronisés en temps réel!
```

**iPad + Lemur (OSC)**:
```bash
# 1. Lemur sur iPad
# 2. IP: 192.168.x.x, Port 8000
# 3. Design interface dans Lemur
# 4. Control REAPER à distance!
```

**Generic Controller (MIDI Learn)**:
```bash
# Options → MIDI Learn Mode
# Click paramètre → Move contrôle
# Automatiquement mappé!
```

Pour tous les détails: **[docs/CONTROL-PROTOCOLS.md](docs/CONTROL-PROTOCOLS.md)**

## �️ Outils Diagnostiques et de Gestion

REAPER OS inclut trois outils puissants pour monitorer et gérer votre configuration audio **sans besoin de lancer REAPER**:

### **reaper-diagnostics** - Monitoring Système
Surveillance en temps réel de la latence JACK, charge CPU, utilisation mémoire, and audio device status.

```bash
reaper-diagnostics           # Mode interactif
reaper-diagnostics --report  # Rapport unique
reaper-diagnostics --continuous  # Monitoring continu
```

**Affiche**: JACK status/latency, CPU load, memory usage, audio devices, MIDI controllers, REAPER process status

### **audio-config-manager** - Gestionnaire de Profils Audio
Sauvegarde et restaure les configurations audio complètes (ALSA, JACK, routing) pour différents projets.

```bash
audio-config-manager list              # Lister les profils
audio-config-manager create mon-projet # Créer profil
audio-config-manager load mon-projet   # Charger profil
audio-config-manager save mon-projet   # Sauvegarder config
```

**Use case**: Créez des profils pour "Studio Recording" (512 samples), "Live Performance" (256 samples), "Mastering" (low latency), etc.

### **test-controllers** - Testeur de Protocoles
Teste MIDI, OSC et les control surfaces sans lancer REAPER. Détecte les périphériques, monitore les événements MIDI, valide la connectivité OSC.

```bash
test-controllers              # Mode interactif
test-controllers detect-midi  # Détect. MIDI devices
test-controllers monitor-midi 30  # Écoute MIDI pendant 30 sec
test-controllers test-all     # Teste tous les protocoles
```

**Supporte**: MCU (Behringer X-Touch), Eucon (Avid S-Series), HUI (MIDI Learn), OSC (iPad/Réseau), Generic MIDI, Keyboard

Pour documentation complète: **[tools/README.md](tools/README.md)**

## �📚 Documentation

| Doc | Purpose |
|---|---|
| [tools/README.md](tools/README.md) | **Nouveaux Outils** - Diagnostics et gestion audio |
| [INSTALLATION.md](docs/INSTALLATION.md) | Installation complète (matériel, ISO, USB, post-install) |
| [AUDIO-INTERFACE-SUPPORT.md](docs/AUDIO-INTERFACE-SUPPORT.md) | Support interfaces audio 50+ marques (RME, UAD, Focusrite, etc.) |
| [WINDOWS-AUDIO-CONTROL-PANELS.md](docs/WINDOWS-AUDIO-CONTROL-PANELS.md) | Softwares Windows audio sur Linux (RME Control, UAD Console, etc.) |
| [CONTROL-PROTOCOLS.md](docs/CONTROL-PROTOCOLS.md) | Tous les protocoles de contrôle (MCU, Eucon, HUI, OSC, MIDI Learn) |
| [VST-SETUP.md](docs/VST-SETUP.md) | Configuration VST Windows (4 méthodes, compatibility, troubleshooting) |
| [VST-WINDOWS-SUPPORT.md](docs/VST-WINDOWS-SUPPORT.md) | Résumé support VST Windows 100% |
| [WINE-SETUP.md](docs/WINE-SETUP.md) | Configuration Wine/Proton et optimization |
| [REAPER-CONFIG.md](docs/REAPER-CONFIG.md) | Customization et optimization REAPER |
| [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) | Guide troubleshooting 400+ lignes |
| [FAQ.md](docs/FAQ.md) | Questions fréquentes |
| [CONTRIBUTING.md](docs/CONTRIBUTING.md) | Contribuer à REAPER OS |
| [PROJECT-STRUCTURE.md](docs/PROJECT-STRUCTURE.md) | Architecture du projet |
| **[DOWNLOAD-INSTALLATION.md](docs/DOWNLOAD-INSTALLATION.md)** | **📥 Télécharger, vérifier, installer** |
| **[CI-CD-PIPELINE.md](docs/CI-CD-PIPELINE.md)** | **🔄 Workflows GitHub Actions, Releases** |
| **[GITHUB-ACTIONS-STATUS.md](docs/GITHUB-ACTIONS-STATUS.md)** | **📊 Accès au statut des workflows** |
| [tools/README.md](tools/README.md) | 🛠️ Outils diagnostiques (reaper-diagnostics, audio-config-manager, test-controllers) |
| [CHANGELOG.md](CHANGELOG.md) | 📋 Version history et roadmap |
| [RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md) | ✅ Checklist avant premier release

## � Installation Rapide

### Télécharger

**[→ Télécharger l'ISO depuis GitHub Releases](https://github.com/devfrp/REAPER-OS/releases)**

Requirements:
- 4GB RAM minimum
- 20GB espace disque
- USB 3.0 (4GB+)

### Installation

```bash
# 1. Créer USB bootable
sudo dd if=reaper-os-*.iso of=/dev/sdX bs=4M status=progress

# 2. Booter depuis USB
# 3. Suivre l'installateur
# 4. REAPER OS lancé automatiquement au démarrage!
```

Pour les instructions détaillées: **[DOWNLOAD-INSTALLATION.md](docs/DOWNLOAD-INSTALLATION.md)**

---

## 🔄 CI/CD & Releases

REAPER OS utilise **GitHub Actions** pour l'automatisation:

- ✅ **Tests automatiques** - Validation ShellCheck, syntax, documentation
- ✅ **Build ISO** - Compilation automatique sur chaque push
- ✅ **Releases automatiques** - Publication sur GitHub avec checksums

**Status des workflows**:
- [Tests & Code Quality](https://github.com/devfrp/REAPER-OS/actions/workflows/test.yml)
- [Build ISO Image](https://github.com/devfrp/REAPER-OS/actions/workflows/build-iso.yml)
- [Create Release](https://github.com/devfrp/REAPER-OS/actions/workflows/release.yml)

Pour plus de détails: **[CI-CD-PIPELINE.md](docs/CI-CD-PIPELINE.md)**

---

## �🛠️ Développement

### Build ISO
```bash
cd installer/
./build-debian-iso.sh
```

### Contribuer
Les contributions sont bienvenues! Consultez [CONTRIBUTING.md](docs/CONTRIBUTING.md)

## 📝 Licence

REAPER OS est un projet communautaire basé sur des logiciels open-source:
- Debian: GPL v2+
- REAPER: Propriétaire (évaluation gratuite / licence commerciale)
- Wine: LGPL
- KDE Dolphin: LGPL

## 💬 Support & Communauté

- GitHub Issues: Bug reports et demandes de fonctionnalités
- Documentation: Guides complets d'utilisation
- Wiki: Tips et astuces

## 🎵 Bienvenue dans REAPER OS!

Commencez à créer de la musique sans compromis. Professionnel. Libre. Performant.
