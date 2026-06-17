# VST Windows Setup Guide

## Guide Complet de Setup des VST Windows sous REAPER OS

REAPER OS offre **deux méthodes** pour utiliser les VST Windows:

### 1. **Wine/Proton Direct** (Recommandé pour latence minimale)
VST Windows s'exécutent directement dans REAPER via Wine/Proton

### 2. **AudioGridder** (Recommandé pour stabilité/isolation)
VST Windows s'exécutent dans un serveur séparé (isolation complète)

## Architecture VST Windows Support

### Méthode 1: Wine/Proton Direct
```
VST Windows (.dll)
    ↓
Wine/Proton Layer (In-Process)
    ↓
REAPER (Linux Native)
    ↓
JACK Audio Server
    ↓
Carte Audio ALSA
```

**Latence**: 3-5ms | **Stabilité**: Bonne | **Isolation**: Non

### Méthode 2: AudioGridder Server
```
REAPER (Linux Native)
    ↓
[AudioGridder VST Plugin]
    ↓ IPC/Network
AudioGridder Server (Processus séparé)
    ↓
Wine/Proton (VST Windows isolé)
    ↓
JACK Audio Server
    ↓
Carte Audio ALSA
```

**Latence**: 1-3ms | **Stabilité**: Excellente | **Isolation**: Oui

## Comparaison des Méthodes

| Aspect | Wine Direct | AudioGridder |
|--------|-----------|--------------|
| **Latence** | 3-5ms | 1-3ms |
| **Stabilité** | Bonne | Excellente |
| **Isolation** | Non (crash = crash REAPER) | Oui (crash = restart serveur) |
| **Setup** | Simple | Moyen |
| **Performance** | 95% | 100% |
| **GPU** | Support | Support avancé |

## Choix de la Méthode

### Utiliser Wine Direct si:
✅ VST légers et stables  
✅ Priorité: latence ultra-basse  
✅ Setup simple préféré  
✅ Peu de VST utilisés  

### Utiliser AudioGridder si:
✅ VST complexes (Kontakt, etc.)  
✅ Priorité: stabilité extrême  
✅ Production critique/live  
✅ Besoin isolation  
✅ Utilisation de 20+ VST  

### Utiliser les Deux (Recommandé):
✅ VST légers → Wine Direct  
✅ VST complexes → AudioGridder  
✅ Flexibilité maximale  
✅ Robustesse optimale

## Installation des VST

### Prérequis

```bash
# Vérifier que Wine est installé
wine --version

# Vérifier que Proton est disponible
ls /opt/proton/

# Vérifier les architectures supportées
dpkg --print-architecture     # amd64
dpkg --print-foreign-architectures  # i386 (si installé)

# Vérifier JACK
jackd -V

# Vérifier AudioGridder (optionnel)
which AudioGridderServer
```

### Installation Rapide

```bash
# 1. Setup Wine/Proton + VST direct
bash wine-config/wine-vst-setup.sh

# 2. (Optionnel) Setup AudioGridder pour isolation
bash wine-config/audiogridder-setup.sh
```

### Méthode 1: Wine Direct - Installation Manuelle

**Emplacement des VST:**

```
~/.wine/drive_c/Program Files/Common Files/VST/          # VST 64-bit
~/.wine/drive_c/Program Files (x86)/Common Files/VST/    # VST 32-bit
~/.wine/drive_c/Program Files/Common Files/VST3/         # VST3
```

**Étapes:**

1. **Copier les fichiers .dll**
   ```bash
   cp my-plugin-64bit.dll ~/.wine/drive_c/Program\ Files/Common\ Files/VST/
   cp my-plugin-32bit.dll ~/.wine/drive_c/Program\ Files\ \(x86\)/Common\ Files/VST/
   ```

2. **Ouvrir REAPER**
   ```bash
   reaper-start
   ```

3. **Scanner les VST**
   - Menu: `Options` → `Preferences` → `Plug-ins`
   - Bouton: `Scan VST for new plugins` ou `Re-scan VST`

4. **Utiliser dans REAPER**
   - Insérer via: `Insert` → `New Track` → `FX` → `VST`

