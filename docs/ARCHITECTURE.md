# Architecture

How the repo becomes a desktop. Written from the Graphify map (`graphify update .`, then
`graphify-out/GRAPH_REPORT.md`) and the live machine, 2026-11-04.

## The big picture

```
install.sh ──► distros/<id>.sh ──► packages (packages/manifest.txt → arch.txt | fedora.txt, + hosts/<h>/packages.txt)
          ├──► stow --no-folding config/<app>/  ──► ~ (one symlink per file, back to this repo)
          ├──► hosts/<h>/home/                  ──► ~ (per-computer files, same way)
          ├──► hosts/<h>/defaults/              ──► ~ (copied once, then yours)
          ├──► services + login session (Hyprland default, KDE kept)
          └──► hosts/<h>/steps/NN-*.sh          (system steps; *.user.sh run as you)

Login ─► Hyprland reads ~/.config/hypr/hyprland.lua
           ├─ modules/*.lua  (env, monitors, input, look, animations, binds, rules, windows, plugins, autostart)
           ├─ settings/*.lua (written by the Settings app; gitignored, live in ~/.config only)
           └─ host.lua       (from hosts/<h>/home: workspaces per monitor, tablet switch)
         autostart ─► qs (Quickshell) ─► bar, dock, launcher, notifications, OSD, Control Center,
                                         power menu, cheatsheet, Settings app, ThemeSync
                   ├► hypridle, hyprpaper, polkit agent, udiskie, clipboard watcher, monswitch, startup-apps
```

## Pieces

| Area | Files | Notes |
|---|---|---|
| Entry point | `install.sh` | `install`, `update`, `doctor` (read-only check), `undo`; `--dry-run`, `--only`, `--host`. Every change goes through `run()` so `--dry-run` shows it. KDE guard: never links over Plasma's own files. |
| Distro backends | `distros/arch.sh`, `distros/fedora.sh` | Package install, repos (COPR / RPM Fusion), NVIDIA driver. Picked from `/etc/os-release` `ID`, then `ID_LIKE`. |
| Packages | `packages/manifest.txt` (logical name, module, why), `arch.txt`, `fedora.txt` | One line per package with its reason. `--only tools` etc. installs a module. |
| Hosts | `hosts/default/`, `hosts/flow-x13/` | `host.conf` (hostnames), `packages.txt`, `home/` (linked), `defaults/` (copied once), `steps/` (system changes, asked first). |
| Hyprland | `config/hypr/.config/hypr/` | Lua config (Hyprland 0.57). `hyprland.lua` loads modules in order. Lock screen `hyprlock.conf` + `lockscreens/*.conf` designs; `defaults/` seeds `settings/`. |
| Shell | `config/quickshell/.config/quickshell/` (~100 QML files) | `shell.qml` root. `ConfigData.qml` = every user default, `Config.qml` = load/save/validate `settings.json` + IPC (`qs ipc call config set …`). `Theme.qml` = design tokens. `ThemeSync.qml` = pushes tokens to Hyprland, hyprlock, GTK, Ghostty, fuzzel. `SettingsApp.qml` + `SettingsPage*.qml` = the Settings app (Super+I). |
| Scripts | `config/scripts/.local/bin/` | `screenshot`, `screentext` (OCR), `theme`, `monswitch` (DDC/CI input switch), `panel` (lid, tablet mode), `powermode`, `asusfan`, `nv` (run on NVIDIA), `clipstore`, `emojipick`, `startup-apps`, `installed-apps`, `theme-add`, `hypr-plugins`, `thermlog`. |
| Apps | `config/ghostty`, `config/fish`, `config/starship`, `config/fuzzel`, `config/fastfetch`, `config/satty`, `config/chrome`, `config/arch-update`, `config/wallpapers` | Each mirrors `~`. |
| Plugin | `plugins/minimize/main.cpp` | Title-bar minimise button support; built at login by `hypr-plugins`. |
| Checks | `.github/workflows/ci.yml`, `tests/container-test.sh`, `.githooks/pre-commit` | CI: shellcheck + install twice + doctor in Arch and Fedora containers. Pre-commit: gitleaks. Local shellcheck without installing it: `docker run --rm -v "$PWD:/mnt" -w /mnt koalaman/shellcheck:stable -S warning install.sh distros/*.sh hosts/*/steps/*.sh config/scripts/.local/bin/*` |
| Dev tooling | `CLAUDE.md`, `.claude/settings.json`, Graphify | `uv tool install graphifyy`; `graphify update .` rebuilds `graphify-out/` (gitignored). |

## Where values live (change them here)

| What | File |
|---|---|
| Colours, fonts, sizes, radius, motion | `config/quickshell/.config/quickshell/Theme.qml` (rules: `docs/DESIGN.md`) |
| Defaults of every Settings option | `config/quickshell/.config/quickshell/ConfigData.qml` |
| Keybinds | `config/hypr/.config/hypr/modules/binds.lua` (Super+/ shows them; Settings can override) |
| Gaps, border, glow, blur, shadows | `modules/look.lua` (border/gap values come from Settings → theme.lua) |
| Animations | `modules/animations.lua` |
| Monitors | Settings → Displays (writes `settings/displays.lua`); per-host fallbacks in `host.lua`, `modules/monitors.lua` |
| Window rules | `modules/rules.lua` |
| Startup programs | `modules/autostart.lua` (desktop pieces), Settings → Startup Apps (`~/.config/autostart`) |

## Your files vs. repo files

Stow links file by file (`--no-folding`), so `~/.config/hypr/settings/`, `~/.config/quickshell/settings.json`,
`~/.config/ghostty/theme.conf` and `~/.config/autostart/` are real files in your home folder, never in the repo.
`./install.sh doctor` lists anything that drifted.

## Drift check (2026-11-04)

`./install.sh doctor`: every link points into the repo; no missing packages; only finding was this
branch's uncommitted work. Local-only by design: `~/.config/hypr/settings/*` (Settings app output),
`~/.config/autostart/*.desktop` (Startup Apps), `~/.config/monswitch.conf` (seeded from
`hosts/flow-x13/defaults`). Nothing changed live without the repo.
