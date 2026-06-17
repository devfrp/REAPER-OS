#!/bin/bash

################################################################################
# ASNUX - Low-Latency Audio Engine Setup for REAPER OS
# Installe et configure ASNUX comme moteur audio par defaut
# Equivalent ASIO4ALL pour Linux
################################################################################

set -e

ASNUX_REPO="https://github.com/devfrp/asnux.git"
ASNUX_DIR="/opt/asnux"
ASNUX_CONFIG="$HOME/.config/asnux/config.json"
SYSFS_BASE="/sys/module/asnux/parameters"

log_info() { echo "[ASNUX] $1"; }
log_err() { echo "[ASNUX] ERROR: $1" >&2; }
log_warn() { echo "[ASNUX] WARNING: $1"; }

is_module_loaded() {
    [ -d "$SYSFS_BASE" ]
}

is_daemon_running() {
    [ -S "/tmp/asnux-daemon.sock" ]
}

install_deps() {
    log_info "Installation des dependances..."
    if command -v apt-get &>/dev/null; then
        apt-get update -qq
        apt-get install -y -qq build-essential curl git cargo rustc linux-headers-$(uname -r) 2>/dev/null || {
            log_info "Tentative avec kernel-headers generique..."
             apt-get install -y -qq linux-headers-amd64 2>/dev/null || true
        }
    elif command -v pacman &>/dev/null; then
        pacman -Sy --noconfirm base-devel curl git rust cargo linux-headers 2>/dev/null || true
    elif command -v dnf &>/dev/null; then
        dnf install -y gcc make curl git rust cargo kernel-devel 2>/dev/null || true
    fi
    log_info "Dependances installees"
}

build_asnux() {
    local workdir="$1"

    log_info "Compilation d'ASNUX depuis les sources..."

    cd "$workdir"

    log_info "Build kernel module..."
    make kernel 2>&1 | grep -E "(error|warning|CC|LD)" || true

    log_info "Build daemon..."
    make daemon 2>&1 | tail -5

    log_info "Build GUI..."
    make gui 2>&1 | tail -5

    log_info "Compilation terminee"
}

install_asnux() {
    local workdir="$1"

    log_info "Installation d'ASNUX..."

    cd "$workdir"

    if [ -f "Makefile" ] && grep -q "^install:" Makefile; then
        make install 2>&1 || log_warn "make install partiellement termine"
    else
        log_info "Installation manuelle..."

        mkdir -p /lib/modules/$(uname -r)/kernel/sound/drivers/
        cp -f kernel/asnux.ko /lib/modules/$(uname -r)/kernel/sound/drivers/ 2>/dev/null || true
        depmod -a

        mkdir -p /usr/local/bin/
        cp -f daemon/target/release/asnux-daemon /usr/local/bin/ 2>/dev/null || true
        cp -f gui/target/release/asnux-gui /usr/local/bin/ 2>/dev/null || true
    fi

    mkdir -p "$ASNUX_DIR"
    log_info "ASNUX installe dans $ASNUX_DIR"
}

configure_asnux() {
    log_info "Configuration d'ASNUX..."

    mkdir -p "$(dirname "$ASNUX_CONFIG")"

    cat > "$ASNUX_CONFIG" << 'EOF'
{
    "buffer_size": 256,
    "sample_rate": 48000,
    "channels": 2,
    "periods": 4,
    "default_engine": true,
    "realtime_priority": 80
}
EOF

    log_info "Configuration par defaut: buffer=256, rate=48000, channels=2, periods=4"
}

setup_systemd_service() {
    log_info "Creation du service systemd..."

    cat > /etc/systemd/system/asnux-daemon.service << 'EOF'
[Unit]
Description=ASNUX Low-Latency Audio Engine Daemon
After=network.target sound.target
Before=jack.service

[Service]
Type=simple
ExecStart=/usr/local/bin/asnux-daemon
Restart=on-failure
RestartSec=3
Environment=RUST_LOG=info
Nice=-15
LimitRTPRIO=99
LimitMEMLOCK=infinity

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable asnux-daemon
    log_info "Service systemd cree et active"
}

load_module() {
    if is_module_loaded; then
        log_info "Module ASNUX deja charge"
        return 0
    fi

    log_info "Chargement du module ASNUX..."
    if modprobe asnux buffer_size=256 sample_rate=48000 channels=2 periods=4 2>/dev/null; then
        log_info "Module ASNUX charge avec succes"
    else
        log_warn "modprobe echoue, tentative insmod..."
        local ko=$(find /lib/modules/$(uname -r) -name "asnux.ko" 2>/dev/null | head -1)
        if [ -n "$ko" ]; then
            insmod "$ko" buffer_size=256 sample_rate=48000 channels=2 periods=4
            log_info "Module ASNUX charge via insmod"
        else
            log_err "Module ASNUX introuvable"
            return 1
        fi
    fi

    sleep 1
    if is_module_loaded; then
        log_info "Verification: module ASNUX actif"
        if command -v aplay &>/dev/null; then
            aplay -l 2>/dev/null | grep -i asnux && log_info "Peripherique ALSA ASNUX detecte" || true
        fi
    fi
}

