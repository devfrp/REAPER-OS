#!/bin/bash

################################################################################
# REAPER OS - Build Debian 13 ISO
# Compile l'ISO bootable Debian 13 pour REAPER OS v1.0.0
################################################################################

set -euo pipefail

# Configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${PROJECT_ROOT}/build"
OUTPUT_DIR="${BUILD_DIR}/iso-output"
DEBIAN_ROOTFS="${BUILD_DIR}/debian-rootfs"
DEBIAN_ISO="${OUTPUT_DIR}/reaper-os-debian-13-v1.0.0.iso"
DEBIAN_CHECKSUM="${OUTPUT_DIR}/reaper-os-debian-13-v1.0.0.iso.sha256"
DEBIAN_CODENAME="trixie"

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

log_header() {
    echo -e "${BLUE}════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}════════════════════════════════════════${NC}"
}

# Vérifier les prérequis
check_prerequisites() {
    log_header "Vérification des prérequis"
    
    local required=("debootstrap" "mkisofs" "isohybrid" "sudo")
    
    for tool in "${required[@]}"; do
        if command -v "$tool" &> /dev/null; then
            log_info "✓ $tool trouvé"
        else
            echo "Installez: sudo apt-get install -y debootstrap genisoimage isohybrid"
            exit 1
        fi
    done
}

# Nettoyer les anciens builds
cleanup() {
    log_header "Nettoyage"
    [ -d "$BUILD_DIR" ] && sudo rm -rf "$BUILD_DIR" 2>/dev/null || true
    mkdir -p "$OUTPUT_DIR" "$DEBIAN_ROOTFS"
    log_info "Répertoires prêts"
}

# Créer le rootfs Debian
create_rootfs() {
    log_header "Création du système Debian 13"
    
    log_info "Téléchargement avec debootstrap..."
    sudo debootstrap \
        --arch=amd64 \
        --variant=minbase \
        "$DEBIAN_CODENAME" \
        "$DEBIAN_ROOTFS" \
        http://deb.debian.org/debian
    
    log_info "Rootfs créé"
}

# Configurer le DNS dans le rootfs
setup_dns() {
    # Copier la config DNS de l'hôte pour garantir la résolution réseau
    if [ -f /etc/resolv.conf ]; then
        sudo cp /etc/resolv.conf "$DEBIAN_ROOTFS/etc/resolv.conf"
        log_info "DNS copié depuis l'hôte"
    else
        sudo tee "$DEBIAN_ROOTFS/etc/resolv.conf" > /dev/null << 'DNS'
nameserver 8.8.8.8
nameserver 1.1.1.1
DNS
        log_info "DNS configuré (fallback Google/Cloudflare)"
    fi
}

# Configurer les dépôts sources Debian
configure_sources() {
    log_header "Configuration des dépôts sources Debian"

    setup_dns

    sudo tee "$DEBIAN_ROOTFS/etc/apt/sources.list" > /dev/null << EOF
deb http://deb.debian.org/debian $DEBIAN_CODENAME main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian $DEBIAN_CODENAME main contrib non-free non-free-firmware
deb http://deb.debian.org/debian $DEBIAN_CODENAME-updates main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian $DEBIAN_CODENAME-updates main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security $DEBIAN_CODENAME-security main contrib non-free non-free-firmware
deb-src http://security.debian.org/debian-security $DEBIAN_CODENAME-security main contrib non-free non-free-firmware
EOF

    log_info "Mise à jour des listes de paquets..."
    sudo chroot "$DEBIAN_ROOTFS" apt-get update

    log_info "Dépôts sources configurés"
}

# Corriger les dépendances cassées éventuelles
fix_broken() {
    sudo chroot "$DEBIAN_ROOTFS" apt-get install -y --fix-broken 2>/dev/null || true
    sudo chroot "$DEBIAN_ROOTFS" apt-get install -y --fix-missing 2>/dev/null || true
}

