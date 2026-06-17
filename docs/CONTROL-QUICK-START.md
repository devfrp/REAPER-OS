# Protocoles de Contrôle - Quick Start

## 🎛️ Setup 5 Minutes: Connecter Votre Contrôleur

### Step 1: Déterminer Votre Protocole

```bash
# Identifier votre contrôleur
aconnect -l

# Exemples:
# "Behringer X-Touch" → MCU Protocol
# "Avid S6" → Eucon Protocol
# "HUI Pro" → Generic MIDI + MIDI Learn
# "Any USB MIDI" → Generic MIDI
```

### Step 2: Configuration Automatique

```bash
# Lance le wizard de configuration
bash reaper-config/control-protocols-setup.sh

# Choisir votre protocole
# Configuration automatique!
```

### Step 3: Connecter dans REAPER

```
Preferences → Control Surfaces → Add Device
Sélectionner votre contrôleur
OK → Automatiquement synchronisé!
```

---

## 🎛️ Quick Setup Par Protocole

### Behringer X-Touch (MCU)

**Tempo**: 2 minutes

```bash
# 1. Connecter en USB
# 2. Terminal:
bash reaper-config/control-protocols-setup.sh
# → Choisir "1) Behringer X-Touch"

# 3. REAPER:
# Preferences → Control Surfaces → Add
# → Mackie MCU Pro (auto-detecded)

# 4. Vérifier:
# - Les 8 faders bougent en sync
# - L'écran affiche les noms des tracks
# - Les buttons mute/solo fonctionnent

# ✅ PRÊT!
```

**Comportement automatique**:
```
Faders 1-8: Volumes Tracks 1-8
Rotaries: Pan Tracks 1-8
Buttons M: Mute Tracks 1-8
Buttons S: Solo Tracks 1-8
Jog Wheel: Navigation curseur
Transport: Play, Stop, Record, Rew, Fwd
```

### Avid S6 / S4 / S3 (Eucon)

**Tempo**: 3 minutes

```bash
# 1. Connecter S6 en USB-B
# 2. REAPER détecte automatiquement Eucon
# 3. S6 affiche config REAPER
# 4. Faders motorisés synchronisés

# Vérifier:
# - S6 écran montre info REAPER
# - Faders motorisés se mettent à jour
# - Tous les paramètres synchronisés

# ✅ COMPLET!
```

### iPad + Lemur (OSC)

**Tempo**: 5 minutes

```bash
# PC (REAPER):
# 1. Note votre IP: ip addr | grep inet

# Terminal:
bash reaper-config/control-protocols-setup.sh
# → Choisir "3) iPad/Mobile (OSC)"

# iPad (Lemur app):
# 1. Installer Lemur depuis App Store
# 2. Lemur → Preferences → Network
# 3. Lemur IP: [Your PC IP]
# 4. Port: 8000
# 5. Enable "Lemur Daemon"

# 6. Lemur Editor:
# - Create custom controls
# - /track/1/volume (fader)
# - /track/1/pan (rotary)
# - /track/1/mute (button)

# ✅ CONTROL RÉCEPTEUR!
```

### Contrôleur Quelconque (MIDI Learn)

**Tempo**: 10-30 minutes

```bash
# Fonctionne avec TOUT contrôleur MIDI!

# REAPER:
# 1. Preferences → Options → MIDI Learn Mode
#    (ou Menu: Options → MIDI Learn Mode)

# 2. Click sur le paramètre que vous voulez:
#    - Fader volume
#    - Rotary pan
#    - Button mute
#    - Etc.

# 3. Actionner le contrôle physique:
#    - Bougez le fader
#    - Tournez le rotary
#    - Pressez le bouton

# 4. REAPER apprend l'association!
#    Le paramètre est maintenant contrôlé

# 5. Répétez pour tous les contrôles

# Résultat: Contrôleur MIDI entièrement custom!
```

---

## 📋 Tableau Rapide: Quel Protocole Pour Quel Contrôleur?

