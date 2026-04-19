# dotfiles

使用 [chezmoi](https://www.chezmoi.io/) 管理個人設定檔（dotfiles），支援 Windows 11 與 Linux/WSL，共用同一個儲存庫（repository）。

## 檔案對應表

| 來源路徑（儲存庫） | 部署路徑 | 平台 |
|--------------------|----------|------|
| `dot_vimrc` | `~/.vimrc` | Linux |
| `dot_bashrc` | `~/.bashrc` | Linux |
| `dot_zshrc` | `~/.zshrc` | Linux |
| `Documents/WindowsPowerShell/Microsoft.PowerShell_profile.ps1` | `~/Documents/WindowsPowerShell/Microsoft.PowerShell_profile.ps1` | Windows |
| `dot_claude/settings.json` | `~/.claude/settings.json` | 雙平台 |
| `dot_claude/commands/` | `~/.claude/commands/` | 雙平台 |

---

## 初始設定（Setup）

### 安裝 chezmoi

**Windows（PowerShell）：**

先安裝 [Scoop](https://scoop.sh/)（若尚未安裝）：
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
```

再安裝 chezmoi：
```powershell
scoop install chezmoi
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
git clone https://github.com/eeeleeeeee/dotfiles.git C:\path\to\dotfiles
```

**Linux/WSL：**
```bash
git clone https://github.com/eeeleeeeee/dotfiles.git ~/dotfiles
```

### 設定 chezmoi 來源目錄（source directory）

> **重要：** Windows 上所有 chezmoi 指令都必須在 **PowerShell** 執行，不可在 Git Bash 或 WSL 中執行，否則 config 會寫入錯誤路徑。

**Windows（PowerShell）：**
```powershell
chezmoi init --source "C:\path\to\dotfiles"
```

chezmoi 會自動建立 `%APPDATA%\chezmoi\chezmoi.toml`，指向你的儲存庫。

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
chezmoi diff               # 預覽所有待套用的變更
chezmoi diff ~/.bashrc     # 預覽特定檔案的變更
chezmoi apply              # 套用所有變更
chezmoi apply ~/.bashrc    # 套用特定檔案
chezmoi managed            # 列出所有受管理的檔案
chezmoi ignored            # 列出被 .chezmoiignore 排除的檔案
```
