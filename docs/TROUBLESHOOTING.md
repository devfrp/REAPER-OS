# Troubleshooting Guide - REAPER OS

## Guide de Dépannage Complet pour REAPER OS

Problèmes courants et solutions.

## Table des Matières

1. [Installation](#installation)
2. [Démarrage](#démarrage)
3. [Audio](#audio)
4. [VST / Plugins](#vst--plugins)
5. [Performance](#performance)
6. [Système](#système)

---

## Installation

### L'ISO ne boot pas

**Symptôme:** REAPER OS ne démarre pas depuis la clé USB

**Solutions:**

1. **Clé USB mal créée**
   ```bash
   # Recréer la clé avec Rufus ou Etcher
   # Sélectionner: Mode DD (Disk Image) ou ISO
   # Attendre la fin complète de l'écriture
   ```

2. **BIOS mal configuré**
   - Entrer le BIOS (Del, F2, F12)
   - Sélectionner la clé USB en premier boot device
   - Sauvegarder et redémarrer

3. **ISO corrompue**
   ```bash
   # Vérifier l'intégrité
   sha256sum reaper-os.iso
   # Comparer avec la valeur officielle
   ```

### Installateur ne se lance pas après boot

**Solutions:**

1. Attendre 3-5 minutes (peut être lent)
2. Appuyer sur Entrée
3. Vérifier l'affichage du clavier (la langue peut être mal détectée)

### Erreur "Device not found" lors installation

**Solutions:**

1. Vérifier que le disque est reconnu: `lsblk`
2. Utiliser `/dev/sda`, `/dev/sdb`, etc. (pas `/dev/sda1`)
3. Si SSD NVMe: attendre que le disque soit détecté

---

## Démarrage

### REAPER OS prend trop de temps à booter

**Symptômes:** Écran noir pendant 2-5 minutes

**Causes:**

1. Chargement JACK/services
2. Configuration du disque

**Solutions:**

```bash
# Après boot, vérifier les services
systemctl status
systemctl list-units --failed

# Désactiver les services inutiles
sudo systemctl disable bluetooth cups avahi-daemon
```

### Écran noir après boot

**Solutions:**

1. Attendre 2-3 minutes
2. Appuyer sur Entrée ou un bouton quelconque
3. Si rien ne se passe, redémarrer en Ctrl+Alt+Del

### REAPER ne se lance pas au boot

**Solutions:**

```bash
# Lancer manuellement
reaper-start

# Ou
~/.config/REAPER/scripts/start-reaper.sh

# Vérifier si REAPER est installé
ls -la ~/.wine/drive_c/Program\ Files/REAPER/
```

---

## Audio

### Pas de Son

**Diagnostic:**

```bash
# 1. Vérifier JACK est en cours d'exécution
pgrep jackd

# 2. Vérifier les volumes
alsamixer
amixer

# 3. Vérifier la sortie audio
aplay -l           # List playback devices
arecord -l          # List recording devices

# 4. Tester l'audio
speaker-test -t wav -c 2 -l 1
```

**Solutions:**

1. **JACK non lancé**
   ```bash
   sudo systemctl restart jack
   # Ou manuellement:
   jackd -d alsa -d hw:0 &
   ```

2. **Mauvaise carte audio sélectionnée**
   ```bash
   # Lister les cartes
   aplay -l
   
   # Configurer JACK pour use card 1
   jackd -d alsa -d hw:1
   ```

3. **Volume muet**
   ```bash
   amixer set Master 100% unmute
   ```

4. **Couches audio conflictuelles**
   ```bash
   # Tuer PulseAudio si problématique
   pulseaudio -k
   # Utiliser JACK seul
   jackd -d alsa
   ```

### Son Distordu / Pétillements (Crackling)

**Cause:** Buffer size trop petit ou charge CPU élevée

**Solutions:**

1. **Augmenter le buffer JACK**
   ```bash
   # De 256 à 512
   jackd -d alsa -d hw:0 -p 512
   ```

2. **Augmenter dans REAPER**
   - Preferences → Audio → Increase buffer

3. **Vérifier la charge CPU**
   ```bash
   top
   htop
   ```

4. **Réduire le nombre de plugins**
   - VST, effects, ou réduire la résolution

### Latence Élevée

**Solutions:**

```bash
# 1. Réduire le buffer JACK (latency minimale)
jackd -p 128  # Latency ~3ms at 48kHz
jackd -p 64   # Latency ~1.5ms (CPU intensive)

# 2. Utiliser le noyau PREEMPT_RT (temps réel)
uname -a
# Si -rt dans le kernel, latence meilleure

# 3. Désactiver les services inutiles
sudo systemctl disable bluetooth cups gdm

# 4. CPU scaling: Force max frequency
echo performance | sudo tee /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor

# 5. Vérifier JACK latency
jack_latent
```

### Pas d'entrée Audio (microphone)

**Solutions:**

```bash
# 1. Vérifier que le périphérique input est reconnu
arecord -l

# 2. Vérifier les niveaux ALSA
alsamixer

# 3. Configurer JACK avec input
qjackctl
# Menu: Setup → Audio Inputs → [Select device]

# 4. Tester l'enregistrement
arecord -f cd -t wav test.wav  # Enregistrer 5 secondes
aplay test.wav                  # Lire
```

---

## VST / Plugins

### VST Non Détecté par REAPER

**Symptôme:** VST ne montre pas dans la liste des plugins

**Diagnostic:**

```bash
# 1. Vérifier le chemin VST
ls ~/.wine/drive_c/Program\ Files/Common\ Files/VST/

# 2. Vérifier les permissions
chmod 755 ~/.wine/drive_c/Program\ Files/Common\ Files/VST/*
chmod 644 ~/.wine/drive_c/Program\ Files/Common\ Files/VST/*.dll

# 3. Vérifier que le VST est un fichier valide
file ~/.wine/drive_c/Program\ Files/Common\ Files/VST/my-plugin.dll
# Doit afficher: PE executable (Windows)
```

**Solutions:**

1. **Copier le VST au bon endroit**
   ```bash
   cp my-vst-64bit.dll ~/.wine/drive_c/Program\ Files/Common\ Files/VST/
   cp my-vst-32bit.dll ~/.wine/drive_c/Program\ Files\ \(x86\)/Common\ Files/VST/
   ```

2. **Forcer le rescan dans REAPER**
   - Supprimer le cache: `rm ~/.cache/reaper/vst-scan/*`
   - Dans REAPER: Options → Preferences → Plug-ins → Re-scan VST

3. **Installer les dépendances Wine**
   ```bash
   winetricks vcrun2019 dotnet48 d3dx11
   ```

### VST Crash au Scan

**Symptôme:** REAPER se freeze ou crash lors du scan VST

**Solutions:**

1. **Identifier le VST problématique**
   ```bash
   # Renommer le VST suspecté
   mv ~/.wine/drive_c/Program\ Files/Common\ Files/VST/bad-plugin.dll \
      ~/.wine/drive_c/Program\ Files/Common\ Files/VST/bad-plugin.dll.bak
   
   # Rescan dans REAPER
   # Si ça marche, c'était ce VST
   ```

2. **Utiliser Proton à la place de Wine**
   ```bash
   export PROTON_PATH=/opt/proton
   wine ~/.wine/drive_c/Program\ Files/REAPER/reaper.exe
   ```

3. **Réinstaller le VST**
   ```bash
   rm ~/.wine/drive_c/Program\ Files/Common\ Files/VST/plugin.dll
   # Réinstaller via installer .exe ou copier de nouveau
   ```

### VST Son Bon mais Interface Lag

**Solutions:**

```bash
# 1. Désactiver CSMT (Multithreading Direct3D)
wine reg add 'HKEY_CURRENT_USER\Software\Wine\Direct3D' \
    /v CSMT /d disabled /t REG_SZ /f

# 2. Essayer window mode
wine reg add 'HKEY_CURRENT_USER\Software\Wine\Explorer\Desktops' \
    /v "Default" /d "1024x768" /t REG_SZ /f

# 3. Réduire la résolution VST UI
# Dans les paramètres du VST si disponible

# 4. Utiliser GPU rendering
export DXVK_ASYNC=1
wine ~/.wine/drive_c/Program\ Files/REAPER/reaper.exe
```

### VST No Sound (Muet)

**Solutions:**

```bash
# 1. Vérifier que JACK est connecté
jack_lsp -p

# 2. Dans REAPER, vérifier les connections JACK
# Options → Preferences → Audio → JACK

# 3. Tester avec un VST simple
# Utiliser un VST inclus (TTS-1) pour tester

# 4. Vérifier l'output routing
# Menu: Mixer → Input/Output
```

---

## Performance

### REAPER Lent / Freeze

**Diagnostic:**

```bash
# 1. Vérifier CPU usage
top -p $(pgrep reaper)
htop

# 2. Vérifier disque I/O
iostat -x 1

# 3. Vérifier mémoire
free -h
```

**Solutions:**

1. **Réduire les plugins**
   ```bash
   # Désactiver les VST inutilisés
   # Options → Preferences → Plug-ins → Disable
   ```

2. **Réduire la polyphonie** (MIDI)
   - Limiter le nombre de voix

3. **Augmenter buffer**
   ```bash
   # Preferences → Audio → Increase buffer size
   ```

4. **Réduire la résolution/quality**
   - Options → Preferences → Audio → Quality: Draft instead of Best

5. **Fermer les autres applications**
   ```bash
   killall firefox
   killall chrome
   ```

### REAPER Utilise Beaucoup de RAM

**Solutions:**

```bash
# 1. Vérifier les samples chargés
# REAPER tends to load large libraries in RAM

# 2. Réduire cache VST
rm ~/.cache/reaper/vst-scan/*

# 3. Limiter la RAM REAPER
# Options → Preferences → Audio → Options...
# Disk buffering, sample cache size
```

---

## Système

### Problème de Boot (Kernel Panic)

**Symptôme:** "Kernel panic - not syncing"

**Solutions:**

1. **Démarrer en mode BIOS legacy** (si EFI cause problème)
2. **Vérifier le disque**
   ```bash
   fsck /dev/sda1
   ```
3. **Réinstaller GRUB**
   ```bash
   sudo grub-install /dev/sda
   ```

### Clavier/Souris ne fonctionne pas

**Solutions:**

```bash
# 1. Redémarrer X11
sudo systemctl restart display-manager

# 2. Redémarrer les services
sudo systemctl restart udev

# 3. Tester avec un autre port USB
```

### Problème de Disque

**Symptôme:** Erreurs disque, système lent

**Diagnostic:**

```bash
# Vérifier l'état du disque
sudo smartctl -a /dev/sda

# Vérifier les erreurs de filesystem
dmesg | tail -20

# Lancer fsck
sudo fsck.ext4 /dev/sda1
```

### Problème d'Écran/Affichage

**Solutions:**

```bash
# 1. Vérifier les drivers GPU
lspci | grep -i vga
glxinfo | grep "OpenGL version"

# 2. Redémarrer le serveur X
sudo systemctl restart display-manager

# 3. Vérifier la résolution
xrandr
```

---

## Obtenir de l'Aide

### Logs Utiles

```bash
# Log système
journalctl -xn

# Wine logs
~/.wine/drive_c/reaper.log

# JACK logs
jack_lsp

# ALSA logs
aplay -vvv
```

### Créer un Bug Report

Incluez:
1. Output de `uname -a`
2. Output de `reaper --version` ou `wine --version`
3. Fichier log pertinent
4. Étapes pour reproduire

---

**Pas résolu?** Consultez [le forum](https://forum.cockos.com) ou ouvrez une [issue GitHub](https://github.com/devfrp/REAPER-OS/issues)

Bonne chance! 🎵
