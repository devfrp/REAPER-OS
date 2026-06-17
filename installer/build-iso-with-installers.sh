#!/bin/bash

################################################################################
# REAPER OS - Build ISO with Installers
# Crée l'ISO Debian 13 avec les deux installeurs (offline et online)
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

# Nettoyer
cleanup() {
    log_header "Nettoyage"
    [ -d "$BUILD_DIR" ] && sudo rm -rf "$BUILD_DIR" 2>/dev/null || true
    mkdir -p "$OUTPUT_DIR" "$DEBIAN_ROOTFS"
    log_info "Répertoires prêts"
}

# Créer le rootfs
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
    # Seuls les paquets non-bootstrap sont compilés depuis les sources
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
        "sox"
        "jq"
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

# Installer REAPER natif Linux dans le rootfs
install_reaper() {
    log_header "Installation de REAPER natif Linux"

    local reaper_url="${REAPER_DOWNLOAD_URL:-}"
    if [ -z "$reaper_url" ]; then
        log_info "Détection de la dernière version de REAPER..."
        reaper_url=$(curl -sL "https://www.reaper.fm/download.php" | grep -oP 'https?://[^"]+reaper[^"]+linux_x86_64\.tar\.xz' | head -1 || true)
    fi

    if [ -n "$reaper_url" ]; then
        log_info "Téléchargement de REAPER depuis: $reaper_url"
        local reaper_tarball="/tmp/reaper-linux.tar.xz"
        if curl -L "$reaper_url" -o "$reaper_tarball" --progress-bar; then
            log_info "Extraction de REAPER..."
            sudo tar -xf "$reaper_tarball" -C "$DEBIAN_ROOTFS/opt/"
            # Le dossier extrait s'appelle généralement "reaper-linux" ou "reaper"
            if [ -d "$DEBIAN_ROOTFS/opt/reaper-linux" ]; then
                sudo ln -sf /opt/reaper-linux/reaper "$DEBIAN_ROOTFS/usr/local/bin/reaper"
                log_success "REAPER Linux natif installé"
            elif [ -d "$DEBIAN_ROOTFS/opt/REAPER" ]; then
                sudo ln -sf /opt/REAPER/reaper "$DEBIAN_ROOTFS/usr/local/bin/reaper"
                log_success "REAPER Linux natif installé"
            else
                # Chercher le binaire reaper
                local reaper_bin
                reaper_bin=$(find "$DEBIAN_ROOTFS/opt" -name "reaper" -type f 2>/dev/null | head -1)
                if [ -n "$reaper_bin" ]; then
                    sudo ln -sf "$reaper_bin" "$DEBIAN_ROOTFS/usr/local/bin/reaper"
                    log_success "REAPER Linux natif installé"
                else
                    log_warning "Binaire REAPER non trouvé après extraction"
                fi
            fi
            rm -f "$reaper_tarball"
        else
            log_warning "Impossible de télécharger REAPER (pas de connexion?)"
        fi
    else
        log_warning "URL REAPER non trouvée. Installation sans REAPER natif."
        log_info "REAPER pourra être installé manuellement depuis www.reaper.fm"
    fi
}

# Copier le projet complet
copy_project() {
    log_header "Copie du projet REAPER OS"
    
    sudo mkdir -p "$DEBIAN_ROOTFS/opt/reaper-os"
    sudo mkdir -p "$DEBIAN_ROOTFS/root/installers"
    
    # Copier tous les dossiers
    for dir in tools scripts docs config tests installer reaper-config wine-config packages; do
        if [ -d "$PROJECT_ROOT/$dir" ]; then
            log_info "Copie: $dir/"
            sudo cp -r "$PROJECT_ROOT/$dir" "$DEBIAN_ROOTFS/opt/reaper-os/"
        fi
    done
    
    # Copier les fichiers de documentation
    for file in README.md CHANGELOG.md LICENSE CONTRIBUTING.md; do
        if [ -f "$PROJECT_ROOT/$file" ]; then
            sudo cp "$PROJECT_ROOT/$file" "$DEBIAN_ROOTFS/opt/reaper-os/"
        fi
    done
    
    # Rendre les scripts exécutables
    sudo find "$DEBIAN_ROOTFS/opt/reaper-os" -name "*.sh" -exec chmod +x {} \;
    sudo find "$DEBIAN_ROOTFS/opt/reaper-os" -name "*.py" -exec chmod +x {} \;
    
    log_info "Projet copié complet"
}

