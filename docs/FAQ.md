# FAQ - REAPER OS

## Questions Fréquemment Posées

### Général

**Q: REAPER OS est-il gratuit?**
A: REAPER OS (la distribution Linux) est gratuit et open-source. REAPER lui-même a une période d'évaluation gratuite de 60 jours, puis nécessite une license (peu coûteuse).

**Q: Puis-je utiliser REAPER OS sans REAPER?**
A: Non, REAPER est le cœur de REAPER OS. C'est l'interface et l'application principale.

**Q: REAPER OS supporte-t-il d'autres DAW (Ableton, FL Studio, etc.)?**
A: Non, REAPER OS est spécialisé pour REAPER. D'autres DAW peuvent être installés mais ne seront pas optimisés.

**Q: Puis-je installer REAPER OS sur macOS/Windows?**
A: REAPER OS est pour Linux uniquement. Pour Linux sur Windows, voir WSL2.

### Installation

**Q: Puis-je installer REAPER OS dans une VM?**
A: Oui, VirtualBox/KVM/VMware fonctionnent bien, mais avec latence audio augmentée.

**Q: Puis-je dual-boot REAPER OS avec Windows/macOS?**
A: Oui. GRUB vous permettra de choisir au boot.

**Q: Quelle est la taille minimale du disque?**
A: 50GB recommandé (30GB minimum).

**Q: REAPER OS fonctionne-t-il sur Raspberry Pi?**
A: Non, REAPER OS nécessite x86_64 (Intel/AMD). Le Raspberry Pi est ARM.

### Audio & Hardware

**Q: Puis-je utiliser ma carte audio externe?**
A: Oui, les cartes audio USB/Thunderbolt sont reconnues automatiquement.

**Q: Quelle latence puis-je atteindre?**
A: Avec JACK + kernel PREEMPT_RT: 1-3ms. Avec kernel standard: 3-5ms.

**Q: Puis-je faire du live performance avec REAPER OS?**
A: Oui, beaucoup d'artistes utilisent REAPER en live. La latence est suffisamment basse.

**Q: Supporte-t-il Dante, CobraNet, ou autres protocoles audio?**
A: Avec les drivers appropriés, oui.

### VST Windows

**Q: Les VST Windows fonctionnent-ils nativement sur REAPER OS?**
A: Oui! Via deux méthodes:
- **Wine Direct**: VST s'exécutent dans REAPER (latence 3-5ms)
- **AudioGridder**: VST dans serveur séparé (latence 1-3ms, meilleure stabilité)
Voir [VST-NATIVE-EXPLANATION.md](VST-NATIVE-EXPLANATION.md) pour détails.

**Q: Quelle méthode choisir: Wine ou AudioGridder?**
A: 
- **Wine Direct** → VST légers, sessions simples, latence ultra-critique
- **AudioGridder** → VST complexes, production, live, stabilité prioritaire

**Q: Tous les VST Windows fonctionnent-ils?**
A: ~95% des VST Windows courants fonctionnent. Quelques VST très complexes peuvent avoir des problèmes.

**Q: Puis-je utiliser les VST natifs Linux?**
A: Oui! REAPER OS supporte VST, VST3, AU, et LV2 Linux natifs. Vous pouvez mélanger VST Windows et natifs.

**Q: Les VST 32-bit fonctionnent-ils?**
A: Oui, avec Wine Direct. AudioGridder supporte aussi 32-bit.

**Q: Puis-je utiliser les VST AAX (Pro Tools)?**
A: Non, AAX n'est pas supporté sur Linux.

**Q: La performance VST Windows est-elle acceptable?**
A: Oui! AudioGridder donne 1-3ms latence (meilleur que Wine), performance 95%+.

### Performance

**Q: Combien de VST puis-je utiliser?**
A: Dépend du hardware, mais 30-50+ VST est possible avec un bon CPU (4+ cores).

**Q: Quelle est la meilleure config pour REAPER OS?**
A: 
- **Budget**: i5-8400, 16GB RAM, SSD 500GB
- **Pro**: i9-13900K, 64GB RAM, NVMe M.2

**Q: Puis-je enregistrer en 24-bit / 192kHz?**
A: Oui, limité seulement par votre hardware audio.

**Q: La température CPU est-elle un problème?**
A: Non, Linux gère bien la thermique. Les CPUs modernes auto-throttle si chaud.

### Software

**Q: Puis-je compiler REAPER OS moi-même?**
A: Oui, les scripts d'installation sont dans `/installer/`.

**Q: Puis-je contribuer à REAPER OS?**
A: Oui! Consultez [CONTRIBUTING.md](CONTRIBUTING.md)

**Q: REAPER OS a-t-il une mascotte?**
A: Pas encore, mais suggestions bienvenues!

### Support

**Q: Où obtenir du support?**
A: 
- GitHub Issues: https://github.com/devfrp/REAPER-OS/issues
- Forum REAPER: https://forum.cockos.com/
- Documentation: [docs/](../docs/)

**Q: Puis-je acheter du support commercial?**
A: REAPER OS est communautaire. Cockos offre du support pour REAPER.

**Q: Est-ce que REAPER OS sera toujours gratuit?**
A: Oui, basé sur Debian (gratuit) et logiciels open-source.

### Sécurité & Privacy

**Q: REAPER OS envoie-t-il des données à Cockos?**
A: Non, REAPER OS ne collecte aucune donnée. REAPER peut envoyer des crash reports (configurable).

**Q: REAPER OS est-il sûr pour la musique confidentielle?**
A: Oui, aucune telemetrie. Vous avez le contrôle complet.

**Q: Puis-je utiliser REAPER OS hors ligne?**
A: Oui, complètement offline après installation. VST Windows scanning a besoin d'une initialisation Wine.

### Problèmes Courants

**Q: Mon VST ne se lance pas.**
A: Consultez [TROUBLESHOOTING.md](TROUBLESHOOTING.md#vst-non-détecté-par-reaper)

**Q: La latence est trop élevée.**
A: Réduire le buffer JACK, vérifier la charge CPU, voir [TROUBLESHOOTING.md](TROUBLESHOOTING.md#latence-élevée)

**Q: REAPER crash au démarrage.**
A: Vérifier les logs: `~/.wine/drive_c/reaper.log` ou `journalctl`

**Q: Pas de son.**
A: `jackd` ne s'est probablement pas lancé. Voir [TROUBLESHOOTING.md](TROUBLESHOOTING.md#pas-de-son)

### Updates & Maintenance

**Q: Puis-je mettre à jour REAPER OS?**
A: Oui, mises à jour Debian standard: `sudo apt update && apt upgrade`

**Q: Dois-je réinstaller les VST après update?**
A: Non, Wine/VST sont conservés.

**Q: Y a-t-il des breaking changes?**
A: Non, REAPER OS maintient la compatibilité rétroactive.

---

**Votre question n'est pas listée?** Ouvrez une [issue](https://github.com/devfrp/REAPER-OS/issues) ou consultez le [forum REAPER](https://forum.cockos.com).

Bonne création! 🎵
