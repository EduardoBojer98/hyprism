# Changelog

All notable changes to Hyprism. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## Unreleased (2.0.0)

### Added

- Full audit, roadmap and feature matrix (`docs/audit/`, `docs/research/`)
- Conventions (`docs/CONVENTIONS.md`)
- `LICENSE` (MIT), `CONTRIBUTING.md`, `VERSION`, this changelog

- Hardware detection: `./install.sh detect` writes `~/.config/hyprism/hardware.toml` (form factor, graphics
  cards, screens, battery, touch, radios, known devices). Correct a wrong guess under `[override]`.
- Modules (`modules/<name>/`): `laptop`, `nvidia`, `nvidia-hybrid`, `asus`, `tablet`, `ddc-monitor`, `logitech`,
  `hibernate` (opt-in) and `quirk-flow-x13`. Each switches on when its hardware is found;
  `./install.sh modules` lists them, `--with` / `--without` override.
- Migrations (`migrations/`), `./install.sh rollback`, `./install.sh backups`, and a log of every run in
  `~/.local/state/hyprism/logs/`.
- `./install.sh uninstall` also undoes the system files and services it changed (kept in a manifest), and moves
  your generated settings aside instead of leaving them.
- `tests/nested.sh`: a test desktop in a window, from this checkout, kept apart from your real session.
- `tests/detect.sh` (seven made-up computers), `tests/format.sh` (shfmt + shellcheck for every shell file).

### Changed

- Every script is formatted with `shfmt -i 4 -ci`
- Finished process notes moved to `docs/history/`

- `install.sh` is a short entry point over `lib/*.sh`. A run that hits a problem ends non-zero with a summary;
  a dry run lists the questions it would ask.
- Bar items can live in their own folder (`bar/items/<id>/`) and every item has its own settings in
  `settings.json` (`bar.items.<id>`): enabled, icon, format, click, right-click, scroll, tooltip, warn, critical.
  See `docs/bar.md`.
- Reactor (acid yellow and orange) is the default theme. Your own choice is kept.
- Hyprland reads the detected hardware (`modules/hardware.lua`): the laptop panel, touch mapping and
  workspace-per-screen rules no longer name `eDP-1` or `HDMI-A-1`.
- Module steps run inside the installer, so `--dry-run` shows each command they would run.
- The lid rule is `/etc/systemd/logind.conf.d/50-hyprism-lid.conf` and only laptops get it.
- Bluetooth is enabled only where there is an adapter.
- State moved from `~/.local/state/linux-setup` to `~/.local/state/hyprism` (migration 0001).

### Removed

- `hosts/` (computers picked by hostname). Replaced by detected modules; migration 0002 carries an existing
  install over.
- `--host` and `steps-done`. Not needed: nothing depends on the hostname any more.
- KDE Plasma guard and the login-screen preselect. Hyprism no longer keeps a KDE fallback.
- JuhRadial MX step for Logitech mice. Replaced by the `logitech` module (Solaar, in both distros' repos).
  An existing JuhRadial install keeps working until you remove it.
- The step that made the LTS kernel the boot default on one laptop (a workaround for a kernel bug). Nothing is
  undone on a computer where it already ran.
- Upgrading straight from before 1.1 (old whole-folder links). Update to 1.1 first.

## 1.1.0 (2026-11-06)

Seven themes with light and dark halves, modular bar and dock, Settings app with one settings file, installer with update, doctor and undo. See `docs/history/` for how it got here.

## 1.0 (2026-10-30)

First release: Quickshell glass shell, Control Center, launcher, tablet mode, installer.
