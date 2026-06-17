#!/bin/bash

################################################################################
# REAPER OS Community Integration
# Integrates community features: GitHub issues, discussions, feedback, showcase
# Features: Bug reporting, feature requests, community voting, user gallery
# Usage: ./community-integration.sh [--report-bug] [--feature-request] [--feedback] [--showcase]
################################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMUNITY_DIR="$HOME/.config/REAPER/community"
COMMUNITY_LOG="$COMMUNITY_DIR/community-activity.log"

mkdir -p "$COMMUNITY_DIR"

# Configuration
GITHUB_REPO="${GITHUB_REPO:-owner/REAPER-OS}"
GITHUB_API="https://api.github.com/repos/$GITHUB_REPO"
DISCUSSIONS_URL="https://github.com/$GITHUB_REPO/discussions"
SHOWCASE_URL="https://github.com/$GITHUB_REPO/discussions/categories/showcase"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" >> "$COMMUNITY_LOG"
}

print_header() {
    echo -e "\n${BOLD}${BLUE}=== $1 ===${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Report bug to GitHub
report_bug() {
    print_header "Report a Bug"
    
    echo "This will help us fix issues and improve REAPER OS."
    echo ""
    
    read -p "Bug Title: " bug_title
    read -p "Description: " bug_description
    read -p "Steps to reproduce: " bug_steps
    
    # Gather system information
    local system_info=$(cat << EOF
**System Information:**
- OS: $(lsb_release -ds 2>/dev/null || echo "Unknown")
- Kernel: $(uname -r)
- REAPER Version: $(reaper --version 2>/dev/null || echo "Unknown")
- Audio Interface: $(aplay -l 2>/dev/null | grep "card" | head -1 || echo "Unknown")
EOF
)
    
    # Create bug report file
    local report_file="$COMMUNITY_DIR/bug-report-$(date +%Y%m%d-%H%M%S).md"
    
    cat > "$report_file" << EOF
# Bug Report

## Title
$bug_title

## Description
$bug_description

## Steps to Reproduce
$bug_steps

## Expected Behavior
<!-- What should happen? -->

## Actual Behavior
<!-- What actually happens? -->

$system_info

## Attachments
<!-- Relevant logs, screenshots, etc. -->

---
Submitted: $(date)
EOF
    
    print_success "Bug report created: $report_file"
    
    # Option to open in browser
    if command -v xdg-open &> /dev/null; then
        read -p "Open bug report form in browser? (y/n): " open_browser
        if [ "$open_browser" = "y" ]; then
            xdg-open "$GITHUB_API/issues/new"
        fi
    fi
    
    log "Bug reported: $bug_title"
}

# Request feature
request_feature() {
    print_header "Request a Feature"
    
    echo "Help us improve REAPER OS with your feature ideas."
    echo ""
    
    read -p "Feature Title: " feature_title
    read -p "Description: " feature_desc
    read -p "Use case: " use_case
    
    # Create feature request file
    local request_file="$COMMUNITY_DIR/feature-request-$(date +%Y%m%d-%H%M%S).md"
    
    cat > "$request_file" << EOF
# Feature Request

## Title
$feature_title

## Description
$feature_desc

## Use Case
$use_case

## Benefits
<!-- What problems does this solve? -->

## Implementation Ideas
<!-- Optional: How might this be implemented? -->

---
Submitted: $(date)
EOF
    
    print_success "Feature request created: $request_file"
    
    # Option to post on discussions
    if command -v xdg-open &> /dev/null; then
        read -p "Post on GitHub Discussions? (y/n): " post_discussion
        if [ "$post_discussion" = "y" ]; then
            xdg-open "$DISCUSSIONS_URL"
        fi
    fi
    
    log "Feature requested: $feature_title"
}

# Submit user feedback
submit_feedback() {
    print_header "User Feedback"
    
    echo "Tell us what you think about REAPER OS."
    echo ""
    
    read -p "Your feedback: " feedback_text
    read -p "Would you recommend REAPER OS? (yes/no): " recommend
    read -p "Rate your experience (1-10): " rating
    
    # Create feedback file
    local feedback_file="$COMMUNITY_DIR/feedback-$(date +%Y%m%d-%H%M%S).json"
    
    cat > "$feedback_file" << EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "feedback": "$feedback_text",
  "recommendation": "$recommend",
  "rating": $rating,
  "system": {
    "os": "$(lsb_release -ds 2>/dev/null || echo 'Unknown')",
    "kernel": "$(uname -r)",
    "username": "$(whoami)"
  }
}
EOF
    
    print_success "Feedback submitted: $feedback_file"
    log "Feedback submitted: rating=$rating, recommend=$recommend"
}

