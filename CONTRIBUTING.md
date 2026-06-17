# 🤝 Contributing to REAPER OS

Thank you for your interest in contributing to REAPER OS! This document provides guidelines and instructions for contributing to the project.

## Code of Conduct

This project adheres to the Contributor Covenant [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

---

## 🎯 How to Contribute

### Reporting Bugs

**Before submitting a bug report**, please check the [issue tracker](https://github.com/devfrp/REAPER-OS/issues) to avoid duplicates.

When reporting a bug, include:
- **Clear title and description**
- **Steps to reproduce**
- **Expected vs. actual behavior**
- **Your environment**: OS version, REAPER version, audio interface model
- **Screenshots or error logs**
- **Relevant configuration files** (without sensitive data)

### Suggesting Features

Feature suggestions are always welcome! Please:

1. Check [GitHub Discussions](https://github.com/devfrp/REAPER-OS/discussions) for similar ideas
2. Describe the desired behavior and use case
3. Explain why this feature would be valuable
4. Provide examples of how it would work

### Pull Requests

#### Before You Start

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature-name`
3. Make your changes following the guidelines below
4. Test thoroughly
5. Submit a pull request

#### Code Style & Standards

**Bash Scripts**:
- Use `#!/bin/bash` shebang
- Follow [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- Check syntax: `bash -n script.sh`
- Use meaningful variable names
- Add comments for complex logic
- Use error handling: `set -euo pipefail`

**Python**:
- Follow [PEP 8](https://pep8.org/)
- Use type hints where applicable
- Maximum line length: 100 characters
- Run `black` and `pylint` before committing
- Add docstrings to functions

**Documentation**:
- Use clear, concise language
- Include code examples where relevant
- Keep README.md up to date
- Update CHANGELOG.md with your changes

#### Commit Messages

Follow this format:

```
<type>: <subject>

<body>

<footer>
```

**Types**: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

**Example**:
```
feat: add hardware controller auto-mapper

- Automatically detect connected MIDI controllers
- Support for 50+ known devices
- Preset-based configuration system

Closes #123
```

#### Testing

Before submitting a PR:

```bash
# Run test suite
./tests/validate-installation.sh

# Check syntax
bash -n tools/*.sh
python -m py_compile tools/*.py

# Verify documentation
grep -r "TODO" docs/ || echo "No TODOs found"
```

---

## 📋 Development Workflow

### Prerequisites

```bash
# Clone repository
git clone https://github.com/devfrp/REAPER-OS.git
cd REAPER-OS

# Install development dependencies
pip install -r requirements-dev.txt

# Optional: Create virtual environment
python -m venv venv
source venv/bin/activate
```

### Project Structure

```
├── scripts/               # Core installation/setup scripts
├── tools/                # Utility and diagnostic tools
├── docs/                 # User documentation
├── tests/                # Test suites
├── installer/            # ISO building
└── config/               # Configuration templates
```

### Building ISO Locally

```bash
# Prerequisites
sudo apt-get install xorriso isolinux

# Build ISO
./installer/build-debian-iso.sh --output reaper-os.iso
```

### Running Tests

```bash
# Full test suite
./tests/validate-installation.sh

# Individual test suites
./tests/test-suite-1-environment.sh
./tests/test-suite-3-syntax.sh
```

---

## 🔄 PR Review Process

1. **Automated Checks**
   - GitHub Actions runs tests and linting
   - All checks must pass

2. **Manual Review**
   - Code review by maintainers
   - Suggestions and discussion
   - Changes requested or approved

3. **Merge**
   - PR merged after approval
   - Author credited in CHANGELOG
   - Branch deleted

---

## 📚 Documentation Guidelines

- Update relevant `.md` files
- Include code examples for new features
- Add comments to complex code
- Update the CHANGELOG.md

### Documentation Sections

- **README.md**: Overview and quick start
- **docs/**: In-depth guides and troubleshooting
- **Code comments**: Implementation details

---

## 🧑‍💻 Areas Needing Help

- [ ] Audio interface driver support (add new devices)
- [ ] VST compatibility testing (report issues)
- [ ] Translation (add new languages)
- [ ] Documentation improvements
- [ ] Performance optimization
- [ ] Security audits
- [ ] Mobile app development (React Native)

---

## 🎁 Recognition

Contributors will be recognized in:
- CONTRIBUTORS.md
- Release notes
- GitHub contributors page

---

## ❓ Questions?

- **Discussions**: [GitHub Discussions](https://github.com/devfrp/REAPER-OS/discussions)
- **Issues**: [GitHub Issues](https://github.com/devfrp/REAPER-OS/issues)

---

## 📖 Additional Resources

- [Git Workflow Tutorial](https://git-scm.com/book/en/v2)
- [GitHub Flow Guide](https://guides.github.com/introduction/flow/)
- [Commit Best Practices](https://chris.beams.io/posts/git-commit/)

Thank you for contributing! 🙏
