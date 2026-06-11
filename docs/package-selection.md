# dotfiles-windows — package selection record

**Date locked:** 2026-06-09 (gh, WinSCP, Sysinternals, Acrobat added 2026-06-10)
**Purpose:** Decision log for what `setup.dsc.yaml` declares. Revisit and promote
skipped items anytime; the YAML is the source of truth for what is installed.

## Locked decisions

- Repo: **`dotfiles-windows`**, public, manager = **chezmoi**, config = **WinGet Configuration 0.2.0** (`winget configure`).
- Package philosophy: curated dev/daily toolchain that a fresh box should rebuild — NOT
  every installed package. Runtimes, OEM/vendor hardware utilities, games, and other
  machine-specific software are excluded by policy.
- Machine-specific apps (e.g. PrusaSlicer) go in the untracked per-machine **`local.dsc.yaml`**,
  not the shared `setup.dsc.yaml`.
- `.gitconfig` tracked as-is, plus `core.sshCommand` pointed at Windows OpenSSH.

## ✅ INCLUDED — 31 packages

### Core dev / shell
| ID | Notes |
|---|---|
| `Git.Git` | |
| `GitHub.cli` | |
| `Microsoft.PowerShell` | pwsh 7 |
| `Microsoft.WindowsTerminal` | |
| `Microsoft.VisualStudioCode` | |
| `Microsoft.WSL` | gateway to Ubuntu CLI tooling |
| `Microsoft.PowerToys` | |
| `WinMerge.WinMerge` | meld analog |
| `AntibodySoftware.WizTree` | ncdu analog |
| `JanDeDobbeleer.OhMyPosh` | powerline-go analog, needed by `$PROFILE` |
| `BurntSushi.ripgrep.MSVC` | |
| `astral-sh.uv` | |
| `Anthropic.Claude` | |
| `Microsoft.WinDbg` | |
| `WerWolv.ImHex` | |
| `JohnMacFarlane.Pandoc` | |
| `9P7KNL5RWT25` (msstore) | Sysinternals Suite — Store version, matches existing install |

### Networking / remote
| ID | Notes |
|---|---|
| `Tailscale.Tailscale` | |
| `WiresharkFoundation.Wireshark` | |
| `Rclone.Rclone` | |
| `WinSCP.WinSCP` | winget build (the Store/MSIX copy on the first box is redundant) |

### Personal / media
| ID | Notes |
|---|---|
| `Obsidian.Obsidian` | |
| `calibre.calibre` | |
| `VideoLAN.VLC` | |
| `HandBrake.HandBrake` | |
| `Google.Chrome.EXE` | EXE variant (matches the installed form) |
| `Google.GoogleDrive` | |
| `CodeSector.TeraCopy` | |
| `AdrienAllard.FileConverter` | |
| `MoritzBunkus.MKVToolNix` | |
| `Adobe.Acrobat.Reader.64-bit` | |

## ❌ DELIBERATELY EXCLUDED

| ID | Reason |
|---|---|
| `SublimeHQ.SublimeText.4` | removed by choice |
| `SublimeHQ.SublimeMerge` | removed by choice |
| `Prusa3D.PrusaSlicer` | wanted on *some* machines → put in `local.dsc.yaml`, not shared config |

## ⬜ Considered but skipped (revisit candidates)

### Dev tools from the Ubuntu setup
`sharkdp.fd` · `UniversalCtags.Ctags` · `GoLang.Go` · `EclipseAdoptium.Temurin.21.JDK` ·
`Apache.Maven` · `charmbracelet.glow` · `restic.restic` · `Facebook.Zstandard`
(Skipped on the theory that most heavy CLI work happens in WSL. Promote any if
Windows-native is wanted.)

### Everything else
Roughly 25 further machine-specific candidates (personal apps, maker/3D tools, games,
niche utilities) were reviewed and left out of the shared config; the full annotated
list is kept locally outside this repo. Anything machine-specific that earns its keep
goes in that machine's `local.dsc.yaml`.

A second sweep over Store/MSIX and uncorrelated win32 installs (apps invisible to
`winget export`) surfaced more candidates — WinSCP/Sysinternals/Acrobat were promoted;
`Mozilla.Firefox`, `dotPDNLLC.paintdotnet`, `OpenSCAD.OpenSCAD`, Speedtest, WinDirStat,
VMware Workstation, and Autodesk Fusion were reviewed and left out for now.

## Settled
- Node manager: **not wanted** (no fnm / nvm-windows).
- OpenSSH Server capability (SSH *into* this box): **NO** — SSH out only.
- VS Code extensions: **deferred** — not part of this pass.
- `~/.ssh/config`: **untracked / local-only** — network-specific + public repo. Not committed.
