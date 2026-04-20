# Statusline Build & Distribution Pipeline Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move statusline source into the dotfiles repo, auto-build cross-platform binaries via GitHub Actions, and have chezmoi auto-download the correct binary on every `chezmoi apply`.

**Architecture:** Source lives in `claude/statusline/`, GitHub Actions cross-compiles 4 platform binaries and publishes them to a `statusline-latest` GitHub Release, and `.chezmoiexternal.toml` tells chezmoi to pull the binary to `~/.local/bin/` with a 1-hour refresh period.

**Tech Stack:** Go 1.23 (stdlib only), GitHub Actions, chezmoi external files

---

## File Map

| Action | Path | Responsibility |
|---|---|---|
| Create | `claude/statusline/go.mod` | Go module declaration |
| Create | `claude/statusline/statusline.go` | Statusline source (moved from `~/.claude/statusline.go`) |
| Create | `.github/workflows/release-statusline.yml` | CI: build 4 platforms, publish release |
| Create | `.chezmoiexternal.toml` | chezmoi: auto-download binary on apply |

---

### Task 1: Create Go module

**Files:**
- Create: `claude/statusline/go.mod`

- [ ] **Step 1: Create the directory and go.mod**

```bash
mkdir -p claude/statusline
```

Create `claude/statusline/go.mod` with this exact content:

```
module statusline

go 1.23
```

- [ ] **Step 2: Commit**

```bash
git add claude/statusline/go.mod
git commit -m "feat: add statusline Go module"
```

---

### Task 2: Move statusline source into repo

**Files:**
- Create: `claude/statusline/statusline.go` (copied from `~/.claude/statusline.go`)

- [ ] **Step 1: Copy the source file**

```bash
cp ~/.claude/statusline.go claude/statusline/statusline.go
```

- [ ] **Step 2: Verify it compiles locally (if Go is installed)**

```bash
cd claude/statusline
go build ./...
```

Expected: no output, no errors. An `statusline` or `statusline.exe` binary appears in the directory.

If Go is not installed locally, skip this step — the CI will catch compile errors.

Clean up the local binary after verifying:
```bash
rm -f statusline statusline.exe
```

- [ ] **Step 3: Commit**

```bash
git add claude/statusline/statusline.go
git commit -m "feat: add statusline source to dotfiles repo"
```

---

### Task 3: Create GitHub Actions workflow

**Files:**
- Create: `.github/workflows/release-statusline.yml`

- [ ] **Step 1: Create the workflows directory**

```bash
mkdir -p .github/workflows
```

- [ ] **Step 2: Create the workflow file**

Create `.github/workflows/release-statusline.yml` with this exact content:

```yaml
name: Release statusline

on:
  push:
    branches:
      - main
    paths:
      - 'claude/statusline/**'
  workflow_dispatch:

jobs:
  build:
    name: Build statusline
    runs-on: ubuntu-latest
    permissions:
      contents: write

    strategy:
      matrix:
        include:
          - goos: linux
            goarch: amd64
            artifact: statusline-linux-amd64
          - goos: darwin
            goarch: amd64
            artifact: statusline-darwin-amd64
          - goos: darwin
            goarch: arm64
            artifact: statusline-darwin-arm64
          - goos: windows
            goarch: amd64
            artifact: statusline-windows-amd64.exe

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Set up Go
        uses: actions/setup-go@v5
        with:
          go-version: 'stable'

      - name: Build
        working-directory: claude/statusline
        env:
          GOOS: ${{ matrix.goos }}
          GOARCH: ${{ matrix.goarch }}
          CGO_ENABLED: '0'
        run: |
          VERSION=$(date -u +%Y%m%d)
          go build -trimpath -ldflags="-s -w -X main.Version=${VERSION}" -o ${{ matrix.artifact }} .

      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: ${{ matrix.artifact }}
          path: claude/statusline/${{ matrix.artifact }}

  release:
    name: Publish GitHub Release
    needs: build
    runs-on: ubuntu-latest
    permissions:
      contents: write

    steps:
      - name: Set version
        id: version
        run: |
          echo "date=$(date -u +%Y%m%d)" >> "$GITHUB_OUTPUT"
          echo "short_sha=${GITHUB_SHA::7}" >> "$GITHUB_OUTPUT"

      - name: Download all artifacts
        uses: actions/download-artifact@v4
        with:
          merge-multiple: true
          path: dist/

      - name: Update statusline-latest release
        uses: softprops/action-gh-release@v2
        with:
          tag_name: statusline-latest
          name: statusline-latest (${{ steps.version.outputs.date }}-${{ steps.version.outputs.short_sha }})
          body: Auto-built statusline binaries from commit ${{ github.sha }}.
          prerelease: false
          files: dist/*
          fail_on_unmatched_files: true

      - name: Create versioned release
        uses: softprops/action-gh-release@v2
        with:
          tag_name: statusline-v${{ steps.version.outputs.date }}-${{ steps.version.outputs.short_sha }}
          name: statusline v${{ steps.version.outputs.date }}-${{ steps.version.outputs.short_sha }}
          body: Built from commit ${{ github.sha }}
          prerelease: false
          files: dist/*
          fail_on_unmatched_files: true
```

