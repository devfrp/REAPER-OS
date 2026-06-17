# REAPER OS GitHub Configuration

This directory contains GitHub-specific configuration and workflows.

## 📁 Contents

### Issue Templates
- **bug_report.md** - Structured bug report form
- **feature_request.md** - Feature request form
- **[config.yml]** - GitHub issue form configuration (auto-managed)

### Pull Request
- **pull_request_template.md** - PR guidelines and checklist

### Workflows (GitHub Actions)
Location: `.github/workflows/`

Automated CI/CD pipelines:
- `test.yml` - Code quality and syntax checks
- `build-iso.yml` - Automated ISO building
- `release.yml` - Automated release creation

### Other
- `dependabot.yml` - Automated dependency scanning

---

## 🚀 Using These Templates

### For Users Reporting Issues
When creating a new issue:
1. Choose "Bug Report" or "Feature Request"
2. Fill out all required fields
3. Submit the issue

Templates auto-load when users click "New Issue".

### For Developers Creating PRs
When submitting a pull request:
1. Use the template to guide your submission
2. Complete all checklist items
3. Describe your changes clearly
4. Submit for review

---

## 🔄 GitHub Actions Workflows

All workflows are stored in `.github/workflows/` (created during setup).

### Test Workflow
Runs on every push and PR:
- Bash syntax validation
- Python syntax validation
- Linting checks

### Build ISO Workflow
Runs manually or on release:
- Builds ISO files
- Generates checksums
- Creates artifacts

### Release Workflow
Runs automatically on version tags:
- Creates GitHub release
- Publishes release notes
- Uploads artifacts

---

## 🔧 Manual Configuration Needed

After repository is created, complete these in GitHub settings:

### Repository Settings
1. Go to Settings → General
2. Set description: "Professional audio workstation distribution for Linux"
3. Add website: `https://reaper-os.dev`
4. Add topics: reaper, audio, daw, linux, debian, vst, jack-audio, music-production

### Branch Protection
1. Go to Settings → Branches
2. Add rule for `main` branch:
   - Require pull request reviews before merging
   - Dismiss stale pull request approvals
   - Require status checks to pass before merging
   - Require branches to be up to date before merging

### Actions Permissions
1. Go to Settings → Actions
2. Allow all actions to run
3. Enable workflow runs on pushes and PRs

### Pages (Optional)
1. Go to Settings → Pages
2. Source: Deploy from a branch
3. Branch: main / /docs folder
4. Save

---

## 📝 Creating Issues

Users can create issues by clicking the "Issues" tab and selecting:
- **Bug Report** - Something is broken
- **Feature Request** - Suggest a new feature

## 📌 Contributing

Developers should:
1. Read [CONTRIBUTING.md](../CONTRIBUTING.md)
2. Fork the repository
3. Create a feature branch
4. Make changes
5. Submit a pull request using the template

---

## 🔐 Security

Report security vulnerabilities:
- **DO NOT** open a public issue
- Email: security@reaper-os.dev
- See [SECURITY.md](../SECURITY.md) for details

---

## 📊 Monitoring

To monitor project health:

1. **Issues Tab**
   - Open, closed, labeled issues
   - Use filters to find specific categories

2. **Pull Requests Tab**
   - Open PRs awaiting review
   - Closed/merged PRs

3. **Actions Tab**
   - Workflow runs and results
   - Build status
   - Test results

4. **Insights Tab**
   - Network graph
   - Contributors
   - Dependency graph

---

## 🎯 Workflow Status Badges

Add these to README.md to show workflow status:

```markdown
[![Tests](https://github.com/devfrp/REAPER-OS/actions/workflows/test.yml/badge.svg)](https://github.com/devfrp/REAPER-OS/actions/workflows/test.yml)
[![Build ISO](https://github.com/devfrp/REAPER-OS/actions/workflows/build-iso.yml/badge.svg)](https://github.com/devfrp/REAPER-OS/actions/workflows/build-iso.yml)
[![Release](https://github.com/devfrp/REAPER-OS/actions/workflows/release.yml/badge.svg)](https://github.com/devfrp/REAPER-OS/actions/workflows/release.yml)
```

---

## 📞 Support

For questions about GitHub configuration:
1. Check [GITHUB-PUBLICATION-GUIDE.md](../GITHUB-PUBLICATION-GUIDE.md)
2. Open a GitHub Discussion
3. Ask in Issues

---

**Last Updated**: May 11, 2026  
**Status**: ✅ Ready for v1.0.0 publication