### Méthode 2: Wine Direct - Installateur Windows (.exe)

Certains VST disposent d'installateurs .exe:

```bash
# Lancer l'installateur
wine my-vst-installer.exe

# L'installateur guidera l'installation dans Wine
# Les fichiers se retrouveront automatiquement aux bons endroits
```

### Méthode 3: Wine Direct - Dolphin (Interface Graphique)

1. **Ouvrir Dolphin**
   ```bash
   dolphin ~/.wine/drive_c/Program\ Files/Common\ Files/VST/
   ```

2. **Copier les VST via drag-drop**
   - Ouvrir le dossier source dans une autre fenêtre
   - Glisser-déposer les .dll

3. **Les VST sont installés!**

### Méthode 4: AudioGridder (Isolation Complète + Ultra Basse Latence)

Pour une stabilité maximale et isolation des VST Windows:

```bash
# 1. Installer et configurer AudioGridder
bash wine-config/audiogridder-setup.sh

# 2. Démarrer le serveur AudioGridder
systemctl --user start audiogridder-server

# 3. Dans REAPER, insérer le plugin AudioGridder VST
#    Insert FX → Search 'AudioGridder'

# 4. Configurer la connexion dans le plugin
#    Server: 127.0.0.1, Port: 55055

# 5. Charger VST Windows depuis le serveur dans le plugin
```

**Avantages AudioGridder:**
- ✅ Isolation complète (crash VST ≠ crash REAPER)
- ✅ Latence ultra-basse (1-3ms au lieu de 3-5ms)
- ✅ Meilleure stabilité pour VST complexes
- ✅ Multi-instance possible
- ✅ Support GPU avancé
- ✅ Idéal pour production/live

**Quand utiliser AudioGridder:**
- VST complexes (Kontakt, Spire, etc.)
- Production critique
- Live performance
- 20+ VST simultanés

📖 Voir [AUDIOGRIDDER.md](../wine-config/AUDIOGRIDDER.md) pour configuration détaillée et troubleshooting.

### Scan VST dans REAPER

Après installation des VST (Wine ou AudioGridder):

1. Ouvrir **REAPER**
   ```bash
   reaper-start
   ```

2. Accéder au menu VST
   - **Options** → **Preferences** → **Plug-ins**

3. Forcer le scan
   - **Re-scan VST** ou **Scan VST for new plugins**

4. Attendre le scan complet
   - Affichage progressif des VST trouvés

**Pour AudioGridder:** Le scan se fera automatiquement dans le serveur via le plugin AudioGridder VST.

## Configuration Avancée

### Optimisation Performance

**Fichier: `~/.config/reaper/reaper.ini`**

```ini
[VST]
vstcache=1              # Utiliser le cache VST
vstrescan=0             # Ne pas rescan à chaque démarrage
vstarchitect=2          # Mode 64-bit
vstarchitect2=2         # Mode 64-bit fallback

[WINE]
PROTON_LOG=0            # Désactiver les logs Wine pour performance
DXVK_ASYNC=1            # Compilation asynchrone shaders
DXVK_HUD=off            # Pas de HUD (performance)
```

### Support 32-bit (i386)

Si vous avez des VST 32-bit:

```bash
# Installer le support i386
sudo dpkg --add-architecture i386
sudo apt update
sudo apt install wine32

# Créer un préfixe 32-bit séparé (optionnel)
WINEARCH=win32 WINEPREFIX=~/.wine32 wine wineboot --init
```

### Configuration Multilib Wine

```bash
# Vérifier les architectures disponibles
wine --version
file $(which wine)

# Installer wine 32-bit si nécessaire
sudo apt install wine:i386
```

## Performance Audio

### Latence Minimale

```bash
# Configuration optimale JACK pour VST
jackd -R -d alsa -d hw:0 -r 48000 -p 128 -n 2

# Paramètres:
# -R = Mode realtime
# -p 128 = Period de 128 samples (~3ms à 48kHz)
# -n 2 = 2 périodes
```

### Gestion du Cache

