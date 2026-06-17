# Configuration REAPER pour REAPER OS

## 📋 Fichiers de Configuration REAPER

REAPER stocke sa configuration dans plusieurs fichiers clés:

### Configuration Principale
- `reaper.ini` - Paramètres globaux REAPER
- `reaper-menu.txt` - Personnalisation du menu contextuel
- `reaper-kb.ini` - Raccourcis clavier

### Contrôle et Protocoles
- `reaper-osc.ini` - Configuration OSC (iPad, Mobile)
- Scripts de setup pour HUI, Eucon, MCU, OSC

## 🎛️ Protocoles de Contrôle Supportés

REAPER OS supporte **TOUS les protocoles de contrôle audio**:

| Protocole | Contrôleurs | Latence | Setup |
|---|---|---|---|
| **MCU** | Behringer X-Touch, Soundcraft | Ultra-bas | Native |
| **Eucon** | Avid S3/S4/S6, Euphonix | Ultra-bas | Native |
| **HUI** | Mackie HUI, Behringer FCB | Ultra-bas | MIDI Learn |
| **OSC** | iPad (Lemur), Mobile | 5-50ms | Network |
| **MIDI Generic** | Tout contrôleur MIDI | Ultra-bas | Learn |
| **Keyboard** | Clavier USB/Bluetooth | Instant | Native |

### Setup Rapide Par Protocole

```bash
# Wizard de configuration
bash reaper-config/control-protocols-setup.sh

# Ou dans REAPER:
# Preferences → Control Surfaces → Add Device
```

### Behringer X-Touch (MCU)

```ini
[MCU]
mcu_enabled=1
device=X-Touch
channel_count=8
flip_enabled=1
```

### Avid S6/S4/S3 (Eucon)

```ini
[EUCON]
eucon_enabled=1
eucon_motorized=1
eucon_channel_count=16
```

### iPad + Lemur (OSC)

```ini
[OSC]
osc_enabled=1
osc_port=8000
osc_listen=0.0.0.0
```

Network: `192.168.x.x:8000`

### Generic Controller (MIDI Learn)

```
Options → MIDI Learn Mode
→ Click parameter
→ Move controller knob
→ Automatic mapping!
```

## 📚 Documentation Détaillée

Pour tous les détails: **[docs/CONTROL-PROTOCOLS.md](../docs/CONTROL-PROTOCOLS.md)**

- ✅ Tous les protocoles expliqués
- ✅ Configuration complète par marque
- ✅ Troubleshooting
- ✅ Cas d'usage avancés

## Paramètres Recommandés pour REAPER OS

## Latence Audio
```ini
[AUDIO]
audiodevice=JACK
buffersize=256         # Pour latence minimale
samplerate=48000       # Ou 44100/96000/192000
```

## Support VST Windows
```ini
[VST]
vstpath=C:\Program Files\Common Files\VST;C:\Program Files (x86)\Common Files\VST
vstpath3=C:\Program Files\Common Files\VST3
vstcache=enabled
vstrescan=0
```

## Interface Système
```ini
[INTERFACE]
theme=default
customtheme=reaper-dark.ReaperThemeZip
```

## Configuration Automatique

Un script `reaper-config-init.sh` génère au premier boot:
1. Configuration optimale pour REAPER OS
2. Plugins VST reconnus
3. Profils MIDI/Audio
4. Intégration Dolphin
5. Protocoles de contrôle

## Customization

Les utilisateurs peuvent modifier:
- Couleurs via les thèmes REAPER
- Raccourcis clavier
- Plugins VST chargés
- Configuration audio/MIDI
- **Protocoles de contrôle** (MCU, Eucon, OSC, etc.)

## Theming

REAPER OS include:
- Thème sombre optimisé
- Icônes personnalisées
- Fonts monospace pour audio pro

Pour charger un thème:
1. Menu: Options > Theme Manager
2. Sélectionner un thème
3. Redémarrer REAPER
