#!/bin/bash

################################################################################
# JACK Audio Setup - Configuration JACK pour REAPER OS
################################################################################

set -e

log_info() { echo "[JACK] $1"; }

log_info "Configuration de JACK2..."

ALSA_DEVICE="hw:0"

if aplay -l 2>/dev/null | grep -q -i asnux; then
    ALSA_DEVICE="hw:ASNUX"
    log_info "ASNUX detecte - JACK utilisera hw:ASNUX"
fi

# Configuration JACK pour latence minimale
cat > "$HOME/.jackrc" << EOF
#!/bin/bash
/usr/bin/jackd -R -d alsa -d $ALSA_DEVICE -r 48000 -p 256 -n 2 -s -c 2
EOF

chmod +x "$HOME/.jackrc"

# Configuration a2jmidid (ALSA to JACK MIDI bridge)
mkdir -p "$HOME/.config/a2jmidid"

cat > "$HOME/.config/a2jmidid/config" << 'EOF'
[main]
autoconnect=on
multicast=off
name=a2jmidid
ports=hardware,software
EOF

log_info "JACK configuré avec:"
log_info "  • Taux d'échantillonnage: 48000 Hz"
log_info "  • Taille de buffer: 256 samples"
log_info "  • Latence estimée: < 6ms"
log_info "  • Interface: ALSA ($ALSA_DEVICE)"

# Démarrer JACK au boot
if command -v systemctl &> /dev/null; then
    log_info "Configuration de JACK pour démarrage automatique..."
    # JACK peut être lancé via user service
    mkdir -p "$HOME/.config/systemd/user"
    
    cat > "$HOME/.config/systemd/user/jack.service" << EOF
[Unit]
Description=JACK Audio Server
After=pulseaudio.service asnux-daemon.service

[Service]
Type=simple
ExecStart=/usr/bin/jackd -R -d alsa -d $ALSA_DEVICE -r 48000 -p 256 -n 2 -s -c 2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
EOF
    
    systemctl --user daemon-reload
    log_info "Service JACK créé"
fi

log_info "Configuration JACK terminée!"
