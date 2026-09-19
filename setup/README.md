# Post-Install Setup Guides (Markdown Edition)

Read-first, edit-by-hand checklists for everything that happens **after Windows 11 finishes
installing** — the Windows side, and the Fedora 44 WSL distro.

These guides replace the script-runner workflow for daily use. There is nothing to execute:
read each file, copy the commands you need, and tick the checkboxes. To change your setup,
edit the markdown and commit it.

> **Backup path:** `migrations/`, `optional-migrations/`, and `run-migrations.ps1` at the repo
> root are kept as the script-based alternative. If you ever want the automated flow instead,
> follow the root `README.md` build order. Don't edit applied migrations; this directory has no
> such constraint.

## Guides, in order

1. **`windows-after-install.md`** — first boot on Windows: WSL install, winget apps, Maple Mono
   NF font, Git defaults, Windows Terminal, Docker group, Windows Update policy.
2. **`wsl-fedora-44.md`** — inside WSL: Fedora distro updates, systemd, dev packages, Git, and
   Docker Desktop integration.

Optional, still manual: **`../defender-disable-steps.md`** for the full Defender disable
runbook (after turning Tamper Protection off in the GUI).

## Conventions

- Each guide is an ordered checklist; do the sections top to bottom.
- Commands are copy-pasteable. Admin/privileged blocks are labeled with where to run them.
- Personal values (usernames, emails, identities) are intentionally not automated — set them
  per machine, per identity, by hand.
