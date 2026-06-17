# Wine/Proton Setup Guide

## Configuration Complète de Wine/Proton pour REAPER OS

Ce guide explique en détail comment configurer Wine/Proton pour un support optimal des VST Windows sous REAPER OS.

## Prérequis

```bash
# Installer Wine et dépendances
sudo apt-get install wine wine32 wine64 winetricks

# Vérifier l'installation
wine --version
winetricks --version

# (Optionnel) Installer Proton
git clone https://github.com/ValveSoftware/Proton.git /opt/proton
```

## Architecture Wine

### Structure des Prefixes

```
WINEPREFIX=~/.wine
├── drive_c/             (disque C:)
│   ├── Program Files/           # Applications 64-bit
│   │   ├── REAPER/              # REAPER DAW
│   │   └── Common Files/VST/    # Plugins VST 64-bit
│   ├── Program Files (x86)/     # Applications 32-bit
│   │   └── Common Files/VST/    # Plugins VST 32-bit
│   ├── Users/
│   │   └── [username]/          # Documents, Desktop
│   └── Windows/
├── drive_d/             (disque D: - optionnel)
├── system.reg           (registry système)
└── user.reg             (registry utilisateur)
```

## Création du Préfixe Wine

### Option 1: Préfixe Automatique (Recommandé)

```bash
# Créer et initialiser le préfixe 64-bit
WINEARCH=win64 WINEPREFIX=~/.wine wine wineboot --init

# Vérifier la création
ls -la ~/.wine/
```

### Option 2: Préfixe Personnalisé

```bash
# Créer un préfixe séparé (pour multilib)
WINEARCH=win32 WINEPREFIX=~/.wine32 wine wineboot --init

# Utiliser lors du lancement
WINEPREFIX=~/.wine32 wine app.exe
```

## Installation des Composants Windows

### Runtime Essentiels

```bash
# Visual C++ Runtime (requis pour beaucoup de VST)
winetricks vcrun2019
winetricks vcrun2017
winetricks vcrun2015

# .NET Framework (pour certains VST moderne)
winetricks dotnet48

# DirectX 11 (audio/vidéo)
winetricks d3dx11

# Codecs audio
winetricks xact

# Installer tout en une fois
winetricks vcrun2019 dotnet48 d3dx11 xact
```

## Configuration du Registre Wine

### Variables Critiques pour Performance Audio

```bash
# Créer un script de configuration
cat > ~/configure-wine-audio.sh << 'EOF'
#!/bin/bash

WINEPREFIX="${WINEPREFIX:-$HOME/.wine}"
export WINEPREFIX

# Désactiver CSMT pour VST (peut causer lag)
wine reg add 'HKEY_CURRENT_USER\Software\Wine\Direct3D' \
    /v CSMT /d disabled /t REG_SZ /f

# Activer MulithreadSafe pour VST plugins
wine reg add 'HKEY_CURRENT_USER\Software\Wine\Direct3D' \
    /v VideoMemorySize /d "2048" /t REG_SZ /f

# Désactiver DirectInput (utiliser native input)
wine reg add 'HKEY_CURRENT_USER\Software\Wine\Direct3D' \
    /v DirectInput /d disabled /t REG_SZ /f

# Optimiser pour plugins VST
wine reg add 'HKEY_CURRENT_USER\Software\Wine\AppDefaults' \
    /v UseOpenGL /d Y /t REG_SZ /f

echo "Wine registry configuré pour VST"
EOF

chmod +x ~/configure-wine-audio.sh
bash ~/configure-wine-audio.sh
```

## Environnement Wine Optimisé

### Variables d'Environnement

```bash
# Créer ~/.bashrc avec les optimisations
cat >> ~/.bashrc << 'EOF'

# Wine Audio Optimization
export WINEPREFIX="$HOME/.wine"
export WINEARCH=win64
export WINE_LARGE_ADDRESS_AWARE=1
export NOMSCOREE=1

# Proton (si disponible)
export PROTON_PATH="/opt/proton"
export PROTON_LOG=1
export PROTON_FORCE_LARGE_ADDRESS_AWARE=1

# Audio Performance
export PULSE_LATENCY_MSEC=10
export JACK_LATENCY_CB=1
export PA_LATENCY_MSEC=10

# GPU Acceleration
export DXVK_ASYNC=1
export DXVK_HUD=off
export DXVK_LOG_LEVEL=warn

# Disable debug output
export WINEDEBUG=-all

# ALSA output
export ALSA_CARD=default
EOF

source ~/.bashrc
```

