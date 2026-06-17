# Configuration Wine/Proton pour VST Windows

## Deux Solutions pour VST Windows

### 1. Wine/Proton Direct (In-Process)
VST s'exécutent directement dans REAPER via une couche Wine/Proton
- **Latence**: 3-5ms
- **Stabilité**: Bonne
- **Setup**: Simple
- **Idéal pour**: VST légers, sessions standard

### 2. AudioGridder (Serveur Séparé) ⭐ Recommandé
VST s'exécutent dans un serveur séparé, accédé via plugin AudioGridder
- **Latence**: 1-3ms (MEILLEUR!)
- **Stabilité**: Excellente
- **Isolation**: Complète (crash ≠ crash REAPER)
- **Setup**: Moyen
- **Idéal pour**: VST complexes, production, live, stabilité maximale

## Objectif
Configurer Wine/Proton pour supporter les VST 32-bit et 64-bit conçus pour Windows avec:
- Latence minimale
- Support complet MIDI
- Scan/cache des plugins
- Isolation des préfixes

## Structure des Prefixes Wine

```
$HOME/.wine/
├── drive_c/
│   ├── Program Files/
│   │   └── Common Files/VST/       # VST 64-bit
│   └── Program Files (x86)/
│       └── Common Files/VST/       # VST 32-bit
├── drive_d/                         # Dossier supplémentaire
└── system.reg                       # Configuration
```

## Variables d'Environnement Critiques

### Optimisations Performance
```bash
# Pour support audio optimal
WINEARCH=win64
WINEPREFIX=$HOME/.wine
PROTON_LOG=1
PROTON_LOG_DIR=$HOME/.logs
PROTON_FORCE_LARGE_ADDRESS_AWARE=1
DXVK_HUD=off

# Audio
PULSE_LATENCY_MSEC=10
JACK_LATENCY_CB=1

# GPU (si disponible)
DXVK_ASYNC=1
PROTON_USE_WINED3D=0
```

### Configuration WINECFG pour VST
```
Registry Keys:
HKEY_CURRENT_USER\Software\Wine\AppDefaults
- VideoMemorySize: 2048 (ou plus)
- CSMT: enabled
- Multisampling: disabled (pour performance)
```

## Installation et Configuration Automatique

Un script `wine-vst-setup.sh` automatisera:
1. Création du préfixe Wine 64-bit
2. Installation des dépendances
3. Configuration des répertoires VST
4. Scan des plugins
5. Optimisation des performances

## Dossiers VST Reconnus

REAPER recherchera les VST à:
- `C:\Program Files\Common Files\VST`  (64-bit)
- `C:\Program Files (x86)\Common Files\VST`  (32-bit)
- `C:\Program Files\Common Files\VST3` (VST 3)

## Support MIDI

Wine bridge audio et MIDI via:
- **JACK**: Connexion audio low-latency
- **ALSA**: Accès direct aux périphériques MIDI
- **UMP**: Universal MIDI Packet (VST 3)

## Cache et Performance

- **Shader Cache**: `$HOME/.cache/dxvk/`
- **Font Cache**: `$HOME/.cache/wine/`
- **Plugin Scan Cache**: `$HOME/.cache/reaper/vst-scan/`

## Notes Importantes

⚠️ **VST 32-bit**: Nécessite multilib (i386) sur Debian
⚠️ **Latence**: Utilisez JACK pour latence < 5ms
⚠️ **GPU**: Drivers propriétaires recommandés pour VST GPU

## Troubleshooting

Si un VST ne fonctionne pas:
1. Vérifier le log Wine: `WINEARCH=win64 wine regedit`
2. Réinstaller les Visual C++ Runtime
3. Essayer avec Proton au lieu de Wine
4. Vérifier les permissions des fichiers VST

## Ressources

- Wine AppDB: https://appdb.winehq.org
- REAPER VST Host: https://www.reaper.fm
- Proton Docs: https://github.com/ValveSoftware/Proton
