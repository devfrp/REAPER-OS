# Contributing to REAPER OS

## Contributing Guide

Merci de vouloir contribuer à REAPER OS! Ce guide explique comment aider au projet.

## Code de Conduite

Nous nous engageons à fournir un environnement accueillant à tous. Consultez [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).

## Types de Contributions

### 🐛 Signaler des Bugs

1. Vérifier que le bug n'est pas déjà reporté
2. Ouvrir une [issue GitHub](https://github.com/REAPER-OS/issues)
3. Inclure:
   - Version du système: `uname -a`
   - Version REAPER: `reaper --version`
   - Description du problème
   - Étapes pour reproduire
   - Logs pertinent

### 🎯 Demander une Fonctionnalité

1. Vérifier que la demande n'existe pas
2. Ouvrir une [issue GitHub](https://github.com/REAPER-OS/issues)
3. Décrire la fonctionnalité demandée
4. Expliquer le cas d'usage

### 📝 Améliorer la Documentation

1. Forker le repository
2. Éditer les fichiers dans `docs/`
3. Soumettre une Pull Request
4. Les corrections peuvent être mineures (typos, clarifications)

### 💻 Coder des Fonctionnalités

1. Fork et créer une branche: `git checkout -b feature/ma-fonctionnalité`
2. Commiter les changements: `git commit -am 'Add my feature'`
3. Push: `git push origin feature/ma-fonctionnalité`
4. Créer une Pull Request

## Setup Développement

```bash
# Clone le repository
git clone https://github.com/REAPER-OS/REAPER-OS.git
cd REAPER-OS

# Créer une branche
git checkout -b feature/my-feature

# Installer les dépendances
sudo apt-get install debootstrap xorriso squashfs-tools

# Tester localement
cd installer/
bash build-debian-iso.sh  # Build ISO (prend 30-60 min)
```

## Standards de Code

### Bash Scripts
```bash
#!/bin/bash
set -e  # Exit on error

# Utiliser des noms significatifs
log_info() { echo "[INFO] $1"; }
log_err() { echo "[ERROR] $1"; exit 1; }

# Commenter les sections complexes
# Utiliser local pour les variables de fonction
function my_function() {
    local var="value"
    # ...
}
```

### Documentation
```markdown
# Titre Principal

## Section

**Bold** pour emphasis
`code` pour code inline
```bash
code block
```
```

## Process de Pull Request

1. **Fork et clone**
   ```bash
   git clone https://github.com/votre-username/REAPER-OS.git
   ```

2. **Créer une branche**
   ```bash
   git checkout -b fix/issue-123
   ```

3. **Faire les changements**
   - Code commits atomiques
   - Messages de commit clairs

4. **Test local**
   ```bash
   # Tester vos changements
   bash scripts/test.sh
   ```

5. **Push et créer PR**
   ```bash
   git push origin fix/issue-123
   # Ensuite créer PR sur GitHub
   ```

6. **Code Review**
   - Les mainteneurs vont review
   - Adresser les commentaires
   - Les commits seront merged

## Commit Messages

Format:
```
[Type] Title (50 chars max)

Description si nécessaire. Expliquer le "pourquoi", pas le "quoi".

Fixes #123
```

Types: `[fix]`, `[feat]`, `[docs]`, `[test]`, `[refactor]`

## Areas d'Intérêt

### Haute Priorité
- [ ] Support multi-architecture (ARM64, RISC-V)
- [ ] Installer graphique amélioré (GTK)
- [ ] Support VST3 complet
- [ ] Optimisation latence audio

### Moyenne Priorité
- [ ] Thèmes REAPER additionnels
- [ ] Scripts REAPER community
- [ ] Support plugins CLAP
- [ ] Intégration git built-in

### Basse Priorité
- [ ] Traductions supplémentaires
- [ ] Wallpapers additionnels
- [ ] Fonts nouvelles
- [ ] Easter eggs

## Testing

```bash
# Test ISO build
bash installer/build-debian-iso.sh

# Test installation
# (Dans VM)
# Démarrer l'ISO et tester l'installateur

# Test REAPER
reaper-start
# Tester les plugins, l'audio, MIDI, etc.
```

## Documentation à Jour

Si votre changement affecte la documentation:
1. Mettre à jour les fichiers pertinent dans `docs/`
2. Ajouter des exemples si applicable
3. Mettre à jour le README si nécessaire

## Licences

Le projet utilise plusieurs licenses:
- **REAPER OS Code**: GPL v3+
- **Documentation**: CC-BY-4.0
- **REAPER**: Propriétaire (Cockos)
- **Debian/Linux**: GPL v2+

Toute contribution doit être compatible.

## Contact

- **Issues**: https://github.com/devfrp/REAPER-OS/issues
- **Discussions**: https://github.com/devfrp/REAPER-OS/discussions
- **Forum REAPER**: https://forum.cockos.com/

---

Merci de contribuer! 🎵