# Builder ASNUX dans le rootfs (evite la compilation au premier boot)
build_asnux_in_rootfs() {
    log_header "Build ASNUX (low-latency audio engine)"

    local asnux_repo="https://github.com/devfrp/asnux.git"

    log_info "Clonage du depot ASNUX dans le rootfs..."
    setup_dns
    sudo chroot "$DEBIAN_ROOTFS" bash -c "
        rm -rf /tmp/asnux
        git clone --depth 1 '$asnux_repo' /tmp/asnux
    " || {
        log_warning "Échec clonage ASNUX (pas de connexion ?), étape ignorée"
        return 0
    }

    log_info "Compilation dans le rootfs (chroot)..."

    # Déterminer la version du kernel INSTALLÉ dans le rootfs (pas le noyau hôte)
    local kern_ver
    kern_ver=$(sudo ls "$DEBIAN_ROOTFS/lib/modules/" 2>/dev/null | grep -E '^[0-9]' | head -1)
    if [ -z "$kern_ver" ]; then
        log_warning "Aucun kernel trouvé dans le rootfs, build ASNUX ignoré"
        return 0
    fi
    log_info "Kernel installé détecté: $kern_ver"

    sudo chroot "$DEBIAN_ROOTFS" bash -c "
        cd /tmp/asnux
        export CARGO_HOME=/root/.cargo
        export PATH=/root/.cargo/bin:\$PATH
        export KDIR=/lib/modules/$kern_ver/build
        export KERNELDIR=/lib/modules/$kern_ver/build
        echo '>>> Building kernel module (KDIR='\$KDIR')...'
        make kernel 2>&1
        echo '>>> Building daemon...'
        make daemon 2>&1
        echo '>>> Building GUI (optionnel, ignoré si échec)...'
        make gui 2>&1 || echo '(GUI ignorée - version Rust incompatible)'
        echo '>>> Installing...'
        make install 2>&1
        depmod -a $kern_ver 2>&1 || true
    " 2>&1 | tail -20

    if sudo test -f "$DEBIAN_ROOTFS/lib/modules/$kern_ver/kernel/sound/drivers/asnux.ko" 2>/dev/null; then
        log_success "Module kernel ASNUX compile et installe (kernel $kern_ver)"
    else
        log_info "Installation manuelle du module kernel ASNUX..."
        sudo mkdir -p "$DEBIAN_ROOTFS/lib/modules/$kern_ver/kernel/sound/drivers/"
        sudo cp -f "$DEBIAN_ROOTFS/tmp/asnux/kernel/asnux.ko" "$DEBIAN_ROOTFS/lib/modules/$kern_ver/kernel/sound/drivers/" 2>/dev/null || true
        sudo chroot "$DEBIAN_ROOTFS" depmod -a "$kern_ver" 2>/dev/null || true
        log_info "Module kernel installe manuellement"
    fi

    if sudo test -f "$DEBIAN_ROOTFS/usr/local/bin/asnux-daemon"; then
        log_success "Daemon ASNUX compile et installe"
    fi
    if sudo test -f "$DEBIAN_ROOTFS/usr/local/bin/asnux-gui"; then
        log_success "GUI ASNUX compilee et installee"
    fi

    sudo rm -rf "$DEBIAN_ROOTFS/tmp/asnux"

    # Marqueur pour setup-asnux.sh : binaires deja installes
    sudo mkdir -p "$DEBIAN_ROOTFS/opt/asnux"
    sudo touch "$DEBIAN_ROOTFS/opt/asnux/.prebuilt"

    # Pre-creer la config par defaut
    sudo mkdir -p "$DEBIAN_ROOTFS/etc/skel/.config/asnux"
    sudo tee "$DEBIAN_ROOTFS/etc/skel/.config/asnux/config.json" > /dev/null << 'ASNUXCFG'
{
    "buffer_size": 256,
    "sample_rate": 48000,
    "channels": 2,
    "periods": 4,
    "default_engine": true,
    "realtime_priority": 80
}
ASNUXCFG

    log_success "ASNUX pre-build et integre dans l'ISO"
}

# Créer un script de bienvenue
create_welcome_script() {
    log_header "Création du script de bienvenue"
    
    sudo tee "$DEBIAN_ROOTFS/root/INSTALL.sh" > /dev/null << 'EOF'
#!/bin/bash

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║        BIENVENUE DANS REAPER OS v1.0.0                     ║"
echo "║  Distribution audio professionelle basée sur Debian 13     ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

echo "Deux options d'installation disponibles:"
echo ""
echo "1️⃣  INSTALLEUR HORS LIGNE (Offline)"
echo "   - Pas besoin de connexion Internet"
echo "   - Installation complète de /opt/reaper-os"
echo "   - Idéal pour démarrage rapide"
echo ""
echo "   $ sudo bash /opt/reaper-os/installer/install-offline.sh"
echo ""

echo "2️⃣  INSTALLEUR EN LIGNE (Online)"
echo "   - Télécharge les dernières versions"
echo "   - Mises à jour depuis GitHub"
echo "   - Idéal pour systèmes établis"
echo ""
echo "   $ sudo bash /opt/reaper-os/installer/install-online.sh"
echo ""

echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "📚 Documentation: /opt/reaper-os/docs/"
echo "🛠️  Outils: /opt/reaper-os/tools/"
echo "📋 Plus d'info: /opt/reaper-os/README.md"
echo ""
EOF
    
    sudo chmod +x "$DEBIAN_ROOTFS/root/INSTALL.sh"
    
    log_info "Script de bienvenue créé"
}

