.PHONY: help install-test validate test-offline test-online clean format check-syntax docs release

help:
	@echo "REAPER OS - Available Commands"
	@echo "=============================="
	@echo ""
	@echo "Installation Testing:"
	@echo "  make test-offline          Test offline installer"
	@echo "  make test-online           Test online installer"
	@echo "  make install-test          Run all installer tests"
	@echo ""
	@echo "Code Quality:"
	@echo "  make validate              Validate all scripts"
	@echo "  make check-syntax          Check Bash syntax"
	@echo "  make format                Format shell scripts"
	@echo ""
	@echo "Documentation:"
	@echo "  make docs                  Generate documentation"
	@echo ""
	@echo "Cleanup:"
	@echo "  make clean                 Remove temporary files"
	@echo ""
	@echo "Release:"
	@echo "  make release               Prepare release (interactive)"
	@echo ""

validate: check-syntax
	@echo "✓ All validations passed"

check-syntax:
	@echo "Checking shell script syntax..."
	@bash -n installer/build-debian-iso.sh
	@bash -n installer/build-iso-with-installers.sh
	@bash -n installer/install-offline.sh
	@bash -n installer/install-online.sh
	@bash -n reaper-os.sh
	@echo "✓ Syntax check passed"

install-test: test-offline test-online
	@echo "✓ All installer tests completed"

test-offline:
	@echo "Testing offline installer..."
	@if [ -f installer/install-offline.sh ]; then \
		echo "✓ Offline installer exists"; \
		bash -n installer/install-offline.sh || exit 1; \
		echo "✓ Offline installer syntax valid"; \
	else \
		echo "✗ Offline installer not found"; \
		exit 1; \
	fi

test-online:
	@echo "Testing online installer..."
	@if [ -f installer/install-online.sh ]; then \
		echo "✓ Online installer exists"; \
		bash -n installer/install-online.sh || exit 1; \
		echo "✓ Online installer syntax valid"; \
	else \
		echo "✗ Online installer not found"; \
		exit 1; \
	fi

format:
	@echo "Formatting shell scripts..."
	@if command -v shfmt &> /dev/null; then \
		shfmt -i 2 -w installer/install-offline.sh; \
		shfmt -i 2 -w installer/install-online.sh; \
		shfmt -i 2 -w reaper-os.sh; \
		echo "✓ Formatting complete"; \
	else \
		echo "⚠ shfmt not installed. Install with: apt-get install shellcheck"; \
	fi

docs:
	@echo "Building documentation index..."
	@echo "# REAPER OS Documentation Index" > docs/INDEX.md
	@echo "" >> docs/INDEX.md
	@echo "## Main Files" >> docs/INDEX.md
	@echo "- [README.md](../README.md) - Project overview" >> docs/INDEX.md
	@echo "- [CONTRIBUTING.md](../CONTRIBUTING.md) - How to contribute" >> docs/INDEX.md
	@echo "- [RELEASE_CHECKLIST.md](../RELEASE_CHECKLIST.md) - Release procedure" >> docs/INDEX.md
	@echo "- [SECURITY.md](../SECURITY.md) - Security guidelines" >> docs/INDEX.md
	@echo "" >> docs/INDEX.md
	@echo "## Installers" >> docs/INDEX.md
	@echo "- [install-offline.sh](../installer/install-offline.sh) - Offline installation" >> docs/INDEX.md
	@echo "- [install-online.sh](../installer/install-online.sh) - Online installation" >> docs/INDEX.md
	@echo "" >> docs/INDEX.md
	@echo "✓ Documentation index generated"

clean:
	@echo "Cleaning up temporary files..."
	@find . -name "*.swp" -delete
	@find . -name "*.swo" -delete
	@find . -name "*~" -delete
	@find . -name ".DS_Store" -delete
	@echo "✓ Cleanup complete"

release:
	@echo "REAPER OS Release Helper"
	@echo "======================="
	@echo ""
	@read -p "Enter version (e.g., 1.0.1): " VERSION; \
	echo ""; \
	echo "Creating release v$$VERSION..."; \
	git tag -a v$$VERSION -m "Release REAPER OS v$$VERSION"; \
	git push origin v$$VERSION; \
	echo ""; \
	echo "✓ Tag v$$VERSION created and pushed"; \
	echo "✓ GitHub Actions will create the release"; \
	echo "✓ Monitor progress: https://github.com/devfrp/REAPER-OS/actions"

.DEFAULT_GOAL := help
