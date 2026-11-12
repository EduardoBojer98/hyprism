# Architecture

How the repo becomes a desktop. Map: `graphify update .`, then `graphify-out/GRAPH_REPORT.md`.

## The big picture

```
install.sh ── reads the command and flags, loads lib/*.sh, runs one command
  ├► lib/detect.sh  ──► ~/.config/hyprism/hardware.toml  (what this computer has; your [override] is kept)
  ├► lib/distro.sh  ──► distros/<id>.sh ──► packages (packages/manifest.txt → arch.txt | fedora.txt, + each module's packages.txt)
  ├► lib/links.sh   ──► stow --no-folding config/<app>/ and modules/<name>/home/ ──► ~ (one symlink per file; a file in the way is backed up)
  ├► services       ──► Bluetooth, NetworkManager and the rest
  ├► lib/modules.sh ──► the modules that fit hardware.toml (or that you turned on): steps/NN-*.sh, asked one by one
  └► lib/migrate.sh ──► migrations/NNNN-*.sh (update only; each runs once)
        Every change goes through run(), so --dry-run shows it. Each one is recorded, so uninstall can undo it.

Login ─► Hyprland reads ~/.config/hypr/hyprland.lua
           ├─ modules/hardware.lua  (first: what this computer has, from hardware.toml)
           ├─ modules/*.lua         (env, monitors, input, look, animations, binds, rules, windows, plugins, autostart)
           ├─ settings/*.lua        (written by the Settings app; gitignored, live in ~/.config only)
           └─ hardware/*.lua        (last: linked from modules/<name>/home, listed in hardware/index)
         autostart ─► qs (Quickshell) ─► bar, dock, launcher, notifications, OSD, Control Center,
                                         power menu, cheatsheet, Settings app, ThemeSync
                   ├► hypridle, hyprpaper, polkit agent, udiskie, clipboard watcher, monswitch, startup-apps
```

## Pieces

