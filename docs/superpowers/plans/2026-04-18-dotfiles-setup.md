# Dotfiles with chezmoi — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Set up a public GitHub repo using chezmoi to manage dotfiles across Windows 11 and Linux/WSL.

**Architecture:** The repo root is the chezmoi source directory. `.chezmoiignore` handles all platform branching using minimal template syntax. All config files themselves are plain text.

**Tech Stack:** chezmoi, Git, GitHub, Bash (Linux), PowerShell (Windows)

> **Spec correction:** Claude Code settings live at `~/.claude/settings.json`, not `~/.config/claude/`. The source path in chezmoi is `dot_claude/settings.json`. Also, Claude Code does not auto-layer multiple settings files, so we start with one shared `settings.json` and add platform-specific handling only if needed later (YAGNI).

---

## File Map

| Source path (repo) | Deployed path | Platform |
|--------------------|---------------|----------|
| `.chezmoiignore` | (chezmoi internal) | both |
| `dot_vimrc` | `~/.vimrc` | Linux |
| `dot_bashrc` | `~/.bashrc` | Linux |
| `dot_zshrc` | `~/.zshrc` | Linux |
| `Documents/PowerShell/Microsoft.PowerShell_profile.ps1` | `~/Documents/PowerShell/Microsoft.PowerShell_profile.ps1` | Windows |
| `dot_claude/settings.json` | `~/.claude/settings.json` | both |
| `dot_claude/commands/` | `~/.claude/commands/` | both |

---

## Task 1: Install chezmoi on Windows

**Files:** none

- [ ] **Step 1: Install via winget**

```powershell
winget install twpayne.chezmoi
```

- [ ] **Step 2: Verify installation**

```powershell
chezmoi --version
```

Expected output: `chezmoi version vX.X.X, ...`

---

## Task 2: Configure chezmoi to use our repo as source directory

chezmoi 預設 source 在 `~/.local/share/chezmoi`。我們讓它指向 repo 所在目錄。
規則：**有指定路徑就用指定路徑，沒指定就用當前目錄。**

**Files:**
- Create: `~/.config/chezmoi/chezmoi.toml`（由 chezmoi init 自動生成）

### Windows（PowerShell，在 repo 目錄內執行）

- [ ] **Step 1: 進入 repo 目錄**

```powershell
cd <你 clone 的路徑>   # 例如 cd D:/personal-project/dotfiles
```

- [ ] **Step 2: 初始化 chezmoi（使用指定路徑，或用當前目錄）**

```powershell
# 有指定路徑：
chezmoi init --source "D:/personal-project/dotfiles"

# 沒有指定，使用當前目錄：
chezmoi init --source (Get-Location).Path
```

chezmoi 會自動建立 `~/.config/chezmoi/chezmoi.toml` 並寫入 sourceDir，不需要手動建立。

- [ ] **Step 3: 確認 chezmoi 認得 source dir**

```powershell
chezmoi source-path
```

Expected output: 你剛才指定（或當前）的路徑。

---

## Task 3: Initialize Git repo

**Files:**
- Create: `D:/personal-project/dotfiles/.gitignore`

- [ ] **Step 1: 進入專案目錄並初始化 git**

```powershell
cd D:/personal-project/dotfiles
git init
```

- [ ] **Step 2: 建立 .gitignore**

```
# OS
.DS_Store
Thumbs.db

# Secrets — never commit these
.env
*.secret
*.key
*_token

# chezmoi cache
.chezmoistate.boltdb
```

存到 `D:/personal-project/dotfiles/.gitignore`。

- [ ] **Step 3: 第一次 commit**

```bash
git add .gitignore
git commit -m "chore: init repo with .gitignore"
```

---

## Task 4: 建立 .chezmoiignore

這個檔案控制哪些平台忽略哪些檔案。

**Files:**
- Create: `D:/personal-project/dotfiles/.chezmoiignore`

- [ ] **Step 1: 建立 .chezmoiignore**

```
{{ if ne .chezmoi.os "linux" }}
dot_vimrc
dot_bashrc
dot_zshrc
dot_claude/settings.linux.json
{{ end }}

{{ if ne .chezmoi.os "windows" }}
Documents/**
dot_claude/settings.windows.json
{{ end }}

# Never deploy docs folder
docs/**
```

- [ ] **Step 2: 確認 chezmoi 能解析此檔案（無語法錯誤）**

```powershell
chezmoi ignored
```

Expected: 列出被忽略的路徑，無錯誤訊息。

- [ ] **Step 3: Commit**

```bash
git add .chezmoiignore
git commit -m "chore: add .chezmoiignore for platform isolation"
```

---

## Task 5: 納入 Linux dotfiles（Vim、Bash、Zsh）

