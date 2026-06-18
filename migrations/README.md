# Migrations

Put first-run post-install setup and future one-off Windows changes here as PowerShell scripts.

Suggested naming:

```text
YYYYMMDD_NNNN_short-description.ps1
```

Examples:

```text
20260618_0001_enable-terminal-profile.ps1
20260618_0002_configure-docker-wsl.ps1
```

Run from an elevated PowerShell at the repo root:

```powershell
powershell -ExecutionPolicy Bypass -File .\run-migrations.ps1
```

Preview migration state:

```powershell
powershell -ExecutionPolicy Bypass -File .\run-migrations.ps1 -List
```

Rules of thumb:

- One concern per migration.
- Prefer idempotent commands where practical.
- Do not edit a migration after it has been applied; add a new migration instead.
- There is no down migration. If a change needs reversal, add a new up migration that reverses it.