```bash
# Cache Wine
~/.cache/wine/

# Cache Proton Shader
~/.cache/proton/

# Cache REAPER VST
~/.cache/reaper/vst-scan/

# Nettoyer les caches (si problèmes)
rm -rf ~/.cache/wine ~/.cache/proton
```

## VST Populaires Testés

### Compatible 100%
- ✅ **Serum** (Xfer Records)
- ✅ **Massive X** (Native Instruments)
- ✅ **Sylenth1** (LennarDigital)
- ✅ **Spire** (Reveal Sound)
- ✅ **Reveal Sound Spire**
- ✅ **Vengeance Sound Essentials**

### Compatible avec Config
- ⚠️ **Kontakt** (Native Instruments) - Nécessite dépendances .NET
- ⚠️ **Komplete** - Peut nécessiter ajustements JACK

### Problèmes Connus
- ❌ **Algumas UI scale** mal
- ❌ **Certains VST** utilisent DirectX 12 (non supporté)

## Troubleshooting

### VST Non Détecté

```bash
# 1. Vérifier le chemin
ls -la ~/.wine/drive_c/Program\ Files/Common\ Files/VST/

# 2. Vérifier les permissions
chmod 755 ~/.wine/drive_c/Program\ Files/Common\ Files/VST/*

# 3. Forcer le rescan
rm ~/.cache/reaper/vst-scan/*
reaper-start
# Dans REAPER: Options → Preferences → Plug-ins → Re-scan
```

### VST Crash au Scan

```bash
# 1. Activer le debug
WINEDEBUG=+loaddll wine ~/.wine/drive_c/Program\ Files/REAPER/reaper.exe 2>&1 | tee /tmp/wine.log

# 2. Vérifier les dépendances manquantes
winetricks dotnet48 vcrun2019

# 3. Essayer Proton au lieu de Wine
PROTON_PATH=/opt/proton wine ...
```

### Son Déformé/Pétillements

```bash
# Problème buffer size:
jackd -p 256  # Augmenter le buffer

# Problème latence JACK-REAPER:
# Dans REAPER: Options → Preferences → Audio
# Augmenter Buffer size

# Vérifier CPU load:
top
htop

# Vérifier JACK
jack_netsource
```

### Interface VST Lag/Slow

```bash
# Désactiver les effets visuels Wine
wine reg add 'HKEY_CURRENT_USER\Software\Wine\Direct3D' \
    /v CSMT /d disabled

# Ou au contraire, activer:
wine reg add 'HKEY_CURRENT_USER\Software\Wine\Direct3D' \
    /v CSMT /d enabled

# Essayer en mode windowed:
wine reg add 'HKEY_CURRENT_USER\Software\Wine\AppDefaults\reaper.exe\Direct3D' \
    /v Decorated /d Y
```

## Optimisation Avancée

### Utiliser Proton au lieu de Wine

```bash
# Proton offre meilleure performance que Wine pour certains VST
export PROTON_PATH=/opt/proton-8.0
wine ~/.wine/drive_c/Program\ Files/REAPER/reaper.exe
```

### Winetricks pour Dépendances

```bash
# Installer les dépendances courantes pour VST
winetricks vcrun2019       # Visual C++ Runtime
winetricks dotnet48        # .NET Framework
winetricks d3dx11          # DirectX 11
winetricks xact            # Audio codecs
```

### Plugin Sandboxing (Isolé)

```bash
# Créer un préfixe séparé pour chaque VST (avancé)
WINEPREFIX=~/.wine-vst-separate wine ~/.wine/drive_c/Program\ Files/VST/my-plugin.dll
```

## Ressources

- **Wine AppDB**: https://appdb.winehq.org/
- **ProtonDB**: https://protondb.com/
- **REAPER Documentation**: https://www.reaper.fm/docs/
- **Cockos Forum**: https://forum.cockos.com/

## Support

Si vous avez des problèmes:

1. Vérifier les logs:
   ```bash
   tail -f ~/.wine/drive_c/reaper.log
   ```

2. Ouvrir une issue GitHub avec:
   - Nom/version du VST
   - Sortie de `wine --version`
   - Logs d'erreur
   - Système (OS, kernel, hardware audio)

---

**Bon mix!** 🎧
