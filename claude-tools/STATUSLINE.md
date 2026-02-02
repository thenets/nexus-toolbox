# Claude Code Statusline Setup

This document explains how to set up a custom statusline for the DedAssistant project in Claude Code.

## What is the Statusline?

The statusline is a customizable status display in Claude Code that shows relevant project information. It displays:
- Current directory name (in cyan)
- Git branch and change statistics (in green/yellow/red)
- AI model being used (in blue)
- Context window remaining percentage (color-coded)

Example output:
```
zelda-assistant (main [15+3-]) Sonnet 4.5 [75%]
```

## Setup Instructions

### 1. Configure Claude Code Settings

Create or edit your Claude Code settings file at `~/.config/claude-code/settings.json`:

```json
{
  "statusline": {
    "enabled": true,
    "command": "~/.claude/statusline-command.sh"
  }
}
```

**Note**: The path can be absolute or use `~` for your home directory.

### 2. Create the Statusline Script

Create the statusline script at `~/.claude/statusline-command.sh`:

```bash
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
# Note: Use "git -C $cwd" to run git in the directory from JSON input,
# not the script's current working directory
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
```

### 3. Make the Script Executable (CRITICAL)

**This step is required** - without it, the statusline will fail silently and show no git data:

```bash
chmod +x ~/.claude/statusline-command.sh
```

Verify the script is executable:
```bash
ls -la ~/.claude/statusline-command.sh
# Should show: -rwxr-xr-x (the 'x' flags indicate executable)
```

### 4. Install Dependencies

The script requires `jq` for JSON parsing:

```bash
# Fedora/RHEL
sudo dnf install jq

# Debian/Ubuntu
sudo apt install jq

# macOS
brew install jq
```

### 5. Test the Statusline

Test the script manually with sample JSON input:

```bash
echo '{"workspace":{"current_dir":"/home/luiz/projects/zelda-assistant"},"model":{"display_name":"Claude Sonnet 4.5"},"context_window":{"remaining_percentage":75}}' | ~/.claude/statusline-command.sh
```

Expected output (with colors):
```
zelda-assistant (main [15+3-]) Sonnet 4.5 [75%]
```

## How It Works

### JSON Input

Claude Code passes context information to the statusline script as JSON via stdin. The JSON structure includes:

```json
{
  "workspace": {
    "current_dir": "/path/to/project"
  },
  "model": {
    "display_name": "Claude Sonnet 4.5"
  },
  "context_window": {
    "remaining_percentage": 75.5
  }
}
```

### Color Coding

The statusline uses ANSI color codes to provide visual feedback:

- **Cyan**: Directory name
- **Green**: Clean git branch / sufficient context (>50%)
- **Yellow**: Git branch with changes / moderate context (20-50%)
- **Red**: Deletions / low context (<20%)
- **Blue**: Model name

### Git Statistics

The script shows:
- **Branch name**: Current git branch (or "detached" if HEAD is detached)
- **Additions**: Lines added (green, e.g., `15+`)
- **Deletions**: Lines deleted (red, e.g., `3-`)
- **File counts**: Tracked via `unstaged_files` and `staged_files`

### Context Window

The percentage shows how much of Claude's context window is still available:
- **Green (>50%)**: Plenty of context remaining
- **Yellow (20-50%)**: Context getting limited
- **Red (<20%)**: Very little context remaining

## Customization

You can customize the statusline script to show additional information:

### Add Service Status

Add service status indicators after git info:

```bash
# Add after git_info section
service_info=""
if screen -list | grep -q "dedassistant-web" 2>/dev/null; then
    service_info=$(printf " ${GREEN}[web]${RESET}")
fi
if podman ps --format "{{.Names}}" | grep -q "dedassistant-postgres" 2>/dev/null; then
    service_info="${service_info}$(printf " ${GREEN}[db]${RESET}")"
fi

# Update final printf
printf "%s%s%s %s%s" "$dir_display" "$git_info" "$service_info" "$model_display" "$context_info"
```

### Show Untracked Files

Add untracked files count to git status:

