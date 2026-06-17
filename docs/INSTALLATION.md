# Installation Guide - REAPER OS

## Table des Matières

1. [Prérequis](#prérequis)
2. [Télécharger l'ISO](#télécharger-liso)
3. [Créer une clé USB bootable](#créer-une-clé-usb-bootable)
4. [Installer REAPER OS](#installer-reaper-os)
5. [Configuration post-installation](#configuration-post-installation)
6. [Installer des VST Windows](#installer-des-vst-windows)

## Prérequis

### Matériel
- **Processeur**: x86_64 (Intel/AMD) 2GHz minimum
- **RAM**: 4GB minimum (8GB recommandé)
- **Disque**: 50GB d'espace libre
- **USB**: Clé USB 4GB pour l'installation
- **Audio**: Carte audio compatible Linux ALSA/JACK

### Logiciels (pour créer l'ISO)
- Linux (Ubuntu/Debian/Fedora)
- `debootstrap`
- `xorriso`
- `squashfs-tools`

## Télécharger l'ISO

### Option 1: Compiler localement

```bash
git clone https://github.com/votre-repo/REAPER-OS.git
cd REAPER-OS/installer
sudo bash build-debian-iso.sh
```

L'ISO sera généré dans `REAPER-OS/build/reaper-os.iso`

### Option 2: Télécharger une image pré-compilée

Les images pré-compilées seront disponibles sur GitHub Releases.

## Créer une clé USB bootable

### Sur Linux

```bash
# Identifier votre clé USB
lsblk -d -o NAME,SIZE,TYPE

# Créer la clé bootable (remplacer sdX par votre périphérique)
sudo dd if=reaper-os.iso of=/dev/sdX bs=4M status=progress && sync
```

### Sur Windows

Utilisez **Rufus** ou **Etcher**:
1. Ouvrir Rufus/Etcher
2. Sélectionner `reaper-os.iso`
3. Sélectionner votre clé USB
4. Cliquer sur "Écrire"

### Sur macOS

```bash
# Identifier la clé USB
diskutil list

# Créer la clé (remplacer diskX par votre disque)
sudo diskutil unmountDisk /dev/diskX
sudo dd if=reaper-os.iso of=/dev/rdiskX bs=4m
sudo diskutil ejectDisk /dev/diskX
```

## Installer REAPER OS

### Étapes

1. **Insérer la clé USB** et redémarrer l'ordinateur
2. **Changer l'ordre de boot** (appuyer sur F2, Del, F12, ou Esc selon le BIOS)
3. **Sélectionner la clé USB** pour booter
4. **Attendre** le démarrage de REAPER OS (2-3 minutes)
5. **Lancer l'installateur** qui s'affiche automatiquement

### Installer (Assistant Graphique)

```
┌─────────────────────────────────┐
│  REAPER OS - Installateur       │
│                                 │
│  1. Sélectionner la langue      │
│  2. Localisation / Fuseau       │
│  3. Sélectionner le disque      │
│  4. Configurer l'utilisateur    │
│  5. Installer                   │
└─────────────────────────────────┘
```

**Étapes détaillées:**

#### 1. Langue
- Français
- English
- Español
- Deutsch

#### 2. Localisation
- Sélectionner votre pays/région
- Fuseau horaire automatique

#### 3. Disque d'Installation
```
Disques disponibles:
1) /dev/sda (500 GB)
2) /dev/sdb (1 TB)

Choix: 1
```

⚠️ **ATTENTION**: Toutes les données du disque sélectionné seront SUPPRIMÉES!

#### 4. Utilisateur
```
Nom d'utilisateur: [votre-nom]
Mot de passe: [••••••••]
Répéter: [••••••••]
```

#### 5. Installation
L'installation prendra **15-45 minutes** selon votre matériel.

Progress:
```
[████████░░░░░░] 45% - Installation du système...
```

### Redémarrage

Une fois terminée, l'ordinateur redémarrera automatiquement dans **REAPER OS**.

## Configuration post-installation

### Premier Boot

**REAPER OS** démarrera avec:
1. ✅ JACK Audio Server
2. ✅ Wine/Proton configuré
3. ✅ REAPER prêt (si licence détectée)
4. ✅ Dolphin (file manager) intégré

### Installer REAPER

Si REAPER n'est pas automatiquement détecté:

```bash
# Télécharger REAPER
wget https://www.cockos.com/reaper/download-linux/

# Ou installer depuis le web
reaper-install-wizard
```

### Configuration Audio

```bash
# Lancer QJackCtl pour configurer JACK
qjackctl

# Ou via terminal
jackd -R -d alsa -d hw:0 -r 48000 -p 256
```

### Configuration Clavier/Souris

L'interface REAPER est complètement customizable:
- **Options** → **Customize keyboard**
- **Options** → **Preferences** → **Mouse**

## Installer des VST Windows

### Méthode 1: Wine WINEPREFIX

```bash
# Le dossier VST par défaut
~/.wine/drive_c/Program\ Files/Common\ Files/VST/

# Copier vos VST DLL
cp my-plugin.dll ~/.wine/drive_c/Program\ Files/Common\ Files/VST/
```

### Méthode 2: Installateur Windows

Certains VST disposent d'installateurs .exe:

```bash
# Lancer l'installateur
wine my-vst-installer.exe
```

### Méthode 3: Dolphin (Graphique)

1. Ouvrir **Dolphin** (file manager)
2. Naviguer à: `home → .wine → drive_c → Program Files → Common Files → VST`
3. Glisser-déposer vos fichiers VST

### Scan dans REAPER

Une fois les VST installés:

1. Ouvrir **REAPER**
2. **Options** → **Preferences** → **Plug-ins**
3. **Re-scan VST** ou **Scan VST for new plugins**
4. Attendre le scan complet

### Troubleshooting VST

**VST non détecté?**
```bash
# Vérifier que Wine/Proton est correctement configuré
wine --version
winetricks --version

# Réinstaller les dépendances
winetricks vcrun2019
```

**VST se bloque au scan?**
```bash
# Activer le debug Wine
WINEDEBUG=+loaddll wine ~/.wine/drive_c/Program\ Files/REAPER/reaper.exe
```

**Latence élevée?**
```bash
# Vérifier JACK
jack_lsp -p  # List ports
jack_netsource  # Check latency
```

## Troubleshooting

### REAPER ne démarre pas

```bash
# Vérifier l'installation
file ~/.wine/drive_c/Program\ Files/REAPER/reaper.exe

# Forcer réinstallation
rm -rf ~/.wine
reaper-os-first-boot.sh
```

### Pas de son

```bash
# Vérifier JACK
jackd &
jack_lsp

# Vérifier la carte audio
arecord -l
aplay -l

# Redémarrer PulseAudio
pulseaudio -k && pulseaudio &
```

### Latence élevée

1. **Réduire la taille du buffer JACK**
   ```bash
   jackd -R -d alsa -d hw:0 -p 128  # 128 = ~3ms
   ```

2. **Activer PREEMPT_RT** (noyau temps réel)
   ```bash
   uname -r
   # Chercher un noyau -rt
   ```

3. **Désactiver les services inutiles**
   ```bash
   sudo systemctl disable bluetooth
   sudo systemctl disable cups
   ```

## Ressources

- **Documentation REAPER**: https://www.reaper.fm/docs/
- **JACK Documentation**: https://jackaudio.org/
- **Wine AppDB**: https://appdb.winehq.org/
- **REAPER OS Wiki**: https://github.com/votre-repo/REAPER-OS/wiki
- **Forum REAPER**: https://forum.cockos.com/

## Support

Pour obtenir de l'aide:
1. Consultez la [documentation](../docs/)
2. Vérifiez les [FAQ](../docs/FAQ.md)
3. Consultez le [Troubleshooting](../docs/TROUBLESHOOTING.md)
4. Ouvrez une [Issue sur GitHub](https://github.com/votre-repo/REAPER-OS/issues)

---

**Prêt à créer de la musique?** 🎵

Bienvenue dans REAPER OS!
