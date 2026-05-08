# dotfiles

使用 [chezmoi](https://www.chezmoi.io/) 管理個人設定檔（dotfiles），支援 Windows 11 與 Linux/WSL，共用同一個儲存庫（repository）。

## 檔案對應表

| 來源路徑（儲存庫） | 部署路徑 | 平台 |
|--------------------|----------|------|
| `dot_vimrc` | `~/.vimrc` | Linux |
| `dot_bashrc` | `~/.bashrc` | Linux |
| `dot_zshrc` | `~/.zshrc` | Linux |
| `Documents/PowerShell/Microsoft.PowerShell_profile.ps1` | `~/Documents/PowerShell/...` | Windows |
| `Documents/WindowsPowerShell/Microsoft.PowerShell_profile.ps1` | `~/Documents/WindowsPowerShell/...` | Windows |
| `dot_claude/settings.json` | `~/.claude/settings.json` | 雙平台 |
| `dot_claude/commands/` | `~/.claude/commands/` | 雙平台 |
| `.chezmoiexternal.toml` → `.local/bin/statusline[.exe]` | `~/.local/bin/statusline[.exe]` | 雙平台 |
| `.chezmoiexternal.toml` → `.oh-my-zsh/custom/plugins/*` | `~/.oh-my-zsh/custom/plugins/*` | Linux |

## 自動安裝的工具（透過 `.chezmoiscripts/`）

`chezmoi apply` 會跑下列腳本，依平台分支執行對應指令。WSL 自動跳過 fonts。

| 腳本 | Windows（`.ps1`） | Linux/WSL（`.sh`） |
|------|------------------|---------------------|
| `install-prereqs` | jq、dos2unix（透過 scoop） | jq、curl、unzip、zip、ca-certificates、fontconfig（透過 apt） |
| `install-01-dev-tools` | Temurin 8/11/17/21、Maven、Go、starship、nvm、Node LTS（透過 scoop） | SDKMAN + Temurin 8/11/17/21 + Maven、Go（apt）、nvm + Node LTS、starship |
| `install-02-npm-tools` | claude、codegraph | claude、codegraph |
| `install-03-cli-tools` | 7zip、curl、wget、clink、nexttrace、ffmpeg、yt-dlp | p7zip-full、wget、ffmpeg、zsh、yt-dlp（release）、nexttrace（release） |
| `install-04-shell` | （無） | oh-my-zsh + chsh 改預設 shell |
| `install-05-fonts` | CaskaydiaCove / JetBrainsMono / Noto Nerd Fonts、Noto CJK | JetBrainsMono / CascadiaCode / Noto Nerd Fonts、Noto CJK（**WSL 自動跳過**） |
| `setup-claude-code` | 外掛、jdtls、cygpath/CRLF/BOM 修正 | 外掛、jdtls |
| `setup-nvm-path` | 修 nvm 在 scoop 下的 PATH 問題 | （Linux 不需要） |
| `sync-windows-terminal` | 同步 Windows Terminal `settings.json` | （N/A） |

---

## 初始設定（Setup）

### 安裝 chezmoi

**Windows（PowerShell）：**

先安裝 [Scoop](https://scoop.sh/)（若尚未安裝）：
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
```

再安裝 Git 與 chezmoi：
```powershell
scoop install git chezmoi
```

**Linux/WSL：**
```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin
```

安裝後確認 chezmoi 可以執行：
```powershell
chezmoi --version
```

> Linux 若出現「找不到指令」，將 `~/.local/bin` 加入 PATH：
> ```bash
> echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc && source ~/.bashrc
> ```

### 複製儲存庫（Clone）

**Windows（PowerShell）：**
```powershell
git clone https://github.com/eeeleeeeee/dotfiles.git D:\path\to\dotfiles
```

**Linux/WSL：**
```bash
git clone https://github.com/eeeleeeeee/dotfiles.git ~/dotfiles
```

### 設定 chezmoi 來源目錄（source directory）

在 repo 根目錄執行：

**Windows（PowerShell）：**
```powershell
chezmoi init --source "D:\path\to\dotfiles"
```

**Linux/WSL：**
```bash
chezmoi init --source ~/dotfiles
```

### 部署（Apply）

```powershell
chezmoi diff      # 先預覽變更內容
chezmoi apply -v  # 套用至家目錄（home directory）
```

---

## 日常工作流程（Workflow）

### 修改已追蹤的設定檔

**推薦做法：** 使用 `chezmoi edit` 直接開啟來源檔案進行編輯，儲存後自動套用到家目錄，不需要手動同步。

```bash
chezmoi edit --apply ~/.bashrc
```

編輯完成後，提交（commit）並推送（push）：

```bash
cd ~/你的路徑/dotfiles
git add dot_bashrc
git commit -m "feat: 更新 bashrc"
git push
```

### 從其他機器同步最新變更

一個指令完成拉取（pull）與套用：

```bash
chezmoi update
```

### 將新的設定檔納入管理

```bash
chezmoi add ~/.some-new-config
cd ~/你的路徑/dotfiles
git add .
git commit -m "feat: 新增 some-new-config"
git push
```

### 其他常用指令

```bash
chezmoi diff                        # 預覽所有待套用的變更
chezmoi diff ~/.bashrc              # 預覽特定檔案的變更
chezmoi apply                       # 套用所有變更
chezmoi apply ~/.bashrc             # 套用特定檔案
chezmoi managed                     # 列出所有受管理的檔案
chezmoi ignored                     # 列出被 .chezmoiignore 排除的檔案
chezmoi forget ~/.bashrc            # 停止追蹤某個檔案（不會刪除實際檔案）
chezmoi cd                          # 跳到 source directory
chezmoi archive --output=backup.tar.gz  # 備份所有 managed 檔案
```

### 檔名前綴（權限控制）

| 前綴 | 效果 | 適用情境 |
|------|------|----------|
| `private_` | chmod 600 | 含敏感資料的設定檔 |
| `executable_` | chmod 700 | 可執行腳本 |
| `readonly_` | chmod 400 | 不希望被意外修改的檔案 |

範例：`private_dot_ssh/config` → `~/.ssh/config`（權限 600）

---

## Claude Code Plugin 安裝

```
/plugin marketplace add https://github.com/eeeleeeeee/dotfiles
/plugin install eugene-dotfiles@eugene-dotfiles
```

安裝後會部署 `commands/` 下的所有 slash commands 與 `agents/` 下的所有 agents。