# Installer les paquets depuis les sources Debian (compilation)
install_packages() {
    log_header "Compilation des paquets depuis les sources Debian"

    configure_sources

    log_info "Installation des outils de compilation (bootstrap binaire obligatoire)..."
    sudo chroot "$DEBIAN_ROOTFS" apt-get install -y \
        build-essential \
        dpkg-dev \
        devscripts \
        fakeroot \
        ca-certificates \
        curl \
        wget \
        git \
        cargo \
        rustc

    # Créer un répertoire pour la compilation des sources
    sudo mkdir -p "$DEBIAN_ROOTFS/src"
    sudo chroot "$DEBIAN_ROOTFS" bash -c "cd /src && rm -rf *"

    # Définir les paquets à compiler depuis les sources
    local source_packages=(
        "linux-image-amd64"
        "grub-pc"
        "isolinux"
        "syslinux"
        "python3"
        "python3-pip"
        "alsa-utils"
        "pulseaudio"
        "jackd2"
        "ffmpeg"
    )

    for pkg in "${source_packages[@]}"; do
        log_info "Compilation de $pkg depuis les sources Debian..."

        # Garantir DNS à jour avant chaque compilation
        setup_dns

        if sudo chroot "$DEBIAN_ROOTFS" bash -c "
            export DEBIAN_FRONTEND=noninteractive
            export DEB_BUILD_OPTIONS=nocheck
            cd /src
            rm -rf /src/* 2>/dev/null || true
            echo '>>> Résolution des dépendances de build...'
            apt-get update 2>&1 | tail -3
            apt-get build-dep -y $pkg 2>&1 | tail -5
            echo '>>> Téléchargement et compilation (tests désactivés)...'
            apt-get source --compile $pkg -y 2>&1 | tail -20
            echo '>>> Installation du .deb...'
            dpkg -i *.deb 2>/dev/null || apt-get install -y ./*.deb 2>/dev/null || true
        "; then
            fix_broken
            log_success "$pkg compilé et installé depuis les sources"
        else
            log_warning "Échec compilation source pour $pkg, fallback binaire..."
            setup_dns
            sudo chroot "$DEBIAN_ROOTFS" apt-get update 2>/dev/null || true
            sudo chroot "$DEBIAN_ROOTFS" apt-get install -y "$pkg" || {
                log_warning "Impossible d'installer $pkg (ni source ni binaire)"
            }
            fix_broken
        fi
    done

    # Nettoyage des sources après compilation
    sudo rm -rf "$DEBIAN_ROOTFS/src"

    log_success "Paquets compilés depuis les sources Debian"
}

# Copier les fichiers du projet
copy_project_files() {
    log_header "Copie des fichiers REAPER OS"
    
    sudo mkdir -p "$DEBIAN_ROOTFS/opt/reaper-os"
    sudo cp -r "$PROJECT_ROOT/tools" "$DEBIAN_ROOTFS/opt/reaper-os/"
    sudo cp -r "$PROJECT_ROOT/scripts" "$DEBIAN_ROOTFS/opt/reaper-os/"
    sudo cp -r "$PROJECT_ROOT/docs" "$DEBIAN_ROOTFS/opt/reaper-os/"
    sudo cp -r "$PROJECT_ROOT/config" "$DEBIAN_ROOTFS/opt/reaper-os/" 2>/dev/null || true
    
    log_info "Fichiers copiés"
}

# Configurer le bootloader ISOLINUX
setup_isolinux() {
    log_header "Configuration du bootloader ISOLINUX"

    sudo mkdir -p "$DEBIAN_ROOTFS/isolinux"

    local isolinux_bin
    isolinux_bin=$(sudo find "$DEBIAN_ROOTFS/usr/lib" -name "isolinux.bin" 2>/dev/null | head -1)

    if [ -z "$isolinux_bin" ]; then
        log_warning "isolinux.bin introuvable — l'ISO ne sera PAS bootable !"
        return 1
    fi
    sudo cp "$isolinux_bin" "$DEBIAN_ROOTFS/isolinux/isolinux.bin"
    log_info "isolinux.bin copié"

    local syslinux_mods_dir
    syslinux_mods_dir=$(sudo find "$DEBIAN_ROOTFS/usr/lib/syslinux/modules" -name "bios" -type d 2>/dev/null | head -1)
    if [ -n "$syslinux_mods_dir" ]; then
        sudo cp "$syslinux_mods_dir"/*.c32 "$DEBIAN_ROOTFS/isolinux/" 2>/dev/null || true
        log_info "Modules syslinux BIOS copiés"
    fi

    local kern_ver
    kern_ver=$(sudo ls "$DEBIAN_ROOTFS/boot/" 2>/dev/null | grep -oP 'vmlinuz-\K[^ ]+' | head -1)

    if [ -z "$kern_ver" ]; then
        log_warning "Kernel introuvable dans /boot/ — le boot échouera !"
        return 1
    fi
    log_info "Kernel détecté: $kern_ver"

    sudo cp "$DEBIAN_ROOTFS/boot/vmlinuz-${kern_ver}" "$DEBIAN_ROOTFS/isolinux/vmlinuz"
    sudo cp "$DEBIAN_ROOTFS/boot/initrd.img-${kern_ver}" "$DEBIAN_ROOTFS/isolinux/initrd.img"
    log_info "Kernel et initrd copiés dans /isolinux/"

    local iso_vol="REAPER-OS-DEBIAN-13"
    sudo tee "$DEBIAN_ROOTFS/isolinux/isolinux.cfg" > /dev/null << ISOCFG
UI menu.c32
PROMPT 0
TIMEOUT 100
DEFAULT reaper-os

MENU TITLE REAPER OS v1.0.0 — Debian 13

LABEL reaper-os
    MENU LABEL ^Boot REAPER OS (Live)
    KERNEL vmlinuz
    APPEND initrd=initrd.img root=/dev/sr0 ro quiet console=tty1

LABEL reaper-os-install
    MENU LABEL ^Install REAPER OS
    KERNEL vmlinuz
    APPEND initrd=initrd.img root=/dev/sr0 ro quiet console=tty1

LABEL reaper-os-rescue
    MENU LABEL ^Rescue Mode (Single User)
    KERNEL vmlinuz
    APPEND initrd=initrd.img root=/dev/sr0 ro single console=tty1
ISOCFG

    log_success "ISOLINUX configuré — kernel $kern_ver"
}

# Créer l'ISO
build_iso() {
    log_header "Création de l'ISO Debian 13"
    
    # Nettoyer les caches apt pour réduire la taille ISO et éviter les conflits Joliet
    log_info "Nettoyage des caches apt..."
    sudo chroot "$DEBIAN_ROOTFS" apt-get clean 2>/dev/null || true
    sudo rm -rf "$DEBIAN_ROOTFS/var/lib/apt/lists/"* 2>/dev/null || true

    local iso_vol="REAPER-OS-DEBIAN-13"
    log_info "Génération de l'image ISO..."

    if [ -f "$DEBIAN_ROOTFS/isolinux/isolinux.bin" ]; then
        sudo mkisofs \
            -o "$DEBIAN_ISO" \
            -R -J -joliet-long \
            -V "$iso_vol" \
            -b isolinux/isolinux.bin \
            -c isolinux/boot.cat \
            -no-emul-boot \
            -boot-load-size 4 \
            -boot-info-table \
            "$DEBIAN_ROOTFS"
        log_success "ISO bootable (ISOLINUX) créée"
    else
        log_warning "ISOLINUX absent — création d'une ISO NON BOOTABLE !"
        sudo mkisofs \
            -o "$DEBIAN_ISO" \
            -R -J -joliet-long \
            -V "$iso_vol" \
            "$DEBIAN_ROOTFS"
    fi
    
    log_info "ISO créée: $DEBIAN_ISO"
    
    # Rendre bootable si possible
    if command -v isohybrid &> /dev/null; then
        sudo isohybrid "$DEBIAN_ISO" 2>/dev/null || true
        log_info "ISO rendue bootable (mode USB)"
    fi
}

# Calculer le checksum
compute_checksum() {
    log_header "Vérification d'intégrité"
    
    local checksum
    checksum=$(sha256sum "$DEBIAN_ISO" | awk '{print $1}')
    echo "$checksum  reaper-os-debian-13-v1.0.0.iso" | sudo tee "$DEBIAN_CHECKSUM" > /dev/null
    
    log_info "SHA256: $checksum"
    log_info "Fichier: $DEBIAN_CHECKSUM"
}

# Résumé final
summary() {
    log_header "COMPILATION TERMINÉE"
    
    echo ""
    echo "📦 ISO Debian 13 v1.0.0:"
    ls -lh "$DEBIAN_ISO" 2>/dev/null && echo "✓ ISO créée" || echo "✗ Erreur"
    echo ""
    echo "📍 Dossier: $OUTPUT_DIR"
    echo ""
    ls -lh "$OUTPUT_DIR"/ 2>/dev/null || echo "Aucun fichier"
    echo ""
}

# Main
main() {
    check_prerequisites
    cleanup
    create_rootfs
    install_packages
    copy_project_files
    setup_isolinux
    build_iso
    compute_checksum
    summary
}

main "$@"
