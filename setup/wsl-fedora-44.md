# WSL — Fedora 44

The Linux environment on this PC is **Fedora 44 inside WSL2**, not a separate install. Fedora
over Ubuntu: much fresher packages, and it's an official WSL distro. One quirk: WSL's Fedora is
not in the Microsoft Store — it installs from the command line only.

- [ ] WSL + Fedora installed
- [ ] Distro updated
- [ ] systemd verified
- [ ] Dev packages + Git configured
- [ ] Docker Desktop integration enabled

## 1. Install (before Docker Desktop!)

Do this before installing Docker Desktop so its WSL2 backend has a working distro. From an
elevated PowerShell on Windows:

```powershell
wsl --list --online          # see available distros; pick the newest Fedora listed
wsl --install FedoraLinux-42 # replace with the newest Fedora (e.g. 44) from the list
```

- Reboot when Windows asks.
- After reboot, launch the distro from the Start menu (or `wsl -d FedoraLinux-42`) and create
  your username when prompted. The default user has no password but is in `wheel` (sudo works).
- Verify from PowerShell: `wsl --list --verbose` should show the Fedora distro on **WSL2**.

## 2. Update the distro

Inside the distro:

```bash
sudo dnf upgrade --refresh -y
```

## 3. Verify systemd

```bash
systemctl is-system-running   # expect "running" (or "starting" right after boot)
```

If it reports an error instead, enable systemd in `/etc/wsl.conf`:

```ini
[boot]
systemd=true
```

Then run `wsl --shutdown` from PowerShell and reopen the distro.

## 4. Dev packages + Git

```bash
sudo dnf install git curl wget unzip tar
git config --global init.defaultBranch main
git config --global fetch.prune true
git config --global pull.ff only
```

- Don't set `core.autocrlf` or `core.longpaths` here — those are Windows-only concerns.
- WSL's git config is separate from the Windows one; set `user.name` / `user.email` **manually
  per identity** here too.

## 5. Docker — via Docker Desktop integration

Don't install a Docker engine inside WSL. Docker Desktop on Windows can plug the CLI straight
into the distro:

1. On Windows, finish Docker Desktop setup and the `docker-users` group step (see
   `windows-after-install.md`).
2. Docker Desktop → **Settings → Resources → WSL integration** → enable the Fedora distro.
3. Back inside WSL: `docker run hello-world`.

## 6. Notes

- **Fonts:** nothing to install inside WSL — Windows Terminal renders with Windows fonts
  (Maple Mono NF comes from the Windows checklist).
- **Files:** keep repos in the Linux home (`~/...`) for best file-I/O performance; `/mnt/c` is
  much slower for git/builds.
- **Interop:** Windows drives appear under `/mnt/...`, and Windows executables can be called
  from WSL and vice versa.
- **Managing:** `wsl --shutdown` stops the WSL VM; `wsl --export` / `wsl --import` move or back
  up the distro.