| Area | Files | Notes |
|---|---|---|
| Entry point | `install.sh`, `lib/*.sh` | `install.sh` reads the command (`install` by default, `update`, `doctor`, `detect`, `modules`, `rollback`, `backups`, `uninstall`) and the flags, then loads `lib/` (ui, detect, distro, packages, links, system, modules, migrate, doctor). Flags: `--dry-run`, `--yes`, `--only`, `--with`, `--without`, `--step`, `--backup`. Logs and state: `~/.local/state/hyprism/`. |
| Distro backends | `distros/arch.sh`, `distros/fedora.sh` | Package install, repos (COPR / RPM Fusion), NVIDIA driver. Picked from `/etc/os-release` `ID`, then `ID_LIKE`. |
| Packages | `packages/manifest.txt` (logical name, module, why), `arch.txt`, `fedora.txt` | One line per package with its reason. `--only tools` etc. installs a module. |
| Modules | `modules/<name>/`, `modules/_template/`, `lib/modules.sh`, `lib/detect.sh` | Optional hardware or uses: one folder per kind of hardware or use (list: `docs/modules.md`). `detect` reads `hardware.toml`; a module is on when it fits, or when you turn it on (`--with`, kept under `[override]`). Each has `packages.txt`, `home/` (linked), `steps/` (system changes, asked first), `doctor` and a `README.md`. |
| Hyprland | `config/hypr/.config/hypr/` | Lua config (Hyprland 0.57). `hyprland.lua` loads modules in order. Lock screen `hyprlock.conf` + the generated `settings/hyprlock-theme.conf`; `defaults/` seeds `settings/`. |
| Themes | `themes/<id>/` (linked to `~/.local/share/hyprism/themes/`), `Themes.qml`, `Theme.qml`, `ThemeSync.qml`, `LockScreen.qml`, `Dock.qml`, `Anchor.qml`, `CursorPopup.qml` | A theme is a folder: `theme.json` plus a wallpaper. Yours go in `~/.config/hyprism/themes/`. `Themes.qml` reads the folders and merges your adjustments; `Theme.qml` turns the active theme plus Settings into tokens; `ThemeSync.qml` pushes it to Hyprland, hyprlock, GTK, Qt, Ghostty, btop, the prompt and the wallpaper. The Dock works on any edge beside the bar; `Anchor` records the clicked item so `CursorPopup` opens panels beside it; `LockScreen` builds the lock layout. `docs/THEMES.md`, `docs/DESIGN.md`. |
| Bar | `Bar.qml`, `BarWidget.qml`, `bar/items/<id>/` | One engine lays out three sections of items on any edge. Each item is a folder: `Item.qml`, `defaults.json`, `README.md`. `docs/bar.md`. |
| Metrics | `Metrics.qml`, `config/scripts/.local/bin/metrics` | The `metrics` script reads system numbers (found by kind of device, never by name) and prints JSON; `Metrics.qml` runs it only while a bar item shows a reading. |
| Shell | `config/quickshell/.config/quickshell/` | One file per panel. `shell.qml` is the root. `ConfigData.qml` holds every user default, `Config.qml` loads, saves and validates `settings.json` and answers IPC (`qs ipc call config set …`). `SettingsApp.qml` and `SettingsPage*.qml` are the Settings app (`Super+I`). |
| Scripts | `config/scripts/.local/bin/` | `theme`, `theme-wallpaper`, `screenshot`, `screentext` (OCR), `record`, `dropterm`, `webapp`, `remind`, `monswitch` (DDC/CI input switch), `panel` (lid, tablet mode), `powermode`, `nv` (run on NVIDIA), `clipstore`, `emojipick`, `startup-apps`, `installed-apps`, `theme-add`, `hypr-plugins`. |
| Fonts | `config/fonts/.local/share/fonts/hyprism/` | OFL fonts the themes use that the distros don't package (licences beside them). |
| Apps | `config/ghostty`, `config/fish`, `config/starship`, `config/fuzzel`, `config/fastfetch`, `config/satty`, `config/chrome`, `config/arch-update`, `config/wallpapers` | Each mirrors `~`. |
| Plugin | `plugins/minimize/main.cpp` | Title-bar minimise button support; built at login by `hypr-plugins`. |
| Checks | `tests/`, `.github/workflows/ci.yml`, `.githooks/pre-commit` | `tests/lint.sh` runs the static checks and the script tests (QML, Lua, colours, themes, formatting, docs links); `tests/detect.sh` detection on seven made-up computers; `tests/container-test.sh` a full install in Arch and Fedora containers; `tests/update-test.sh` an update from the last release; `tests/all.sh` runs them through Docker; `tests/nested.sh` opens a test desktop. CI runs them on every push. Pre-commit: gitleaks. |
| Migrations | `migrations/NNNN-*.sh`, `lib/migrate.sh` | One-time changes that carry an old install to a newer layout; each runs once on `update`. |
| Dev tooling | `CLAUDE.md`, `.claude/settings.json`, Graphify | `uv tool install graphifyy`; `graphify update .` rebuilds `graphify-out/` (gitignored). |

## Where values live (change them here)

| What | File |
|---|---|
| The whole look: colours, fonts, shapes, bar style and items, dock, motion | `themes/<id>/theme.json` (rules: `docs/DESIGN.md`); adjust per theme in Settings → Appearance → Themes |
| Bar place, size and items; dock place | Settings → Menu Bar, Settings → Dock (`Config.bar`, `Config.dock`) |
| Defaults of every Settings option | `config/quickshell/.config/quickshell/ConfigData.qml` |
| Keybinds | `config/hypr/.config/hypr/modules/binds.lua` (Super+/ shows them; Settings can override) |
| Gaps, border, glow, blur, shadows | `config/hypr/.config/hypr/modules/look.lua` (border/gap values come from Settings → theme.lua) |
| Animations | `config/hypr/.config/hypr/modules/animations.lua` (presets the themes name) |
| Monitors | Settings → Displays (writes `settings/displays.lua`, read by `config/hypr/.config/hypr/modules/monitors.lua`); the laptop panel name comes from `hardware.toml` (`display.internal`), read in `config/hypr/.config/hypr/modules/hardware.lua` |
| Window rules | `config/hypr/.config/hypr/modules/rules.lua` |
| Startup programs | `config/hypr/.config/hypr/modules/autostart.lua` (desktop pieces), Settings → Startup Apps (`~/.config/autostart`) |

## Your files vs. repo files

Stow links file by file (`--no-folding`), so `~/.config/hypr/settings/`, `~/.config/quickshell/settings.json`,
`~/.config/ghostty/theme.conf` and `~/.config/autostart/` are real files in your home folder, never in the repo.
`./install.sh doctor` lists anything that drifted.
