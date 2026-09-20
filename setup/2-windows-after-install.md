# Windows 11 — After Install

Checklist for the first hour after Windows 11 25H2 Pro finishes OOBE and the `autounattend.xml`
first-logon tweaks have run. Do the sections in order. Run everything in an elevated
**Terminal (Admin)** unless noted.

> **Before this checklist:** complete **[`1-defender-disable-steps.md`](1-defender-disable-steps.md)**
> — Defender is disabled first, before anything is installed.

- [ ] WSL2 + Arch set up (WSL2 powers Podman's machine)
- [ ] winget refreshed
- [ ] Apps installed
- [ ] Store apps installed
- [ ] Maple Mono NF font installed
- [ ] Git defaults configured
- [ ] Windows Terminal configured
- [ ] Podman machine set up
- [ ] Windows Update active hours set

## 1. WSL (Arch Linux, not Ubuntu)

WSL2 is required anyway — it powers Podman's machine (section 8). Full
bootstrap lives in **[`3-wsl-arch.md`](3-wsl-arch.md)** — the official image boots as barebones
`root` (no sudo, no user) and needs setup. The install is just:

```powershell
wsl --list --online    # confirm archlinux is listed
wsl --install archlinux
```

Reboot when Windows asks, then continue with steps 2–9 below and finish the WSL setup in
`3-wsl-arch.md`.

## 2. Refresh winget first

Fresh Windows images ship a stale App Installer client that fails on current manifests.

```powershell
winget upgrade --id Microsoft.AppInstaller -e
winget source update
```

If winget itself is missing, open the Microsoft Store, let App Installer update, and retry.

### Install Latest PowerShell
Install the latest PowerShell directly from its [release page](https://github.com/PowerShell/PowerShell/releases) in GitHub because winget timesout for some reason. After installing it restart your terminal.


## 3. Install apps (winget)

One command installs all of them (`-e` exact-matches each ID):

```powershell
winget install -e `
  Google.Chrome `
  Notion.Notion `
  Git.Git `
  Microsoft.VisualStudioCode `
  RedHat.Podman `
  Microsoft.PowerToys `
  voidtools.Everything `
  M2Team.NanaZip `
  SumatraPDF.SumatraPDF `
  ShareX.ShareX `
  jdx.mise `
  OpenJS.NodeJS `
  eza-community.eza `
  BurntSushi.ripgrep.MSVC `
  ajeetdsouza.zoxide `
  junegunn.fzf `
  sharkdp.fd `
  sharkdp.bat `
  allankoechke.which `
  vim.vim
```

- Installs still run one after another, but a single invocation skips the per-app
  startup/source-check overhead — noticeably faster than 11 separate commands. Don't run
  several winget commands in parallel instead; they contend on the installer mutex and
  source catalog.
- If one package fails mid-run, re-run just that ID: `winget install -e <ID>`.
- To add or remove apps later, edit this block. Browse IDs with `winget search <name>`.

## 4. Store apps (winget msstore source)

```powershell
winget install --id 9NCBCSZSJRSB -s msstore -e   # Spotify (desktop installer rejects admin installs; use Store)
winget install --id 9NKSQGP7F2NH -s msstore -e   # WhatsApp
winget install --id 9WZDNCRFJ3TJ -s msstore -e   # Netflix
winget install --id 9P4CLT2RJ1RS -s msstore -e   # MusicBee
```

## 6. Git defaults

Git came from the winget step above. Save the following as `C:\Users\<you>\.gitconfig`
(PowerShell: `notepad $env:USERPROFILE\.gitconfig`), filling in your name and email:

```ini
[user]
    name = Your Name
    email = you@example.com
[init]
    defaultBranch = main
[core]
    autocrlf = false
    longpaths = true
[fetch]
    prune = true
[pull]
    ff = only
[credential]
    helper = manager
```

## 7. Windows Terminal (GUI)

Open **Windows Terminal → Settings**:

- **Startup → Default profile:** `PowerShell` (the PowerShell 7 / pwsh one, not
  "Windows PowerShell").
- Leave copy-on-select **off** (default) if you want Ctrl+C/Ctrl+V-style copying.

## 8. Podman machine

Podman replaces Docker Desktop. The Windows `podman` CLI runs containers inside a **podman
machine** — a small WSL2 distro it manages itself (your Arch distro from `3-wsl-arch.md`
stays separate):

```powershell
podman machine init
podman machine start
podman run quay.io/podman/hello
```

- Run `podman machine start` after each Windows reboot before using containers.
- The CLI speaks docker-style commands (`podman ps`, `podman build`, `podman compose`), and
  podman also serves the Docker API socket, so Docker-based tools work against it. To type
  `docker` out of habit, add `Set-Alias docker podman` to your PowerShell profile
  (`notepad $PROFILE`).
- Prefer a GUI? `winget install -e RedHat.Podman-Desktop` manages machines and containers
  visually.

## 9. Windows Update active hours (GUI)

Settings → **Windows Update**:

- **Advanced options → Active hours:** set **8:00 – 23:00**.
- In the same Advanced options page, make sure the PC won't auto-restart on its own
  ("Restart needed" prompts should wait for you).

## Reboot notes

A reboot is needed before these take effect: Developer Mode, Sudo for Windows, and HAGS
(already staged by `autounattend.xml`).
