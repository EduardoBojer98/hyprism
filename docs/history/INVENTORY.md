# Inventory (2026-11-05)

What the repo holds, what lives only on the machine, and the measured baseline. How the pieces connect is in
[ARCHITECTURE.md](../ARCHITECTURE.md); the look is in [DESIGN.md](../DESIGN.md); scores are in [COUNCIL.md](COUNCIL.md).

## Repo

| Area | Count | Where |
|---|---|---|
| Packages | 69 (desktop 25, tools 21, core 8, look 7, shell 6, apps 2) | `packages/manifest.txt` → `arch.txt` / `fedora.txt`, plus `hosts/<h>/packages.txt` |
| Distros | Arch / CachyOS, Fedora 44+ | `distros/arch.sh`, `distros/fedora.sh` |
| Hosts | `default` (any PC), `flow-x13` (this laptop: 6 system steps) | `hosts/` |
| Hyprland | 10 Lua modules + `hyprland.lua`, hyprlock, hypridle | `config/hypr/.config/hypr/` |
| Shell (Quickshell) | 115 QML files: bar, dock, panels, launcher, notifications, OSD, lock layout, Settings (31 pages) | `config/quickshell/.config/quickshell/` |
| Themes | 6 built-in (Pebble, Monolith, Console, Poster, Glass, Atlas), each with a light and a dark half; your own from the Theme Builder | `Themes.qml` (data), `Theme.qml` (tokens), `ThemeSync.qml` (Hyprland, hyprlock, GTK, Ghostty, wallpaper) |
| Scripts | 20 | `config/scripts/.local/bin/` |
| Apps configured | Ghostty, fish, starship, fuzzel, fastfetch, satty, Chrome flags, arch-update | `config/<app>/` |
| Checks | shellcheck + install twice + doctor in Arch and Fedora containers (CI); gitleaks pre-commit | `.github/workflows/ci.yml`, `tests/`, `.githooks/` |

## Only on the machine (by design)

Written by the Settings app, never in the repo (`./install.sh doctor` checks the links around them):

| File | Written by |
|---|---|
| `~/.config/quickshell/settings.json` | every Settings page (`Config.qml`, schema-checked on load) |
| `~/.config/hypr/settings/{theme,displays,input,keybinds,windows}.lua` | ThemeSync, Displays, Input, Keyboard Shortcuts, Windows pages |
| `~/.config/hypr/settings/hypridle.conf`, `hyprlock-theme.conf`, `wallpaper` | Lock & Sleep, ThemeSync, Wallpaper |
| `~/.config/ghostty/theme.conf` | ThemeSync |
| `~/.local/share/linux-setup/themes/*-v6.png` | `theme-wallpaper` (drawn once per design) |
| `~/.config/autostart/*.desktop`, `~/.config/monswitch.conf` | Startup Apps page, host defaults (copied once) |

## Baseline measurements (this laptop, Monolith, both screens on)

| Metric | Measured | How |
|---|---|---|
| Shell idle CPU | 0.40 % of one core | `/proc/<qs>/stat` ticks over 20 s, nothing open |
| Shell RAM | 337 MB RSS | `ps -o rss` (Qt + QML engine + two screens of layer surfaces) |
| Other daemons RAM | hyprpaper 55 MB, udiskie 23 MB, polkit agent 11 MB, hypridle 4 MB, wl-paste 2 MB | `ps -o rss` |
| Theme switch → Hyprland config written | 524 ms | `qs ipc call config set appearance theme` until `settings/theme.lua` names it (first draw of a new wallpaper adds ImageMagick time) |
| Doctor | clean apart from uncommitted work | `./install.sh doctor` |
| QML lint | no errors in the changed files | `qmllint` |
| Lua lint | not run: `luacheck` isn't installed | — |
| Shell lint | CI only: `shellcheck` isn't installed locally (CI uses the Docker image) | `.github/workflows/ci.yml` |
