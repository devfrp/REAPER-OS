# REAPER OS - Getting Started

## Bienvenue dans REAPER OS! 🎵

Un système d'exploitation Linux professionnel pour musiciens et producteurs audio basé sur Debian 13 avec REAPER comme interface principale.

## 🚀 Démarrage Rapide

### Pour les Utilisateurs

**Vous voulez utiliser REAPER OS:**

1. **Télécharger l'ISO**
   - Accueil des builds (à venir)
   - Ou compiler localement (voir ci-dessous)

2. **Créer une clé USB bootable**
   ```bash
   dd if=reaper-os.iso of=/dev/sdX bs=4M
   # ou utiliser Rufus/Etcher
   ```

3. **Installer**
   - Booter sur la clé USB
   - Suivre l'installateur interactif
   - Sélectionner langue, localisation, disque

4. **Créer de la musique!**
   ```bash
   reaper-start
   # REAPER démarre avec support VST Windows
   ```

📖 Guide complet: [INSTALLATION.md](docs/INSTALLATION.md)

### Pour les Développeurs

**Vous voulez contribuer ou compiler:**

```bash
# 1. Cloner le repository
git clone https://github.com/devfrp/REAPER-OS.git
cd REAPER-OS

# 2. Installer les dépendances
sudo apt-get install debootstrap xorriso squashfs-tools

# 3. Compiler l'ISO (30-60 minutes)
bash ./installer/build-debian-iso.sh

# 4. Tester dans une VM
# Créer une nouvelle VM
# Utiliser: build/reaper-os.iso comme image boot
```

Pour plus de détails: [CONTRIBUTING.md](docs/CONTRIBUTING.md)

## 📋 Fichiers Importants

| Fichier | Description |
|---------|-------------|
| [README.md](README.md) | Vue d'ensemble du projet |
| [docs/INSTALLATION.md](docs/INSTALLATION.md) | Guide d'installation complet |
| [docs/VST-SETUP.md](docs/VST-SETUP.md) | Setup VST Windows |
| [docs/WINE-SETUP.md](docs/WINE-SETUP.md) | Configuration Wine/Proton |
| [docs/REAPER-CONFIG.md](docs/REAPER-CONFIG.md) | Configuration REAPER |
| [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) | Dépannage |
| [docs/FAQ.md](docs/FAQ.md) | Questions fréquentes |

## 🛠️ Utilisation du Script Helper

Un script helper simplifie les commandes courantes:

```bash
# Afficher le menu
bash reaper-os.sh

# Options disponibles:
bash reaper-os.sh build-iso          # Build l'ISO
bash reaper-os.sh install-deps       # Install dépendances
bash reaper-os.sh clean              # Nettoyer les artifacts
bash reaper-os.sh status             # Afficher le status
bash reaper-os.sh docs               # Ouvrir la doc
bash reaper-os.sh test               # Lancer les tests
bash reaper-os.sh git-init           # Init git hooks
```

## 📁 Structure du Projet

```
REAPER-OS/
├── installer/              # Scripts de build ISO
├── config/                 # Configuration système
├── scripts/                # Scripts utilitaires
├── wine-config/           # Configuration Wine/VST
├── reaper-config/         # Configuration REAPER
├── docs/                  # Documentation complète
└── build/                 # Artifacts de build
```

Voir [docs/PROJECT-STRUCTURE.md](docs/PROJECT-STRUCTURE.md) pour la structure complète.

## 🎯 Caractéristiques Principales

✅ **Base Solide**: Debian 13 stable  
✅ **Interface Pro**: REAPER DAW intégré  
✅ **VST Windows 100%**: Wine/Proton optimisé  
✅ **Audio Pro**: JACK avec latence < 5ms  
✅ **Installation Simple**: Installateur multilingue  
✅ **Optimisé**: Performance audio maximale  

## 📚 Documentation

### Pour les Utilisateurs
- [Installation Guide](docs/INSTALLATION.md) - Comment installer REAPER OS
- [VST Setup](docs/VST-SETUP.md) - Installer des VST Windows
- [REAPER Config](docs/REAPER-CONFIG.md) - Configuration REAPER
- [Troubleshooting](docs/TROUBLESHOOTING.md) - Dépannage
- [FAQ](docs/FAQ.md) - Questions fréquentes

### Pour les Développeurs
- [Contributing Guide](docs/CONTRIBUTING.md) - Comment contribuer
- [Project Structure](docs/PROJECT-STRUCTURE.md) - Structure du projet
- [Wine Setup](docs/WINE-SETUP.md) - Configuration Wine détaillée

## 🐛 Signaler un Bug

Si vous trouvez un bug:

1. Vérifier les [issues existantes](https://github.com/devfrp/REAPER-OS/issues)
2. Ouvrir une [nouvelle issue](https://github.com/devfrp/REAPER-OS/issues/new)
3. Inclure:
   - Description du problème
   - Étapes pour reproduire
   - Output de: `uname -a`
   - Logs pertinents

## 💡 Suggérer une Fonctionnalité

Suggestions bienvenues!

1. Ouvrir une [issue GitHub](https://github.com/devfrp/REAPER-OS/issues)
2. Décrire la fonctionnalité souhaitée
3. Expliquer le cas d'usage

## 🤝 Contribuer

REAPER OS accueille les contributions!

- 🐛 **Bugs**: Signaler via GitHub Issues
- 📝 **Docs**: Améliorations documentations (Pull Request)
- 💻 **Code**: Nouvelles features (Pull Request)
- 🌍 **Traductions**: Aider à traduire l'installateur

Voir [CONTRIBUTING.md](docs/CONTRIBUTING.md) pour détails.

## 📦 Prérequis Système

**Matériel Minimum:**
- Processeur x86_64 (Intel/AMD)
- 4GB RAM
- 50GB disque
- Carte audio compatible Linux

**Recommandé:**
- i5/i7 ou équivalent
- 8GB+ RAM
- SSD 500GB+
- Carte audio USB de qualité

## 🎵 Prochaines Étapes

1. **Utilisateurs**: Télécharger et installer REAPER OS
2. **Développeurs**: Compiler l'ISO et tester
3. **Contributeurs**: Consulter [CONTRIBUTING.md](docs/CONTRIBUTING.md)

## 📞 Support

- **Documentation**: Consultez [docs/](docs/)
- **Issues**: Ouvrir sur [GitHub Issues](https://github.com/devfrp/REAPER-OS/issues)
- **Forum REAPER**: https://forum.cockos.com/
- **Community**: [GitHub Discussions](https://github.com/devfrp/REAPER-OS/discussions)

## 📄 License

- **Code**: GPL-3.0+
- **Docs**: CC-BY-4.0
- **REAPER**: Propriétaire (Cockos)

Voir [LICENSE](LICENSE) pour détails.

## 🎉 Merci!

Merci de votre intérêt pour REAPER OS. Ensemble, créons le meilleur système d'exploitation pour musiciens professionnels sur Linux!

---

**Prêt à créer?** Commencez avec [Installation](docs/INSTALLATION.md) ou [Contributing](docs/CONTRIBUTING.md).

**Questions?** Consultez [FAQ](docs/FAQ.md) ou ouvrez une [issue](https://github.com/devfrp/REAPER-OS/issues).

🎶 **REAPER OS: Professional Audio Creation on Linux** 🎶
