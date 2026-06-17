# REAPER OS - CI/CD & Release Pipeline

This document explains the automated CI/CD pipeline for REAPER OS.

## Overview

REAPER OS uses **GitHub Actions** to automatically:
- ✅ Test code quality (ShellCheck, syntax validation)
- ✅ Build ISO images
- ✅ Generate releases
- ✅ Upload to GitHub Releases

## Workflows

### 1. **test.yml** - Code Quality & Validation

**Triggers**: Every push and pull request

**Tests**:
- ShellCheck (bash linting)
- Bash syntax validation
- Documentation checks
- Script functionality tests
- Configuration validation
- Integration tests

**Status**: Check in GitHub → Actions tab

**Fix Issues**:
```bash
# Run locally to fix before committing:
sudo apt-get install shellcheck
shellcheck scripts/*.sh reaper-config/*.sh tools/*.sh
```

### 2. **build-iso.yml** - Build ISO Image

**Triggers**: 
- Push to `main` branch
- Push new tags (v*)
- Manual trigger (workflow_dispatch)

**Steps**:
1. Validate environment
2. Validate scripts
3. Install build tools
4. Create ISO structure
5. Generate checksums
6. Test ISO content
7. Upload as artifact

**Result**:
- ISO image artifact
- SHA256 checksums
- Build metadata
- Available for 30 days

**Download Artifact**:
1. Go to GitHub → Actions → Latest "Build ISO" run
2. Click "Artifacts" section
3. Download `reaper-os-iso-*` ZIP

### 3. **release.yml** - Create Release

**Triggers**:
- New tag starting with `v` (e.g., `v0.1.0`)
- Manual trigger with version

**Steps**:
1. Prepare release
2. Build artifacts:
   - Source code (tar.gz)
   - Source code (zip)
   - Release notes
   - Installation guide
   - Checksums
3. Create GitHub Release
4. Upload files to GitHub Releases

**Result**:
- GitHub Release page
- Downloadable artifacts
- Checksums for verification

## Creating a Release

### Automated Release (Recommended)

```bash
# 1. Ensure main branch is up to date
git checkout main
git pull

# 2. Create release tag
git tag -a v0.1.0 -m "Release version 0.1.0"

# 3. Push tag to GitHub
git push origin v0.1.0

# release.yml workflow triggers automatically!
# Check GitHub → Actions for progress
# Releases appear at GitHub → Releases
```

### Manual Release

In GitHub:
1. Go to **Actions** tab
2. Select **Create Release** workflow
3. Click **Run workflow**
4. Enter version number (e.g., `0.1.0`)
5. Click **Run workflow**

---

## GitHub Releases Page

### Access Releases

**Link**: `https://github.com/devfrp/REAPER-OS/releases`

### Download Files

Each release includes:

```
📦 reaper-os-X.X.X-source.tar.gz          ← Source code (Linux/macOS)
📦 reaper-os-X.X.X-source.zip             ← Source code (Windows)
📄 RELEASE_NOTES.md                       ← What's included
📄 INSTALLATION.txt                       ← How to install
✓ SHA256SUMS                              ← Verify downloads
```

### ISO Downloads

⚠️ **Note**: Full ISO builds require additional setup. For now:
- Source code releases are available
- Full ISO builds happen on tagged releases
- ISO will be added to Releases when build is complete

---

## Testing Locally

### Run Code Quality Tests

```bash
# Install dependencies
sudo apt-get install shellcheck

# Run all checks
bash tests/validate-installation.sh

# Or run individual tools:
shellcheck scripts/*.sh
bash -n scripts/reaper-os-first-boot.sh
```

### Simulate CI/CD

```bash
# Create a test branch
git checkout -b test/new-feature

# Make changes...
git add .
git commit -m "Test changes"

# Push branch
git push origin test/new-feature

# Tests run automatically!
# Check GitHub → Pull Requests → test/new-feature
```

---

## Troubleshooting CI/CD

### Tests Failing

1. **Check error** in GitHub → Actions → Failed workflow
2. **Run locally**:
   ```bash
   bash tests/validate-installation.sh
   shellcheck scripts/*.sh
   ```