```bash
# Add after staged_files
untracked_files=$(git ls-files --others --exclude-standard 2>/dev/null | wc -l)

# Add to git_status (after additions/deletions)
if [ "$untracked_files" -gt 0 ]; then
    git_status="${git_status}$(printf " ${YELLOW}%s?${RESET}" "$untracked_files")"
fi
```

### Show Last Commit Hash

Add the short commit hash to git info:

```bash
# Add after branch
commit_hash=$(git rev-parse --short HEAD 2>/dev/null)
branch_display="$branch@$commit_hash"

# Use branch_display instead of branch in git_info
```

### Customize Model Display

Show only model family (remove version):

```bash
# Replace model_clean line
model_clean=$(echo "$model" | sed 's/^Claude //' | sed 's/ [0-9.]*$//')
```

Or add emoji indicators:

```bash
# Add model emoji based on model name
case "$model_clean" in
    *Opus*)   model_icon="🧠" ;;
    *Sonnet*) model_icon="🎵" ;;
    *Haiku*)  model_icon="🍃" ;;
    *)        model_icon="🤖" ;;
esac
model_display=$(printf "${BLUE}%s %s${RESET}" "$model_icon" "$model_clean")
```

## Advanced Configuration

### Project-Specific Information

Add DedAssistant-specific status indicators:

```bash
# Add after context_info, before final printf

# Check if in project directory
project_info=""
if [[ "$cwd" == *"zelda-assistant"* ]]; then
    # Check web server status
    web_status=""
    if screen -list 2>/dev/null | grep -q "dedassistant-web"; then
        web_status="${GREEN}●${RESET}"
    else
        web_status="${RED}○${RESET}"
    fi

    # Check database status
    db_count=$(podman ps -q --filter "name=dedassistant-postgres" 2>/dev/null | wc -l)
    if [ "$db_count" -eq "2" ]; then
        db_status="${GREEN}●${RESET}"
    else
        db_status="${RED}○${RESET}"
    fi

    project_info=$(printf " [web:%s db:%s]" "$web_status" "$db_status")
fi

# Update final printf
printf "%s%s %s%s%s" "$dir_display" "$git_info" "$model_display" "$context_info" "$project_info"
```

### Environment Detection

Show environment based on configuration:

```bash
# Add environment indicator
env_info=""
if [ -f "$cwd/.env" ]; then
    if grep -q "BEHIND_PROXY=true" "$cwd/.env" 2>/dev/null; then
        env_info=$(printf " ${RED}[PROD]${RESET}")
    else
        env_info=$(printf " ${GREEN}[DEV]${RESET}")
    fi
fi

# Add to final printf
printf "%s%s %s%s%s" "$dir_display" "$git_info" "$model_display" "$context_info" "$env_info"
```

### Performance Optimization

The statusline runs frequently, so optimize expensive operations:

```bash
# Cache git operations if possible
if [ -z "$GIT_BRANCH_CACHE" ] || [ "$(($(date +%s) - GIT_BRANCH_CACHE_TIME))" -gt 5 ]; then
    export GIT_BRANCH_CACHE=$(git branch --show-current 2>/dev/null)
    export GIT_BRANCH_CACHE_TIME=$(date +%s)
fi
branch="$GIT_BRANCH_CACHE"

# Use timeout for slow commands
db_count=$(timeout 0.5s podman ps -q --filter "name=dedassistant-postgres" 2>/dev/null | wc -l || echo "0")
```

## Troubleshooting

### Statusline Not Showing

1. **Check if statusline is enabled in settings:**
   ```bash
   cat ~/.config/claude-code/settings.json
   ```
   Should show:
   ```json
   {
     "statusline": {
       "enabled": true,
       "command": "~/.claude/statusline-command.sh"
     }
   }
   ```

2. **Verify script exists and is executable:**
   ```bash
   ls -la ~/.claude/statusline-command.sh
   ```
   Should show: `-rwxr-xr-x` (executable permissions)

