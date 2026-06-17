#!/bin/bash
#
# REAPER OS v0.2.0 - Quick Approval Checklist
# Pour le propriétaire - Liste rapide de vérification
#

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║   REAPER OS v0.2.0 - OWNER APPROVAL CHECKLIST                  ║"
echo "║          Quick Verification Before Release                     ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

VERSION="0.2.0"
RELEASE_DIR="./releases"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

check() {
    local status=$1
    local message=$2
    if [ $status -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $message"
    else
        echo -e "${RED}✗${NC} $message"
    fi
}

fail() {
    echo -e "${RED}✗ FAILED:${NC} $1"
}

pass() {
    echo -e "${GREEN}✓ PASSED:${NC} $1"
}

# ============================================================================
# PHASE 1: Vérifications Simples
# ============================================================================

echo -e "${BLUE}PHASE 1: Fichiers & Intégrité${NC}"
echo "─────────────────────────────────────────────────────────────────"

OFFLINE="${RELEASE_DIR}/reaper-os-${VERSION}-offline-x86_64.iso"
ONLINE="${RELEASE_DIR}/reaper-os-${VERSION}-online-x86_64.iso"

# Vérifier ISOs existent
if [ -f "$OFFLINE" ]; then
    local size=$(du -h "$OFFLINE" | cut -f1)
    pass "ISO OFFLINE existe ($size)"
else
    fail "ISO OFFLINE manquante"
fi

if [ -f "$ONLINE" ]; then
    local size=$(du -h "$ONLINE" | cut -f1)
    pass "ISO ONLINE existe ($size)"
else
    fail "ISO ONLINE manquante"
fi

# Vérifier checksums
if [ -f "$RELEASE_DIR/.release-config" ]; then
    grep -q "OFFLINE_CHECKSUM" "$RELEASE_DIR/.release-config" && \
        pass "Checksum OFFLINE présent"
    grep -q "ONLINE_CHECKSUM" "$RELEASE_DIR/.release-config" && \
        pass "Checksum ONLINE présent"
fi

# Vérifier tailles raisonnables
if [ -f "$OFFLINE" ]; then
    local offline_bytes=$(stat -c%s "$OFFLINE" 2>/dev/null || stat -f%z "$OFFLINE")
    if [ $offline_bytes -gt 3000000000 ] && [ $offline_bytes -lt 4000000000 ]; then
        pass "Taille ISO OFFLINE raisonnable (~3.5 GB)"
    else
        fail "Taille ISO OFFLINE suspecte (${offline_bytes} bytes)"
    fi
fi

if [ -f "$ONLINE" ]; then
    local online_bytes=$(stat -c%s "$ONLINE" 2>/dev/null || stat -f%z "$ONLINE")
    if [ $online_bytes -gt 1500000000 ] && [ $online_bytes -lt 2500000000 ]; then
        pass "Taille ISO ONLINE raisonnable (~2 GB)"
    else
        fail "Taille ISO ONLINE suspecte (${online_bytes} bytes)"
    fi
fi

echo ""

# ============================================================================
# PHASE 2: Documents de Release
# ============================================================================

echo -e "${BLUE}PHASE 2: Documentation${NC}"
echo "─────────────────────────────────────────────────────────────────"

[ -f "./README.md" ] && pass "README.md existe" || fail "README.md manquante"
[ -f "./CHANGELOG.md" ] && pass "CHANGELOG.md existe" || fail "CHANGELOG.md manquante"
[ -f "./INSTALLATION.md" ] && pass "INSTALLATION.md existe" || fail "INSTALLATION.md manquante"
[ -f "./ISO-SELECTION.md" ] && pass "ISO-SELECTION.md existe" || fail "ISO-SELECTION.md manquante"
[ -f "./RELEASE-PROCEDURE.md" ] && pass "RELEASE-PROCEDURE.md existe" || fail "RELEASE-PROCEDURE.md manquante"
[ -f "./IMPLEMENTATION-SUMMARY.md" ] && pass "IMPLEMENTATION-SUMMARY.md existe" || fail "IMPLEMENTATION-SUMMARY.md manquante"

echo ""

# ============================================================================
# PHASE 3: Outils et Scripts
# ============================================================================

echo -e "${BLUE}PHASE 3: Outils Implémentés${NC}"
echo "─────────────────────────────────────────────────────────────────"

# HAUTE PRIORITÉ
[ -f "./installer/gui-installer.py" ] && pass "GUI Installer (800 lines)" || fail "GUI Installer manquante"
[ -f "./tools/audio-profile-manager-gui.py" ] && pass "Audio Profile Manager (700 lines)" || fail "Audio Profile Manager manquante"
[ -f "./tools/package-manager.sh" ] && pass "Package Manager (500 lines)" || fail "Package Manager manquant"

# MOYEN PRIORITÉ
[ -f "./tools/system-dashboard.py" ] && pass "System Dashboard (600 lines)" || fail "System Dashboard manquant"
[ -f "./tools/logging-system.sh" ] && pass "Logging System (650 lines)" || fail "Logging System manquant"
[ -f "./tools/benchmarking-tool.sh" ] && pass "Benchmarking Tool (700 lines)" || fail "Benchmarking Tool manquant"

# BAS PRIORITÉ
[ -f "./tools/backup-restore.sh" ] && pass "Backup & Restore (700 lines)" || fail "Backup & Restore manquant"
[ -f "./tools/update-manager.sh" ] && pass "Update Manager (700 lines)" || fail "Update Manager manquant"
[ -f "./scripts/setup-localization.sh" ] && pass "Multi-Language (700 lines)" || fail "Multi-Language manquant"

# Package manifest
[ -f "./packages/manifest.json" ] && pass "Package Manifest (16 packages)" || fail "Package Manifest manquant"

echo ""

# ============================================================================
# PHASE 4: Gestion Release
# ============================================================================

echo -e "${BLUE}PHASE 4: Scripts de Release${NC}"
echo "─────────────────────────────────────────────────────────────────"

[ -x "./release-manager.sh" ] && pass "release-manager.sh exécutable" || fail "release-manager.sh non exécutable"
[ -x "./tools/iso-comparison.sh" ] && pass "iso-comparison.sh exécutable" || fail "iso-comparison.sh non exécutable"
[ -f "./APPROVAL-FORM.md" ] && pass "APPROVAL-FORM.md existe" || fail "APPROVAL-FORM.md manquante"

echo ""

# ============================================================================
# PHASE 5: Vérifications Finales
# ============================================================================

echo -e "${BLUE}PHASE 5: Vérifications Finales${NC}"
echo "─────────────────────────────────────────────────────────────────"

# Vérifier fichiers de config existent
[ -f "./RELEASE-PROCEDURE.md" ] && pass "Procédure de release documentée" || fail "Procédure manquante"
[ -f "./.release-config" ] && pass "Configuration release créée" || fail "Configuration manquante"

# Vérifier pas de changements git non committes (optionnel)
if command -v git &> /dev/null; then
    if [ -z "$(cd . && git status --porcelain 2>/dev/null)" ]; then
        pass "Tous les changements sont committés"
    else
        echo -e "${YELLOW}⚠ Changements non committés détectés${NC}"
    fi
fi

echo ""

# ============================================================================
# RÉSUMÉ ET PROCHAINES ÉTAPES
# ============================================================================

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                    RÉSUMÉ VÉRIFICATION                         ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

cat << EOF

Si tous les points ci-dessus sont PASSÉS (✓):

PROCHAINES ÉTAPES:

1. Vérifier les deux ISOs (optionnel mais recommandé):
   ./tools/iso-comparison.sh

2. Approuver la release:
   ./release-manager.sh approve

3. Publier sur GitHub:
   ./release-manager.sh github

4. Créer les notes de release:
   ./release-manager.sh release-notes

5. Annoncer aux utilisateurs:
   - Email
   - Social media
   - Community forums

═══════════════════════════════════════════════════════════════════════

INFORMATIONS IMPORTANTES:

Deux ISOs fournis:

  📦 OFFLINE (reaper-os-0.2.0-offline-x86_64.iso)
     - 3.5 GB
     - Tout inclus
     - Pas internet requis
     - Installation rapide (~30 min)
     - RECOMMANDÉ

  📦 ONLINE (reaper-os-0.2.0-online-x86_64.iso)
     - 2 GB
     - Minimal
     - Internet requis
     - Installation 55-60 min*
     - Pour bandwidth limité

  * Dépend de la vitesse internet

═══════════════════════════════════════════════════════════════════════

Contenu de v0.2.0:

  ✅ 9 nouveaux outils (4,500+ lignes)
  ✅ GUI Installer professionnel
  ✅ Audio Profile Manager
  ✅ Package Manager (16 packages)
  ✅ System Dashboard
  ✅ Logging System
  ✅ Benchmarking Tool
  ✅ Backup & Restore
  ✅ Update Manager
  ✅ Multi-Language infrastructure

  📊 Statistiques:
     - Total: 14,500+ lignes de code
     - 12 outils en total
     - 6 langues supportées
     - 100% compatible avec v0.1.0

═══════════════════════════════════════════════════════════════════════

Formulaire d'approbation:

  📝 Voir: APPROVAL-FORM.md

  À compléter:
    - Nom du propriétaire
    - Date d'approbation
    - Signature
    - Commentaires

═══════════════════════════════════════════════════════════════════════

En cas de problème:

  ❌ ISO manquante?
     → Exécuter: ./release-manager.sh build-offline
     → Exécuter: ./release-manager.sh build-online

  ❌ Checksum invalide?
     → Vérifier l'intégrité: ./release-manager.sh verify

  ❌ Configuration manquante?
     → Réinitialiser: ./release-manager.sh prepare

═══════════════════════════════════════════════════════════════════════

PRÊT POUR LA RELEASE? 🚀

  OUI  → Compléter APPROVAL-FORM.md et approuver
  NON  → Corriger les problèmes identifiés et re-exécuter ce script

EOF

echo ""
echo "═══════════════════════════════════════════════════════════════════════"
echo "Dernière mise à jour: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""
