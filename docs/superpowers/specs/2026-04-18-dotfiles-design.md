# Dotfiles Management with chezmoi — Design Doc

**Date:** 2026-04-18  
**Status:** Approved

---

## Overview

A single Git repository (public on GitHub) that uses chezmoi to manage dotfiles across Windows 11 and Linux/WSL. Platform differences are handled via `.chezmoiignore`, keeping all config files as plain text with no template syntax.

---

## Scope

| Config File | Platform |
|-------------|----------|
| Vim (`~/.vimrc`) | Linux/WSL only |
| Bash (`~/.bashrc`) | Linux/WSL only |
| Zsh (`~/.zshrc`) | Linux/WSL only |
| PowerShell profile | Windows only |
| Claude Code `settings.json` | Both (shared + platform diff) |
| Claude Code commands | Both (shared) |

---

## Directory Structure

```
dotfiles/                                      # Git repo root
├── README.md
├── .gitignore
├── docs/
│   └── superpowers/
│       └── specs/
│
└── (chezmoi source root — repo root itself)
    ├── .chezmoiignore
    ├── dot_vimrc                              # → ~/.vimrc (Linux)
    ├── dot_bashrc                             # → ~/.bashrc (Linux)
    ├── dot_zshrc                              # → ~/.zshrc (Linux)
    ├── Documents/                             # → ~/Documents/ (Windows)
    │   └── PowerShell/
    │       └── Microsoft.PowerShell_profile.ps1
    └── dot_config/
        └── claude/
            ├── settings.json                  # shared Claude Code settings
            ├── settings.linux.json            # Linux-specific overrides
            ├── settings.windows.json          # Windows-specific overrides
            └── commands/                      # shared Claude Code commands
```

---

## Platform Isolation via `.chezmoiignore`

```
{{ if ne .chezmoi.os "linux" }}
dot_vimrc
dot_bashrc
dot_zshrc
dot_config/claude/settings.linux.json
{{ end }}

{{ if ne .chezmoi.os "windows" }}
Documents/**
dot_config/claude/settings.windows.json
{{ end }}
```

All platform branching is centralized in this one file. All other config files are plain text.

---

## Claude Code Settings Strategy

- `settings.json` — shared settings applied on both platforms
- `settings.linux.json` — Linux-specific additions (e.g., Linux paths, WSL-specific tools)
- `settings.windows.json` — Windows-specific additions (e.g., Windows paths, PowerShell integration)

chezmoi applies the relevant file per platform; Claude Code layers them.

---

## Daily Workflow

```bash
# Pull latest and apply
chezmoi update

# Preview changes before applying
chezmoi diff
chezmoi diff ~/.vimrc

# Apply
chezmoi apply
chezmoi apply ~/.vimrc
chezmoi apply -v

# Edit a tracked file
chezmoi edit ~/.vimrc
chezmoi edit --apply ~/.vimrc

# Add an existing file to management
chezmoi add ~/.vimrc

# List all managed files
chezmoi managed
```

---

## Security (Public Repo)

| Risk | Mitigation |
|------|-----------|
| API keys / tokens | Never commit; use chezmoi secret or env vars |
| Personal paths | Use `{{ .chezmoi.homeDir }}` in template files if needed |
| Private aliases or company info | Exclude via `.chezmoiignore` or keep in a separate private repo |
| `.env` files | Add to `.gitignore` |

---

## Success Criteria

- `chezmoi apply` on Linux deploys Vim, Bash, Zsh, and Claude Code configs correctly
- `chezmoi apply` on Windows deploys PowerShell profile and Claude Code configs correctly
- No sensitive information in Git history
- Daily workflow (diff, apply, sync) works smoothly on both platforms
