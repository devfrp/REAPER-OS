#!/bin/bash
#
# REAPER OS Multi-Language Support
# Gettext-based translation system
#
# This script initializes the multi-language infrastructure
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LOCALE_DIR="$PROJECT_ROOT/locale"
DOMAIN="reaper-os"

# Supported languages
LANGUAGES=("fr" "es" "de" "pt" "ja")

echo "Setting up REAPER OS Multi-Language Support..."

# Create locale directory structure
mkdir -p "$LOCALE_DIR"

for lang in "${LANGUAGES[@]}"; do
    mkdir -p "$LOCALE_DIR/$lang/LC_MESSAGES"
    echo "Created: $LOCALE_DIR/$lang/LC_MESSAGES"
done

# Create template .pot file
cat > "$LOCALE_DIR/$DOMAIN.pot" << 'EOF'
# REAPER OS Translation Template
# Copyright (C) 2026 REAPER OS Team
# This file is distributed under the same license as the REAPER OS package.
#
#, fuzzy
msgid ""
msgstr ""
"Content-Type: text/plain; charset=UTF-8\n"
"Language: \n"
"Plural-Forms: nplurals=2; plural=(n != 1);\n"

#: installer/gui-installer.py:50
msgid "REAPER OS Installation"
msgstr ""

#: installer/gui-installer.py:52
msgid "Professional Audio Distribution"
msgstr ""

#: installer/gui-installer.py:100
msgid "Welcome to REAPER OS"
msgstr ""

#: tools/package-manager.sh:45
msgid "Installing package"
msgstr ""

#: tools/package-manager.sh:50
msgid "Package already installed"
msgstr ""

#: tools/audio-profile-manager-gui.py:80
msgid "Audio Profiles"
msgstr ""

#: tools/logging-system.sh:30
msgid "System Event"
msgstr ""

#: tools/benchmarking-tool.sh:40
msgid "Starting full benchmark suite"
msgstr ""

msgid "Select Language"
msgstr ""

msgid "Select Region & Timezone"
msgstr ""

msgid "Select Installation Disk"
msgstr ""

msgid "Installation Summary"
msgstr ""

msgid "Installing REAPER OS"
msgstr ""

msgid "Installation Complete"
msgstr ""

msgid "System Monitoring"
msgstr ""

msgid "Audio Configuration"
msgstr ""

msgid "Download & Install"
msgstr ""

msgid "Next"
msgstr ""

msgid "Back"
msgstr ""

msgid "Cancel"
msgstr ""

msgid "OK"
msgstr ""

msgid "Error"
msgstr ""

msgid "Warning"
msgstr ""

msgid "Success"
msgstr ""
EOF

echo "✓ Created translation template: $LOCALE_DIR/$DOMAIN.pot"

# Create French translation stub
cat > "$LOCALE_DIR/fr/LC_MESSAGES/$DOMAIN.po" << 'EOF'
# REAPER OS French Translation
# Copyright (C) 2026 REAPER OS Team
# This file is distributed under the same license as the REAPER OS package.
#
msgid ""
msgstr ""
"Project-Id-Version: REAPER OS 0.1.0\n"
"Content-Type: text/plain; charset=UTF-8\n"
"Language: fr\n"
"Plural-Forms: nplurals=2; plural=(n > 1);\n"

msgid "REAPER OS Installation"
msgstr "Installation REAPER OS"

msgid "Professional Audio Distribution"
msgstr "Distribution Audio Professionnel"

msgid "Welcome to REAPER OS"
msgstr "Bienvenue dans REAPER OS"

msgid "Select Language"
msgstr "Sélectionner la langue"

msgid "Select Region & Timezone"
msgstr "Sélectionner la région et fuseau horaire"

msgid "Installing package"
msgstr "Installation du paquet"

msgid "Audio Profiles"
msgstr "Profils Audio"

msgid "Installation Complete"
msgstr "Installation terminée"
EOF

echo "✓ Created French translation: $LOCALE_DIR/fr/LC_MESSAGES/$DOMAIN.po"

# Create Spanish translation stub
cat > "$LOCALE_DIR/es/LC_MESSAGES/$DOMAIN.po" << 'EOF'
# REAPER OS Spanish Translation
# Copyright (C) 2026 REAPER OS Team
#
msgid ""
msgstr ""
"Project-Id-Version: REAPER OS 0.1.0\n"
"Content-Type: text/plain; charset=UTF-8\n"
"Language: es\n"
"Plural-Forms: nplurals=2; plural=(n != 1);\n"

msgid "REAPER OS Installation"
msgstr "Instalación REAPER OS"

msgid "Professional Audio Distribution"
msgstr "Distribución de Audio Profesional"

msgid "Welcome to REAPER OS"
msgstr "Bienvenido a REAPER OS"

msgid "Select Language"
msgstr "Seleccionar idioma"

