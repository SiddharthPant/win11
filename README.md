# Windows 11 25H2 Pro — Dual-Boot Answer File

Windows 11 setup notes for a dual-boot desktop. `autounattend.xml` handles edition selection,
policy/registry setup, and first-logon
personalization after you choose the target disk and complete Microsoft-account OOBE. Run
`run-migrations.ps1` once from the desktop for apps, font, Chrome defaults, WSL, and all future
incremental setup changes.

## Files

- **`autounattend.xml`** — primary answer file: Pro edition key, machine-wide policies,
  OOBE trimming, first-logon user tweaks, debloat, System Restore, and network profile.
- **`autounattend.minimal.xml`** — bare-bones backup that only prevents automatic BitLocker
  device encryption. Rename it to `autounattend.xml` for a mostly vanilla install.
- **`bootable-usb.md`** — step-by-step guide for creating a bootable USB from the official
  Windows 11 ISO, including the FAT32 WIM-splitting flow used from macOS.
- **`run-migrations.ps1`** — up-only migration runner. It applies pending scripts from
  `migrations/` and records successful runs in `%ProgramData%\Win11Setup\migrations.json`.
- **`migrations/`** — post-install setup and future one-off changes, named so they sort in the
  order you want them applied.
- **`defender-disable-steps.md`** — manual checklist for fully disabling Defender after
  Tamper Protection is turned off in Windows Security.
- **`optional-migrations/defender/`** — opt-in Defender disable automation to run only after
  Tamper Protection is manually turned off.

## Build Order

1. **Make the USB:** follow `bootable-usb.md`, including the `autounattend.xml` copy step.
2. In firmware, disable CSM/Legacy, enable Secure Boot and TPM, then boot the USB's
   **`UEFI:`** entry.
3. At Windows Setup, target the Windows disk manually. Use Shift+F10 -> `diskpart` ->
   `list disk` -> `select disk N` -> `clean` -> `convert gpt` -> `exit`, replacing `N` with the
   intended Windows disk number, then install to the unallocated space so Windows creates EFI +
   MSR + Windows + Recovery partitions.
4. **Do not touch any existing data or Linux disks.**
5. Complete OOBE with the Microsoft account. The first-logon commands run when the desktop
   is created.
6. Confirm activation if needed: Settings -> System -> Activation. The key in the answer
   file only selects Pro; the digital license is tied to the Microsoft account/hardware.
7. Open an elevated PowerShell, allow scripts for that terminal with
   `Set-ExecutionPolicy RemoteSigned -Scope Process`, then run `.\run-migrations.ps1` once with
   internet access.
8. Later, pull repo changes, repeat the process-scoped execution policy command in an elevated
   PowerShell, then run `.\run-migrations.ps1` again to apply only new migrations.
9. Reboot to finish WSL. The first `wsl` launch creates the Linux username/password.
10. Optional: finish Defender disable using `defender-disable-steps.md`.

## What `autounattend.xml` Does

**During specialize / machine-wide:** selects Windows 11 Pro, prevents automatic BitLocker
device encryption, applies Defender policy values, lowers telemetry, disables web search,
Widgets/news, Spotlight/consumer content, Copilot/Windows AI policy, location, advertising ID,
AutoRun, and Start Recommended. It also enables long paths, Developer Mode, Sudo for Windows
inline mode, and Hardware-Accelerated GPU Scheduling. Locale defaults to en-US UI, en-IN region,
US keyboard, and India Standard Time; customize these before install if needed.

**At first logon / per-user:** keeps online Microsoft-account OOBE, removes selected inbox apps
(Copilot, Bing News/Weather, Maps, Feedback Hub, Get Help/Get Started, Office hub, Solitaire,
People, Mixed Reality Portal, Wallet, Teams, new Outlook, old Mail/Calendar, Widgets host, and
Cortana), shows the five standard desktop icons, shows file extensions and hidden files, hides
taskbar search/widgets/Copilot, left-aligns the taskbar, enables dark mode and clock seconds,
opens Explorer to This PC, shows all drives, expands the navigation pane, enables End Task on
taskbar right-click, disables Sticky Keys prompt and mouse acceleration, enables NumLock, suppresses
Start/Explorer/Settings suggestions, suppresses new-app default prompts, enables Ultimate
Performance, turns on System Restore for C: with a 10 GB cap, and sets the network profile to
Private.

## What Migrations Install

- **`20260618_0001_install-winget-apps.ps1`:** Chrome, Spotify, Notion, Git, VS Code,
  PowerShell 7, Docker Desktop, PowerToys, Everything, NanaZip, SumatraPDF, ShareX.
- **`20260618_0002_install-maple-mono-nf.ps1`:** Maple Mono NF from GitHub releases.
- **`20260618_0003_set-chrome-default.ps1`:** Chrome via SetUserFTA config file
  (`http`, `https`, `.htm`, `.html`).
- **`20260618_0004_install-wsl-ubuntu.ps1`:** WSL2 stack + Ubuntu, installed without launching.
- **`20260618_0005_install-store-apps.ps1`:** WhatsApp and Netflix from the Microsoft Store.
- **`20260618_0006_configure-git-defaults.ps1`:** Git defaults for branch naming, line endings,
  long paths, pruning, fast-forward-only pulls, and Git Credential Manager.
- **`20260618_0007_configure-windows-terminal.ps1`:** Windows Terminal defaults to PowerShell 7
  and Maple Mono NF.
- **`20260618_0008_configure-docker-user.ps1`:** adds the current Windows user to `docker-users`.
- **`20260618_0009_configure-windows-update.ps1`:** sets active hours and prevents auto-reboots
  while a user is logged on.

SetUserFTA note: the migration downloads the public Personal Edition from
`https://setuserfta.com/SetUserFTA.zip`; the old `https://kolbi.cz/SetUserFTA.zip` URL returns
404. SetUserFTA v2.x is customer-only; as of the checked official version history, current v2 is
2.7.3, released on 2025-12-16. The script uses the config-file syntax documented for v2 and still
compatible with the public Personal Edition. If Windows asks for WMIC for the Personal Edition,
follow the prompt or substitute a licensed v2 `SetUserFTA.exe`.

To add/remove apps, edit the relevant migration or add a new migration.

## Migrations

Use migrations for first-run post-install setup and for changes you want to apply later to an
already-installed PC. Add a new PowerShell file under `migrations/`, commit it, then run:

```powershell
Set-ExecutionPolicy RemoteSigned -Scope Process
.\run-migrations.ps1
```

The `Process` scope lasts only for the current elevated PowerShell session.

The runner sorts migration filenames lexically, skips anything already recorded, and records a
script only after it exits successfully. Keep migration scripts small and idempotent enough to
survive a failed half-run, because there is intentionally no down/rollback path.

To preview state without applying anything:

```powershell
Set-ExecutionPolicy RemoteSigned -Scope Process
.\run-migrations.ps1 -List
```

## Notes

- **Disk safety:** confirm the Windows target disk by size/model before partitioning; do not touch
  existing data or Linux disks.
- **Takes effect after a reboot:** Developer Mode, Sudo, HAGS, WSL completion.
- **Fast Startup:** left on by choice. No dual-boot RTC=UTC fix is applied, so expect a Windows/
  Linux clock offset until you set one side to match. Turn Fast Startup off manually before relying
  on Linux writes to Windows NTFS partitions.
- **Defender:** registry policy is applied by the answer file, but a full disable still depends on
  turning Tamper Protection off in the GUI first. After that, run the optional Defender migration
  from `defender-disable-steps.md`. Feature updates can re-enable it.
