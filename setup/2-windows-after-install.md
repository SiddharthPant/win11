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
  LocalSend.LocalSend `
  Microsoft.BingWallpaper `
  jqlang.jq
```

- Installs still run one after another, but a single invocation skips the per-app
  startup/source-check overhead — noticeably faster than 11 separate commands. Don't run
  several winget commands in parallel instead; they contend on the installer mutex and
  source catalog.
- If one package fails mid-run, re-run just that ID: `winget install -e <ID>`.
- To add or remove apps later, edit this block. Browse IDs with `winget search <name>`.
- Bing Wallpaper replaces Windows Spotlight for a daily desktop wallpaper — Spotlight on this
  setup kept cycling its 4 built-in fallback images instead of downloading new ones.

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

## MacBook ↔ PC (SSH + SMB)

SSH for the CLI and SMB for the file browser, both directions, over the home LAN. Both are
built into Windows and macOS — nothing to install beyond the OpenSSH Server feature.

| Machine | Name | IP | Link | User |
|---|---|---|---|---|
| PC | `pinaka` | `192.168.29.30` | Ethernet | `sidpa` (Microsoft account) |
| MacBook Pro | `mbp` | `192.168.29.112` | Wi-Fi | `sid` |

### Fixed IPs + hosts files (not `.local`)

`Siddharths-MacBook-Pro.local` doesn't resolve from the PC even though the IP works for both SSH
and SMB. `.local` names use mDNS (multicast UDP 5353), and the JioFiber router doesn't bridge
multicast between its Ethernet and Wi-Fi sides — unicast crosses fine, so IPs work. The Windows
side is fine (network profile Private, mDNS firewall rules on).

1. **Reserve both IPs** in the JioFiber admin page (`http://192.168.29.1` → Network → LAN →
   DHCP / static lease). On the Mac, set **Wi-Fi → Details → Private Wi-Fi address** to
   **Off** or **Fixed** for this network, or its MAC changes and the reservation stops matching.
2. **Windows** `C:\Windows\System32\drivers\etc\hosts` (edit as admin):
   ```
   192.168.29.112 mbp Siddharths-MacBook-Pro.local # My MacBook Pro Laptop
   ```
3. **Mac** `/etc/hosts`:
   ```bash
   echo "192.168.29.30   pinaka" | sudo tee -a /etc/hosts
   ```
   No `pinaka.local` alias — macOS sends `.local` to Bonjour first and can stall.

### PC → Mac

On the Mac, **System Settings → General → Sharing**:

- **Remote Login** on (ⓘ → allow `sid`; optionally "Allow full disk access for remote users").
- **File Sharing** on → ⓘ → **Options…** → tick **Share files and folders using SMB**, and under
  *Windows File Sharing* tick `sid` and enter its password.
- Optional: **Battery → Options** → "Wake for network access" so a sleeping Mac stays reachable.

`~\.ssh\config` on the PC (the key is the existing `id_rsa`, already in the Mac's
`~/.ssh/authorized_keys`):

```
Host mac
    HostName mbp
    User sid
    IdentityFile ~/.ssh/id_rsa
```

- CLI: `ssh mac`.
- Explorer: `\\mbp` in the address bar, sign in as `sid`. For a drive letter:
  `net use M: \\mbp\sid /persistent:yes`.

### Mac → PC: OpenSSH Server

1. **Settings → System → Optional features → View features** (the "available features" dialog —
   the main page search only lists *installed* features, which is just OpenSSH Client) →
   search `openssh` → **OpenSSH Server** → Next → Add. CLI equivalent:
   `Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0`.
2. `services.msc` → **OpenSSH SSH Server** → Startup type **Automatic** → **Start**.
3. Firewall: the install creates **OpenSSH SSH Server (sshd)** (`OpenSSH-Server-In-TCP`) already
   scoped to **Private** — nothing to do. Check with `wf.msc` → Inbound Rules.
4. Default shell → PowerShell 7 instead of `cmd.exe`: `regedit` →
   `HKEY_LOCAL_MACHINE\SOFTWARE\OpenSSH` → new String Value `DefaultShell` =
       `C:\Program Files\PowerShell\7\pwsh.exe`. Or execute following in admin powershell:
    ```powershell
    New-ItemProperty -Path HKLM:\SOFTWARE\OpenSSH -Name DefaultShell -Value "C:\Program Files\PowerShell\7\pwsh.exe" -PropertyType String -Force
    ```
5. **Authorize the Mac's key.** `sidpa` is an admin, so sshd ignores
   `~\.ssh\authorized_keys` and reads `C:\ProgramData\ssh\administrators_authorized_keys`
   instead. Paste the Mac's `~/.ssh/id_rsa.pub` into it (e.g. `sudo vim` — Sudo for Windows is
   under **Settings → System → Advanced**), or pull it over the working PC → Mac link from an
   admin terminal:
   ```powershell
   ssh mac "cat ~/.ssh/id_rsa.pub" | Set-Content -Encoding ascii C:\ProgramData\ssh\administrators_authorized_keys
   ```
   No `icacls` needed: the file inherits `C:\ProgramData\ssh`'s ACL (SYSTEM + Administrators full,
   Authenticated Users read), which sshd accepts. If key login ever silently falls back to a
   password, lock it down:
   `icacls C:\ProgramData\ssh\administrators_authorized_keys /inheritance:r /grant "*S-1-5-32-544:F" /grant "SYSTEM:F"`.

