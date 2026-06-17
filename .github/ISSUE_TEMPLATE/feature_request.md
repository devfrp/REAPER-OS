name: Feature Request
description: Suggest a new feature for REAPER OS
title: "[FEATURE] "
labels: ["enhancement"]

body:
  - type: markdown
    attributes:
      value: |
        Thanks for the feature suggestion! Please provide details below.

  - type: textarea
    id: feature-description
    attributes:
      label: Feature Description
      description: Clear description of the proposed feature
      placeholder: "Describe the feature..."
    validations:
      required: true

  - type: textarea
    id: use-case
    attributes:
      label: Use Case
      description: Why would this feature be useful?
      placeholder: "Describe your use case..."
    validations:
      required: true

  - type: textarea
    id: expected-behavior
    attributes:
      label: Expected Behavior
      description: How should the feature work?
      placeholder: "Describe expected behavior..."
    validations:
      required: true

  - type: textarea
    id: alternatives
    attributes:
      label: Alternatives Considered
      description: Other approaches you've considered
      placeholder: "List alternatives..."

  - type: textarea
    id: additional-context
    attributes:
      label: Additional Context
      description: Screenshots, examples, or other context
      placeholder: "Add context..."

  - type: checkboxes
    id: consent
    attributes:
      label: Consent
      options:
        - label: I agree to the Code of Conduct
          required: true