3. **Fix issues** in your scripts
4. **Push fix** to GitHub (tests re-run automatically)

### ShellCheck Errors

Common issues:
```bash
# Issue: Variable not quoted
❌ grep $pattern     # Bad - spaces break
✅ grep "$pattern"   # Good - quoted

# Issue: Double quotes in double quotes
❌ echo "foo $var bar"
✅ echo "foo ${var} bar"  # Better

# Issue: Using [ instead of [[
❌ [ $var = "test" ]
✅ [[ $var = "test" ]]  # Preferred
```

**Fix**:
```bash
shellcheck -f gcc scripts/*.sh  # Shows all issues
# Fix each issue, push again
```

### Build Failures

**Check logs**:
1. GitHub → Actions → Failed "Build ISO" workflow
2. Click workflow → See error details
3. Common issues:
   - Missing dependencies (installed in workflow)
   - Syntax errors (run ShellCheck locally)
   - File permissions

---

## Automation Details

### Secrets & Permissions

Currently uses default GitHub token for:
- Creating releases
- Uploading artifacts
- Pushing to GitHub

No additional secrets needed!

### Artifact Retention

- **Build artifacts**: 30 days (configurable)
- **Release artifacts**: Permanent (on Releases page)

### Scheduled Runs

Currently manual or on code push. Could add:
- Nightly builds
- Weekly releases
- Security updates

---

## Best Practices

### Before Committing

```bash
# 1. Run validation locally
bash tests/validate-installation.sh

# 2. Check syntax
bash -n scripts/*.sh reaper-config/*.sh

# 3. Run shellcheck
shellcheck scripts/*.sh

# 4. Verify no secrets in code
grep -r "password\|token\|key" . --include="*.sh"
```

### Before Creating Release

```bash
# 1. Update version in docs
grep -r "version" . --include="*.md" | head -5

# 2. Update CHANGELOG
# (if using one)

# 3. Commit changes
git add .
git commit -m "Release v0.1.0"

# 4. Create tag
git tag -a v0.1.0 -m "Version 0.1.0"

# 5. Push
git push origin main --tags
```

---

## Advanced: Customization

### Add New Tests

Edit `.github/workflows/test.yml`:

```yaml
  new-test:
    runs-on: ubuntu-latest
    name: My New Test
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Run my test
        run: |
          # Add test commands here
          bash my-test-script.sh
```

### Add Build Tools

Edit `.github/workflows/build-iso.yml`:

```yaml
  - name: Install additional tools
    run: |
      sudo apt-get install -y tool1 tool2 tool3
```

### Change Release Artifacts

Edit `.github/workflows/release.yml`:

```yaml
      files: |
        ${{ env.ARTIFACT_DIR }}/reaper-os-*
        ${{ env.ARTIFACT_DIR }}/SHA256SUMS
        # Add more files here
```

---

## Monitoring

### View Workflow Status

- **GitHub**: Actions tab → Select workflow
- **Command line**:
  ```bash
  gh run list --workflow=test.yml
  gh run view <run-id>
  ```

### Subscribe to Notifications

GitHub → Settings → Notifications:
- Check "All Activity"
- Get emails for workflow failures
- Get alerts for releases

---

## FAQ

**Q: How often do tests run?**
A: On every push and pull request. Takes 2-5 minutes.

**Q: Can I skip tests?**
A: Not recommended! But can add `[skip ci]` to commit message.

**Q: Where are artifacts stored?**
A: GitHub (30 days) and GitHub Releases (permanent).

**Q: How big is the ISO?**
A: ~2-4GB (depends on content included).

**Q: Can I test ISO before release?**
A: Yes! Download artifact from Actions → Build ISO run.

**Q: How do I roll back a release?**
A: Delete tag and release on GitHub, fix code, create new tag.

---

## Support

For CI/CD issues:
1. Check [GitHub Actions documentation](https://docs.github.com/en/actions)
2. Review workflow logs in GitHub → Actions
3. Check ShellCheck rules: [ShellCheck wiki](https://www.shellcheck.net/)
4. Open GitHub Issue with workflow logs

---

**Happy building! 🚀**
