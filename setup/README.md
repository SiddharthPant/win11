# Post-Install Setup Guides (Markdown Edition)

Read-first, edit-by-hand checklists for everything that happens **after Windows 11 finishes
installing** — the Windows side, and the Arch Linux WSL distro.

These guides replace the script-runner workflow for daily use. There is nothing to execute:
read each file and copy the commands you need. To change your setup, edit the markdown and
commit it.

> **Backup path:** `old-scripts/` at the repo root (the migration runner plus `migrations/`
> and `optional-migrations/`) is kept as the script-based alternative. If you ever want the
> automated flow instead, follow the root `README.md` build order. Don't edit applied
> migrations; this directory has no such constraint.

## Guides, in order

1. **`1-defender-disable-steps.md`** — do this **first**, before installing anything: turn
   Tamper Protection off in Windows Security, then pick one of the disable options in the
   guide.
2. **`2-windows-after-install.md`** — first boot on Windows: WSL install, winget apps, PostgreSQL 18, Maple Mono
   NF font, Git defaults, Windows Terminal, Podman machine, Windows Update policy.
3. **`3-wsl-arch.md`** — inside WSL: Arch Linux bootstrap from its barebones root-only image
   (sudo, user account, default user), systemd, dev packages, Git, and native rootless Podman.

## Conventions

- Each guide is an ordered checklist; do the sections top to bottom.
- Section headings are unnumbered and referenced by name ("see **Podman machine**"), so inserting
  or reordering a section never forces renumbering of headings or cross-guide references.
- Commands are copy-pasteable. Admin/privileged blocks are labeled with where to run them.
- Personal values (usernames, emails, identities) are intentionally not automated — set them
  per machine, per identity, by hand.