- [ ] **Step 3: Commit**

```bash
git add .github/workflows/release-statusline.yml
git commit -m "feat: add GitHub Actions workflow to build and release statusline"
```

---

### Task 4: Create .chezmoiexternal.toml

**Files:**
- Create: `.chezmoiexternal.toml`

chezmoi treats this file as a template automatically — no `.tmpl` extension needed.

- [ ] **Step 1: Create the file**

Create `.chezmoiexternal.toml` with this exact content:

```toml
# statusline binary — built by GitHub Actions when claude/statusline/** changes
# chezmoi apply downloads the correct platform binary to ~/.local/bin/

{{ $ext := "" -}}
{{ if eq .chezmoi.os "windows" }}{{ $ext = ".exe" }}{{ end -}}

[".local/bin/statusline{{ $ext }}"]
    type = "file"
    executable = true
    url = "https://github.com/eeeleeeeee/dotfiles/releases/download/statusline-latest/statusline-{{ .chezmoi.os }}-{{ .chezmoi.arch }}{{ $ext }}"
    refreshPeriod = "1h"
```

- [ ] **Step 2: Commit**

```bash
git add .chezmoiexternal.toml
git commit -m "feat: add .chezmoiexternal.toml to auto-download statusline binary"
```

---

### Task 5: Push and verify GitHub Actions

- [ ] **Step 1: Push all commits to GitHub**

```bash
git push origin main
```

- [ ] **Step 2: Verify Actions triggered**

Go to `https://github.com/eeeleeeeee/dotfiles/actions` and confirm a workflow run named "Release statusline" is in progress or completed.

Expected: both `build` and `release` jobs succeed (green checkmarks).

If the build job fails with a compile error, fix `claude/statusline/statusline.go`, commit, and push again.

- [ ] **Step 3: Verify release was created**

Go to `https://github.com/eeeleeeeee/dotfiles/releases` and confirm:
- A release tagged `statusline-latest` exists with 4 files attached:
  - `statusline-linux-amd64`
  - `statusline-darwin-amd64`
  - `statusline-darwin-arm64`
  - `statusline-windows-amd64.exe`
- A versioned release tagged `statusline-v<date>-<sha>` also exists

---

### Task 6: Verify chezmoi downloads the binary

- [ ] **Step 1: Delete the manually-placed binary to test a clean download**

```bash
rm ~/.local/bin/statusline.exe
```

- [ ] **Step 2: Run chezmoi apply**

```bash
chezmoi apply
```

Expected: chezmoi downloads `statusline-windows-amd64.exe` from the `statusline-latest` release and places it at `~/.local/bin/statusline.exe`. No errors.

- [ ] **Step 3: Verify the binary exists and runs**

```bash
~/.local/bin/statusline.exe --version
```

Expected: outputs a date string like `20260420`.

- [ ] **Step 4: Verify idempotency**

Run `chezmoi apply` again immediately:

```bash
chezmoi apply
chezmoi diff
```

Expected: `chezmoi diff` shows no changes (binary is fresh, within 1h TTL).