這些檔案在 WSL/Linux 環境存在就用 `chezmoi add` 匯入，否則建立最小內容。

**Files:**
- Create: `D:/personal-project/dotfiles/dot_vimrc`
- Create: `D:/personal-project/dotfiles/dot_bashrc`
- Create: `D:/personal-project/dotfiles/dot_zshrc`

**注意：** 這個任務在 WSL/Linux 環境執行效果最佳（因為這些檔案在 Linux home 目錄）。如果在 Windows 執行，手動建立佔位檔案即可，之後在 Linux 再用 `chezmoi add` 覆蓋。

### 情況 A：在 WSL/Linux 執行

- [ ] **Step 1: 在 Linux 安裝 chezmoi**

```bash
sh -c "$(curl -fsLS get.chezmoi.io)"
```

- [ ] **Step 2: 設定 Linux 的 chezmoi source（指向 clone 下來的 repo）**

```bash
mkdir -p ~/.config/chezmoi
cat > ~/.config/chezmoi/chezmoi.toml << 'EOF'
[chezmoi]
    sourceDir = "/path/to/your/cloned/dotfiles"
EOF
```

將 `/path/to/your/cloned/dotfiles` 替換為實際路徑（例如 `~/dotfiles`）。

- [ ] **Step 3: 匯入現有 dotfiles（如果存在）**

```bash
# 如果 ~/.vimrc 存在
chezmoi add ~/.vimrc

# 如果 ~/.bashrc 存在
chezmoi add ~/.bashrc

# 如果 ~/.zshrc 存在
chezmoi add ~/.zshrc
```

### 情況 B：在 Windows 先建立佔位檔案

- [ ] **Step 1: 建立最小內容的 dot_vimrc**

```
" Vim configuration
set number
set expandtab
set tabstop=4
set shiftwidth=4
```

存到 `D:/personal-project/dotfiles/dot_vimrc`。

- [ ] **Step 2: 建立最小內容的 dot_bashrc**

```bash
# ~/.bashrc

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

export EDITOR=vim
```

存到 `D:/personal-project/dotfiles/dot_bashrc`。

- [ ] **Step 3: 建立最小內容的 dot_zshrc**

```zsh
# ~/.zshrc

export EDITOR=vim
```

存到 `D:/personal-project/dotfiles/dot_zshrc`。

- [ ] **Step 4: Commit**

```bash
git add dot_vimrc dot_bashrc dot_zshrc
git commit -m "feat: add Linux dotfiles (vim, bash, zsh)"
```

---

## Task 6: 納入 Windows PowerShell profile

**Files:**
- Create: `D:/personal-project/dotfiles/Documents/PowerShell/Microsoft.PowerShell_profile.ps1`

- [ ] **Step 1: 確認現有 PowerShell profile 位置**

```powershell
echo $PROFILE
```

Expected output: `C:\Users\<username>\Documents\PowerShell\Microsoft.PowerShell_profile.ps1`

- [ ] **Step 2: 如果 profile 已存在，用 chezmoi add 匯入**

```powershell
chezmoi add $PROFILE
```

如果 profile 不存在，建立 `D:/personal-project/dotfiles/Documents/PowerShell/Microsoft.PowerShell_profile.ps1`：

```powershell
# PowerShell Profile

# Useful aliases
Set-Alias -Name vim -Value nvim -ErrorAction SilentlyContinue
```

- [ ] **Step 3: 確認 chezmoi 能看到此檔案**

```powershell
chezmoi managed
```

Expected: 列表中出現 PowerShell profile 路徑。

- [ ] **Step 4: Commit**

```bash
git add "Documents/PowerShell/Microsoft.PowerShell_profile.ps1"
git commit -m "feat: add Windows PowerShell profile"
```

---

## Task 7: 納入 Claude Code settings

**Files:**
- Create: `D:/personal-project/dotfiles/dot_claude/settings.json`

- [ ] **Step 1: 確認現有 Claude Code settings 位置**

```powershell
ls "$env:USERPROFILE\.claude\settings.json"
```

- [ ] **Step 2: 如果 settings.json 已存在，用 chezmoi add 匯入**

```powershell
chezmoi add "$env:USERPROFILE\.claude\settings.json"
```

如果不存在，先建立 `D:/personal-project/dotfiles/dot_claude/settings.json`：

```json
{
  "theme": "dark"
}
```

（之後再補充實際設定。）

- [ ] **Step 3: 安全性確認——開啟檔案，移除任何 API key 或 token**

```powershell
chezmoi edit "$env:USERPROFILE\.claude\settings.json"
```

確認沒有 `apiKey`、`token`、`secret` 等欄位。

- [ ] **Step 4: Commit**

```bash
git add dot_claude/settings.json
git commit -m "feat: add Claude Code shared settings"
```