| Contrôleur | Protocole | Latence | Setup Time |
|---|---|---|---|
| **Behringer X-Touch** | MCU | Ultra-bas | 2 min |
| **Avid S6/S4/S3** | Eucon | Ultra-bas | 2 min |
| **Mackie HUI Pro** | Generic MIDI | Ultra-bas | 10 min |
| **iPad Lemur** | OSC | 5-50ms | 5 min |
| **Any MIDI Controller** | Generic MIDI | Ultra-bas | 5-30 min |

---

## ✨ Après le Setup: Utiliser Votre Contrôleur

### Workflow Basique

```bash
# 1. REAPER lancé avec config contrôleur
# 2. Mixer:
#    - Faders: Volume chaque track
#    - Rotaries: Pan chaque track
#    - Buttons: Mute/Solo
#    - Transport: Play, Stop, Record

# 3. Production:
#    - Ajuster les niveaux
#    - Balance stéréo
#    - Mute instruments
#    - Record à distance!
```

### Advanced: Multiple Contrôleurs

Vous pouvez connecter plusieurs contrôleurs simultanément!

```bash
# Exemple:
# - Behringer X-Touch (8 faders principaux)
# - iPad Lemur (contrôles supplémentaires)
# - Keyboard (shortcuts rapides)

# Tous synchronisés, tous actifs!
```

---

## 🐛 Troubleshooting Rapide

### Contrôleur Non Détecté

```bash
# 1. Vérifier connexion USB
lsusb | grep -i "midi\|audio\|control"

# 2. Restart JACK
sudo systemctl restart jack

# 3. Restart REAPER

# 4. Si toujours pas détecté:
#    - Utiliser "Generic MIDI + MIDI Learn"
#    - Fonctionne avec n'importe quel device!
```

### Pas de Feedback (LCD vide)

```bash
# MCU seulement:
# REAPER doit envoyer MIDI OUT au device

# Preferences → Control Surfaces → Device
# → Output: Sélectionner le device
# → OK
```

### Latence Contrôleur

```bash
# Très rare sur USB direct
# Si problème:

# 1. Utiliser USB direct (pas hub)
# 2. Vérifier JACK:
jackd -d alsa &
jack_latent
# Doit être < 5ms

# 3. Si OSC (iPad):
#    - Vérifier WiFi stable
#    - 5G ou Ethernet réduirait latence
```

---

## 🎵 Cas d'Usage Réels

### Cas 1: Studio Professionnel (Behringer X-Touch)

```
Setup: 2 minutes
Devices: X-Touch + Keyboard
Workflow:
├─ Faders: Volume chaque track
├─ Rotaries: Pan/plugins
├─ Transport: Play/Stop/Record
└─ Keyboard: Shortcuts rapides

Résultat: Mix fluide et naturel! 🎚️
```

### Cas 2: Production Mobile (iPad Lemur)

```
Setup: 5 minutes
Devices: iPad WiFi
Workflow:
├─ Lemur: Contrôles custom design
├─ Network: Pas de câbles
├─ Laptop: Libre de position
└─ Distance: Contrôle à distance!

Résultat: Créativité sans limites! 📱
```

### Cas 3: Budget Limité (Generic MIDI)

```
Setup: 20 minutes
Devices: N'importe quel contrôleur MIDI
Workflow:
├─ MIDI Learn: Chaque control mappé
├─ Flexible: Adapt pour votre gear
├─ Gratuit: Aucun driver spécial
└─ Compatible: Tout contrôleur MIDI

Résultat: Pro sans dépenser! 💰
```

---

## 📚 Pour Plus de Détails

Voir la documentation complète: **[docs/CONTROL-PROTOCOLS.md](../docs/CONTROL-PROTOCOLS.md)**

- ✅ Tous les protocoles expliqués
- ✅ Configuration complète par marque
- ✅ Cas d'usage avancés
- ✅ Troubleshooting exhaustif

---

## 🚀 Prêt?

```bash
# 1. Connecter votre contrôleur
# 2. Lancer le wizard:
bash reaper-config/control-protocols-setup.sh

# 3. Suivre les instructions
# 4. Mixer/produire/profiter! 🎵
```

---

**REAPER OS: Tous les contrôleurs supportés!** 🎛️✨