## Dépannage Wine

### Problème: "DLL not found"

```bash
# Vérifier les DLLs manquantes
wine regedit

# Navigate: HKEY_CURRENT_USER\Software\Wine\DllOverrides

# Ajouter overrides pour VST si nécessaire
wine reg add 'HKEY_CURRENT_USER\Software\Wine\DllOverrides' \
    /v "d3dx11_43" /d "native,builtin" /t REG_SZ /f
```

### Problème: "No application associated"

```bash
# Créer l'association
wine assoc .exe=exefile
wine ftype exefile="C:\Program Files\REAPER\reaper.exe" "%%1"
```

### Problème: Son qui crackle

```bash
# Augmenter le buffer Wine
wine reg add 'HKEY_CURRENT_USER\Software\Wine\Audio' \
    /v BufferSize /d 4096 /t REG_DWORD /f

# Ou réduire le buffer JACK
jackd -p 512  # Augmenter la taille
```

## Proton vs Wine

### Quand Utiliser Proton

Proton offre meilleure performance pour:
- VST heavy (20+)
- GPU rendering VST
- Plugins complexes

```bash
# Utiliser Proton au lieu de Wine
export PROTON_PATH="/opt/proton"
${PROTON_PATH}/proton run ~/.wine/drive_c/Program\ Files/REAPER/reaper.exe
```

### Quand Utiliser Wine

Wine est plus léger et suffisant pour:
- Setup simple
- VST légers
- Projets basiques

## Support 32-bit

Pour utiliser des VST 32-bit:

```bash
# Installer le support multilib
sudo dpkg --add-architecture i386
sudo apt-get update
sudo apt-get install wine32 wine32:i386

# Créer un préfixe 32-bit
WINEARCH=win32 WINEPREFIX=~/.wine32 wine wineboot --init

# Installer VST 32-bit
WINEPREFIX=~/.wine32 winetricks vcrun2019

# Utiliser
WINEPREFIX=~/.wine32 wine ~/.wine32/drive_c/Program\ Files\ \(x86\)/...
```

## Performance Tuning

### CPU Affinity (affinité processeur)

```bash
# Réserver un CPU core pour REAPER
taskset -c 0 wine ~/.wine/drive_c/Program\ Files/REAPER/reaper.exe
```

### Realtime Priority

```bash
# Lancer Wine/REAPER en priorité realtime
chrt -rr 50 wine ~/.wine/drive_c/Program\ Files/REAPER/reaper.exe
```

### Cache Optimization

```bash
# Nettoyage du cache Wine (careful!)
rm -rf ~/.cache/wine
mkdir ~/.cache/wine

# Pour Proton
rm -rf ~/.cache/proton
```

## Uninstall / Reset

### Réinitialiser le Préfixe Wine

```bash
# Backup avant reset
mv ~/.wine ~/.wine.bak

# Créer un nouveau préfixe
WINEARCH=win64 WINEPREFIX=~/.wine wine wineboot --init

# Restaurer si besoin
rm -rf ~/.wine
mv ~/.wine.bak ~/.wine
```

## Ressources

- **Wine AppDB**: https://appdb.winehq.org/
- **Wine Docs**: https://wiki.winehq.org/
- **WineHQ Download**: https://winehq.org/
- **Proton GitHub**: https://github.com/ValveSoftware/Proton
- **DXVK**: https://github.com/doitsujin/dxvk

## Tips & Tricks

### Lancer `winecfg` GUI

```bash
# Ouvrir la configuration GUI Wine
WINEPREFIX=~/.wine winecfg
```

### Parcourir le disque Windows

```bash
# Utiliser Dolphin pour explorer ~/.wine/drive_c/
dolphin ~/.wine/drive_c/
```

### Déboguer un VST

```bash
# Lancer REAPER avec debug Wine
WINEDEBUG=+loaddll wine ~/.wine/drive_c/Program\ Files/REAPER/reaper.exe 2>&1 | tee /tmp/wine-debug.log

# Analyser les logs
grep ERROR /tmp/wine-debug.log
```

---

**Wine/Proton = VST Windows sur Linux!** 🎛️