msgid "Select Region & Timezone"
msgstr "Seleccionar región y zona horaria"
EOF

echo "✓ Created Spanish translation: $LOCALE_DIR/es/LC_MESSAGES/$DOMAIN.po"

# Create German translation stub
cat > "$LOCALE_DIR/de/LC_MESSAGES/$DOMAIN.po" << 'EOF'
# REAPER OS German Translation
# Copyright (C) 2026 REAPER OS Team
#
msgid ""
msgstr ""
"Project-Id-Version: REAPER OS 0.1.0\n"
"Content-Type: text/plain; charset=UTF-8\n"
"Language: de\n"
"Plural-Forms: nplurals=2; plural=(n != 1);\n"

msgid "REAPER OS Installation"
msgstr "REAPER OS Installation"

msgid "Professional Audio Distribution"
msgstr "Professionelle Audio-Distribution"

msgid "Welcome to REAPER OS"
msgstr "Willkommen bei REAPER OS"

msgid "Select Language"
msgstr "Sprache wählen"

msgid "Select Region & Timezone"
msgstr "Region und Zeitzone wählen"
EOF

echo "✓ Created German translation: $LOCALE_DIR/de/LC_MESSAGES/$DOMAIN.po"

# Create helper functions for translations in bash
cat > "$PROJECT_ROOT/scripts/i18n-helper.sh" << 'EOF'
#!/bin/bash
# Translation helper functions for bash scripts

# Get current system language
get_system_language() {
    local lang="${LANG%%_*}"
    case "$lang" in
        fr) echo "fr" ;;
        es) echo "es" ;;
        de) echo "de" ;;
        pt) echo "pt" ;;
        ja) echo "ja" ;;
        *) echo "en" ;;  # Default to English
    esac
}

# Translate message
translate() {
    local message="$1"
    local lang="${2:-$(get_system_language)}"
    
    # For now, return English. In production, use gettext
    # gettext -d reaper-os -l "$lang" "$message"
    echo "$message"
}

# Alias for translation
_() {
    translate "$@"
}
EOF

chmod +x "$PROJECT_ROOT/scripts/i18n-helper.sh"

# Create translation contribution guide
cat > "$LOCALE_DIR/TRANSLATORS.md" << 'EOF'
# REAPER OS Translation Guide

Thank you for helping translate REAPER OS!

## Supported Languages

- 🇫🇷 Français (French)
- 🇪🇸 Español (Spanish)  
- 🇩🇪 Deutsch (German)
- 🇵🇹 Português (Portuguese)
- 🇯🇵 日本語 (Japanese)

## How to Contribute

1. **Choose a language** from the list above
2. **Open the .po file** for your language in `locale/LANG/LC_MESSAGES/`
3. **Translate the strings** - focus on user-facing messages
4. **Test your translations** in the GUI
5. **Submit a pull request** with your translations

## Translation Tips

- Keep translations concise
- Maintain formatting (%, \n, etc.)
- Use professional audio terminology
- Test in context when possible

## Files to Translate

- GUI Installer strings
- Package Manager messages
- Audio Profile Manager labels
- Tool help text
- Documentation

## Getting Help

For translation questions:
- Check existing translations for consistency
- Use professional audio terminology
- Ask in GitHub Issues

## Compilation

Compile .po files to .mo:

```bash
msgfmt locale/fr/LC_MESSAGES/reaper-os.po -o locale/fr/LC_MESSAGES/reaper-os.mo
```

All contributions appreciated! 🎵
EOF

echo "✓ Created translation guide: $LOCALE_DIR/TRANSLATORS.md"

# Create .gitignore for compiled translations
cat > "$LOCALE_DIR/.gitignore" << 'EOF'
# Compiled translation files
*.mo

# Temporary files
*.pot~
*.po~
EOF

echo "✓ Created .gitignore for locale directory"

# Summary
cat << 'EOF'

✓ Multi-Language Setup Complete!

Structure created:
  locale/
    ├── reaper-os.pot           (Translation template)
    ├── fr/LC_MESSAGES/         (French)
    ├── es/LC_MESSAGES/         (Spanish)
    ├── de/LC_MESSAGES/         (German)
    ├── pt/LC_MESSAGES/         (Portuguese)
    ├── ja/LC_MESSAGES/         (Japanese)
    └── TRANSLATORS.md          (Contribution guide)

Next steps:
  1. Edit locale/*/LC_MESSAGES/*.po files with translations
  2. Compile: msgfmt locale/fr/LC_MESSAGES/reaper-os.po -o locale/fr/LC_MESSAGES/reaper-os.mo
  3. Load in Python: import gettext; gettext.translation('reaper-os', localedir='locale')
  4. Load in Bash: source scripts/i18n-helper.sh

Tools:
  - Poedit (GUI editor): https://poedit.net/
  - msgfmt/msgmerge (command line)
  - Weblate (online translation platform)

EOF
