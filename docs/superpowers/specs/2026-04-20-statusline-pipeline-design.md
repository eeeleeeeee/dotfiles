# Statusline Build & Distribution Pipeline Design

**Date:** 2026-04-20
**Status:** Approved

## Goal

Move `statusline.go` into the dotfiles repo, auto-build cross-platform binaries via GitHub Actions, and distribute them to all machines automatically via chezmoi on every `chezmoi apply`.

## Architecture

```
claude/statusline/statusline.go  →  GitHub Actions  →  GitHub Release (statusline-latest)
                                                              ↓
                                               .chezmoiexternal.toml
                                                              ↓
                                          ~/.local/bin/statusline[.exe]
```

## File Changes

| Action | Path | Responsibility |
|---|---|---|
| Create | `claude/statusline/statusline.go` | Source code (moved from `~/.claude/statusline.go`) |
| Create | `claude/statusline/go.mod` | Go module declaration |
| Create | `.github/workflows/release-statusline.yml` | CI: build 4 platforms, publish GitHub Release |
| Create | `.chezmoiexternal.toml` | chezmoi: auto-download binary on apply |

## Go Module

`claude/statusline/go.mod`:
```
module statusline

go 1.23
```

No third-party dependencies — standard library only.

## GitHub Actions

**Trigger:** push to `main` with changes in `claude/statusline/**`, or manual dispatch.

**Build matrix (4 platforms):**

| Artifact | GOOS | GOARCH |
|---|---|---|
| `statusline-linux-amd64` | linux | amd64 |
| `statusline-darwin-amd64` | darwin | amd64 |
| `statusline-darwin-arm64` | darwin | arm64 |
| `statusline-windows-amd64.exe` | windows | amd64 |

Build flags: `-trimpath -ldflags="-s -w -X main.Version=<YYYYMMDD>"`

**Releases:**
- `statusline-latest` — updated on every build; chezmoi downloads from this tag
- `statusline-v<YYYYMMDD>-<sha7>` — immutable versioned snapshot for rollback

## `.chezmoiexternal.toml`

```toml
{{ $ext := "" -}}
{{ if eq .chezmoi.os "windows" }}{{ $ext = ".exe" }}{{ end -}}

[".local/bin/statusline{{ $ext }}"]
    type = "file"
    executable = true
    url = "https://github.com/eeeleeeeee/dotfiles/releases/download/statusline-latest/statusline-{{ .chezmoi.os }}-{{ .chezmoi.arch }}{{ $ext }}"
    refreshPeriod = "1h"
```

`refreshPeriod = "1h"`: chezmoi re-downloads at most once per hour, avoiding redundant GitHub API calls on every apply.

## End-to-End Flow

1. Edit `claude/statusline/statusline.go` and push to `main`
2. GitHub Actions triggers, cross-compiles 4 binaries, updates `statusline-latest` release
3. On any machine: `chezmoi apply` → detects 1h TTL expired → downloads new binary to `~/.local/bin/statusline[.exe]`
4. Restart Claude Code → updated statusline active

## Execution Units (5–10 min each)

1. Create `claude/statusline/go.mod`
2. Move `statusline.go` into `claude/statusline/statusline.go`
3. Create `.github/workflows/release-statusline.yml`
4. Create `.chezmoiexternal.toml`
5. Push to GitHub, verify Actions run and release is created
6. Run `chezmoi apply`, verify binary downloaded to `~/.local/bin/`