3. **Test script manually with sample input:**
   ```bash
   echo '{"workspace":{"current_dir":"'$(pwd)'"},"model":{"display_name":"Claude Sonnet 4.5"},"context_window":{"remaining_percentage":75}}' | ~/.claude/statusline-command.sh
   ```

### Common Errors

#### "jq: command not found"

Install `jq`:
```bash
# Fedora/RHEL
sudo dnf install jq

# Debian/Ubuntu
sudo apt install jq

# macOS
brew install jq
```

#### "Permission denied" (Most Common Issue)

This is the most frequently encountered problem. The statusline will fail silently and show no git data if the script is not executable.

Make the script executable:
```bash
chmod +x ~/.claude/statusline-command.sh
```

Verify it worked:
```bash
ls -la ~/.claude/statusline-command.sh
# Must show 'x' in permissions: -rwxr-xr-x
```

#### No Colors Showing

Check if your terminal supports colors:
```bash
echo -e "\033[0;32mGreen\033[0m \033[0;31mRed\033[0m"
```

If colors don't show, your terminal may not support ANSI codes. Consider:
- Using a different terminal (iTerm2, GNOME Terminal, Windows Terminal)
- Removing color codes from the script

#### Git Information Not Showing

1. **Check script permissions first** (see "Permission denied" above)

2. **Ensure the script uses `git -C "$cwd"`**: The script receives the working directory via JSON input. All git commands must use `git -C "$cwd"` to run in the correct directory, not the script's execution directory.

3. **Verify the directory is a git repository:**
   ```bash
   git rev-parse --git-dir
   ```

   If not a git repo, initialize one:
   ```bash
   git init
   ```

### Performance Issues

If the statusline updates are slow:

1. **Profile the script** to find slow commands:
   ```bash
   time ~/.claude/statusline-command.sh < sample.json
   ```

2. **Use timeout for slow operations:**
   ```bash
   timeout 0.5s podman ps
   ```

3. **Remove expensive checks** (podman, screen) if not needed

4. **Disable statusline temporarily:**
   ```json
   {
     "statusline": {
       "enabled": false
     }
   }
   ```

## Example Statusline Configurations

### Minimal (Default)

The provided script is already minimal and efficient. It shows:
```
zelda-assistant (main) Sonnet 4.5 [75%]
```

### With Git Statistics

Shows line additions/deletions when there are changes:
```
zelda-assistant (main [15+3-]) Sonnet 4.5 [75%]
```

### With Service Status

Full-featured version for DedAssistant with service monitoring:

```bash
#!/bin/bash

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

# Directory
dir_name=$(basename "$cwd")
dir_display=$(printf "${CYAN}%s${RESET}" "$dir_name")

# Git information (same as before)
git_info=""
if git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
    branch=$(git -C "$cwd" branch --show-current 2>/dev/null || echo "detached")
    unstaged_files=$(git -C "$cwd" diff --name-only 2>/dev/null | wc -l)
    staged_files=$(git -C "$cwd" diff --cached --name-only 2>/dev/null | wc -l)

    git_color="$GREEN"
    if [ "$unstaged_files" -gt 0 ] || [ "$staged_files" -gt 0 ]; then
        git_color="$YELLOW"
    fi

    git_status=""
    if [ "$unstaged_files" -gt 0 ] || [ "$staged_files" -gt 0 ]; then
        stats=$(git -C "$cwd" diff --numstat 2>/dev/null | awk '{added+=$1; deleted+=$2} END {printf "%d %d", added, deleted}')
        additions=$(echo "$stats" | cut -d' ' -f1)
        deletions=$(echo "$stats" | cut -d' ' -f2)

        if [ "$additions" -gt 0 ] || [ "$deletions" -gt 0 ]; then
            git_status=$(printf " [${GREEN}%s+${RESET}${RED}%s-${RESET}]" "$additions" "$deletions")
        fi
    fi

    git_info=$(printf " (${git_color}%s${RESET}%s)" "$branch" "$git_status")
fi

# Service status (DedAssistant-specific)
service_info=""
if [[ "$cwd" == *"zelda-assistant"* ]]; then
    web_status="${RED}○${RESET}"
    if timeout 0.5s screen -list 2>/dev/null | grep -q "dedassistant-web"; then
        web_status="${GREEN}●${RESET}"
    fi

    db_count=$(timeout 0.5s podman ps -q --filter "name=dedassistant-postgres" 2>/dev/null | wc -l || echo "0")
    db_status="${RED}○${RESET}"
    if [ "$db_count" -eq "2" ]; then
        db_status="${GREEN}●${RESET}"
    fi

    service_info=$(printf " [w:%s d:%s]" "$web_status" "$db_status")
fi

# Model
model_clean=$(echo "$model" | sed 's/^Claude //')
model_display=$(printf "${BLUE}%s${RESET}" "$model_clean")

# Context
context_info=""
if [ -n "$remaining" ]; then
    context_color="$GREEN"
    remaining_int=${remaining%.*}

    if [ "$remaining_int" -lt 20 ]; then
        context_color="$RED"
    elif [ "$remaining_int" -lt 50 ]; then
        context_color="$YELLOW"
    fi

    context_info=$(printf " [${context_color}%s%%${RESET}]" "$remaining")
fi

# Build full status line
printf "%s%s %s%s%s" "$dir_display" "$git_info" "$model_display" "$context_info" "$service_info"
```

