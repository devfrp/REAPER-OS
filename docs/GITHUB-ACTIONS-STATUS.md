# GitHub Actions & CI/CD Status

**Quick Links**:
- 🔴🟢 [View All Workflows Status](https://github.com/devfrp/REAPER-OS/actions) 
- 📦 [Download Releases](https://github.com/devfrp/REAPER-OS/releases)
- 🐛 [Report Issues](https://github.com/devfrp/REAPER-OS/issues)

---

## Workflows Overview

### 1. Code Quality Tests (`test.yml`)

**When**: Every push & pull request  
**Duration**: ~2-5 minutes  
**Link**: [View test.yml workflow](https://github.com/devfrp/REAPER-OS/actions/workflows/test.yml)

**Tests**:
- ShellCheck (bash linting)
- Bash syntax validation
- Documentation format checks
- Script functionality tests
- Configuration validation
- Integration tests

**Status**: [![Tests](https://github.com/devfrp/REAPER-OS/actions/workflows/test.yml/badge.svg)](https://github.com/devfrp/REAPER-OS/actions/workflows/test.yml)

### 2. ISO Building (`build-iso.yml`)

**When**: Push to main, new tags, manual trigger  
**Duration**: ~10-15 minutes  
**Link**: [View build-iso.yml workflow](https://github.com/devfrp/REAPER-OS/actions/workflows/build-iso.yml)

**Produces**:
- ISO image artifact (tar.gz for testing)
- SHA256 checksums
- Build manifest
- Content verification

**Status**: [![Build ISO](https://github.com/devfrp/REAPER-OS/actions/workflows/build-iso.yml/badge.svg)](https://github.com/devfrp/REAPER-OS/actions/workflows/build-iso.yml)

**Note**: Artifact available for 30 days after build.

### 3. Release Creation (`release.yml`)

**When**: New version tag (v*), manual trigger  
**Duration**: ~5-10 minutes  
**Link**: [View release.yml workflow](https://github.com/devfrp/REAPER-OS/actions/workflows/release.yml)

**Produces**:
- GitHub Release page
- Source code downloads
- Installation guide
- Release notes
- SHA256 checksums

**Status**: [![Release](https://github.com/devfrp/REAPER-OS/actions/workflows/release.yml/badge.svg)](https://github.com/devfrp/REAPER-OS/actions/workflows/release.yml)

---

## How to Check Workflow Status

### In Browser

1. Go to **[GitHub Repository](https://github.com/devfrp/REAPER-OS)**
2. Click **Actions** tab (top navigation)
3. Select workflow from list:
   - "Tests & Code Quality"
   - "Build ISO"
   - "Create Release"
4. Click latest run to see details

### See All Runs

**[View all workflow runs](https://github.com/devfrp/REAPER-OS/actions)**

### Check Specific Workflow

- **[test.yml runs](https://github.com/devfrp/REAPER-OS/actions/workflows/test.yml)**
- **[build-iso.yml runs](https://github.com/devfrp/REAPER-OS/actions/workflows/build-iso.yml)**
- **[release.yml runs](https://github.com/devfrp/REAPER-OS/actions/workflows/release.yml)**

---

## Understanding Workflow Status

### Status Badges

```
✅ Success    - All tests/builds passed
🟡 In Progress - Currently running
❌ Failed    - Something went wrong
⏭️ Skipped    - Skipped (conditional)
```

### Common Failures

**ShellCheck failed**:
- Script has syntax/style issues
- Fix: Run `shellcheck scripts/*.sh` locally
- See error details in workflow logs

**Tests failed**:
- Test assertion failed
- Fix: Run `bash tests/validate-installation.sh` locally
- Check logs for specific test that failed

**Build failed**:
- ISO build encountered error
- Common causes: disk space, missing tool, syntax error
- Check workflow logs for details

---

## Downloading Build Artifacts

### From Workflow Run

1. Go to **[Actions](https://github.com/devfrp/REAPER-OS/actions)**
2. Select "Build ISO" workflow
3. Click latest successful run
4. Scroll to **Artifacts** section
5. Download `reaper-os-iso-*` ZIP

### From GitHub Release

1. Go to **[Releases](https://github.com/devfrp/REAPER-OS/releases)**
2. Select release version
3. Download ISO and checksums

---

## Triggering Workflows Manually

### Build ISO (Manual Trigger)

1. Go to **[Actions](https://github.com/devfrp/REAPER-OS/actions)**
2. Click "Build ISO" workflow
3. Click **Run workflow** button
4. Choose branch (main recommended)
5. Click **Run workflow**

### Create Release (Manual Trigger)

1. Go to **[Actions](https://github.com/devfrp/REAPER-OS/actions)**
2. Click "Create Release" workflow
3. Click **Run workflow** button
4. Enter version (e.g., "0.1.0")
5. Choose if prerelease
6. Click **Run workflow**

### Auto-trigger via Git

```bash
# Auto-trigger build-iso.yml when pushing to main:
git push origin main

# Auto-trigger release.yml with version tag:
git push origin v0.1.0
```

---

## Viewing Detailed Logs

### For Failed Workflow

1. Click on failed run
2. Expand failing job
3. Expand failing step
4. See full error output
5. Copy error message

### Common Log Locations

- **ShellCheck errors**: Last few lines
- **Syntax errors**: Shows exact line number
- **Test failures**: Shows which test failed
- **Build logs**: Detailed build output

### Get Help with Errors

```bash
# Reproduce locally first
bash tests/validate-installation.sh
shellcheck scripts/*.sh

# Then share error output in GitHub Issue
```

---

## Notifications

### GitHub Notifications

1. Go to **Settings** → **Notifications**
2. Choose notification method:
   - Email
   - In-browser
   - Mobile app

### Watch Repository

1. Go to repository
2. Click **Watch** button
3. Choose notification level:
   - Participating and mentions
   - All Activity
   - Releases only
   - Ignore

---

## Advanced: Workflow Configuration

### Modify Workflows

Workflows defined in: `.github/workflows/`

To modify:
1. Edit `.github/workflows/test.yml`, etc.
2. Commit changes
3. Workflows automatically use new config

### Common Modifications

**Add new test**:
```yaml
  my-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run test
        run: |
          bash my-test.sh
```

**Change trigger**:
```yaml
on:
  push:
    branches: [main, develop]  # Branches to trigger
  schedule:
    - cron: '0 0 * * *'        # Daily at midnight
```

**Add artifact upload**:
```yaml
  - name: Upload artifact
    uses: actions/upload-artifact@v3
    with:
      name: my-artifact
      path: build/
```

---

## FAQ

**Q: How long do workflows take?**
A: Tests: 2-5 min | Build ISO: 10-15 min | Release: 5-10 min

**Q: Where are artifacts stored?**
A: GitHub (30 days) for builds, GitHub Releases (permanent) for releases

**Q: Can I see detailed logs?**
A: Yes! Click workflow run → expand job → scroll through output

**Q: What if a workflow fails?**
A: Check error in logs, fix locally, push to GitHub, workflow auto-reruns

**Q: How do I skip a test?**
A: Add `[skip ci]` to commit message (not recommended!)

**Q: Can I run workflows manually?**
A: Yes! Use "Run workflow" button in Actions tab

**Q: Are there costs?**
A: Free for public repos, 2000 min/month for private

---

## Resources

- **GitHub Actions Docs**: https://docs.github.com/en/actions
- **ShellCheck Manual**: https://www.shellcheck.net/
- **Workflow Syntax**: https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions
- **Artifacts**: https://docs.github.com/en/actions/using-workflows/storing-workflow-data-as-artifacts

---

## Support

- **Questions**: Open GitHub Issue with label `question`
- **Workflow Help**: Open Issue with label `ci-cd`
- **Report Bugs**: Include workflow logs in Issue

---

**Happy building! 🚀**
