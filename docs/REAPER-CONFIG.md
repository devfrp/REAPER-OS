# REAPER Configuration Guide

## Configuration Optimale REAPER pour REAPER OS

REAPER s'exécute nativement sur Linux. Cette configuration optimise REAPER pour une utilisation maximale sur REAPER OS.

## Fichier reaper.ini

**Emplacement:** `~/.config/REAPER/reaper.ini`

```ini
[AUDIO]
# Audio device - JACK pour latence minimale
audiodevice=JACK
# Audio settings
buffersize=256
samplerate=48000
recmeterdb=1
preciseaudiotime=1
recordmeterpos=0
metronomemode=1
metrovolume=1.0
recmonitor=2

[VST]
# Chemins des plugins VST Windows
vstpath=C:\Program Files\Common Files\VST;C:\Program Files (x86)\Common Files\VST
vstpath3=C:\Program Files\Common Files\VST3
vstcache=1
vstrescan=0
vstarchitect=2          # 64-bit
vstarchitect2=2         # 64-bit fallback

[JACK]
# Configuration JACK
jackconnect=1
jackautoconnect=1
jacklatency=128
jackbuffering=256

[INTERFACE]
# Interface
ui_scale=100
theme=dark
fontsize=14
wantidletimer=0

[MIDI]
# MIDI Input/Output
midiindev=*             # All input devices
midioutdev=             # No specific output
midieventmode=1
midiccmode=1

[PERFORMANCE]
# Performance optimizations
maxdiskio=16384
buildcache=1
asyncmixmode=1
lockui=0
autounarm=1

[GENERAL]
# General settings
screenupdatetime=0
checkforupdates=0
autosave=1
autosaveinterval=60000  # 1 minute
defaudioext=.wav
defbitsz=24
```

## Customisation Clavier

**File:** `~/.config/REAPER/reaper-kb.ini`

Les raccourcis clavier par défaut de REAPER sont optimisés. Pour customiser:

1. REAPER → **Options** → **Customize keyboard**
2. Rechercher l'action
3. Assigner un raccourci
4. Les changements sont sauvegardés automatiquement

### Raccourcis Essentiels

```
Ctrl+T          - New Track
Ctrl+Space      - Play/Pause
S               - Record/Solo
M               - Mute
Shift+R         - Record armed
Enter           - Repeat toggle
Ctrl+Shift+F    - Fullscreen
Ctrl+Shift+P    - Project properties
Ctrl+E          - Edit item (double-click area)
```

## Scripts REAPER

REAPER supporte les scripts (ReaScript) en Lua, Python, ou EEL2.

**Emplacement:** `~/.config/REAPER/Scripts/`

Exemples de scripts utiles:
- Normalization
- Batch processing
- MIDI helpers
- Routing automation

Pour installer un script:
1. Télécharger le script ReaScript
2. Placer dans `Scripts/`
3. Créer un custom action
4. `Actions` → `Show action list` → `New action`

## Theming

REAPER OS include un thème sombre optimisé pour les sessions prolongées.

### Charger un Thème

1. **Options** → **Theme Manager**
2. Sélectionner un thème
3. Redémarrer REAPER pour appliquer

### Thèmes Recommandés

- **REAPER Dark** (par défaut, inclus)
- **Darker** (contraste élevé)
- **ReaperDarkMode** (OLED-friendly)

### Customiser les Couleurs

**File:** `~/.config/REAPER/reaper-colors.ini`

```ini
[COLORS]
# Format: #RRGGBB
color_play_marker=FF6600
color_track_bg=1A1A1A
color_waveform=00CCFF
color_grid=333333
```

## Profils Audio/MIDI

Sauvegarder différentes configurations pour différents projets:

1. Configurer Inputs/Outputs/Effects
2. **File** → **Project settings** → **Save as default**
3. Pour de futurs projets, charger le profil

## Extensions REAPER

REAPER supporte les extensions (JS effects, VST, AU/LV2).

### ReaScript Extensions (JS)

Placer dans: `~/.config/REAPER/Effects/`

Exemples:
- Analyseurs spectraux
- Utilitaires de mixing
- Tools créatifs

### VST Extensions

Les VST Windows (via Wine) s'installent comme décrit dans [VST-SETUP.md](VST-SETUP.md)

## Preferences Essentielles

### Audio
- Sample rate: 48000 Hz (ou 44100 si nécessaire)
- Buffer: 256 samples (latence ~5ms)
- Channels: Stéréo ou Surround selon config

### MIDI
- All inputs enabled
- Monitoring: Auto

### Performance
- Threaded MIDI: On
- Built-in limiter: On
- Async mixing: On

### Appearance
- Theme: Dark
- UI Scale: 100-200% selon écran
- Show dock icons: On

### Saving
- Autosave: On (60 secondes)
- Backup projects: On

## Raccourcis REAPER OS Spécifiques

```
Ctrl+Alt+F    - Ouvrir Dolphin (file manager)
Ctrl+Alt+T    - Terminal
Ctrl+Alt+R    - Restart JACK
Ctrl+Alt+P    - Pulse Audio mixer
```

## Optimization pour Sessions Longues

Paramètres pour un workflow intense:

```ini
# Minimal UI updates
screenupdatetime=100

# Disable unnecessary features
autounarm=0
autoloadsettings=0

# Enable performance mode
asyncmixmode=1
maxdiskio=32768

# Increase autosave
autosaveinterval=30000  # 30 secondes
```

## REAPER + JACK Integration

Configuration optimale pour JACK + REAPER:

1. **Lancer JACK** avant REAPER
   ```bash
   jackd -R -d alsa -d hw:0 -r 48000 -p 256 -n 2 &
   reaper-start
   ```

2. **Dans REAPER**, vérifier:
   - Preferences → Audio → Device: **JACK**
   - JACK connections visible dans QJackCtl

3. **MIDI via JACK**
   - REAPER détecte automatiquement les MIDI ports JACK
   - Utiliser `a2jmidid` pour ALSA to JACK bridging

## Backup Configuration

```bash
# Sauvegarder votre configuration
cp -r ~/.config/REAPER ~/reaper-backup-$(date +%Y%m%d)

# Restaurer depuis backup
rm -rf ~/.config/REAPER
cp -r ~/reaper-backup-20240101 ~/.config/REAPER
```

## Ressources

- **REAPER Manual**: https://www.reaper.fm/docs/
- **REAPER Forum**: https://forum.cockos.com/
- **ReaScript Docs**: https://www.reaper.fm/sdk/reascript/reascript.php
- **REAPER Scripts**: https://stash.reaper.fm/

## Troubleshooting

### REAPER Lent

```bash
# Vérifier l'utilisation CPU
top -p $(pgrep reaper)

# Désactiver les plugins inutiles
# Dans REAPER: Options → Preferences → Plug-ins → Disable

# Augmenter buffer size
# Preferences → Audio → Increase buffersize
```

### VST ne fonctionne pas

Voir [VST-SETUP.md](VST-SETUP.md) pour le troubleshooting complet

### Latence Audio

```bash
# Vérifier la latence JACK
jack_latent

# Réduire le buffer JACK
jackd -p 128  # ~3ms instead of 5ms
```

---

**REAPER OS = Productivité Maximale** 🎵
