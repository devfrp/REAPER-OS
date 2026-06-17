# Release Checklist for REAPER OS v1.0.0+

Use this checklist for every release to ensure quality and completeness.

## Pre-Release (1-2 weeks before)

- [ ] Code freeze - no new features
- [ ] Create release branch: `release/v1.x.0`
- [ ] Update version numbers in:
  - [ ] README.md
  - [ ] CHANGELOG.md
  - [ ] Installer scripts
  - [ ] Package configurations
- [ ] Test installers on clean systems:
  - [ ] Ubuntu 22.04 LTS
  - [ ] Ubuntu 20.04 LTS
  - [ ] Debian 13 (Bookworm)
  - [ ] WSL2 with Ubuntu 22.04
- [ ] Run all tests: `make test`
- [ ] Security audit of changes
- [ ] Documentation review

## Release Week

### Monday-Wednesday
- [ ] Final testing on all target systems
- [ ] Performance benchmarking (if applicable)
- [ ] Accessibility review
- [ ] Create release notes draft
- [ ] Alert major users/stakeholders

### Thursday
- [ ] Create annotated git tag
  ```bash
  git tag -a v1.x.0 -m "Release version 1.x.0"
  ```
- [ ] Push tag to GitHub
  ```bash
  git push origin v1.x.0
  ```
- [ ] Verify GitHub Actions workflows pass

### Friday
- [ ] Create GitHub Release
  - [ ] Populate with release notes
  - [ ] Add/verify assets:
    - [ ] install-offline.sh
    - [ ] install-online.sh
    - [ ] README.md
    - [ ] CHANGELOG.md
    - [ ] LICENSE
  - [ ] Mark as "Published" (not Draft)
  - [ ] Set prerelease flag if applicable

## Post-Release

- [ ] Announce release on:
  - [ ] GitHub Releases page
  - [ ] Social media (if applicable)
  - [ ] Email list (if maintained)
  - [ ] Project website
- [ ] Create next development version branch
- [ ] Open issues for known limitations
- [ ] Monitor for bug reports
- [ ] Prepare next sprint

## Quality Gates

Before release, verify:

- ✅ All tests passing
- ✅ No critical security issues
- ✅ Documentation complete
- ✅ Installers tested
- ✅ Performance acceptable
- ✅ No breaking changes (unless major version)

## Emergency Procedures

### If bugs found after release:

1. **Critical Bug**: Create patch release (v1.0.1)
   - Fix bug
   - Test thoroughly
   - Create new tag and release
   - Notify users immediately

2. **Non-critical Bug**: 
   - Document in known issues
   - Plan for next minor release
   - Offer workaround if possible

### Rollback Procedure

If release is severely broken:
1. Delete GitHub release
2. Delete git tag: `git tag -d v1.x.0`
3. Push deletion: `git push origin :refs/tags/v1.x.0`
4. Create hotfix release when ready

## Version Numbering

Follow Semantic Versioning: `MAJOR.MINOR.PATCH`

- **MAJOR**: Breaking changes or major new features
- **MINOR**: New features, backwards compatible
- **PATCH**: Bug fixes only

Example: v1.0.0 → v1.1.0 (new feature) → v1.1.1 (bug fix)

## Success Criteria

Release is successful when:
- ✅ All CI/CD checks pass
- ✅ Installers work on all tested systems
- ✅ Documentation is up to date
- ✅ Users can download and use release
- ✅ No critical issues in first week
