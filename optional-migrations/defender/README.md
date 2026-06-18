# Optional Defender Migration

Run this only after manually turning **Tamper Protection** off in Windows Security.

```powershell
powershell -ExecutionPolicy Bypass -File .\run-migrations.ps1 `
  -MigrationPath .\optional-migrations\defender `
  -StatePath "$env:ProgramData\Win11Setup\defender-migrations.json"
```

This automates the PowerShell, policy-refresh, and scheduled-task parts from
`defender-disable-steps.md`. It does not and cannot turn Tamper Protection off.
