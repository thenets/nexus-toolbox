#!/bin/bash

# Simplified status line for Claude Code with colors
# Format: directory (branch [additions+deletions-]) Model [percentage%]
# Colors: Cyan (dir), Green/Yellow (git), Green/Red (stats), Blue (model), Green/Yellow/Red (context)

# Read JSON input from stdin
input=$(cat)

# Extract Claude Code context
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')
model=$(echo "$input" | jq -r '.model.display_name // "Unknown"')
remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')

# ANSI color codes
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
RESET='\033[0m'

# Format directory - just the directory name (not full path) - CYAN
dir_name=$(basename "$cwd")
dir_display=$(printf "${CYAN}%s${RESET}" "$dir_name")

# Git information
git_info=""
if git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
    # Get branch name
    branch=$(git -C "$cwd" branch --show-current 2>/dev/null || echo "detached")

    # Get unstaged changes count (files)
    unstaged_files=$(git -C "$cwd" diff --name-only 2>/dev/null | wc -l)

    # Get staged changes count
    staged_files=$(git -C "$cwd" diff --cached --name-only 2>/dev/null | wc -l)

    # Determine git color (Green if clean, Yellow if changes)
    git_color="$GREEN"
    if [ "$unstaged_files" -gt 0 ] || [ "$staged_files" -gt 0 ]; then
        git_color="$YELLOW"
    fi

    # Build git status string with colored stats (only if there are changes)
    git_status=""
    if [ "$unstaged_files" -gt 0 ] || [ "$staged_files" -gt 0 ]; then
        # Get additions and deletions separately
        stats=$(git -C "$cwd" diff --numstat 2>/dev/null | awk '{added+=$1; deleted+=$2} END {printf "%d %d", added, deleted}')
        additions=$(echo "$stats" | cut -d' ' -f1)
        deletions=$(echo "$stats" | cut -d' ' -f2)

        # Only show stats if there are actual changes
        if [ "$additions" -gt 0 ] || [ "$deletions" -gt 0 ]; then
            git_status=$(printf " [${GREEN}%s+${RESET}${RED}%s-${RESET}]" "$additions" "$deletions")
        fi
    fi

    git_info=$(printf " (${git_color}%s${RESET}%s)" "$branch" "$git_status")
fi

# Context usage indicator - GREEN/YELLOW/RED based on remaining percentage
context_info=""
if [ -n "$remaining" ]; then
    context_color="$GREEN"
    remaining_int=${remaining%.*}  # Remove decimal if present

    if [ "$remaining_int" -lt 20 ]; then
        context_color="$RED"
    elif [ "$remaining_int" -lt 50 ]; then
        context_color="$YELLOW"
    fi

    context_info=$(printf " [${context_color}%s%%${RESET}]" "$remaining")
fi

# Model name - BLUE (remove "Claude" prefix)
model_clean=$(echo "$model" | sed 's/^Claude //')
model_display=$(printf "${BLUE}%s${RESET}" "$model_clean")

# Build full status line
printf "%s%s %s%s" "$dir_display" "$git_info" "$model_display" "$context_info"