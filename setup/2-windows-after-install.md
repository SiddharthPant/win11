# Windows 11 — After Install

Checklist for the first hour after Windows 11 25H2 Pro finishes OOBE and the `autounattend.xml`
first-logon tweaks have run. Do the sections in order. Run everything in an elevated
**Terminal (Admin)** unless noted.

> **Before this checklist:** complete **[`1-defender-disable-steps.md`](1-defender-disable-steps.md)**
> — Defender is disabled first, before anything is installed.

## WSL (Arch Linux, not Ubuntu)

WSL2 is required anyway — it powers Podman's machine (the **Podman machine** section). Full
bootstrap lives in **[`3-wsl-arch.md`](3-wsl-arch.md)** — the official image boots as barebones
`root` (no sudo, no user) and needs setup. The install is just:

```powershell
wsl --list --online    # confirm archlinux is listed
wsl --install archlinux
```

Reboot when Windows asks, then continue with the sections below and finish the WSL setup in
`3-wsl-arch.md`.

## Refresh winget first

Fresh Windows images ship a stale App Installer client that fails on current manifests.

```powershell
winget upgrade --id Microsoft.AppInstaller -e
winget source update
```

If winget itself is missing, open the Microsoft Store, let App Installer update, and retry.

### Install Latest PowerShell
Install the latest PowerShell directly from its [release page](https://github.com/PowerShell/PowerShell/releases) in GitHub because winget timesout for some reason. After installing it restart your terminal.


## Install apps (winget)

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
  vim.vim `
  Rem0o.FanControl `
  LibreHardwareMonitor.LibreHardwareMonitor `
  LocalSend.LocalSend
```

- Installs still run one after another, but a single invocation skips the per-app
  startup/source-check overhead — noticeably faster than 11 separate commands. Don't run
  several winget commands in parallel instead; they contend on the installer mutex and
  source catalog.
- If one package fails mid-run, re-run just that ID: `winget install -e <ID>`.
- To add or remove apps later, edit this block. Browse IDs with `winget search <name>`.

Vim requires you to setup its installer path in system PATH variable as its not automatically setup.
## Store apps (winget msstore source)

```powershell
winget install --id 9NCBCSZSJRSB -s msstore -e   # Spotify (desktop installer rejects admin installs; use Store)
winget install --id 9NKSQGP7F2NH -s msstore -e   # WhatsApp
winget install --id 9WZDNCRFJ3TJ -s msstore -e   # Netflix
winget install --id 9P4CLT2RJ1RS -s msstore -e   # MusicBee
```

## PostgreSQL 18

Not in the bulk list above — it needs installer switches (unattended mode + a pinned port)
rather than a plain `winget install -e`:

```powershell
winget install --id PostgreSQL.PostgreSQL.18 --exact --override '--mode unattended --unattendedmodeui none --serverport 5432'
```

- `--override` **replaces** winget's default arguments with EDB's own installer switches, so the
  interactive wizard never runs. UAC still prompts once.
- `--mode unattended --unattendedmodeui none` suppresses the GUI and every prompt;
  `--serverport 5432` states the port explicitly instead of leaning on the default.
- Keep `--superpassword` off — the guide uses the installer's defaults as-is. What lands:
  - Superuser role `postgres`, password `postgres` (the unattended default).
  - Port 5432; auth is `scram-sha-256`, so a password is always required over TCP.
  - Install dir `C:\Program Files\PostgreSQL\18\`, data dir `...\data\`, with
    `postgresql.conf` and `pg_hba.conf` inside it.
  - Windows service `postgresql-x64-18`, start type Automatic, running as
    `NT AUTHORITY\NetworkService`.
  - Bundled extras: pgAdmin 4 and StackBuilder.

### Put `psql` on PATH

The EDB installer does not add its `bin` folder to PATH. Append it to the system PATH:

```powershell
$bin  = 'C:\Program Files\PostgreSQL\18\bin'
$path = [Environment]::GetEnvironmentVariable('PATH', 'Machine')
if ($path -notlike "*$bin*") {
  [Environment]::SetEnvironmentVariable('PATH', "$path;$bin", 'Machine')
}
```

Open a new terminal afterwards for the change to apply.

### Create the password file

Stops `psql` prompting on every connection. `libpq` reads `%APPDATA%\postgresql\pgpass.conf`, one
`host:port:database:username:password` line per role — `*` matches any database:

```powershell
$dir = "$env:APPDATA\postgresql"
New-Item -ItemType Directory -Path $dir -Force | Out-Null
@(
  'localhost:5432:*:postgres:postgres'
  '127.0.0.1:5432:*:postgres:postgres'
) | Set-Content "$dir\pgpass.conf"
```

### Verify

```powershell
Get-Service postgresql-x64-18    # Running
psql --version                   # psql (PostgreSQL) 18.6
psql -U postgres -h localhost -d postgres -c "select version();"    # connects with no prompt
```

### Connect

```powershell
psql -U postgres -h localhost
```

- Windows has no Unix socket, so bare `psql -U postgres` also connects to localhost:5432.
- In-session: `\l` databases, `\dt` tables, `\conninfo` current connection, `\?` help, `\q` quit.
- URI form, for tools and env vars (sqlx, pgAdmin, containers):
  `postgresql://postgres:postgres@localhost:5432/postgres`

### Restarting the service

```powershell
Restart-Service postgresql-x64-18    # admin; run after editing pg_hba.conf / postgresql.conf
```

The data directory belongs to the service account, not your user — edit those config files from an
elevated terminal.

## Visual Studio Build Tools (MSVC linker)

Rust's default Windows target (`x86_64-pc-windows-msvc`) needs `link.exe` from the MSVC toolset.
Without it, every `cargo build` / `mise install` of cargo tools (sqlx-cli, askama_fmt, …) fails
with `linker 'link.exe' not found`. VS Code is NOT sufficient. Version-agnostic winget ID →
installs the current stable (VS 2026):

```powershell
winget install --id Microsoft.VisualStudio.BuildTools --exact --override "--quiet --wait --norestart --nocache --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended"
```

- `--includeRecommended` pulls the MSVC v143+ compiler/linker plus the Windows SDK.
- ~2–3 GB, several minutes, UAC prompt. No PATH setup needed — `cargo`/`cc` auto-detect it
  via `vswhere`; just use a new terminal afterwards.
- Do this before the first `mise install` in a Rust project.

## Git defaults

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

## Windows Terminal (GUI)

Open **Windows Terminal → Settings**:

- **Startup → Default profile:** `PowerShell` (the PowerShell 7 / pwsh one, not
  "Windows PowerShell").
- Leave copy-on-select **off** (default) if you want Ctrl+C/Ctrl+V-style copying.

## Podman machine

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

## Windows Update active hours (GUI)

Settings → **Windows Update**:

- **Advanced options → Active hours:** set **8:00 – 23:00**.
- In the same Advanced options page, make sure the PC won't auto-restart on its own
  ("Restart needed" prompts should wait for you).

## Reboot notes

A reboot is needed before these take effect: Developer Mode, Sudo for Windows, and HAGS
(already staged by `autounattend.xml`).