set_default_engine() {
    log_info "Configuration d'ASNUX comme moteur audio par defaut..."

    if [ -f "/etc/pulse/default.pa" ]; then
        if ! grep -q "asnux" /etc/pulse/default.pa 2>/dev/null; then
            cat >> /etc/pulse/default.pa << 'EOF'
load-module module-alsa-sink device_id=asnux
EOF
        fi
        pkill -HUP pulseaudio 2>/dev/null || true
        log_info "PulseAudio configure pour utiliser ASNUX"
    fi
}

configure_jack_for_asnux() {
    log_info "Configuration de JACK pour utiliser ASNUX..."

    local asnux_card=$(aplay -l 2>/dev/null | grep -i "asnux" -B 2 | grep "^card" | head -1 | awk '{print $2}' | tr -d ':')

    if [ -n "$asnux_card" ]; then
        cat > "$HOME/.jackrc" << EOF
#!/bin/bash
/usr/bin/jackd -R -d alsa -d hw:ASNUX -r 48000 -p 256 -n 2 -s -c 2
EOF
        chmod +x "$HOME/.jackrc"

        mkdir -p "$HOME/.config/systemd/user"
        cat > "$HOME/.config/systemd/user/jack.service" << 'EOF'
[Unit]
Description=JACK Audio Server (via ASNUX)
After=asnux-daemon.service pulseaudio.service

[Service]
Type=simple
ExecStart=/usr/bin/jackd -R -d alsa -d hw:ASNUX -r 48000 -p 256 -n 2 -s -c 2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
EOF
        systemctl --user daemon-reload 2>/dev/null || true
        log_info "JACK configure pour utiliser hw:ASNUX ($asnux_card)"
    else
        log_warn "Peripherique ASNUX non trouve dans ALSA - JACK utilisera hw:0"
    fi
}

start_daemon() {
    if is_daemon_running; then
        log_info "Daemon ASNUX deja actif"
        return 0
    fi

    log_info "Demarrage du daemon ASNUX..."
    systemctl start asnux-daemon 2>/dev/null || {
        log_info "Demarrage manuel..."
        /usr/local/bin/asnux-daemon &
        sleep 1
    }

    if is_daemon_running; then
        log_info "Daemon ASNUX demarre"
    else
        log_warn "Daemon ASNUX non demarre"
    fi
}

main() {
    log_info "╔════════════════════════════════════════════════════════╗"
    log_info "║  ASNUX - Low-Latency Audio Engine Setup                ║"
    log_info "╚════════════════════════════════════════════════════════╝"
    echo ""

    if ! is_module_loaded && [ ! -f "/usr/local/bin/asnux-daemon" ]; then
        log_info "ASNUX non installe - installation depuis les sources..."

        local tempdir=$(mktemp -d)
        trap "rm -rf $tempdir" EXIT

        log_info "Clonage du depot ASNUX..."
        git clone --depth 1 "$ASNUX_REPO" "$tempdir"

        install_deps
        build_asnux "$tempdir"
        install_asnux "$tempdir"
    elif [ -f "/opt/asnux/.prebuilt" ]; then
        log_info "ASNUX pre-build detecte dans l'ISO - pas de compilation necessaire"
        log_info "Binaires deja presents: $(ls /usr/local/bin/asnux-* 2>/dev/null | tr '\n' ' ')"
    else
        log_info "ASNUX deja installe"
    fi

    configure_asnux
    setup_systemd_service
    load_module
    set_default_engine
    configure_jack_for_asnux
    start_daemon

    echo ""
    log_info "╔════════════════════════════════════════════════════════╗"
    log_info "║  ASNUX configure comme moteur audio par defaut         ║"
    log_info "╚════════════════════════════════════════════════════════╝"
    echo ""
    log_info "Configuration:"
    log_info "  Buffer:      256 samples"
    log_info "  Sample Rate: 48000 Hz"
    log_info "  Channels:    2 (stereo)"
    log_info "  Periods:     4"
    echo ""
    log_info "Commandes utiles:"
    log_info "  asnux-gui                Interface graphique"
    log_info "  systemctl status asnux-daemon   Statut du daemon"
    log_info "  aplay -l | grep asnux    Verifier peripherique"
    log_info "  cat /sys/module/asnux/parameters/buffer_size"
    echo ""
}

main "$@"
