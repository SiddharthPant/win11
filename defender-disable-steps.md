# Disabling Microsoft Defender — Post-Install Runbook

**Target:** Windows 11 Pro desktop.

> **Read this first.** On current Windows 11, Defender cannot be killed purely from a script or the registry while **Tamper Protection** is on — it reverts every change. There is no single switch that disables it permanently and survives every feature update. What works is a **layered** approach below. The single most reliable "permanent" option is **Option B (install a third-party AV)**, which puts Defender into passive mode automatically. Pick Option A *or* B; Option C is the nuclear route if you want the service itself gone.

Your `autounattend.xml` already pre-staged the Defender policy registry keys, so several of these are half-done at first boot — they just can't take effect until Tamper Protection is off.

---

## Step 0 — Prerequisite: turn off Tamper Protection (mandatory)

Nothing below sticks until this is done. For this unmanaged local install, do it in the GUI; registry/GPO/PowerShell changes to protected settings are ignored while Tamper Protection is on.

1. Open **Windows Security** (Start → search "Windows Security").
2. **Virus & threat protection** → under *Virus & threat protection settings*, click **Manage settings**.
3. Toggle **Tamper Protection** → **Off**. Accept the UAC prompt.

Leave Windows Security open; you'll use it again in Step 1.

---

## Option A — Layered manual disable (no third-party AV)

Holds for normal daily use. A major feature update can reset some of these, so re-check afterward (see "After Windows Updates").

### Step 1 — Turn off the real-time toggles (GUI)

Same **Manage settings** pane, turn all of these **Off**:

- Real-time protection
- Cloud-delivered protection
- Automatic sample submission
- Tamper Protection (already off from Step 0)

### Step 2 — Lock it down via PowerShell (run as admin)

With Tamper Protection off, these now apply. Open **Terminal (Admin)**:

```powershell
Set-MpPreference -DisableRealtimeMonitoring $true
Set-MpPreference -DisableBehaviorMonitoring $true
Set-MpPreference -DisableScriptScanning $true
Set-MpPreference -DisableArchiveScanning $true
Set-MpPreference -DisableIOAVProtection $true
Set-MpPreference -MAPSReporting Disabled
Set-MpPreference -SubmitSamplesConsent NeverSend
```

Or run the optional migration from the repo root:

```powershell
Set-ExecutionPolicy RemoteSigned -Scope Process
.\run-migrations.ps1 `
  -MigrationPath .\optional-migrations\defender `
  -StatePath "$env:ProgramData\Win11Setup\defender-migrations.json"
```

This also reapplies the registry policy backstops, runs `gpupdate /force`, and disables the
Windows Defender scheduled tasks in Step 4.

### Step 3 — Group Policy (Pro has gpedit)

Run `gpedit.msc`:

- **Computer Configuration → Administrative Templates → Windows Components → Microsoft Defender Antivirus**
  - `Turn off Microsoft Defender Antivirus` → **Enabled**
- **…→ Microsoft Defender Antivirus → Real-time Protection**
  - `Turn off real-time protection` → **Enabled**
  - `Turn off behavior monitoring` → **Enabled**

> Note: Microsoft deprecated the old `DisableAntiSpyware` value years ago, so on consumer SKUs the "Turn off Microsoft Defender Antivirus" policy may be partially ignored even with Tamper Protection off. It still contributes; the real-time + scheduled-task steps do the heavy lifting.

Then apply:

```powershell
gpupdate /force
```

### Step 4 — Disable the scheduled scans

This is the "virus scans" part. Open **Task Scheduler** (`taskschd.msc`) →
**Task Scheduler Library → Microsoft → Windows → Windows Defender**, and **Disable** all four:

- Windows Defender Cache Maintenance
- Windows Defender Cleanup
- Windows Defender Scheduled Scan
- Windows Defender Verification

### Step 5 — (Optional) SmartScreen / reputation checks

If you also want the file/web reputation prompts gone:

- Windows Security → **App & browser control → Reputation-based protection settings** → turn off *Check apps and files*, *SmartScreen for Microsoft Edge*, *Potentially unwanted app blocking*.

### Step 6 — Reboot and verify

```powershell
Get-MpComputerStatus | Select RealTimeProtectionEnabled, AntivirusEnabled, BehaviorMonitorEnabled, IsTamperProtected
```

`RealTimeProtectionEnabled` should be `False` and `IsTamperProtected` should be `False`.

---

## Option B — Install a third-party antivirus (most reliable "permanent")

When a registered AV product is installed, Windows **automatically** flips Defender into **passive mode** — real-time scanning steps aside without you fighting Tamper Protection, and it stays that way across updates.

1. Do **Step 0** (Tamper Protection off) — optional but recommended.
2. Install any reputable third-party AV.
3. Verify:
   ```powershell
   Get-MpComputerStatus | Select AMRunningMode
   ```
   It should report `Passive Mode` (or `EDR Block Mode`), not `Normal`.

Caveat: in passive mode some components (network inspection, AMSI, periodic scan) can still run lightly, so it's "passive," not 100% gone — but it's the cleanest durable result without hacks.

---

## Option C — Disable the WinDefend service itself (nuclear, advanced)

Only if Options A/B aren't enough. The `WinDefend` service is a protected process (PPL) and **cannot** be stopped or set to disabled normally, even as admin. The service start type can only be changed offline / in Safe Mode, and **feature updates may re-protect and re-enable it**.

1. Tamper Protection **off** (Step 0).
2. Boot into **Safe Mode**: Settings → System → Recovery → Advanced startup → Restart now → Troubleshoot → Advanced options → Startup Settings → Restart → press **4**.
3. In Safe Mode, in the registry (`regedit`), set the `Start` value to `4` (disabled) for the Defender services under `HKLM\SYSTEM\CurrentControlSet\Services\`:
   - `WinDefend`, `WdNisSvc`, `WdNisDrv`, `WdFilter`, `Sense`
4. Reboot normally.

> Third-party "Defender Control"–type tools automate this, but they break across updates and some get flagged. Treat Option C as something you may need to re-do after big updates.

---

## After Windows Updates (important)

Cumulative and especially **feature updates** can silently:

- Re-enable real-time protection
- Reset the Group Policy values
- Re-protect / re-enable the WinDefend service
- Re-stage removed apps (Copilot, etc.)

After any large update, re-run the **Step 6 verify** command. If `RealTimeProtectionEnabled` came back `True`, re-confirm Tamper Protection is off and re-apply Steps 1–4 (or just rely on Option B, which survives updates best).

---

## Security note

This machine is set up unencrypted (no BitLocker) and with Defender disabled. That's a reasonable trade for a home desktop you control physically, but you're removing two safety nets at once. Worth compensating with: a separate AV (Option B) if you only wanted Defender's overhead gone rather than *all* protection, keeping backups of anything important on a separate disk or external backup target, and caution with downloads/email since nothing is scanning them. Your call — just going in eyes open.
