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
- A firewall step (`./install.sh --only firewall`): when none is active it asks, then turns on ufw (Arch) or
  firewalld (Fedora), blocking incoming connections. The doctor notes when there is none.
- `tests/update-test.sh` and a CI job `update`: install release 1.1.0, then update to this code, and check the
  migrations ran once, no link is dead and the doctor is clean.

### Changed

- Every script is formatted with `shfmt -i 4 -ci`
- Finished process notes moved to `docs/history/`

- `install.sh` is a short entry point over `lib/*.sh`. A run that hits a problem ends non-zero with a summary;
  a dry run lists the questions it would ask.
- Themes are folders (`themes/<id>/theme.json` + wallpaper). Copy `_template`, edit one file, `theme <id>`: no
  code changes. Yours go in `~/.config/hyprism/themes/`. Terminal colours come from the theme file. The contrast
  test also covers accents, status colours, bar text and the terminal palette. See `docs/THEMES.md`.
- A system-info bar item (`sysinfo`): pick any of 25 readings, their order, compact or detailed, levels per
  reading, "only above", and a trend in the tooltip. One `metrics` program feeds it, found by kind of device.
- Bar items can live in their own folder (`bar/items/<id>/`) and every item has its own settings in
  `settings.json` (`bar.items.<id>`): enabled, icon, format, click, right-click, scroll, tooltip, warn, critical.
  See `docs/bar.md`.
- Reactor (acid yellow and orange) is the default theme. Your own choice is kept.
- Hyprland reads the detected hardware (`modules/hardware.lua`): the laptop panel, touch mapping and
  workspace-per-screen rules no longer name `eDP-1` or `HDMI-A-1`.
- Module steps run inside the installer, so `--dry-run` shows each command they would run.
- The lid rule is `/etc/systemd/logind.conf.d/50-hyprism-lid.conf` and only laptops get it.
- Bluetooth is enabled only where there is an adapter.
- AUR packages, COPR repos and RPM Fusion are named and asked about before they are trusted (answered yes
  under `--yes`).
- The extra Hyprland plugins (title-bar buttons) are no longer downloaded and built at login. Login only loads
  what is built; `./install.sh update` runs `hypr-plugins build`, which checks the download against a pinned
  commit and refuses a Hyprland version that has no pin.
- Autostart finds the polkit agent on Arch and Fedora, and unlocks KWallet or starts GNOME Keyring, whichever
  is installed.
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
