# WSL — Arch Linux

The Linux environment on this PC is **Arch Linux inside WSL2**. Arch is a rolling-release
distro: always-current packages, and no more switching to a new numbered release every six
months — the same install keeps rolling forward.

Expect a **barebones** first launch: the official WSL image boots straight to `root` with just
the base packages — no sudo, no `which`, no user account, nothing. This guide bootstraps it.

## Install

WSL2 is also required on the Windows side — it powers Podman's machine there
(see **Podman machine** in `2-windows-after-install.md`). From an elevated PowerShell on Windows:

```powershell
wsl --list --online    # confirm archlinux is listed
wsl --install archlinux
```

Reboot when Windows asks. Launch the distro from the Start menu or `wsl -d archlinux`.

(A community alternative — [yuk7/ArchWSL](https://github.com/yuk7/ArchWSL) with its
`Arch.exe` launcher — exists, but the official image above is the default choice.)

## Bootstrap (as root)

The first session runs as `root`. Set things up in order:

```bash
# locale first — every command warns about setlocale until it's generated
sed -i 's/^#en_US\.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo 'LANG=en_US.UTF-8' > /etc/locale.conf
ln -sf /etc/locale.conf /etc/default/locale   # WSL otherwise forces the Windows locale

passwd                 # set a root password — your recovery path if sudo breaks

pacman -Syu            # sync + full upgrade (do this first, always)

# sudo + the small basics the image leaves out
pacman -S --needed sudo which git wget unzip vim fzf zoxide fd ripgrep

# allow the wheel group to sudo
echo '%wheel ALL=(ALL:ALL) ALL' > /etc/sudoers.d/wheel

# your actual user
useradd -m -G wheel -s /bin/bash <username>
passwd <username>
```

## Make your user the default

WSL reopens the distro as `root` unless told otherwise. Create `/etc/wsl.conf` (it doesn't
exist yet on a fresh image):

```ini
[user]
default = <username>
```

Then, **from Windows PowerShell**, terminate the session so it takes effect:

```powershell
wsl --shutdown
```

Reopen the distro — it should land directly as your user. Verify:

```bash
whoami        # -> <username>
sudo -v       # should prompt for *your* password, not root's
```

If you're ever locked out, get back in as root from PowerShell: `wsl -d archlinux -u root`.

## Verify systemd

```bash
systemctl is-system-running   # expect "running" (or "starting" right after boot)
```

If it reports an error instead, add to `/etc/wsl.conf`:

```ini
[boot]
systemd=true
```

Then `wsl --shutdown` from PowerShell and reopen the distro.

## Git

Save the following as `~/.gitconfig` (e.g. `nano ~/.gitconfig` or `code ~/.gitconfig`),
filling in your name and email:

```ini
[user]
    name = Your Name
    email = you@example.com
[init]
    defaultBranch = main
[fetch]
    prune = true
[pull]
    ff = only
```

- Don't add `core.autocrlf` or `core.longpaths` here — those are Windows-only concerns.
- WSL's `.gitconfig` is separate from the Windows one, so fill in your identity in both.

## Podman (native, rootless)

No Docker Desktop integration here — install Podman directly in the distro. Inside a real
Linux distro there is no podman machine; containers run natively:

```bash
sudo pacman -S podman podman-compose shadow
```
Choose crun when asked which runtime to choose from:
```
resolving dependencies...
:: There are 3 providers available for oci-runtime:
:: Repository extra
   1) crun  2) krun  3) runc

Enter a number (default=1): 1
```
Add `command="mount --make-rshared /"` to `[boot]` section in `/etc/wsl.conf`.
Then run a container
```bash
podman run quay.io/podman/hello
```

Known Arch-on-WSL issues with rootless containers (per the
[ArchWiki WSL page](https://wiki.archlinux.org/title/Install_Arch_Linux_on_WSL)):

- `newuidmap: Could not set caps` → reinstall the shadow package: `sudo pacman -S shadow`,
  then retry.
- "Failed to start the systemd user session" / rootless tools misbehaving →
  `sudo loginctl enable-linger <username>`.

This is independent of the Windows-side podman machine (**Podman machine** in guide 2) — that one
lives in its own small WSL distro managed by Podman.

## Notes

- **Rolling release:** `pacman -Syu` regularly (weekly is plenty). There are no version
  upgrades to babysit — that's the point of choosing Arch.
- **Barebones by design:** the base install is tiny. `pacman -S <pkg>` as you need things;
  `pacman -Ss <term>` to search, `pacman -Fy <file>` to find which package ships a file.
- **Locale:** set to `en_US.UTF-8` during bootstrap. Note WSL tries to match the Windows locale
  on each session — the `/etc/default/locale` symlink created there makes the distro's setting
  win. Want a different locale? Repeat the same commands with that locale's line instead.
- **Fonts:** nothing to install inside WSL — Windows Terminal renders with Windows fonts
  (Maple Mono NF comes from the Windows checklist).
- **Files:** keep repos in the Linux home (`~/...`) for best file-I/O performance; `/mnt/c` is
  much slower for git/builds.
- **Interop:** Windows drives appear under `/mnt/...`, and Windows executables can be called
  from WSL and vice versa.
- **Managing:** `wsl --shutdown` stops the WSL VM; `wsl --export` / `wsl --import` move or back
  up the distro.