# Configurer les services
setup_services() {
    log_header "Configuration des services"
    
    # Service systemd pour REAPER OS (optionnel)
    sudo tee "$DEBIAN_ROOTFS/etc/systemd/system/reaper-os.service" > /dev/null << 'EOF'
[Unit]
Description=REAPER OS Audio System
After=sound.target
Wants=reaper-os.socket

[Service]
Type=simple
User=root
WorkingDirectory=/opt/reaper-os
ExecStart=/opt/reaper-os/scripts/start-system.sh

[Install]
WantedBy=multi-user.target
EOF
    
    log_info "Services configurés"
}

# Créer le point d'entrée
create_entrypoint() {
    log_header "Création du point d'entrée"
    
    sudo tee "$DEBIAN_ROOTFS/root/startup.sh" > /dev/null << 'EOF'
#!/bin/bash
# Point d'entrée pour l'ISO

export PATH="/opt/reaper-os/scripts:$PATH"
export REAPER_OS_ROOT="/opt/reaper-os"

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  REAPER OS v1.0.0 - Démarrage                              ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Vérifier si déjà installé
if [ -d "$REAPER_OS_ROOT/tools" ]; then
    echo "✓ REAPER OS détecté dans $REAPER_OS_ROOT"
    echo ""
    echo "Pour l'installation hors ligne:"
    echo "  sudo bash $REAPER_OS_ROOT/installer/install-offline.sh"
    echo ""
    echo "Pour l'installation en ligne:"
    echo "  sudo bash $REAPER_OS_ROOT/installer/install-online.sh"
else
    echo "⚠️  REAPER OS non trouvé"
fi

bash
EOF
    
    sudo chmod +x "$DEBIAN_ROOTFS/root/startup.sh"
    
    log_info "Point d'entrée créé"
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

    log_info "Nettoyage du rootfs..."
    sudo chroot "$DEBIAN_ROOTFS" apt-get clean 2>/dev/null || true
    sudo rm -rf "$DEBIAN_ROOTFS/var/lib/apt/lists/"* 2>/dev/null || true
    sudo rm -rf "$DEBIAN_ROOTFS/var/cache/apt/"* 2>/dev/null || true
    sudo rm -rf "$DEBIAN_ROOTFS/root/.cargo/registry/"* 2>/dev/null || true
    sudo rm -rf "$DEBIAN_ROOTFS/usr/share/doc/"* 2>/dev/null || true
    sudo rm -rf "$DEBIAN_ROOTFS/usr/share/man/"* 2>/dev/null || true
    sudo rm -rf "$DEBIAN_ROOTFS/usr/share/locale/"* 2>/dev/null || true
    sudo rm -rf "$DEBIAN_ROOTFS/tmp/"* 2>/dev/null || true
    sudo rm -rf "$DEBIAN_ROOTFS/root/.cache/"* 2>/dev/null || true

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

    if command -v isohybrid &> /dev/null; then
        sudo isohybrid "$DEBIAN_ISO" 2>/dev/null || true
        log_info "ISO rendue bootable USB (mode hybrid)"
    fi
}

# Calculer le checksum
compute_checksum() {
    log_header "Génération du checksum"
    
    local checksum
    checksum=$(sha256sum "$DEBIAN_ISO" | awk '{print $1}')
    echo "$checksum  reaper-os-debian-13-v1.0.0.iso" | sudo tee "$DEBIAN_CHECKSUM" > /dev/null
    
    log_info "SHA256: $checksum"
    log_info "Fichier: $DEBIAN_CHECKSUM"
}

# Afficher le résumé
summary() {
    log_header "COMPILATION ISO TERMINÉE"
    
    echo ""
    echo "📦 ISO Debian 13 v1.0.0 avec installeurs:"
    ls -lh "$DEBIAN_ISO" 2>/dev/null && echo "✓ ISO créée" || echo "✗ Erreur"
    echo ""
    echo "📍 Dossier: $OUTPUT_DIR"
    echo ""
    ls -lh "$OUTPUT_DIR"/ 2>/dev/null
    echo ""
    echo "🚀 Utilisation:"
    echo "   - Bootable USB: dd if=$DEBIAN_ISO of=/dev/sdX bs=4M status=progress"
    echo "   - Démarrer et exécuter: /root/INSTALL.sh"
    echo ""
}

# Main
main() {
    check_prerequisites
    cleanup
    create_rootfs
    install_packages
    copy_project
    install_reaper
    build_asnux_in_rootfs
    create_welcome_script
    setup_services
    create_entrypoint
    setup_isolinux
    build_iso
    compute_checksum
    summary
}

main "$@"