---

## Task 8: 納入 Claude Code commands

**Files:**
- Create: `D:/personal-project/dotfiles/dot_claude/commands/` 目錄

- [ ] **Step 1: 確認現有 commands 位置**

```powershell
ls "$env:USERPROFILE\.claude\commands"
```

- [ ] **Step 2: 如果 commands 目錄有內容，逐一用 chezmoi add 匯入**

```powershell
# 範例（針對每個 .md 檔案）
chezmoi add "$env:USERPROFILE\.claude\commands\my-command.md"
```

如果目錄是空的，建立一個 `.gitkeep` 佔位：

```powershell
New-Item -ItemType Directory -Force "D:/personal-project/dotfiles/dot_claude/commands"
New-Item -ItemType File "D:/personal-project/dotfiles/dot_claude/commands/.gitkeep"
```

- [ ] **Step 3: Commit**

```bash
git add dot_claude/
git commit -m "feat: add Claude Code commands"
```

---

## Task 9: 在 Windows 驗證 chezmoi apply

Apply 之前**一定先看 diff**，確認要部署的內容符合預期。

- [ ] **Step 1: 查看 diff（不實際套用）**

```powershell
chezmoi diff
```

預期：只顯示 Windows 相關檔案（PowerShell profile、Claude settings），不顯示 dot_vimrc、dot_bashrc、dot_zshrc（因為被 .chezmoiignore 排除）。

- [ ] **Step 2: 確認 .chezmoiignore 正確排除 Linux 檔案**

```powershell
chezmoi ignored
```

預期：`dot_vimrc`、`dot_bashrc`、`dot_zshrc` 出現在忽略清單中。

- [ ] **Step 3: 套用（verbose 模式看詳細過程）**

```powershell
chezmoi apply -v
```

- [ ] **Step 4: 確認檔案已正確部署**

```powershell
ls "$env:USERPROFILE\.claude\settings.json"
ls "$env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
```

---

## Task 10: 推送到 GitHub

- [ ] **Step 1: 在 GitHub 建立新的 public repo**

前往 https://github.com/new，建立名為 `dotfiles` 的 public repo，**不要**勾選 Initialize with README。

- [ ] **Step 2: 連結遠端並推送**

```bash
git remote add origin https://github.com/<your-username>/dotfiles.git
git branch -M main
git push -u origin main
```

- [ ] **Step 3: 確認 GitHub 頁面上沒有敏感資訊**

瀏覽器開啟 repo 頁面，逐一確認：
- `dot_claude/settings.json` — 無 API key 或 token
- `Documents/PowerShell/Microsoft.PowerShell_profile.ps1` — 無密碼或私人路徑

---

## Task 11: 在 Linux/WSL 設定 chezmoi

- [ ] **Step 1: 在 WSL 安裝 chezmoi（如尚未安裝）**

```bash
sh -c "$(curl -fsLS get.chezmoi.io)"
```

- [ ] **Step 2: Clone repo 到偏好的路徑**

```bash
# 有指定路徑：
git clone https://github.com/<your-username>/dotfiles.git <你偏好的路徑>
# 例如：git clone ... ~/dotfiles

# 沒有偏好，用預設：
git clone https://github.com/<your-username>/dotfiles.git
cd dotfiles
```

- [ ] **Step 3: 設定 chezmoi source（使用指定路徑，或用當前目錄）**

```bash
# 有指定路徑：
chezmoi init --source ~/dotfiles

# 沒有指定，使用當前目錄（先 cd 進 repo）：
cd <clone 的路徑>
chezmoi init --source "$(pwd)"
```

chezmoi 會自動建立 `~/.config/chezmoi/chezmoi.toml`，不需要手動編輯。

- [ ] **Step 4: 查看 diff（確認 Linux 檔案會被部署，Windows 不會）**

```bash
chezmoi diff
```

預期：顯示 `~/.vimrc`、`~/.bashrc`、`~/.zshrc`、`~/.claude/settings.json`，不顯示 `Documents/PowerShell/...`。

- [ ] **Step 5: 套用**

```bash
chezmoi apply -v
```

- [ ] **Step 6: 確認檔案已部署**

```bash
ls ~/.vimrc ~/.bashrc ~/.zshrc ~/.claude/settings.json
```

---

## 日常工作流程速查

```bash
# 拉取最新並套用
chezmoi update

# 查看差異
chezmoi diff
chezmoi diff ~/.vimrc

# 套用全部 / 特定檔案
chezmoi apply
chezmoi apply ~/.vimrc

# 編輯並立即套用
chezmoi edit --apply ~/.vimrc

# 納入新的設定檔
chezmoi add ~/.some-new-config

# 查看管理中的檔案
chezmoi managed
```
