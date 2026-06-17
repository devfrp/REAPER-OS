#!/bin/bash

################################################################################
# REAPER OS Project Version Control v0.5.0
# Git-based version control for REAPER projects
# Usage: ./project-version-control.sh [--init] [--commit] [--diff]
################################################################################

set -euo pipefail

PROJECTS_DIR="$HOME/Music/REAPER Projects"
GIT_CONFIG="$HOME/.config/REAPER/git-projects"

mkdir -p "$GIT_CONFIG"

# Initialize project git repo
init_project_repo() {
    local project_dir="$1"
    
    if [ ! -d "$project_dir" ]; then
        echo "Error: Project directory not found"
        return 1
    fi
    
    cd "$project_dir"
    
    if [ ! -d ".git" ]; then
        git init
        git config user.name "REAPER OS"
        git config user.email "reaper@localhost"
        
        # Create .gitignore for REAPER
        cat > .gitignore << 'EOF'
*.bak
*.old
*.tmp
.reaper-undo
.reaper-nofocus
project-cache.RProjectCache
*.exe
*.dll
.DS_Store
EOF
        
        git add .gitignore
        git commit -m "Initial commit: Project initialized"
        
        echo "Git repository initialized for: $(basename "$project_dir")"
    else
        echo "Git repository already exists"
    fi
}

# Commit project changes
commit_project() {
    local project_dir="$1"
    local message="${2:-Auto-commit from REAPER OS}"
    
    cd "$project_dir"
    
    if [ ! -d ".git" ]; then
        echo "No git repository found. Initializing..."
        init_project_repo "$project_dir"
    fi
    
    # Stage changes
    git add -A
    
    # Check if there are changes
    if git diff --cached --quiet; then
        echo "No changes to commit"
        return 0
    fi
    
    git commit -m "$message"
    
    echo "Changes committed"
}

# Show file differences
show_diff() {
    local project_dir="$1"
    local file_pattern="${2:-.}"
    
    cd "$project_dir"
    
    git diff "$file_pattern"
}

# List commits
list_commits() {
    local project_dir="$1"
    local limit="${2:-20}"
    
    cd "$project_dir"
    
    echo "Recent commits:"
    echo "==============="
    git log --oneline -n "$limit"
}

# Create version tag
create_version_tag() {
    local project_dir="$1"
    local version="$2"
    local message="${3:-Version $version}"
    
    cd "$project_dir"
    
    git tag -a "v$version" -m "$message"
    
    echo "Version tag created: v$version"
}

# Checkout version
checkout_version() {
    local project_dir="$1"
    local version="$2"
    
    cd "$project_dir"
    
    git checkout "v$version"
    
    echo "Checked out version: $version"
}

# Branch for experimentation
create_experiment_branch() {
    local project_dir="$1"
    local branch_name="$2"
    
    cd "$project_dir"
    
    git checkout -b "experiment/$branch_name"
    
    echo "Experiment branch created: $branch_name"
}

# Merge experimental branch
merge_experiment() {
    local project_dir="$1"
    local branch_name="$2"
    
    cd "$project_dir"
    
    git checkout main 2>/dev/null || git checkout master
    git merge "experiment/$branch_name"
    
    echo "Experiment merged: $branch_name"
}

# Get project stats
project_stats() {
    local project_dir="$1"
    
    cd "$project_dir"
    
    echo "Project Statistics:"
    echo "==================="
    echo "Total commits: $(git log --oneline | wc -l)"
    echo "Total tags: $(git tag | wc -l)"
    echo "Total branches: $(git branch -a | wc -l)"
    echo "Current branch: $(git rev-parse --abbrev-ref HEAD)"
    echo "Repository size: $(du -sh .git | cut -f1)"
}

# Sync with remote
sync_remote() {
    local project_dir="$1"
    local remote="${2:-origin}"
    
    cd "$project_dir"
    
    if git remote | grep -q "^$remote$"; then
        git pull "$remote" main 2>/dev/null || git pull "$remote" master
        git push "$remote" --all
        
        echo "Synced with remote: $remote"
    else
        echo "Remote not configured: $remote"
    fi
}

# Auto-backup to cloud
auto_backup() {
    local project_dir="$1"
    local backup_remote="${2:-backup}"
    
    cd "$project_dir"
    
    # Ensure all changes are committed
    git add -A
    git commit -m "Auto-backup $(date +%Y-%m-%d\ %H:%M:%S)" 2>/dev/null || true
    
    # Push to backup remote
    git push "$backup_remote" --all
    
    echo "Backed up to: $backup_remote"
}

main() {
    case "${1:-help}" in
        --init)
            init_project_repo "${2:-.}"
            ;;
        --commit)
            commit_project "${2:-.}" "${3:-Auto-commit}"
            ;;
        --diff)
            show_diff "${2:-.}" "${3:-.}"
            ;;
        --list)
            list_commits "${2:-.}" "${3:-20}"
            ;;
        --tag)
            create_version_tag "${2:-.}" "$3" "${4:-Version $3}"
            ;;
        --checkout)
            checkout_version "${2:-.}" "$3"
            ;;
        --branch)
            create_experiment_branch "${2:-.}" "$3"
            ;;
        --merge)
            merge_experiment "${2:-.}" "$3"
            ;;
        --stats)
            project_stats "${2:-.}"
            ;;
        --sync)
            sync_remote "${2:-.}" "${3:-origin}"
            ;;
        --backup)
            auto_backup "${2:-.}" "${3:-backup}"
            ;;
        *)
            echo "REAPER OS Project Version Control"
            echo "Usage: project-version-control.sh [OPTIONS] [PROJECT_DIR]"
            echo ""
            echo "Options:"
            echo "  --init PROJECT_DIR     Initialize git repo"
            echo "  --commit PROJECT_DIR   Commit changes"
            echo "  --diff PROJECT_DIR     Show file differences"
            echo "  --list PROJECT_DIR     List recent commits"
            echo "  --tag PROJECT_DIR VERSION  Create version tag"
            echo "  --checkout PROJECT_DIR VERSION  Checkout version"
            echo "  --branch PROJECT_DIR NAME  Create experiment branch"
            echo "  --merge PROJECT_DIR NAME   Merge experiment branch"
            echo "  --stats PROJECT_DIR    Show project statistics"
            echo "  --sync PROJECT_DIR     Sync with remote"
            echo "  --backup PROJECT_DIR   Auto-backup to cloud"
            ;;
    esac
}

main "$@"
