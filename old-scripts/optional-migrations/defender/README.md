# Optional Defender Migration

Run from `old-scripts/` (so the script finds `migrations/_helpers.ps1`), only after manually
turning **Tamper Protection** off in Windows Security.

```powershell
Set-ExecutionPolicy RemoteSigned -Scope Process
.\run-migrations.ps1 `
  -MigrationPath .\optional-migrations\defender `
  -StatePath "$env:ProgramData\Win11Setup\defender-migrations.json"
```

This automates the PowerShell, policy-refresh, and scheduled-task parts from
`defender-disable-steps.md`. It does not and cannot turn Tamper Protection off.
