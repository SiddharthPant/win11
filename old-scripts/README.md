# Old Setup Scripts (Backup)

Superseded by the markdown guides in `../setup/`. Kept as a working script-based alternative:

- **`run-migrations.ps1`** — applies pending scripts from `migrations/`, ordered by filename,
  recorded in `%ProgramData%\Win11Setup\migrations.json`, no rollback path.
- **`migrations/`** — the first-run post-install setup scripts.
- **`optional-migrations/defender/`** — opt-in Defender disable automation (Tamper Protection
  must be turned off first — see `../setup/1-defender-disable-steps.md`).

Run from **this directory** in an elevated PowerShell:

```powershell
Set-ExecutionPolicy RemoteSigned -Scope Process
.\run-migrations.ps1          # apply pending migrations
.\run-migrations.ps1 -List    # preview state only
```
