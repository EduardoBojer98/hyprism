# Feature matrix (2026-11-11)

What three well-loved Hyprland setups do, what Hyprism does today, and what we decided. Ideas only: nothing is
copied from them. "unverified" means the project's README, docs or issues did not say.

Sources: [HyDE](https://github.com/HyDE-Project/HyDE), [Omarchy](https://github.com/basecamp/omarchy) and its
[manual](https://learn.omacom.io/2/the-omarchy-manual), [ML4W](https://github.com/mylinuxforwork/dotfiles) and
[ml4w.com/os](https://ml4w.com/os/). Issue numbers are in each project's own tracker.

| Feature | HyDE | Omarchy | ML4W | Ours now | Decision |
|---|---|---|---|---|---|
| Installer | clone + `install.sh`, package lists | its own ISO, or on top of Arch | one `curl` command, live ISO | `./install.sh`: dry run, safe to repeat, backups, asks before system changes | **keep**: already stronger (dry run + idempotent, tested in CI) |
| Distros | Arch family; Fedora is an open PR | Arch only | Arch, Fedora, Ubuntu, openSUSE | Arch/CachyOS, Fedora 44+ | **keep**; more distros only after hardware detection lands |
| Update command | `git pull` + reinstall | `omarchy update`, channels | rerun the installer | `./install.sh update` | **keep** |
| Versioned migrations | a `migrations/` folder | yes, run on every update | unverified | none (two old one-off moves live inside `install.sh` and `Config.qml`) | **adopt**: `migrations/NNNN-name.sh`, each run once, recorded in the state folder |
| Rollback | config backups | snapshot on every update, boot entry | unverified | config backups; btrfs snapshots where snap-pac exists (documented, doctor checks) | **adapt**: keep snapshots optional, add "undo the last update of our files" (git tag before update) |
| Uninstall / restore | `uninstall.sh`, `restore_cfg.sh` | reinstall one config | unverified | `./install.sh undo` restores the last backup only | **adapt**: pick any backup, remove generated files and state too |
| Theme switch | script + rofi picker, live | menu, key, `omarchy theme set` | wallpaper-driven | `theme NAME`, Settings gallery with previews, live | **keep** |
| Theme packaging | themepatcher, files per theme | a folder per theme, `colors.toml`, install from a URL | unverified | all themes in one QML file + 2 terminal files + a wallpaper recipe in a script | **adopt** (Omarchy's shape): `themes/<id>/` with one tokens file, wallpaper, optional overrides |
| Themes shipped | 12 + gallery | 19 | unverified | 7, each light and dark | **keep few**; review each, make Reactor the default |
| Wallpaper colours | wallbash | no | yes ("adaptive") | no (rejected earlier for contrast risk) | **adapt**: optional mode, own code (ImageMagick is already here), result must pass the contrast check or it is corrected |
| Apps themed | GTK, Qt, terminal | unverified | GTK, kitty | Hyprland, shell, lock, GTK 3/4, Ghostty, fuzzel, cursor, icons | **adopt** the missing ones: Qt, login screen, btop, starship/fish, editor hint |
| Bar technology | Waybar | own script | Quickshell or Waybar | Quickshell | **keep Quickshell** (ADR 0001) |
| Bar layouts | switchable Waybar layouts | unverified | several Waybar themes | one layout per theme, editable; hide per monitor | **adopt**: named presets (minimal, full, laptop, external) and a layout per monitor |
| Per-module bar config | Waybar module JSON | unverified | unverified | order and section only | **adopt**: every item its own file + own settings block |
| Metrics in the bar | cpu / gpu / sensors scripts | battery, clock | unverified | CPU %, RAM %, iGPU % (fixed); more in a popup | **adopt**: one system-info module with a metric registry |
| Central menu | rofi menus | one menu for everything | sidebar | launcher (apps, files, actions, clipboard) + Control Center + logo menu | **adapt**: the launcher's Actions mode becomes the one menu; add themes, update, wifi, bluetooth, audio, displays |
| Keybind cheat sheet | hint script | Super+K | sidebar button | Super+/, read live from Hyprland, searchable | **keep** |
| Keybind override | unverified | `bindings.conf` | unverified | `binds.lua` + overrides from Settings | **keep**; move user overrides into the one config file |
| Settings app | open PR | no | yes | yes, 31 pages, one `settings.json` | **keep**; close the remaining side-state |
| Monitor tool | unverified | unverified | requests open | Displays page (arrange, mode, scale), shared-monitor hand-off | **keep**; add hotplug profiles and a DPI-based default scale |
| Notification centre + DND | script + menu | unverified | unverified | yes, both | **keep** |
| OSD | volume, brightness | volume, brightness | unverified | volume, brightness | **adopt** more: mic mute, caps lock, keyboard layout |
| Lock / idle | hyprlock, idle inhibitor | lock key | hypridle toggle | hyprlock themed, hypridle, dim, caffeine | **keep** |
| Screenshots | grimblast | region, text, QR | present, bugs open | grim + slurp + Satty, OCR | **keep**; add pin-to-screen (own small window) |
| Recording | script | with webcam | unverified | area or screen | **adapt**: audio source choice |
| Clipboard | cliphist | yes | unverified | history, images, pins, clear | **keep** |
| Wi-Fi / BT / audio pickers | unverified | scripts + panel | unverified | Control Center lists, Settings pages | **keep**; reachable from the one menu |
| Web apps | no | yes | no | `webapp` script | **keep**; add to the menu |
| First run | no | no | Welcome app | one notification | **adopt**: a short welcome (theme, layouts, modules) + cheat sheet once |
| Hardware detection | NVIDIA auto-detect | per-laptop quirks, many issues | unverified | by hostname (`hosts/flow-x13`), a few runtime checks | **adopt, our own way**: `detect` → `hardware.toml`, modules key off it |
| Gaming | game launcher, gamemode | unverified | unverified | `nv` (run on the dGPU) | **adopt** as an optional module: Steam, gamemode, guide |
| Dev tools | unverified | many, incl. AI agents | unverified | fish, starship, fzf, zoxide | **adapt**: light optional module (mise for versions, Docker) |
| Doctor | no | `omarchy-debug` | unverified | `./install.sh doctor` | **keep**; add hardware modules and a fix line for every finding |
| Docs | wiki | strong manual | site | README with screenshots, user guide | **adopt** the manual's "how to change X" shape |
| CI | unverified | unverified | unverified | lint + install twice + doctor on Arch and Fedora | **keep**; add hardware-profile and migration tests |

## Pain points users report elsewhere (so we avoid them)

- **Compositor updates break themes** (HyDE #1945 after Hyprland's Lua change). Ours: CI parses every Lua file;
  migrations will carry config changes.
- **Bar started twice / not at all** (ML4W #1904, HyDE #1992). Ours: the bar is part of the one shell process; the
  doctor already flags duplicate helpers.
- **A migration broke something unrelated** (Omarchy #18469). Ours: migrations must be small, re-runnable and
  dry-runnable, and are tested in CI from the previous release.
- **Per-laptop quirks pile up as issues** (Omarchy #18476, #18478, #18483). Ours: generic interfaces first
  (UPower, power-profiles-daemon, brightnessctl), vendor extras as detected modules.
- **Apps don't follow the theme** (HyDE #1776, ML4W #974, #1671). Ours: generate each app's colours from the same
  tokens and test that every output exists for every theme.
- **No multi-monitor bar** (ML4W #1842). Ours: per-monitor layouts.

## Logitech MX Master 4 haptics (checked 2026-11-11)

- **Solaar** supports it: a HAPTIC setting since 1.1.17, documented in 1.1.20. Command line:
  `solaar config 'mx master 4' haptic-play 'HAPPY ALERT'`; rules can trigger it. Open problems with the Bolt
  receiver at boot (Solaar #3356, #3290).
- **logiops**: the haptics change (logiops PR #524) has been open and unreviewed since 2025-10. Not supported.
- **This repo today** installs JuhRadial MX through a host step. Decision: move to Solaar as the optional Logitech
  module (it is in both distros' repos, covers every Logitech device, and needs no third-party installer).