# User showcase submission
submit_showcase() {
    print_header "Community Showcase"
    
    echo "Share your REAPER OS setup or project with the community!"
    echo ""
    
    read -p "Project/Setup Name: " project_name
    read -p "Brief description: " project_desc
    read -p "Screenshot path (optional): " screenshot_path
    read -p "GitHub link (optional): " github_link
    
    # Create showcase submission
    local showcase_file="$COMMUNITY_DIR/showcase-$(date +%Y%m%d-%H%M%S).md"
    
    cat > "$showcase_file" << EOF
# Showcase Submission

## Project Name
$project_name

## Description
$project_desc

## Setup Details
<!-- Share details about your setup -->

## Use Case
<!-- What do you use REAPER OS for? -->

## Screenshot
<!-- If available -->
$screenshot_path

## Links
- GitHub: $github_link

---
Submitted by: $(whoami)
Date: $(date)
EOF
    
    print_success "Showcase submission created: $showcase_file"
    print_info "Post your showcase on: $SHOWCASE_URL"
    
    log "Showcase submitted: $project_name"
}

# View community guidelines
show_guidelines() {
    print_header "Community Guidelines"
    
    cat << 'EOF'
REAPER OS Community Guidelines
=============================

1. Be Respectful
   - Treat all members with courtesy
   - Respect diverse perspectives
   - No harassment or discrimination

2. Be Constructive
   - Provide helpful feedback
   - Share knowledge and solutions
   - Help other users

3. Code of Conduct
   - Follow GitHub Community Guidelines
   - No spam or promotional content
   - Respect intellectual property

4. Bug Reports
   - Include system information
   - Provide reproduction steps
   - Be specific and detailed

5. Feature Requests
   - Explain the use case
   - Discuss potential benefits
   - Consider existing features

6. Community Discussions
   - Search before posting
   - Use appropriate categories
   - Keep discussions focused

For full guidelines, visit:
https://github.com/$GITHUB_REPO/blob/main/CONTRIBUTING.md
EOF
}

# View community statistics
show_stats() {
    print_header "Community Statistics"
    
    # Count local submissions
    local bug_count=$(ls "$COMMUNITY_DIR"/bug-report-*.md 2>/dev/null | wc -l)
    local feature_count=$(ls "$COMMUNITY_DIR"/feature-request-*.md 2>/dev/null | wc -l)
    local feedback_count=$(ls "$COMMUNITY_DIR"/feedback-*.json 2>/dev/null | wc -l)
    local showcase_count=$(ls "$COMMUNITY_DIR"/showcase-*.md 2>/dev/null | wc -l)
    
    echo "Your Community Contributions:"
    echo "=============================="
    echo "  Bug Reports: $bug_count"
    echo "  Feature Requests: $feature_count"
    echo "  Feedback Submissions: $feedback_count"
    echo "  Showcase Items: $showcase_count"
    echo ""
    
    # Try to fetch GitHub stats
    if command -v curl &> /dev/null; then
        print_info "Fetching GitHub statistics..."
        
        local stars=$(curl -s "$GITHUB_API" | grep -o '"stargazers_count":[0-9]*' | cut -d: -f2 || echo "0")
        local forks=$(curl -s "$GITHUB_API" | grep -o '"forks_count":[0-9]*' | cut -d: -f2 || echo "0")
        local issues=$(curl -s "$GITHUB_API" | grep -o '"open_issues_count":[0-9]*' | cut -d: -f2 || echo "0")
        
        echo "GitHub Repository:"
        echo "=================="
        echo "  Stars: $stars"
        echo "  Forks: $forks"
        echo "  Open Issues: $issues"
    fi
}