Output example:
```
zelda-assistant (main [15+3-]) Sonnet 4.5 [75%] [w:● d:●]
```

Where:
- `w:●` = Web server running (green dot)
- `d:●` = Database running (green dot)
- `w:○` = Web server stopped (red dot)
- `d:○` = Database stopped (red dot)

## JSON Input Reference

Claude Code provides the following JSON structure to the statusline script:

```json
{
  "workspace": {
    "current_dir": "/absolute/path/to/project"
  },
  "model": {
    "display_name": "Claude Sonnet 4.5",
    "id": "claude-sonnet-4-5-20250929"
  },
  "context_window": {
    "remaining_percentage": 75.5,
    "used": 50000,
    "total": 200000
  }
}
```

### Available Fields

Extract these using `jq`:

```bash
# Working directory
cwd=$(echo "$input" | jq -r '.workspace.current_dir')

# Model information
model=$(echo "$input" | jq -r '.model.display_name')
model_id=$(echo "$input" | jq -r '.model.id')

# Context window
remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage')
used=$(echo "$input" | jq -r '.context_window.used')
total=$(echo "$input" | jq -r '.context_window.total')
```

## Common Pitfalls

These are frequently encountered issues when setting up the statusline:

| Problem | Symptom | Solution |
|---------|---------|----------|
| Script not executable | Statusline shows no git data, fails silently | Run `chmod +x ~/.claude/statusline-command.sh` |
| Missing `git -C "$cwd"` | Git info shows wrong repo or nothing | Use `git -C "$cwd"` for all git commands |
| Missing `jq` | Script fails completely | Install jq: `sudo dnf install jq` |
| Wrong JSON path | Empty values in output | Check JSON structure with `jq` debugging |

## Tips and Best Practices

1. **Keep it fast**: Statusline runs frequently, avoid slow operations
2. **Use timeouts**: Wrap potentially slow commands (podman, screen) with `timeout`
3. **Cache when possible**: Cache expensive git operations with timestamps
4. **Test with real JSON**: Use actual Claude Code JSON structure for testing
5. **Color carefully**: Not all terminals support ANSI colors
6. **Handle errors**: Use fallbacks for missing commands or data
7. **Be minimal**: Show only essential information to avoid clutter
8. **Always use `git -C "$cwd"`**: The script runs outside the project directory; use `-C` flag to target the correct repo

## References

- [Claude Code Documentation](https://github.com/anthropics/claude-code)
- [jq Manual](https://jqlang.github.io/jq/manual/)
- [ANSI Color Codes](https://en.wikipedia.org/wiki/ANSI_escape_code#Colors)
- Project Structure: `CLAUDE.md`
- Service Management: `Makefile`

---

**Last Updated**: 2026-01-23
**Script Location**: `~/.claude/statusline-command.sh`
**Settings Location**: `~/.config/claude-code/settings.json`
