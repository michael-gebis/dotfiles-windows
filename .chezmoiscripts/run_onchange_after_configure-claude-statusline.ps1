# Point Claude Code's statusLine at the tracked PowerShell status script.
#
# run_onchange_ => re-runs only when this script's rendered content changes.
# after_        => runs after chezmoi has written dot_claude/statusline-command.ps1.
#
# Idempotent + non-clobbering: reads the existing ~/.claude/settings.json (a
# file Claude Code also rewrites itself, e.g. on /config theme changes), sets
# ONLY the statusLine key, and writes it back -- every other key is preserved.
# Path is derived from $env:USERPROFILE so it is correct on any machine/user.
#
# Must run under Windows PowerShell 5.1 (chezmoi's configured .ps1 interpreter,
# chosen so clean boxes apply before pwsh 7 is installed). So: no -AsHashtable
# (7-only), and write UTF-8 *without* BOM via .NET (5.1's Set-Content -Encoding
# utf8 emits a BOM that Node's JSON.parse rejects).
$ErrorActionPreference = 'Stop'

$claudeDir = Join-Path $env:USERPROFILE '.claude'
$settings  = Join-Path $claudeDir 'settings.json'
$script    = Join-Path $claudeDir 'statusline-command.ps1'

if (-not (Test-Path $claudeDir)) {
    New-Item -ItemType Directory -Path $claudeDir | Out-Null
}

if (Test-Path $settings) {
    $raw = Get-Content -Raw -Path $settings
    $obj = if ([string]::IsNullOrWhiteSpace($raw)) { [pscustomobject]@{} }
           else { $raw | ConvertFrom-Json }
} else {
    $obj = [pscustomobject]@{}
}

$statusLine = [pscustomobject]@{
    type    = 'command'
    command = "pwsh -NoProfile -File `"$script`""
}

# Add-Member -Force adds or replaces the property; works in 5.1 and 7.
$obj | Add-Member -NotePropertyName statusLine -NotePropertyValue $statusLine -Force

$json = $obj | ConvertTo-Json -Depth 10
[System.IO.File]::WriteAllText($settings, $json, (New-Object System.Text.UTF8Encoding($false)))
Write-Host "==> Claude statusLine configured -> $script"
