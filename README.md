# dotfiles-windows

Windows-only machine provisioning, modeled on my Ubuntu `yadm` + Ansible flow.
On a fresh box, two commands lay down all config and bring the machine to its
desired state (packages, settings); re-running only fixes drift.

| Ubuntu (yadm + Ansible) | Here (chezmoi + WinGet DSC) |
|---|---|
| `yadm` bare repo over `$HOME` | **chezmoi** — writes real files, no symlinks, no admin |
| `~/.config/yadm/bootstrap` | `.chezmoiscripts/run_onchange_after_configure-machine.ps1.tmpl` |
| `setup.yml` (Ansible playbook) | `~/.config/winget/setup.dsc.yaml` (`winget configure`, DSC) |
| `local.yml` (untracked) | `~/.config/winget/local.dsc.yaml` (untracked) |
| `.bashrc` | PowerShell 7 `$PROFILE` |
| `~/.bashrc.local` (untracked) | `~/.config/powershell/profile.local.ps1` (untracked) |

This repo is **Windows-only and standalone**. My WSL/Ubuntu dotfiles are a separate
repo and are not touched here.

## Quick start (day zero on a new machine)

```powershell
# 1. Install the core pair (everything else is declared in the config)
winget install -e --id Git.Git
winget install -e --id twpayne.chezmoi

# 2. One command: clone, lay down files, run configuration
chezmoi init --apply https://github.com/michael-gebis/dotfiles-windows.git
```

That's it. chezmoi writes the dotfiles, then the bridge script runs
`winget configure` to install/repair every declared package. Windows
updates/reboots can interrupt a long first run — just re-run `chezmoi apply`
(everything is idempotent).

```powershell
# 3. One manual step: the WSL *distro* is not in the package config (see Notes)
wsl --install -d Ubuntu
```

> First-run prerequisite chezmoi handles for you on apply: scripts need a
> non-Restricted execution policy. If a fresh box blocks scripts, run once:
> `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser`.
>
> Day-zero uses **HTTPS** (no SSH key yet). Switch the remote to SSH later:
> `chezmoi git -- remote set-url origin git@github.com:michael-gebis/dotfiles-windows.git`

## What's included

- **`$PROFILE`** (`Documents/PowerShell/Microsoft.PowerShell_profile.ps1`) — oh-my-posh
  prompt, PSReadLine history + ListView prediction, an `ssh` wrapper that tints the
  terminal background per host, and an `Update-Machine` helper. Sources an untracked
  local profile last.
- **`dot_config/winget/setup.dsc.yaml`** — the package manifest (curated dev/daily
  toolchain). Source of truth for what's installed; see the file for the grouped list.
- **`.chezmoiscripts/...configure-machine.ps1.tmpl`** — the bridge script. Embeds the
  DSC file's hash so editing the YAML re-triggers `winget configure` on next apply.
- **`dot_gitconfig`** — identity + `core.sshCommand` pointed at Windows OpenSSH.
- **Windows Terminal `settings.json`** — tracked at the Store-install path.

## How it works

`chezmoi apply` writes/updates the tracked files. The bridge script is a
`run_onchange_after_` script: chezmoi re-runs it only when its rendered content
changes, and the embedded `setup.dsc.yaml` hash makes any edit to the package
manifest count as a change. So:

- Nothing drifted → `chezmoi apply` is a silent no-op; the bridge script does not run.
- You edited the DSC YAML → apply re-runs `winget configure` (idempotent: installs
  what's missing, upgrades what's behind, leaves the rest alone).

## Updating / re-running

```powershell
Update-Machine        # profile function: chezmoi update (git pull + apply) + local.dsc.yaml
# or, manually:
chezmoi update                                              # pull + apply tracked config
winget configure -f $HOME\.config\winget\setup.dsc.yaml `   # force a full re-apply
    --accept-configuration-agreements
```

## Untracked, machine-local escape hatches

These are **never committed** (machine/secret-specific). Create them per machine as needed.

| File | Purpose |
|---|---|
| `~/.config/winget/local.dsc.yaml` | Per-machine packages (e.g. `Prusa3D.PrusaSlicer`). Applied on top of `setup.dsc.yaml` by the bridge script and by `Update-Machine`. |
| `~/.config/powershell/profile.local.ps1` | Per-machine `$PROFILE` overrides; dot-sourced last. |
| `~/.config/ssh-terminal-colors` | Host→background-color rules for the `ssh` wrapper (see below). |
| `~/.ssh/config`, `~/.ssh/*` keys | SSH config/keys stay local; not tracked in this public repo. |

### `ssh-terminal-colors` format

One rule per line: `<glob_pattern> <hex_color>`. First match wins; `#` comments allowed.
The `ssh` wrapper sets the terminal background (OSC 11) before connecting and resets it
(OSC 111) on exit. Windows Terminal supports both.

```
# pattern            color
*prod*               #3b1010
*.lab.example.com    #102a10
192.168.1.*          #101a2a
```

## One-time manual step (per machine, elevated)

The ssh-agent service is enabled once with admin rights so git and `ssh` share keys:

```powershell
# Run from an elevated PowerShell:
Set-Service ssh-agent -StartupType Automatic
Start-Service ssh-agent
```

## Notes / gotchas

- **The Ubuntu WSL distro is a manual step.** `setup.dsc.yaml` installs `Microsoft.WSL`
  (the runtime) but NOT the Ubuntu distro itself — the distro is a Store package whose
  setup (username, password, first-boot) is interactive anyway. On a fresh box run
  `wsl --install -d Ubuntu` once, then bootstrap the Ubuntu dotfiles inside it
  (separate repo). A reboot may be required after the first WSL install.

- **Windows Terminal settings path** differs by install type. This repo tracks the
  Store path (`...Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json`);
  an unpackaged install uses `%LOCALAPPDATA%\Microsoft\Windows Terminal\settings.json`.
- **OneDrive-redirected Documents** would move `$PROFILE` under `~\OneDrive\Documents`.
  Verify with `echo $PROFILE` on a new box before relying on the tracked path.
- **Package upgrade policy:** packages are kept at latest — re-running `winget configure`
  upgrades anything with an available update. Pin versions in the DSC YAML if you want to
  hold a package back.
- Best clean-box test: **Windows Sandbox** or a throwaway VM, running the two-command
  bootstrap from scratch.