Mac `~/.ssh/config`:

```
Host pc
    HostName pinaka
    User sidpa
    IdentityFile ~/.ssh/id_rsa
    WarnWeakCrypto no
```

Then `ssh pc`.

- `WarnWeakCrypto no` silences macOS OpenSSH 10.x's "connection is not using a post-quantum key
  exchange algorithm" warning. Windows' OpenSSH 9.5p2 doesn't offer ML-KEM/sntrup, so it
  negotiates `curve25519` — still secure, just not post-quantum.
- **Password login fails** (`Failed password for sidpa` in Event Viewer →
  Applications and Services Logs → OpenSSH → Operational) while Windows Hello-only sign-in is on.
  Key login avoids it; for passwords see **Mac → PC: Microsoft account password sign-in**.
- sshd log from a normal terminal:
  `Get-WinEvent -LogName OpenSSH/Operational -MaxEvents 20 | Format-List TimeCreated,Message`.

### WinGet tools over SSH (PowerShell profile)

Over SSH, the profile failed with `Program 'zoxide.exe' failed to run … The path cannot be
traversed because it contains an untrusted mount point` (same for `mise`, and `eza`/`rg`/`bat`/…
on use). WinGet puts its CLIs in `%LOCALAPPDATA%\Microsoft\WinGet\Links` as symlinks created
without admin rights, and processes in an sshd session refuse to follow those. Fix: at the top
of `$PROFILE`, only when `SSH_CONNECTION` is set (the Windows sshd sets it), put the symlinks'
real package dirs ahead of `Links` on PATH:

```powershell
# Over SSH, Windows won't follow the user-created symlinks in WinGet\Links
# ("untrusted mount point"), so put the real package dirs first on PATH
if ($env:SSH_CONNECTION) {
    $wingetDirs = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Links" -File |
        Where-Object LinkType -eq 'SymbolicLink' |
        ForEach-Object { Split-Path $_.Target } |
        Select-Object -Unique
    $env:PATH = ($wingetDirs -join ';') + ';' + $env:PATH
}
```

It's rebuilt each session, so tools installed later are picked up automatically. Local terminals
are unaffected.

### Mac → PC: Microsoft account password sign-in

SMB (and SSH password login) authenticate with the **Microsoft account password**, which Windows
checks against a locally cached copy. With **"only allow Windows Hello sign-in"** on (the Windows
default for Microsoft accounts), the PC only ever sees the PIN, so that copy is missing or stale
and every network password is rejected — the Mac's "Registered User" dialog just keeps
re-prompting. Check the state (`2` = Hello-only on, `0` = off):

```powershell
(Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\PasswordLess\Device').DevicePasswordLessBuildVersion
```

Fix:

1. **Settings → Accounts → Sign-in options** → turn **off** "For improved security, only allow
   Windows Hello sign-in for Microsoft accounts on this device".
2. **Win+L** to lock, then unlock with the **password**: **Sign-in options** → key icon →
   Microsoft account password. That caches it; a full sign-out isn't needed.

Trade-offs of leaving Hello-only off:

- PIN / Windows Hello still work and stay the default tile — the password is just an extra
  option. Nothing else (BitLocker, Store, OneDrive) depends on the toggle.
- The Microsoft account password now unlocks the PC at the keyboard and over SMB/SSH on the LAN.
  Account 2FA doesn't cover local or network logons, so keep that password strong and unique.
  SMB/SSH are only open on the Private profile.
- After changing the Microsoft password online, lock + unlock once with the new password, or SMB
  (and the Mac's Keychain entry) keeps failing on the stale cached copy.

Diagnosing a rejected login (admin terminal, right after the failure) — look at **Sub Status**:
`0xC000006A` = wrong/stale password (redo step 2), `0xC0000064` = unknown username (try `sidpa`
instead of the email):

```powershell
Get-WinEvent -FilterHashtable @{LogName='Security';Id=4625} -MaxEvents 3 | Format-List TimeCreated,Message
```

If the Microsoft account itself is passwordless (account.microsoft.com → Security → Passwordless
account), there is no password to cache — the fallback is a dedicated local account for SMB
(`net user smbuser <password> /add`), which also needs NTFS access granted on `C:\Users\sidpa`.

### Mac → PC: SMB

SMB-In is already allowed on Private (File and Printer Sharing rules), but out of the box only the
admin shares (`C$`, `D$`, `E$`) exist. Share folders (admin terminal):

```powershell
New-SmbShare -Name sidpa -Path C:\Users\sidpa -FullAccess "PINAKA\sidpa"
New-SmbShare -Name D -Path D:\ -FullAccess "PINAKA\sidpa"
```

Or right-click a folder → **Properties → Sharing → Advanced Sharing** → **Share this folder** →
**Permissions** → add `sidpa` with **Full Control**.

Needs **Mac → PC: Microsoft account password sign-in** done first. On the Mac:

1. Finder → **⌘K** → `smb://pinaka/sidpa` (or `smb://pinaka` to pick from the share list).
2. **Registered User**: Microsoft account email + Microsoft account password (not the PIN);
   tick **Remember this password in my keychain**.
3. **+** in Connect to Server to favorite it; drag the mounted share into **System Settings →
   General → Login Items** to auto-mount.

## Reboot notes

A reboot is needed before these take effect: Developer Mode, Sudo for Windows, and HAGS
(already staged by `autounattend.xml`).
