# Protocoles de Contrôle REAPER - REAPER OS

## 🎛️ Support Complet des Protocoles de Contrôle Audio

REAPER OS supporte **tous les protocoles de contrôle** pour mixer/produire avec contrôleurs hardware externes:

- ✅ **HUI** (Human User Interface) - Mackie
- ✅ **Eucon** - Euphonix/Avid
- ✅ **MCU** (Mackie Control Universal) - Mackie Extended
- ✅ **OSC** (Open Sound Control) - Réseau flexible
- ✅ **MIDI Generic** - MIDI standard
- ✅ **Keyboard Shortcuts** - Clavier
- ✅ **MIDI Learn** - Apprentissage dynamique

---

## 📋 Protocoles Supportés

### 1. HUI (Human User Interface) - Mackie Protocol

**Description**: Protocole Mackie pour contrôleurs 8 faders

**Caractéristiques**:
- 8 faders de gain
- 8 boutons Mute
- 8 boutons Solo
- Transport (play, stop, rec, etc.)
- LCD display feedback
- **Latence**: Ultra-basse (USB direct)

**Contrôleurs HUI**:
- Mackie HUI Pro
- Behringer FCB1010 (avec firmware HUI)
- Tascam US-2400

**Configuration REAPER**:
```ini
[MIDI]
hui_enabled=1
midi_hwout=USB HUI  ; Remplacer par votre interface
```

### 2. Eucon - Euphonix Control Protocol

**Description**: Protocole professionnel d'Avid (Euphonix)

