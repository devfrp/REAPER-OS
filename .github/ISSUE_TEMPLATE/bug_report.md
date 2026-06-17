name: Bug Report
description: Report a bug in REAPER OS
title: "[BUG] "
labels: ["bug"]

body:
  - type: markdown
    attributes:
      value: |
        Thanks for reporting a bug! Please fill out the form below to help us understand the issue.

  - type: checkboxes
    id: prerequisites
    attributes:
      label: Prerequisites
      description: Please check these first
      options:
        - label: I have checked existing issues and discussions
          required: true
        - label: I am using the latest version of REAPER OS
          required: true
        - label: I have searched the documentation
          required: true

  - type: textarea
    id: bug-description
    attributes:
      label: Bug Description
      description: Clear and concise description of the bug
      placeholder: "Describe the problem..."
    validations:
      required: true

  - type: textarea
    id: reproduction-steps
    attributes:
      label: Steps to Reproduce
      description: Steps to reproduce the issue
      placeholder: |
        1. First step
        2. Second step
        3. ...
    validations:
      required: true

  - type: textarea
    id: expected-behavior
    attributes:
      label: Expected Behavior
      description: What should happen instead?
      placeholder: "Expected behavior..."
    validations:
      required: true

  - type: textarea
    id: actual-behavior
    attributes:
      label: Actual Behavior
      description: What actually happens?
      placeholder: "Actual behavior..."
    validations:
      required: true

  - type: input
    id: audio-interface
    attributes:
      label: Audio Interface Model
      description: What audio interface are you using?
      placeholder: "e.g., RME Babyface Pro, Focusrite Scarlett, etc."

  - type: textarea
    id: system-info
    attributes:
      label: System Information
      description: Run `uname -a` and `cat /etc/os-release`
      placeholder: |
        OS: REAPER OS v1.0.0 Debian 13
        Kernel: 6.1.0
        CPU: Intel Core i7-10700K
        RAM: 16GB
    validations:
      required: true

  - type: textarea
    id: logs
    attributes:
      label: Relevant Logs
      description: Paste error logs or output
      render: bash
      placeholder: "Paste logs here..."

  - type: textarea
    id: additional-context
    attributes:
      label: Additional Context
      description: Any additional information
      placeholder: "Add any other context..."

  - type: checkboxes
    id: consent
    attributes:
      label: Consent
      options:
        - label: I agree to the Code of Conduct
          required: true
