# PowerShell 7 profile  ($PROFILE)  --  analog of the Ubuntu .bashrc
# Tracked by chezmoi (dotfiles-windows). Same shape as .bashrc:
#   - organized, existence-guarded setup (never hard-errors when a tool is missing)
#   - untracked machine-local overrides sourced LAST (~/.config/powershell/profile.local.ps1)
# Keep this fast: it runs on every shell launch. No network, no git calls.

# --- oh-my-posh prompt (powerline-go analog) -------------------------------
# Customize the theme by setting $env:POSH_THEME or overriding in profile.local.ps1.
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    if ($env:POSH_THEME) {
        oh-my-posh init pwsh --config $env:POSH_THEME | Invoke-Expression
    } else {
        oh-my-posh init pwsh | Invoke-Expression
    }
}

# --- PSReadLine: history + prediction (atuin analog) -----------------------
# Ctrl+R reverse search works out of the box. ListView prediction needs PSReadLine 2.2+.
if (Get-Module -ListAvailable -Name PSReadLine) {
    Import-Module PSReadLine
    Set-PSReadLineOption -EditMode Windows
    Set-PSReadLineOption -HistoryNoDuplicates
    Set-PSReadLineOption -HistorySearchCursorMovesToEnd
    try {
        Set-PSReadLineOption -PredictionSource History
        Set-PSReadLineOption -PredictionViewStyle ListView
    } catch {
        # Older PSReadLine without prediction support -- ignore.
    }
    # Up/Down do prefix-aware history search (type a few chars, then Up).
    Set-PSReadLineKeyHandler -Key UpArrow   -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
}

# --- ssh background-tint wrapper (ported from the .bashrc ssh() function) ---
# Tints the terminal background per destination host using OSC 11 (set bg) and
# OSC 111 (reset) -- Windows Terminal supports both. Host->color rules live in the
# untracked ~/.config/ssh-terminal-colors file, format:  <glob_pattern> <hex_color>
# one per line, '#' comments allowed. Escapes are written to the console, not the
# pipeline, so they never pollute command output.
function ssh {
    $defaultColor = '#1a1b26'
    $color        = $null
    $config       = Join-Path $HOME '.config\ssh-terminal-colors'
    $argString    = "$args"

    if (Test-Path $config) {
        foreach ($line in Get-Content -LiteralPath $config) {
            $entry = $line.Trim()
            if ($entry -eq '' -or $entry.StartsWith('#')) { continue }
            $parts = $entry -split '\s+', 2
            if ($parts.Count -lt 2) { continue }
            $pattern, $hex = $parts[0], $parts[1].Trim()
            if ($argString -like $pattern) { $color = $hex; break }
        }
    }
    if (-not $color) { $color = $defaultColor }

    $sshExe = (Get-Command ssh.exe -CommandType Application -ErrorAction SilentlyContinue |
               Select-Object -First 1).Source
    if (-not $sshExe) { Write-Error 'ssh.exe not found on PATH'; return }

    $ESC = [char]27
    $BEL = [char]7
    try {
        # OSC 11 ; <color> BEL  -- set background
        [Console]::Write("$ESC]11;$color$BEL")
        & $sshExe @args
    } finally {
        # OSC 111 BEL  -- reset background to default
        [Console]::Write("$ESC]111$BEL")
    }
}

# --- Maintenance: pull dotfiles + re-apply configuration -------------------
# Analog of "re-running the Ansible playbook". `chezmoi update` does git pull +
# apply, which re-runs the bridge script (and thus setup.dsc.yaml) only when the
# tracked DSC content changed. The untracked local.dsc.yaml is applied explicitly
# here because, being untracked, edits to it never re-trigger the bridge script.
function Update-Machine {
    chezmoi update
    $local = Join-Path $env:USERPROFILE '.config\winget\local.dsc.yaml'
    if (Test-Path $local) {
        winget configure -f $local --accept-configuration-agreements
    }
}

# --- Machine-local overrides (untracked; sourced LAST, like ~/.bashrc.local) ---
$localProfile = Join-Path $HOME '.config\powershell\profile.local.ps1'
if (Test-Path $localProfile) { . $localProfile }
