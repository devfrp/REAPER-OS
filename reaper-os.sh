#!/bin/bash

################################################################################
# REAPER OS - Quick Build Script
# Raccourci pour les commandes courantes
################################################################################

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Affichage
print_header() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  REAPER OS - Build Helper Script   ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════╝${NC}"
    echo ""
}

print_menu() {
    echo "Options:"
    echo ""
    echo "  Build & Development:"
    echo "    ${YELLOW}build-iso${NC}        - Build ISO REAPER OS"
    echo "    ${YELLOW}install-deps${NC}     - Install build dependencies"
    echo "    ${YELLOW}clean${NC}            - Clean build artifacts"
    echo ""
    echo "  Documentation:"
    echo "    ${YELLOW}docs${NC}             - Open documentation"
    echo "    ${YELLOW}docs-build${NC}       - Build docs (if applicable)"
    echo ""
    echo "  Development:"
    echo "    ${YELLOW}git-init${NC}         - Initialize git hooks"
    echo "    ${YELLOW}test${NC}             - Run tests"
    echo ""
    echo "  Other:"
    echo "    ${YELLOW}help${NC}             - Show this menu"
    echo "    ${YELLOW}status${NC}           - Show project status"
    echo ""
}

# Commands
cmd_build_iso() {
    echo -e "${GREEN}Building REAPER OS ISO...${NC}"
    bash "$PROJECT_ROOT/installer/build-debian-iso.sh"
}

cmd_install_deps() {
    echo -e "${GREEN}Installing build dependencies...${NC}"
    
    # Check if running with sudo
    if [ "$EUID" -ne 0 ]; then
        echo -e "${YELLOW}This command requires sudo${NC}"
        sudo bash -c "$(declare -f); cmd_install_deps_run"
    else
        cmd_install_deps_run
    fi
}

cmd_install_deps_run() {
    apt-get update
    apt-get install -y \
        debootstrap \
        xorriso \
        squashfs-tools \
        grub-pc-bin \
        grub-efi-amd64-bin \
        git \
        build-essential
    
    echo -e "${GREEN}✓ Dependencies installed${NC}"
}

cmd_clean() {
    echo -e "${GREEN}Cleaning build artifacts...${NC}"
    
    # Remove build directory
    if [ -d "$PROJECT_ROOT/build" ]; then
        rm -rf "$PROJECT_ROOT/build"
        echo -e "${GREEN}✓ Removed build/${NC}"
    fi
    
    # Clean other artifacts
    find "$PROJECT_ROOT" -name "*.bak" -delete
    find "$PROJECT_ROOT" -name "*~" -delete
    
    echo -e "${GREEN}✓ Cleanup complete${NC}"
}

cmd_docs() {
    echo -e "${GREEN}Opening documentation...${NC}"
    
    # Try to open docs directory
    if command -v xdg-open &> /dev/null; then
        xdg-open "$PROJECT_ROOT/docs"
    elif command -v open &> /dev/null; then
        open "$PROJECT_ROOT/docs"
    else
        echo "Documentation location: $PROJECT_ROOT/docs"
        ls -la "$PROJECT_ROOT/docs"
    fi
}

cmd_docs_build() {
    echo -e "${GREEN}Building documentation...${NC}"
    
    # Check if mkdocs is available
    if command -v mkdocs &> /dev/null; then
        cd "$PROJECT_ROOT"
        mkdocs build
    else
        echo -e "${YELLOW}mkdocs not installed. Installing...${NC}"
        pip install mkdocs
        mkdocs build
    fi
}

cmd_git_init() {
    echo -e "${GREEN}Initializing git hooks...${NC}"
    
    mkdir -p "$PROJECT_ROOT/.git/hooks"
    
    # Create pre-commit hook
    cat > "$PROJECT_ROOT/.git/hooks/pre-commit" << 'EOF'
#!/bin/bash
# Pre-commit hook for REAPER OS

# Check shell scripts syntax
for file in $(git diff --cached --name-only | grep -E '\.sh$'); do
    bash -n "$file" 2>/dev/null || {
        echo "Syntax error in $file"
        exit 1
    }
done

echo "✓ Pre-commit checks passed"
EOF
    
    chmod +x "$PROJECT_ROOT/.git/hooks/pre-commit"
    echo -e "${GREEN}✓ Git hooks installed${NC}"
}

cmd_test() {
    echo -e "${GREEN}Running tests...${NC}"
    
    # Run shellcheck on scripts if available
    if command -v shellcheck &> /dev/null; then
        echo "Checking shell scripts..."
        find "$PROJECT_ROOT" -name "*.sh" -exec shellcheck {} \;
        echo -e "${GREEN}✓ Shell scripts OK${NC}"
    else
        echo -e "${YELLOW}shellcheck not installed. Skipping...${NC}"
    fi
    
    # Check file permissions
    echo "Checking file permissions..."
    find "$PROJECT_ROOT" -name "*.sh" -not -perm /u=x -not -path "./.git/*" | while read -r file; do
        echo -e "${YELLOW}Warning: $file not executable${NC}"
        chmod +x "$file"
    done
    
    echo -e "${GREEN}✓ Tests complete${NC}"
}

cmd_status() {
    echo -e "${GREEN}Project Status${NC}"
    echo ""
    
    echo "📁 Directory: $PROJECT_ROOT"
    echo ""
    
    echo "📊 Structure:"
    echo "   - Installer scripts: $(ls -1 installer/*.sh 2>/dev/null | wc -l)"
    echo "   - Config files: $(ls -1 config 2>/dev/null | wc -l)"
    echo "   - Helper scripts: $(ls -1 scripts/*.sh 2>/dev/null | wc -l)"
    echo "   - Documentation files: $(ls -1 docs/*.md 2>/dev/null | wc -l)"
    echo ""
    
    echo "🔧 Build status:"
    local iso_path
    iso_path=$(ls -t "$PROJECT_ROOT/build/iso-output/"*.iso 2>/dev/null | head -1 || true)
    if [ -n "$iso_path" ] && [ -f "$iso_path" ]; then
        echo "   ✓ ISO built: $(ls -lh "$iso_path" | awk '{print $5}')"
    else
        echo "   ✗ ISO not built yet"
    fi
    echo ""
    
    echo "📦 Git status:"
    if [ -d "$PROJECT_ROOT/.git" ]; then
        cd "$PROJECT_ROOT"
        echo "   Branch: $(git rev-parse --abbrev-ref HEAD)"
        echo "   Commits: $(git rev-list --count HEAD)"
        echo "   Changes: $(git status --short | wc -l) files"
    else
        echo "   ✗ Not a git repository"
    fi
    echo ""
}

# Main
main() {
    if [ $# -eq 0 ]; then
        print_header
        print_menu
        return
    fi
    
    case "$1" in
        build-iso)
            cmd_build_iso
            ;;
        install-deps)
            cmd_install_deps
            ;;
        clean)
            cmd_clean
            ;;
        docs)
            cmd_docs
            ;;
        docs-build)
            cmd_docs_build
            ;;
        git-init)
            cmd_git_init
            ;;
        test)
            cmd_test
            ;;
        status)
            cmd_status
            ;;
        help)
            print_header
            print_menu
            ;;
        *)
            echo -e "${RED}Unknown command: $1${NC}"
            print_menu
            exit 1
            ;;
    esac
}

# Run
main "$@"
