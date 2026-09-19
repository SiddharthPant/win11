# Windows 11 — After Install

Checklist for the first hour after Windows 11 25H2 Pro finishes OOBE and the `autounattend.xml`
first-logon tweaks have run. Do the sections in order. Run everything in an elevated
**Terminal (Admin)** unless noted.

> **Before this checklist:** complete **[`defender-disable-steps.md`](defender-disable-steps.md)**
> — Defender is disabled first, before anything is installed.

- [ ] WSL set up (before Docker Desktop!)
- [ ] winget refreshed
- [ ] Apps installed
- [ ] Store apps installed
- [ ] Maple Mono NF font installed
- [ ] Git defaults configured
- [ ] Windows Terminal configured
- [ ] Docker user group set
- [ ] Windows Update active hours set

## 1. WSL (Fedora, not Ubuntu)

Do this **before** installing Docker Desktop so its WSL2 backend has a working distro. Full
distro setup lives in **[`wsl-fedora-44.md`](wsl-fedora-44.md)**; the install is just:

```powershell
wsl --list --online          # see available distros; pick the newest Fedora listed
wsl --install FedoraLinux-44 # replace with the newest Fedora (e.g. 44) from the list
```

Reboot when Windows asks, then continue with steps 2–10 below and finish the WSL setup in
`wsl-fedora-44.md`.

## 2. Refresh winget first

Fresh Windows images ship a stale App Installer client that fails on current manifests.

```powershell
winget upgrade --id Microsoft.AppInstaller -e
winget source update
```

If winget itself is missing, open the Microsoft Store, let App Installer update, and retry.

## 3. Install apps (winget)

One command installs all of them (`-e` exact-matches each ID):

```powershell
winget install -e `
  Google.Chrome `
  Notion.Notion `
  Git.Git `
  Microsoft.VisualStudioCode `
  Microsoft.PowerShell `
  Docker.DockerDesktop `
  Microsoft.PowerToys `
  voidtools.Everything `
  M2Team.NanaZip `
  SumatraPDF.SumatraPDF `
  ShareX.ShareX
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
```

## 5. Maple Mono NF font (manual)

1. Download the latest release asset
   [`MapleMono-NF.zip`](https://github.com/subframe7536/maple-font/releases/latest) from the
   maple-font GitHub releases.
2. Extract the zip.
3. Select all `.ttf` files → right-click → **Install for all users** (needs admin, so Windows
   Terminal and elevated apps can see it).

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
- **Defaults → Appearance → Font face:** `Maple Mono NF`, font size `11`.
- Leave copy-on-select **off** (default) if you want Ctrl+C/Ctrl+V-style copying.

## 8. Docker Desktop user group

Docker Desktop created a local `docker-users` group; join it so Docker works without elevation:

```powershell
net localgroup docker-users "$env:USERNAME" /add
```

Then sign out and back in (or reboot) before using Docker. On first Docker Desktop launch,
accept the service agreement and confirm it uses the **WSL2** backend.

## 9. Windows Update active hours (GUI)

Settings → **Windows Update**:

- **Advanced options → Active hours:** set **8:00 – 23:00**.
- In the same Advanced options page, make sure the PC won't auto-restart on its own
  ("Restart needed" prompts should wait for you).

## Reboot notes

A reboot is needed before these take effect: Developer Mode, Sudo for Windows, HAGS (already
staged by `autounattend.xml`), and the docker-users group membership.
