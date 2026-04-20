# Claude Code Settings Sync Design

**Date:** 2026-04-20
**Status:** Approved

## Goal

Sync personal Claude Code preferences across devices via chezmoi, without overwriting fields that Claude Code runtime manages itself.

## Approach: `modify_` Script

Replace the static `dot_claude/settings.json` with a chezmoi `modify_` script (`dot_claude/modify_settings.json.sh.tmpl`).

**How `modify_` works:**
1. chezmoi pipes the existing `~/.claude/settings.json` into the script via stdin
2. The script uses `jq` to patch only the specified preference fields
3. The patched output (stdout) is written back to `~/.claude/settings.json`

This ensures runtime-managed fields (`enabledPlugins`, `extraKnownMarketplaces`, `model`) are never overwritten.

## File Changes

### Deleted
- `dot_claude/settings.json` — replaced by the modify_ script

### Added
- `dot_claude/modify_settings.json.sh.tmpl` — patches preference fields
- `.chezmoiscripts/run_onchange_before_install-prereqs.sh.tmpl` — installs jq on Linux

## Settings Managed by the Script

| Field | Value | Platform |
|---|---|---|
| `statusLine` | `type: command`, binary at `~/.local/bin/statusline[.exe]`, `padding: 0` | cross-platform |
| `autoUpdatesChannel` | `"latest"` | cross-platform |
| `tui` | `"fullscreen"` | cross-platform |
| `effortLevel` | `"medium"` | cross-platform |
| `env.CLAUDE_CODE_NO_FLICKER` | `"1"` | cross-platform |
| `env.CLAUDE_CODE_GIT_BASH_PATH` | `~/scoop/apps/git/current/bin/bash.exe` | Windows only |

## Settings Left Alone (Runtime-managed)

- `enabledPlugins`
- `extraKnownMarketplaces`
- `model`

## Cross-platform Handling

The script uses chezmoi template syntax to handle platform differences:

- **statusLine command path:** appends `.exe` on Windows, nothing on Linux
- **`CLAUDE_CODE_GIT_BASH_PATH`:** written only on Windows; deleted from env on Linux if present
- **Line endings:** `tr -d '\r'` strips CRLF from jq output on Windows to prevent chezmoi false diffs

## Bootstrap (New Machine)

If `~/.claude/settings.json` does not exist yet, stdin will be empty. The script starts from `{}` in that case:

```bash
input="$(cat)"
[ -z "$input" ] && input='{}'
```

## Prerequisites

| Tool | Windows | Linux |
|---|---|---|
| `jq` | already installed via `run_onchange_before_install-prereqs.ps1.tmpl` | installed via new `run_onchange_before_install-prereqs.sh.tmpl` |
| `bash` | Git Bash via scoop; configured in `chezmoi.toml` `[interpreters.sh]` | native |

## Execution Units (5–10 min each)

1. **Delete `dot_claude/settings.json`** from the repo
2. **Write `dot_claude/modify_settings.json.sh.tmpl`** — the jq patch script
3. **Write `.chezmoiscripts/run_onchange_before_install-prereqs.sh.tmpl`** — Linux prereqs (jq)
4. **Test on Windows** — run `chezmoi apply` and verify `~/.claude/settings.json`