**Caractéristiques**:
- Contrôle multi-faders (jusqu'à 128 chaînes)
- Rotary encoders pour paramètres
- Large LCD display avec feedback
- Support plugins VST complet
- Faders motorisés haute-résolution
- **Latence**: Ultra-basse (directe)

**Contrôleurs Eucon**:
- Avid S3 / S4 / S6
- Euphonix MC Control
- Euphonix MC Fader Banks

**Configuration REAPER**:
```ini
[MIDI]
eucon_enabled=1
eucon_port=MIDI_Port_Name
```

### 3. MCU (Mackie Control Universal)

**Description**: Version étendue du protocole HUI avec plus de canaux

**Caractéristiques**:
- 8-16+ faders (extensible)
- Jog wheel pour édition
- Cristal LCD 
- Transport avancé
- Paramètres plugin
- **Latence**: Ultra-basse

**Contrôleurs MCU**:
- Mackie MCU Pro
- Behringer X-Touch
- Behringer X-Air (mode MCU)
- Soundcraft Series

**Configuration REAPER**:
```ini
[MIDI]
mcu_enabled=1
mcu_channel_count=8  ; ou 16, 24, 32
mcu_flip_enabled=1
```

### 4. OSC (Open Sound Control)

**Description**: Protocole réseau flexible (UDP/TCP) pour contrôle à distance

**Caractéristiques**:
- Réseau Ethernet (latence variable)
- Support des floats et strings
- Flexible et personnalisable
- Multi-contrôleurs simultanés
- Support iPad/Mobile (via apps)
- **Latence**: 5-50ms (dépend du réseau)

**Cas d'usage**:
- Contrôle à distance (studio distant)
- iPad/Mobile (Lemur, Controlly, etc.)
- Multi-utilisateur (sessions collaboratives)
- Intégration avec logiciels tiers

**Configuration REAPER**:
```ini
[OSC]
osc_enabled=1
osc_port=8000
osc_listen=all
osc_layout=/path/to/layout.txt
```

**Exemple Layout OSC**:
```
/track/1/volume
/track/1/pan
/track/1/mute
/track/1/solo
/master/volume
```

### 5. MIDI Generic

**Description**: MIDI standard pour tous contrôleurs USB/MIDI

**Caractéristiques**:
- Compatibilité universelle
- Faders, rotaries, buttons
- Feedback en temps-réel
- **Latence**: Ultra-basse

**Configuration REAPER**:
```
Preferences → Control Surfaces
→ Add → Generic Keyboard/MIDI
→ Apprendre les contrôles (MIDI Learn)
```

### 6. MIDI Learn (Apprentissage Dynamique)

**Description**: Associer n'importe quel contrôleur MIDI à n'importe quelle fonction

**Comment ça marche**:
1. Menu: Options → MIDI Learn Mode
2. Cliquer sur le paramètre à contrôler
3. Actionner le contrôle physique (fader, bouton, rotary)
4. REAPER apprend l'association

**Avantages**:
- Fonctionne avec tout contrôleur MIDI
- Pas de configuration requise
- Ultraflexible

---

## 🎛️ Contrôleurs Populaires & Configuration

### Mackie HUI

```
❌ Pas natif dans REAPER
✅ Utilisez Generic MIDI + MIDI Learn
```

**Exemple workflow**:
```bash
# 1. Connecter le contrôleur USB
# 2. Dans REAPER: Preferences → Control Surfaces → Add → Generic Keyboard/MIDI
# 3. Activer MIDI Learn
# 4. Cliquer sur faders volume → Mover faders HUI
# 5. Automatiquement mappé!
```

### Behringer X-Touch (MCU Mode)

```ini
# Configuration MCU Native
[MIDI]
mcu_enabled=1
mcu_device=Behringer X-Touch
mcu_channel_count=8

# Comportement:
# - Jog wheel → Cursor navigation
# - Faders → Track volume
# - Rotaries → Pan/params
# - Buttons → Mute/Solo
# - Display → Feedback REAPER
```

### Soundcraft Compact Mix

```ini
# MCU Compatible via firmware USB
[MIDI]
mcu_enabled=1
mcu_channel_count=8
```

### Avid S6 (Eucon)

```ini
# Eucon Native
[MIDI]
eucon_enabled=1
eucon_device=Avid S6
eucon_motorized=1  # Faders motorisés
eucon_display=1    # LCD feedback
```

### Lemur iPad/iPad (OSC)

```bash
# 1. Installer Lemur sur iPad
# 2. Configurer OSC:
#    Lemur → Network → Lemur Daemon
#    IP PC: 192.168.x.x
#    Port: 8000
# 3. Dans REAPER:
#    [OSC]
#    osc_enabled=1
#    osc_port=8000
# 4. Créer interface custom dans Lemur
```

### Controlly (iPad - OSC)

```bash
# Application iPad pour OSC
# Prédefini pour REAPER
# Connecter via réseau local
```

---

## 📋 Tableau de Support Complet

| Protocole | Support | Latence | Contrôleurs |
|---|---|---|---|
| **HUI** | ✓ Generic MIDI | Ultra-basse | Mackie HUI Pro, Behringer FCB |
| **Eucon** | ✓ Native | Ultra-basse | Avid S3/S4/S6, Euphonix |
| **MCU** | ✓ Native | Ultra-basse | Behringer X-Touch, Soundcraft |
| **OSC** | ✓ Native | 5-50ms | iPad, Mobile, Réseau |
| **MIDI** | ✓ Native | Ultra-basse | Tous contrôleurs MIDI |
| **Keyboard** | ✓ Natif | Instant | Clavier USB/Bluetooth |
| **MIDI Learn** | ✓ Natif | Ultra-basse | Tout + MIDI Learn |

---

## 🚀 Configuration Rapide Par Protocole

### Setup Behringer X-Touch (MCU)

```bash
# 1. Connecter en USB
# 2. REAPER: Preferences → Control Surfaces → Add Device
# 3. Sélectionner "Mackie MCU Pro"
# 4. Configuration automatique!

# Vérification:
# - Faders bougent en sync
# - Écran affiche info REAPER
# - Transport fonctionne
```

### Setup MIDI Learn (Pour tout contrôleur)

```bash
# 1. Preferences → Options → MIDI Learn Mode
# 2. Cliquer sur fader volume track 1
# 3. Actionner fader contrôleur
# 4. ASSOCIÉ!
# 5. Répéter pour tous les contrôles

# Résultat: Contrôleur MIDI custom entièrement mappé
```

### Setup OSC (iPad + Lemur)

```bash
# PC (REAPER):
# 1. Note: IP locale = 192.168.1.100
# 2. REAPER Preferences → OSC
#    osc_enabled=1
#    osc_port=8000

# iPad (Lemur):
# 1. Lemur → Preferences → Network
# 2. IP: 192.168.1.100, Port: 8000
# 3. Enable Lemur Daemon
# 4. Design interface dans Lemur Editor
# 5. Play sur iPad

# Résultat: Contrôle iPad complète du mix!
```

### Setup Avid S6 (Eucon)

```bash
# 1. Connecter S6 en USB
# 2. REAPER détecte automatiquement Eucon
# 3. S6 affiche config REAPER
# 4. Faders motorisés synchronisés
# 5. LCD full feedback

# Vérification:
jack_lsp | grep -i midi  # S6 visible?
```

---

## 🎵 Configurations Recommandées Par Workflow

### Workflow 1: Mixing Préférentiel (Behringer X-Touch)

```ini
[MCU]
mcu_enabled=1
device=Behringer X-Touch
channel_count=8
flip_enabled=1      # Basculer faders/pan

[FADERS]
mode=volume         # Mode primaire
flip_mode=pan       # Mode secondaire (bouton Flip)
```

**Comportement**:
```
Normal Mode:
- 8 Faders → Volume tracks 1-8
- Rotaries → Pan tracks 1-8

Flip Mode (appui bouton):
- 8 Faders → Pan tracks 1-8
- Rotaries → 4 paramètres plugins
```

### Workflow 2: Édition Créative (OSC + iPad)

```ini
[OSC]
osc_enabled=1
osc_port=8000
osc_listen=all
```

**Exemple layout iPad**:
```
Top row:
  [Track 1 Fader] [Track 2 Fader] [Track 3 Fader]

Middle:
  [Master Vol] [Master Pan]

Bottom:
  [Play] [Stop] [Rec]
  [Undo] [Redo]
```

### Workflow 3: Production Multi-Canaux (Avid S6 + MCU Extension)

```ini
[EUCON]
eucon_enabled=1
eucon_motorized=1
eucon_channel_count=16  # ou 32, 48, 64

[MCU_EXTENSION]
mcu_enabled=1
mcu_channel_count=8
mcu_device=Behringer X-Touch Extension
```

**Résultat**: 24 chaînes de faders pour grand mix!

---

## 🔌 Connecteurs & Protocoles Physiques

### USB (Recommandé)

```
Contrôleur USB
    ↓
Driver USB standard
    ↓
ALSA/JACK MIDI
    ↓
REAPER
```

**Avantages**:
- Plug and play
- Power + données simultanés
- Faible latence

### MIDI 5-DIN

```
Contrôleur MIDI out
    ↓
Câble MIDI (5-DIN)
    ↓
Interface Audio (MIDI In)
    ↓
ALSA MIDI
    ↓
REAPER
```

**Avantages**:
- Isolation électrique
- Longue portée (15m+)
- Fiabilité professionnelle

### Réseau (OSC)

```
Contrôleur réseau (iPad)
    ↓
WiFi/Ethernet
    ↓
REAPER (port 8000)
    ↓
Feedback OSC
```

**Avantages**:
- Distance illimitée
- Multi-contrôleurs
- Mobile/laptop

---

## 📝 Configuration Fichier Exemple (reaper.ini)

```ini
[CONTROL_SURFACES]
; MCU Config
0=MCU|enabled=1|device=Behringer X-Touch|channels=8

; OSC Config
1=OSC|enabled=1|port=8000|listen=all

; MIDI Generic Config
2=MIDI|enabled=1|device=Generic MIDI|midilearn=1

[MCU_PREFS]
flip_enabled=1
jog_mode=0
channel_count=8
motorized=0

[OSC_PREFS]
osc_port=8000
osc_layout=/home/user/.config/REAPER/osc_layout.txt

[MIDI_LEARN]
enabled=1
; Exemples:
; [CC61]=Volume_Track_1
; [CC62]=Pan_Track_1
; [Note60]=Play
```

---

## 🎛️ Troubleshooting & Support

### Contrôleur Non Reconnu

```bash
# 1. Vérifier la connexion
lsusb | grep -i "control"

# 2. Vérifier MIDI
aconnect -l

# 3. Redémarrer JACK
sudo systemctl restart jack@${USER}.service

# 4. Relancer REAPER
reaper-start
```

### Pas de Feedback LCD

```bash
# 1. Vérifier périphérique MIDI OUT
aconnect -l | grep REAPER

# 2. Contrôleur doit avoir même périphérique MIDI OUT
# 3. Activer output dans REAPER
#    Preferences → Control Surfaces → Device → Output
```

### Latence MIDI Élevée

```bash
# 1. Vérifier JACK running
jack_lsp

# 2. Réduire JACK buffer
jackd -p 128

# 3. Vérifier CPU
top | grep -i jack

# 4. Utiliser USB direct (pas hub)
```

### OSC Port Occupé

```bash
# 1. Vérifier quel process utilise 8000
sudo lsof -i :8000

# 2. Changer port REAPER
# Preferences → OSC → Port 9000

# 3. Restart REAPER
```

---

## 📚 Documentation Détaillée Par Protocole

### HUI Protocol

**REAPER Support**: Generic MIDI recommended
**Documentation**: https://www.mackie.com/en-US/products/huipro

**Fichier config**:
```ini
[HUI]
enabled=1
device=HUI_Device_Name
; REAPER ne supporte pas HUI natif
; Utilisez Generic MIDI + MIDI Learn à la place
```

### Eucon (Euphonix Control)

**REAPER Support**: ✅ Native
**Documentation**: https://www.avid.com/en/en/products/control-surfaces

**Fichier config**:
```ini
[EUCON]
eucon_enabled=1
eucon_device=Avid_S6
eucon_motorized=1
eucon_force_motorized=1
```

### MCU (Mackie Control Universal)

**REAPER Support**: ✅ Native
**Documentation**: https://mackie.com/en-US/products/mcu-pro

**Fichier config**:
```ini
[MACKIE_CONTROL]
mcu_enabled=1
mcu_device=X-Touch
mcu_channel_count=8
mcu_flip_enabled=1
mcu_jog_mode=0
mcu_alternate_mode=0
```

### OSC (Open Sound Control)

**REAPER Support**: ✅ Native
**Documentation**: https://www.reaper.fm/sdk/osc/osc.php

**Fichier config**:
```ini
[OSC]
osc_enabled=1
osc_port=8000
osc_listen=0.0.0.0
osc_layout=/path/to/layout.txt
osc_queuesize=10000
```

**Format messages**:
```
/track/1/volume 0.75
/track/1/pan -0.5
/master/volume 0.85
/transport/play 1
```

---

## 🎼 Examples de Mapping Complets

### Exemple 1: Behringer X-Touch (MCU)

```ini
[MCU_CONFIG]
Faders 1-8: Volume Tracks 1-8
Rotaries: Pan Tracks 1-8 (mode normal) / Plugin params (Flip)
Buttons M: Mute Tracks 1-8
Buttons S: Solo Tracks 1-8
Jog Wheel: Navigation curseur
LCD: Infos REAPER

Transport:
  Rew: Rewind
  Fwd: Forward
  Stop: Stop
  Play: Play
  Rec: Record
  << >>: Previous/Next marker
```

### Exemple 2: iPad Lemur (OSC)

```
Layout sur iPad:

┌─────────────────────────────────┐
│ Vol1 Vol2 Vol3 Vol4 Vol5 Vol6   │  ← 6 Faders
│ Pan1 Pan2 Pan3 Pan4 Pan5 Pan6   │  ← 6 Rotaries
│                                  │
│ [Mute 1-6 Buttons]              │
│ [Solo 1-6 Buttons]              │
│                                  │
│ Master Vol |████| Master Pan +0  │
│                                  │
│ [Play] [Stop] [Record]          │
│ [Undo] [Redo]                   │
└─────────────────────────────────┘

Tous mappés via OSC!
```

---

## ✨ Cas d'Usage Avancés

### Multi-Contrôleurs (MCU + OSC)

```ini
# Contrôleur 1: Behringer X-Touch (8 faders locaux)
[MCU]
mcu_enabled=1
mcu_device=X-Touch
mcu_channels=8

# Contrôleur 2: iPad (6 faders custom OSC)
[OSC]
osc_enabled=1
osc_port=8000
osc_listen=all

# Résultat: 14 faders simultanés! 🎛️
```

### Commutation de Contexte

```bash
# Script pour switcher configurations
# (pour différents projets/workflows)

#!/bin/bash
case "$1" in
  mixing)
    # MCU seulement - volume/pan
    ;;
  mastering)
    # OSC pour edit précise
    ;;
  live)
    # HUI + generic MIDI pour effects
    ;;
esac
```

---

## 🎯 Recommandations

### Pour Mixing Pro:
→ **Behringer X-Touch** (MCU) = Meilleur rapport/qualité

### Pour Édition Créative:
→ **iPad Lemur** (OSC) = Flexibilité maximale

### Pour Production Haute Gamme:
→ **Avid S6** (Eucon) = Professionnel complet

### Pour Budget Limité:
→ **Generic MIDI Learn** = Gratuit + flexible

---

**REAPER OS: Tous les protocoles de contrôle supportés!** 🎛️✨
