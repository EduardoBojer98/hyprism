# Conventions

The rules every change follows. Short on purpose: if a rule isn't here, copy what the file next to yours does.

## Hard rules

1. **Free software only.** No paid apps, trials or subscriptions.
2. **Few dependencies.** A new package needs one line in `packages/manifest.txt` (or its module's
   `packages.txt`) saying why, and a row in `docs/DECISIONS.md`.
3. **Our own code.** Other projects are for ideas. Nothing is copied or vendored.
4. **No hardware names in core.** No monitor names (`eDP-1`), PCI addresses, battery names (`BAT0`), sensor
   driver names, resolutions, vendor names or hostnames outside `modules/<name>/` and `tests/fixtures/`.
   Core asks `hardware.toml`. `tests/no-hardcode.sh` enforces this.
5. **No distro commands outside `distros/`.** No `pacman`, `dnf`, `rpm`, `paru`, bootloader tools or
   distro-only paths anywhere else. Add a backend function instead.
6. **Never break the running desktop.** Test in a container, a dry run or a nested session. Ask the owner before
   applying to the live session, installing packages or writing system files.

## Names and places

| Thing | Rule |
|---|---|
| Project name | Hyprism. The command on the PATH is `hyprism`. |
| User config | `~/.config/hyprism/` (`hardware.toml`, `themes/`). Shell settings: `~/.config/quickshell/settings.json`. |
| State, logs, backups | `~/.local/state/hyprism/` (`logs/`, `backups/`, `migrations/`, `manifest`) |
| Files, folders, scripts | lower-case, words joined by `-` (`theme-wallpaper`). QML types are `PascalCase.qml`. |
| Settings keys | `camelCase`, plain words, the unit in a comment (`warnAt: 15  // %`) |
| Module | `modules/<name>/`: `detect`, `packages.txt`, `home/`, `steps/`, `doctor`, `README.md` (all optional but `detect` and `README.md`) |
| Theme | `themes/<id>/`: `theme.json`, `wallpaper.*`, optional `overrides/` |
| Bar item | `bar/items/<id>/`: `Item.qml`, `defaults.json`, `README.md` |
| Migration | `migrations/NNNN-what-it-does.sh`, four digits, never renumbered, never edited after release |

## Shell scripts

- Bash, `#!/usr/bin/env bash`, then a comment block that **is** the help text: what it does, then one usage line
  per command. `usage` (from the shared library) prints that block, so help can't drift.
- `set -euo pipefail` right after the header. A script that must not stop on errors says why in a comment.
- Source the shared library instead of copying helpers:
  - installer code: `lib/*.sh` in the repo;
  - desktop scripts: `~/.local/lib/hyprism/common.sh` (from `config/scripts/.local/lib/hyprism/`).
- Messages go through `say`, `warn`, `bad`, `ok`. Anything that changes the system goes through `run`, so
  `--dry-run` shows it.
- Don't hide errors. `|| true` and `2>/dev/null` need a reason on the same line; otherwise log with `log`.
- Values from files or users are data: pass them as arguments, never build a command string from them, never
  `source` a config file.
- Every script that changes something is safe to run twice.
- Formatting: `shfmt -i 4 -ci`. Lint: `shellcheck -S style`. Both run in CI.

## QML (the shell)

- One component per file, at most about 400 lines. Split by section before it grows past that.
- Folders: `bar/` (engine and `items/`), `panels/`, `settings/`, `controls/` (shared buttons, sliders, rows),
  `services/` (singletons: `Config`, `Theme`, `Themes`, `Machine`, `Metrics`, sync writers).
- Colours, sizes, radii, fonts and motion come from `Theme`. No hex colour outside `themes/`.
- State lives in `Config` (`settings.json`). A page never writes another file itself; writers in `services/`
  generate files from `Config` and skip the write when the text is unchanged.
- Hardware comes from `Machine` (which reads `hardware.toml`). A component for absent hardware is not created,
  rather than created and hidden.
- Polling: use an event where one exists. A timer must be tied to something visible, and its interval is a setting.
- Every interactive control takes keyboard focus and has `Accessible.name` and `Accessible.role`.
- A state shown by colour also has a glyph or text.

## Hyprland (Lua)

- `hyprland.lua` loads `modules/*.lua` in a fixed order; each module is one topic.
- Values the Settings app owns come from generated files in `~/.config/hypr/settings/`, loaded with `pcall` so a
  bad file can't stop the session.
- A bind has an id, a group and a description (the cheat sheet reads them). Binds for optional hardware are
  registered only when `hardware.toml` says it is there.

## Comments and docs

- Comments say **why**, in one line. The code says what.
- Write for someone who has never seen the repo: short sentences, plain words, no time estimates.
- A user-visible change updates `CHANGELOG.md` (under "Unreleased") and the doc that describes it, in the same commit.
- A removal says in the changelog what was removed and what replaces it.

## Git

- Work on a branch, never on `main`. Merging needs the owner's OK.
- Conventional Commits, one logical change each: `feat(bar): …`, `fix(install): …`, `refactor(theme): …`,
  `docs: …`, `test: …`, `style: …`, `chore: …`.
- No secrets, ever. The gitleaks hook and CI check every commit.

## Checks before a change counts as done

```bash
tests/lint.sh
```

```bash
docker run --rm -v "$PWD":/mnt/repo:ro archlinux:latest bash /mnt/repo/tests/container-test.sh
```

```bash
docker run --rm -v "$PWD":/mnt/repo:ro fedora:latest bash /mnt/repo/tests/container-test.sh
```

A sub-agent's report is not proof. The lead reads the diff and runs the checks.

## How to add things

| To add | Do |
|---|---|
| A package | a line in `packages/manifest.txt` (name, module, why), its real name in `packages/arch.txt` and `packages/fedora.txt` |
| A setting | default in `ConfigData.qml`, rule in `Config.qml`'s schema, a row on its Settings page, a search word |
| A hardware module | copy `modules/_template/`, write `detect` (exit 0 when the hardware is present), list packages, add a `doctor` |
| A theme | copy `themes/_template/`, edit `theme.json`, add a wallpaper |
| A bar item | copy `bar/items/_template/`, edit the three files |
| A metric | one entry in `services/Metrics.qml`'s registry and a line in `docs/bar.md` |
| A migration | next number in `migrations/`, safe to run twice, works under `--dry-run` |
