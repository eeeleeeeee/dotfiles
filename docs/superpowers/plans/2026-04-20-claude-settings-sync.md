# Claude Code Settings Sync Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the static `dot_claude/settings.json` with a chezmoi `modify_` script that patches only personal preference fields, leaving Claude Code runtime fields untouched, with cross-platform support.

**Architecture:** A bash `modify_` script (`dot_claude/modify_settings.json.sh.tmpl`) receives the existing `~/.claude/settings.json` via stdin and uses jq to patch preference fields. chezmoi template syntax handles platform differences (Windows `.exe` suffix, `CLAUDE_CODE_GIT_BASH_PATH`). A Linux prereqs script ensures jq is available on non-Windows systems.

**Tech Stack:** chezmoi (modify_ scripts, templates), bash, jq

---

## File Map

| Action | Path | Responsibility |
|---|---|---|
| Delete | `dot_claude/settings.json` | Replaced by modify_ script |
| Create | `dot_claude/modify_settings.json.sh.tmpl` | Patch settings.json on every `chezmoi apply` |
| Create | `.chezmoiscripts/run_onchange_before_install-prereqs.sh.tmpl` | Install jq on Linux before modify_ script runs |

---

### Task 1: Remove static settings.json

**Files:**
- Delete: `dot_claude/settings.json`

chezmoi `modify_` scripts and static files cannot coexist for the same target. We must remove the static file first.

- [ ] **Step 1: Delete the static file**

```bash
cd D:/personal-project/dotfiles
git rm dot_claude/settings.json
```

Expected output:
```
rm 'dot_claude/settings.json'
```

- [ ] **Step 2: Commit**

```bash
git commit -m "chore: remove static dot_claude/settings.json (replaced by modify_ script)"
```

---

### Task 2: Create the modify_ script

**Files:**
- Create: `dot_claude/modify_settings.json.sh.tmpl`

This script is the core of the design. chezmoi renames it: strips `modify_` prefix and `.sh.tmpl` suffix, giving target `~/.claude/settings.json`. It receives the existing file content via stdin, patches it with jq, and writes the result back.

- [ ] **Step 1: Create the file**

Create `dot_claude/modify_settings.json.sh.tmpl` with this exact content:

```bash
#!/usr/bin/env bash
# chezmoi modify_ script — patch Claude Code settings.json
#
# Strategy: patch stable personal preference fields only.
# Leave enabledPlugins, extraKnownMarketplaces, model alone
# (managed by Claude Code runtime).

set -euo pipefail

input="$(cat)"
[ -z "$input" ] && input='{}'

echo "$input" | jq \
  --arg statusline_cmd '{{ .chezmoi.homeDir }}/.local/bin/statusline{{ if eq .chezmoi.os "windows" }}.exe{{ end }}' \
{{- if eq .chezmoi.os "windows" }}
  --arg git_bash '{{ printf "%s/scoop/apps/git/current/bin/bash.exe" .chezmoi.homeDir | replace "/" "\\" }}' \
{{- end }}
  '
    .autoUpdatesChannel = "latest"
    | .tui = "fullscreen"
    | .effortLevel = "medium"
    | .statusLine = {
        type: "command",
        command: $statusline_cmd,
        padding: 0
      }
    | .env = (.env // {})
    | .env.CLAUDE_CODE_NO_FLICKER = "1"
{{- if eq .chezmoi.os "windows" }}
    | .env.CLAUDE_CODE_GIT_BASH_PATH = $git_bash
{{- else }}
    | .env |= del(.CLAUDE_CODE_GIT_BASH_PATH)
{{- end }}
  ' | tr -d '\r'
```

- [ ] **Step 2: Preview what chezmoi will do (dry run)**

```bash
chezmoi diff
```

Expected: shows a diff for `~/.claude/settings.json` adding `effortLevel`, `statusLine`, `env` block while preserving `enabledPlugins` and `extraKnownMarketplaces`.

If it shows the entire file being replaced (not a diff), something is wrong — the static file may not have been removed cleanly. Stop and fix Task 1.

- [ ] **Step 3: Apply**

```bash
chezmoi apply
```

Expected output: no errors.

- [ ] **Step 4: Verify the result**

```bash
jq . ~/.claude/settings.json
```

Expected output must contain all of the following:
```json
{
  "autoUpdatesChannel": "latest",
  "tui": "fullscreen",
  "effortLevel": "medium",
  "statusLine": {
    "type": "command",
    "command": "C:\\Users\\eugene.zheng/.local/bin/statusline.exe",
    "padding": 0
  },
  "env": {
    "CLAUDE_CODE_NO_FLICKER": "1",
    "CLAUDE_CODE_GIT_BASH_PATH": "C:\\Users\\eugene.zheng\\scoop\\apps\\git\\current\\bin\\bash.exe"
  },
  "enabledPlugins": { ... },
  "extraKnownMarketplaces": { ... }
}
```

Verify:
- `enabledPlugins` is still present (not wiped)
- `extraKnownMarketplaces` is still present (not wiped)
- `effortLevel` is `"medium"`
- `statusLine.command` ends with `statusline.exe`
- `env.CLAUDE_CODE_GIT_BASH_PATH` uses backslashes

- [ ] **Step 5: Commit**

```bash
git add dot_claude/modify_settings.json.sh.tmpl
git commit -m "feat: add modify_ script to sync Claude Code settings via chezmoi"
```

---

### Task 3: Add Linux prereqs script

**Files:**
- Create: `.chezmoiscripts/run_onchange_before_install-prereqs.sh.tmpl`

The `modify_` script requires jq. On Windows, jq is already installed by the existing `run_onchange_before_install-prereqs.ps1.tmpl`. On Linux, we need a parallel script. The `run_onchange_before_` prefix ensures this runs before any `modify_` scripts on every chezmoi apply where the file changes.

- [ ] **Step 1: Create the file**

Create `.chezmoiscripts/run_onchange_before_install-prereqs.sh.tmpl` with this exact content:

```bash
{{- if ne .chezmoi.os "windows" -}}
#!/usr/bin/env bash
set -euo pipefail

echo "=== Prerequisites Setup ==="

install_package() {
    local pkg="$1"
    if command -v apt-get &>/dev/null; then
        sudo apt-get install -y "$pkg"
    elif command -v brew &>/dev/null; then
        brew install "$pkg"
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y "$pkg"
    else
        echo "WARNING: Cannot install $pkg automatically. Install it manually." >&2
    fi
}

if ! command -v jq &>/dev/null; then
    echo "[jq] Installing..."
    install_package jq
else
    echo "[jq] already installed, skipping."
fi

echo "=== Prerequisites setup complete. ==="
{{- end }}
```

- [ ] **Step 2: Commit**

```bash
git add .chezmoiscripts/run_onchange_before_install-prereqs.sh.tmpl
git commit -m "feat: add Linux prereqs script to install jq for modify_ scripts"
```

---

## Notes

**statusline binary location:** The modify_ script configures Claude Code to look for the binary at `~/.local/bin/statusline.exe` (Windows) or `~/.local/bin/statusline` (Linux). The binary itself is not managed by this plan — ensure it exists at that path before running Claude Code. The current binary at `~/.claude/statusline.exe` must be copied/moved manually until a separate installation step is added.
