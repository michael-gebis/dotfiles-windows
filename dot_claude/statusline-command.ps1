#!/usr/bin/env pwsh
# Claude Code status line -- native PowerShell port of the bash version in the
# dotfiles repo (.claude/statusline-command.sh). Reads Claude's JSON on stdin
# and prints one compact line:
#   ctx:92%  75%/3:04P  @HOST  ~/path  [branch]  Model (1M) [effort]
# No jq/bash needed: ConvertFrom-Json + builtins, git only when cwd is a repo.

$ErrorActionPreference = 'SilentlyContinue'

$raw = [Console]::In.ReadToEnd()
if (-not $raw) { return }
$d = $raw | ConvertFrom-Json

$cwd = $d.cwd
if (-not $cwd) { $cwd = $d.workspace.current_dir }

$model = $d.model.display_name
if (-not $model) { $model = '' }
# Shorten "(1M context)" -> "(1M)"
$model = $model -replace '\(1M context\)', '(1M)'

$usedPct   = $d.context_window.used_percentage
$fivePct   = $d.rate_limits.five_hour.used_percentage
$fiveReset = $d.rate_limits.five_hour.resets_at
$effort    = $d.effort.level

# Host: first component only. COMPUTERNAME carries no domain suffix.
$hostShort = $env:COMPUTERNAME

# Shorten cwd: replace $HOME with ~, and show forward slashes like the original.
$shortCwd = $cwd
if ($cwd -and $HOME -and $cwd.StartsWith($HOME, [System.StringComparison]::OrdinalIgnoreCase)) {
    $shortCwd = '~' + $cwd.Substring($HOME.Length)
}
if ($shortCwd) { $shortCwd = $shortCwd -replace '\\', '/' }

# Git branch, falling back to a short hash when detached; both quietly yield
# nothing when cwd isn't a git repo.
$branch = ''
if ($cwd) {
    $branch = (git -C $cwd symbolic-ref --short HEAD 2>$null)
    if (-not $branch) { $branch = (git -C $cwd rev-parse --short HEAD 2>$null) }
    if ($branch) { $branch = $branch.Trim() }
}

# Round half away from zero to match the bash printf "%.0f".
function Fmt-Pct($v) { [math]::Round([double]$v, 0, [System.MidpointRounding]::AwayFromZero) }

# Build the line -- ctx first, then 5h limit, @host, cwd, git, model.
$line = ''

if ($null -ne $usedPct -and "$usedPct" -ne '') {
    $line = "ctx:$(Fmt-Pct $usedPct)%"
}

if ($null -ne $fivePct -and "$fivePct" -ne '') {
    $seg = "$(Fmt-Pct $fivePct)%"
    if ($fiveReset) {
        # epoch seconds -> local 12h time; strip the trailing M of AM/PM so
        # "3:04PM" becomes "3:04P", matching the bash `${reset%[Mm]}`.
        $t = [System.DateTimeOffset]::FromUnixTimeSeconds([long][double]$fiveReset).LocalDateTime
        $seg += '/' + ($t.ToString('h:mmtt') -replace '[Mm]$', '')
    }
    $line += $(if ($line) { '  ' } else { '' }) + $seg
}

$line += $(if ($line) { '  ' } else { '' }) + "@$hostShort  $shortCwd"

if ($branch) { $line += "  [$branch]" }

if ($model) {
    $line += "  $model"
    if ($effort) { $line += " [$effort]" }
}

[Console]::Out.Write($line)
