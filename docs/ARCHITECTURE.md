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
| Modules | `modules/<name>/`, `modules/_template/`, `lib/modules.sh`, `lib/detect.sh` | Optional hardware or uses: `laptop`, `nvidia`, `asus`, `tablet`, and so on. `detect` reads `hardware.toml`; a module is on when it fits, or when you turn it on (`--with`, kept under `[override]`). Each has `packages.txt`, `home/` (linked), `steps/` (system changes, asked first), `doctor` and a `README.md`. |
| Hyprland | `config/hypr/.config/hypr/` | Lua config (Hyprland 0.57). `hyprland.lua` loads modules in order. Lock screen `hyprlock.conf` + the generated `settings/hyprlock-theme.conf`; `defaults/` seeds `settings/`. |
| Themes | `Themes.qml`, `Theme.qml`, `ThemeSync.qml`, `LockScreen.qml`, `Bar.qml` + `BarWidget.qml` + `Bar*.qml`, `Dock.qml`, `Anchor.qml`, `CursorPopup.qml`, `Sys.qml` | Themes.qml holds the 6 designs as data (and the bar item catalogue) and merges your adjustments; Theme turns the active one plus Settings into tokens; ThemeSync pushes it to Hyprland, hyprlock, GTK, Ghostty, wallpaper. One Bar engine lays out three sections of BarWidget items on any edge; the Dock works on any edge beside the bar; Anchor records the clicked item so CursorPopup opens panels beside it with the theme's motion; LockScreen builds the lock layout for hyprlock and the Settings preview. `docs/DESIGN.md`. |
| Shell | `config/quickshell/.config/quickshell/` (~105 QML files) | `shell.qml` root. `ConfigData.qml` = every user default, `Config.qml` = load/save/validate `settings.json` + IPC (`qs ipc call config set …`). `Theme.qml` = design tokens. `ThemeSync.qml` = pushes tokens to Hyprland, hyprlock, GTK, Ghostty, fuzzel. `SettingsApp.qml` + `SettingsPage*.qml` = the Settings app (Super+I). |
| Scripts | `config/scripts/.local/bin/` | `theme`, `theme-wallpaper`, `screenshot`, `screentext` (OCR), `record`, `dropterm`, `webapp`, `remind`, `monswitch` (DDC/CI input switch), `panel` (lid, tablet mode), `powermode`, `asusfan`, `nv` (run on NVIDIA), `clipstore`, `emojipick`, `startup-apps`, `installed-apps`, `theme-add`, `hypr-plugins`, `thermlog`. |
| Fonts | `config/fonts/.local/share/fonts/linux-setup/` | OFL fonts the themes use that the distros don't package (licences beside them). |
| Apps | `config/ghostty`, `config/fish`, `config/starship`, `config/fuzzel`, `config/fastfetch`, `config/satty`, `config/chrome`, `config/arch-update`, `config/wallpapers` | Each mirrors `~`. |
| Plugin | `plugins/minimize/main.cpp` | Title-bar minimise button support; built at login by `hypr-plugins`. |
| Checks | `tests/lint.sh`, `tests/detect.sh`, `tests/format.sh`, `tests/container-test.sh`, `.github/workflows/ci.yml`, `.githooks/pre-commit` | `lint.sh`: QML, Lua, colours, themes and the script tests. `detect.sh`: detection on seven made-up computers. `format.sh`: shfmt and shellcheck. `container-test.sh`: a full install in Arch and Fedora containers, run twice, then doctor and uninstall. CI runs these on every push. Pre-commit: gitleaks. Local shellcheck without installing it: `docker run --rm -v "$PWD:/mnt" -w /mnt koalaman/shellcheck:stable -S warning install.sh lib/*.sh distros/*.sh modules/*/steps/*.sh config/scripts/.local/bin/*` |
| Dev tooling | `CLAUDE.md`, `.claude/settings.json`, Graphify | `uv tool install graphifyy`; `graphify update .` rebuilds `graphify-out/` (gitignored). |

## Where values live (change them here)

| What | File |
|---|---|
| The whole look: colours, fonts, shapes, bar style and items, dock, motion | `config/quickshell/.config/quickshell/Themes.qml` (rules: `docs/DESIGN.md`); adjust per theme in Settings → Appearance → Themes |
| Bar place, size and items; dock place | Settings → Menu Bar, Settings → Dock (`Config.bar`, `Config.dock`) |
| Defaults of every Settings option | `config/quickshell/.config/quickshell/ConfigData.qml` |
| Keybinds | `config/hypr/.config/hypr/modules/binds.lua` (Super+/ shows them; Settings can override) |
| Gaps, border, glow, blur, shadows | `modules/look.lua` (border/gap values come from Settings → theme.lua) |
| Animations | `modules/animations.lua` (presets the themes name) |
| Monitors | Settings → Displays (writes `settings/displays.lua`, read by `modules/monitors.lua`); the laptop panel name comes from `hardware.toml` (`display.internal`), read in `modules/hardware.lua` |
| Window rules | `modules/rules.lua` |
| Startup programs | `modules/autostart.lua` (desktop pieces), Settings → Startup Apps (`~/.config/autostart`) |

## Your files vs. repo files

Stow links file by file (`--no-folding`), so `~/.config/hypr/settings/`, `~/.config/quickshell/settings.json`,
`~/.config/ghostty/theme.conf` and `~/.config/autostart/` are real files in your home folder, never in the repo.
`./install.sh doctor` lists anything that drifted.
