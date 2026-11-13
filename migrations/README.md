# Migrations

One-time changes that carry an existing install over to a newer layout. `./install.sh update` (and `install`)
runs the ones that haven't run yet, in number order, and remembers them in `~/.local/state/hyprism/migrations/`.
A fresh install marks them all as done without running them.

Rules:

- Name: `NNNN-what-it-does.sh`, four digits, the next free number. Never renumber or edit one after a release.
- The comment block at the top says, in plain words, what moves where. It is shown before the migration runs.
- Plain bash, run inside the installer: use `run`, `say`, `warn`, `sys_write`, `sys_remove`, `hw_get`.
  Everything that changes something goes through `run` so `--dry-run` shows it.
- Safe to run twice. It must do nothing when there is nothing to carry over.
- Never delete a user's file: move it, and say where.