# Create community dashboard
create_dashboard() {
    print_header "Creating Community Dashboard..."
    
    local dashboard_file="$COMMUNITY_DIR/dashboard.html"
    
    cat > "$dashboard_file" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>REAPER OS Community Dashboard</title>
    <style>
        body { font-family: Arial; margin: 20px; background: #f5f5f5; }
        .header { background: #333; color: white; padding: 20px; }
        .section { background: white; margin: 20px 0; padding: 20px; border-radius: 5px; }
        .stat { display: inline-block; margin: 10px; padding: 10px; background: #007bff; color: white; border-radius: 5px; }
        .action-button { display: inline-block; margin: 10px; padding: 10px 20px; background: #28a745; color: white; border-radius: 5px; cursor: pointer; }
        .action-button:hover { background: #218838; }
    </style>
</head>
<body>
    <div class="header">
        <h1>REAPER OS Community Dashboard</h1>
        <p>Participate in shaping the future of REAPER OS</p>
    </div>
    
    <div class="section">
        <h2>Your Contributions</h2>
        <div class="stat">Bug Reports: <strong id="bugs">0</strong></div>
        <div class="stat">Feature Requests: <strong id="features">0</strong></div>
        <div class="stat">Feedback: <strong id="feedback">0</strong></div>
        <div class="stat">Showcases: <strong id="showcases">0</strong></div>
    </div>
    
    <div class="section">
        <h2>Quick Actions</h2>
        <div class="action-button">Report Bug</div>
        <div class="action-button">Request Feature</div>
        <div class="action-button">Submit Feedback</div>
        <div class="action-button">Share Showcase</div>
    </div>
    
    <div class="section">
        <h2>Recent Community Activity</h2>
        <ul id="activity-list">
            <li>Loading...</li>
        </ul>
    </div>
    
    <script>
        // Load statistics
        document.getElementById('bugs').textContent = '0';
        document.getElementById('features').textContent = '0';
        document.getElementById('feedback').textContent = '0';
        document.getElementById('showcases').textContent = '0';
    </script>
</body>
</html>
EOF
    
    print_success "Dashboard created: $dashboard_file"
    
    # Option to open in browser
    if command -v xdg-open &> /dev/null; then
        read -p "Open dashboard in browser? (y/n): " open_dash
        if [ "$open_dash" = "y" ]; then
            xdg-open "$dashboard_file"
        fi
    fi
}

# Main function
main() {
    local action="${1:-help}"
    
    case "$action" in
        --report-bug)
            report_bug
            ;;
        --feature-request)
            request_feature
            ;;
        --feedback)
            submit_feedback
            ;;
        --showcase)
            submit_showcase
            ;;
        --guidelines)
            show_guidelines
            ;;
        --stats)
            show_stats
            ;;
        --dashboard)
            create_dashboard
            ;;
        *)
            print_header "REAPER OS Community Integration"
            echo "Options:"
            echo "  --report-bug         Report a bug to the community"
            echo "  --feature-request    Request a new feature"
            echo "  --feedback           Submit user feedback"
            echo "  --showcase           Share your setup with community"
            echo "  --guidelines         View community guidelines"
            echo "  --stats              Show community statistics"
            echo "  --dashboard          Open community dashboard"
            echo ""
            echo "GitHub: https://github.com/$GITHUB_REPO"
            echo "Discussions: $DISCUSSIONS_URL"
            ;;
    esac
}

main "$@"
