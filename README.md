<div align="center">

# Hyprism

**One Wayland desktop, seven complete designs.**
Hyprland + a Quickshell shell for Arch, CachyOS and Fedora, switched in one step and set up from a Settings app instead of config files.

[![CI](https://github.com/EduardoBojer98/hyprism/actions/workflows/ci.yml/badge.svg)](https://github.com/EduardoBojer98/hyprism/actions/workflows/ci.yml)
![Hyprland 0.57](https://img.shields.io/badge/Hyprland-0.57-58E1FF?logo=hyprland&logoColor=white)
![Quickshell 0.3](https://img.shields.io/badge/Quickshell-0.3-7E57C2)
![Arch / CachyOS](https://img.shields.io/badge/Arch%20%2F%20CachyOS-supported-1793D1?logo=archlinux&logoColor=white)
![Fedora 44+](https://img.shields.io/badge/Fedora%2044%2B-supported-51A2DA?logo=fedora&logoColor=white)

[Themes](#themes) · [Features](#features) · [Install](#install) · [Keys](#keys) · [Customise](#customise) · [Recovery](#uninstall-and-recovery) · [User guide](docs/USER-GUIDE.md)

<img src="docs/screenshots/themes/reactor-dark.webp" alt="Hyprism desktop with the Reactor theme: acid yellow on near-black with hot orange, a floating bar with an inverse clock block" width="100%">

</div>

## Why Hyprism

- **7 themes, each a whole desktop design**: fonts, corners, window frames, shadows, bar and dock layout, panel depth,
  motion, notifications, lock screen, terminal palette and wallpaper. Every one has a light and a dark version.
- **Everything in Settings** (`Super+I`): bar, dock, displays, keyboard, shortcuts, wallpaper, power, lock screen,
  default apps. Your choices live in `~/.config`, never in the repo.
- **One command** installs, updates, checks (`doctor`) and uninstalls it. `uninstall` puts back the files it replaced.
- **Free software only.** Hardware extras (ASUS fan curves, keyboard light, a shared monitor over DDC/CI) switch on
  only where the hardware exists.

## Themes

`theme` lists them, `theme atlas` switches, or **Settings → Appearance → Themes**. Each theme's own default half is on the left.

| Theme | The idea | Bar | Motion |
|---|---|---|---|
| **Pebble** | soft and round, glass, coral and sea green | three floating glass pills at the top | soft, a touch of spring |
| **Monolith** | the desktop as tmux, acid lime | a mono status line at the bottom with your apps and an inverse lime clock | near-instant |
| **Console** | amber HUD | a framed caps readout, rules between items, corner brackets, glowing panels | crisp snap-on |
| **Poster** | loud and flat, red and cobalt on paper | a paper bar with huge workspace blocks, hard shadows | slams in |
| **Glass** | liquid glass, electric blue to violet | a floating glass bar with a lit rim, glowing window frames | smooth ease-out |
| **Atlas** | Swiss, signal red on white | a black strip on top, heavy numerals, red squares, a black dock | snappy slide |
| **Reactor** (default) | radioactive: acid yellow on near-black, hot orange | a floating strip with an inverse acid clock block | quick, decisive |

<table>
  <tr>
    <th>Pebble</th>
    <th>Monolith</th>
  </tr>
  <tr>
    <td><img src="docs/screenshots/themes/pebble-dark.webp" alt="Pebble, dark"><br><img src="docs/screenshots/themes/pebble-light.webp" alt="Pebble, light"></td>
    <td><img src="docs/screenshots/themes/monolith-dark.webp" alt="Monolith, dark"><br><img src="docs/screenshots/themes/monolith-light.webp" alt="Monolith, light"></td>
  </tr>
  <tr>
    <th>Console</th>
    <th>Poster</th>
  </tr>
  <tr>
    <td><img src="docs/screenshots/themes/console-dark.webp" alt="Console, dark"><br><img src="docs/screenshots/themes/console-light.webp" alt="Console, light"></td>
    <td><img src="docs/screenshots/themes/poster-light.webp" alt="Poster, light"><br><img src="docs/screenshots/themes/poster-dark.webp" alt="Poster, dark"></td>
  </tr>
  <tr>
    <th>Glass</th>
    <th>Atlas</th>
  </tr>
  <tr>
    <td><img src="docs/screenshots/themes/glass-dark.webp" alt="Glass, dark"><br><img src="docs/screenshots/themes/glass-light.webp" alt="Glass, light"></td>
    <td><img src="docs/screenshots/themes/atlas-light.webp" alt="Atlas, light"><br><img src="docs/screenshots/themes/atlas-dark.webp" alt="Atlas, dark"></td>
  </tr>
  <tr>
    <th colspan="2">Reactor</th>
  </tr>
  <tr>
    <td><img src="docs/screenshots/themes/reactor-dark.webp" alt="Reactor, dark"></td>
    <td><img src="docs/screenshots/themes/reactor-light.webp" alt="Reactor, light"></td>
  </tr>
</table>

**Adjust** (Settings → Appearance) changes any theme's accent colours, corners, gaps, frame, font, text size, window
motion, shadow and blur, kept per theme; Reset puts it back. **Animations** is Full, Reduced or Off.
**Light or dark** picks each theme's default, or Light or Dark for all of them.

## Features

<table>
  <tr>
    <td width="50%"><img src="docs/screenshots/features/settings-themes.webp" alt="Settings app, Themes page with a gallery of the seven themes"></td>
    <td width="50%"><img src="docs/screenshots/features/theme-builder.webp" alt="Settings app, Theme Builder page"></td>
  </tr>
  <tr>
    <td><b>Settings</b> (<code>Super+I</code>): every page searchable, live, with Reset to defaults.</td>
    <td><b>Theme Builder</b>: start from any theme and change colours, fonts, shape, bar, dock, motion, lock screen, terminal, wallpaper.</td>
  </tr>
  <tr>
    <td><img src="docs/screenshots/features/settings-bar.webp" alt="Settings app, Menu Bar page with position, size, shape and a drag-and-drop item editor"></td>
    <td><img src="docs/screenshots/features/lock-screen.webp" alt="Settings app, Lock Screen page with a live preview"></td>
  </tr>
  <tr>
    <td><b>Menu bar</b>: any edge, any size, floating or attached, per monitor; drag items between its three zones.</td>
    <td><b>Lock screen</b>: clock style and position, greeting, picture, widgets, background, blur, with a live preview.</td>
  </tr>
  <tr>
    <td><img src="docs/screenshots/features/launcher.webp" alt="Spotlight launcher showing all apps by category"></td>
    <td><img src="docs/screenshots/features/calendar.webp" alt="Calendar panel with a month grid and upcoming holidays"></td>
  </tr>
  <tr>
    <td><b>Spotlight</b> (tap <code>Super</code>): suggestions, then apps, files, calculator, settings, actions and web; all apps by category.</td>
    <td><b>Calendar</b> (click the clock): public holidays for your country, observances, moon phases, what's coming up.</td>
  </tr>
  <tr>
    <td><img src="docs/screenshots/features/control-center.webp" alt="Control Center with Wi-Fi, Bluetooth, toggles, brightness, sound and power mode"></td>
    <td><img src="docs/screenshots/features/power.webp" alt="Power menu with lock, sleep, hibernate, log out, restart and shut down"></td>
  </tr>
  <tr>
    <td><b>Control Center</b> (<code>Super+C</code>): Wi-Fi, Bluetooth, Focus, Night Light, Caffeine, touch, recording, sliders, power mode; sections rearrangeable.</td>
    <td><b>Power menu</b>: lock, sleep, hibernate, log out, restart, shut down.</td>
  </tr>
  <tr>
    <td colspan="2"><img src="docs/screenshots/features/cheatsheet.webp" alt="Keyboard shortcut cheatsheet grouped by apps, windows, workspaces, screen, media and session"></td>
  </tr>
  <tr>
    <td colspan="2"><b>Shortcut cheatsheet</b> (<code>Super+/</code>): every binding on screen, type to filter, all rebindable in Settings.</td>
  </tr>
</table>

<details>
<summary><b>Everything else</b></summary>

- **The bar**: one engine for every theme. Items: apps (the dock), apps button, workspaces, active window, clock,
  date, media player, tray, keyboard layout, notifications, quick settings, network, Bluetooth, volume, brightness,
  battery (percentage inside, beside or off), power profile, CPU, memory, GPU, recording, power menu. Every item works
  on a horizontal bar and down a vertical one. Place, shape and items are kept per theme; "Save as a theme" keeps them
  as your own theme.
- **The dock**: on the theme's own edge, or in the bar as its Apps item. Size, icon size, auto-hide, pinned apps, open
  windows, per monitor. Like the Windows taskbar, each open window is its own tile; **Combine** merges them into the
  app icon, with a live preview of each window on hover (click to bring up, middle-click to close).
- **Notifications** have their own panel from the bell (with the unread count): Do Not Disturb, history grouped by app, Clear all.
- **Mission Control** (`Super+W`, three fingers up).
- Keyboard shortcuts, displays, a shared monitor, sound, network, Bluetooth, power, wallpaper folders and slideshow,
  startup apps, lock and sleep, default apps, weather: all in Settings.
- Small tools: `record` (screen recording, `Super+Alt+R`), `dropterm` (drop-down terminal, ``Super+` ``),
  `webapp add "Name" URL` (a site as its own app), `remind 20m "Stand up"` (a reminder notification).
- Hardware extras that switch themselves on where the hardware exists: ASUS fan curves and charge limit (asusctl),
  keyboard light, a monitor shared with another computer (DDC/CI).

</details>

## Install

Needs Arch Linux, CachyOS (or another Arch-based distro) or Fedora 44+, a normal user with sudo, and
a login screen that lists Wayland sessions.

```bash
git clone https://github.com/EduardoBojer98/hyprism.git ~/hyprism
cd ~/hyprism
./install.sh --dry-run     # see everything it would do; changes nothing
./install.sh               # do it (asks before system changes; safe to run again)
```

Log out and pick **Hyprland** at the login screen.

What `./install.sh` does, in order:

- detects the hardware and writes `~/.config/hyprism/hardware.toml`;
- installs packages (Arch: repos and AUR; Fedora: repos, COPR, RPM Fusion);
- links `config/<app>/` and each module's `home/` into your home folder, file by file. A file in the way is backed up to `~/.local/state/hyprism/backups/`;
- enables services (Bluetooth, NetworkManager, and so on);
- runs the system steps of the modules that fit this computer, asking before each one.

Options: `--dry-run` (show, change nothing), `--yes` (no questions), `--only LIST` (steps like `links`, or groups like `shell`), `--with LIST` / `--without LIST` (turn modules on or off). `./install.sh uninstall` removes the links, puts a backup back and undoes the system changes. The full list of commands and flags is `./install.sh --help`.

On Fedora, Hyprland 0.57 comes from the `sdegler/hyprland` COPR and Quickshell 0.3.2 from
`errornointernet/quickshell` (Fedora's own Quickshell is too old). A few packages have no Fedora
build (`squeekboard`): `packages/fedora.txt` says what to do instead.

This repo is the desktop only: Hyprland, the shell, their tools and look, a terminal and a file
manager. Your other apps (browser, editors, dev tools, …) are yours to install; the desktop works with
whatever you pick in **Settings → Default Apps**. The cursor is your system's default until you pick or
add another in **Settings → Appearance → Cursor**.

### First run

A welcome note names the three keys you need: **tap Super** to search for anything, **Super+I** for Settings,
**Super+/** for every shortcut. In Settings, set the weather city, wallpaper, keyboard layouts and displays. If a
choice ever breaks the desktop, `desktop-reset` puts the defaults back (see [docs/USER-GUIDE.md](docs/USER-GUIDE.md)).

### Update and doctor

```bash
./install.sh update
```

Pulls this repo (only when it has no local changes), updates the whole system (`paru -Syu` or
`pacman -Syu` / `dnf upgrade`, plus Flatpaks), installs packages the repo added, runs new migrations, relinks the
configs and runs the doctor. Same as **Settings → About → Update**. `./install.sh rollback` goes back to the
Hyprism version from before the last update.

```bash
./install.sh doctor
```

Lists missing packages, configs that aren't linked or were changed locally, unknown files in the managed
folders, services that are off, and uncommitted changes. Also in **Settings → About → Run doctor**.

## Keys

`Super` = Windows key. All of these can be changed in **Settings → Keyboard Shortcuts**; **`Super+/` shows every one on screen**.

| Keys | Action |
|---|---|
| tap `Super`, `Super+Space` | Spotlight (`Super+Shift+Space` files, `Super+A` all apps) |
| `Super+V` | Clipboard history at the pointer |
| `Super+C` / `Super+N` / `Super+Shift+N` | Control Center / notification centre / Do Not Disturb |
| `Super+W`, three fingers up | Mission Control |
| `Super+I` | Settings |
| `Super+Enter` / `Super+E` / `Super+B` | Terminal / files / browser |
| `Super+.` | Emoji picker |
| `Super+Ctrl+Space` | Next keyboard layout (add layouts in Settings → Keyboard & Touchpad) |
| `Super+Q` / `Super+H` | Close / minimise window (restore from the dock) |
| `Super+F` / `Super+Shift+F` / `Super+T` | Fullscreen / maximise / float |
| `Super+Arrows` / `Super+Shift+Arrows` | Focus / move window |
| `Super+1…0` / `Super+Shift+1…0` | Go to / send window to desktop; `Super+Tab` previous |
| `Super+S` / `Super+Alt+S` | Scratchpad / send window there |
| ``Super+` `` | Drop-down terminal (again: hide it) |
| `Super+Alt+R` / `Super+Alt+Shift+R` | Record the screen / an area (again: stop and save to ~/Videos/Recordings) |
| `Super+M` | Hand a shared monitor to the other computer and back (Settings → Displays → Shared Monitor) |
| `Super+Ctrl+↓` | Next empty workspace |
| `Alt+Shift+S` (also `Print`, `Super+Shift+S`) | Screenshot an area, then annotate |
| `Ctrl+Print` / `Shift+Print` / `Super+Print` / `Ctrl+Shift+Print` / `Alt+Print` | Area straight to clipboard / this screen / focused window / both screens / in 5 seconds |
| `Super+Shift+T` | Copy text from the screen (OCR) |
| `Super+Shift+C` | Colour picker |
| `Super+L` / `Super+Shift+E` | Lock / log out |
| `Super+F5` | Next power mode: Quiet → Balanced → Performance (also `powermode` in a terminal) |
| `Super+drag` / `Super+right-drag` | Move / resize window |
| Three-finger swipe sideways | Switch desktop |

### Screenshots

`screenshot` (`~/.local/bin`) = **grim** (capture) + **slurp** (pick an area) + **Satty** (editor).
`Alt+Shift+S`, drag an area (works across both screens, and with touch), annotate (arrow, shapes, pen, highlighter,
text, numbered markers, blur, crop). **Enter** copies and saves, **Ctrl+S** saves, **Esc** cancels. Files land in
`~/Pictures/Screenshots/`. `screenshot area|screen|window|all|delay N`, add `--copy` to skip the editor.

## Customise

| Path | What |
|---|---|
| `install.sh` | the one command (install, update, doctor, detect, modules, rollback, backups, uninstall) |
| `lib/` | the installer's parts, one file each (`detect.sh`, `modules.sh`, `links.sh`, `packages.sh`, `migrate.sh`, `doctor.sh`, …) |
| `config/<app>/` | one folder per app, mirroring `~`: `hypr`, `quickshell`, `ghostty`, `fish`, `starship`, `fuzzel`, `scripts` (`~/.local/bin`), … |
| `config/quickshell/.config/quickshell/` | the shell; `ConfigData.qml` holds every default, `Theme.qml` the tokens, `bar/items/` the bar items |
| `config/hypr/.config/hypr/` | Hyprland Lua config: `hyprland.lua` loads `modules/hardware.lua` first, then `modules/` (env, monitors, input, look, animations, binds, rules, windows, plugins, autostart), then the hardware files linked from `modules/<name>/home/.config/hypr/hardware/` |
| `modules/<name>/` | optional hardware or uses: `detect`, `packages.txt`, `home/` (linked), `steps/` (system steps, asked one by one), `doctor`, `README.md`. See [modules/_template/](modules/_template/) |
| `migrations/` | one-time changes that carry an old install over to a newer layout, run once by `update` |
| `packages/` | `manifest.txt` (logical name, module, why) and `arch.txt` / `fedora.txt` (real names and sources) |
| `distros/` | `arch.sh`, `fedora.sh`: install packages, enable repos, NVIDIA driver |
| `tests/` | the checks: `lint.sh` (static checks), `detect.sh` (fake computers), `container-test.sh` (a full install in Arch and Fedora containers) |
| `plugins/` | Hyprland plugin (title-bar minimise), built by `hypr-plugins` |
| `docs/` | users: [USER-GUIDE.md](docs/USER-GUIDE.md), [THEMES.md](docs/THEMES.md). Contributors: [ARCHITECTURE.md](docs/ARCHITECTURE.md), [DESIGN.md](docs/DESIGN.md), [DECISIONS.md](docs/DECISIONS.md), [CONVENTIONS.md](docs/CONVENTIONS.md), [audit](docs/audit/AUDIT.md), [CHANGELOG.md](CHANGELOG.md) |

- **Hardware modules**: the installer detects this computer's hardware and turns on the modules that fit it.
  `./install.sh modules` lists them; `--with NAME` / `--without NAME` override detection. A wrong guess is fixed under
  `[override]` in `~/.config/hyprism/hardware.toml`. To add one, copy [modules/_template/](modules/_template/).
- **Another distro**: add `distros/<id>.sh` (the functions are listed in [distros/README.md](distros/README.md)) and `packages/<id>.txt`. See [distros/README.md](distros/README.md).
- **A new theme**: copy `themes/_template` to `~/.config/hyprism/themes/<id>`, edit `theme.json`, run `theme <id>`.
  No code changes. Or use Settings → Appearance → Theme Builder (no files). Guide: [docs/THEMES.md](docs/THEMES.md).
- **A new setting**: a default in `ConfigData.qml`, its rule in `Config.qml`'s `schema`, a row on its
  `SettingsPage<Id>.qml`, and a search word in `SettingsApp.qml`. **A new bar item**: copy
  `bar/items/_template` ([docs/bar.md](docs/bar.md)).
- Fonts the themes use that distros don't ship are bundled in `config/fonts/` (SIL Open Font License).

## Uninstall and recovery

| What broke | Do this |
|---|---|
| Dotfiles | `./install.sh uninstall` removes the links and puts back the backed-up files (`./install.sh backups` lists them) |
| The Hyprland session | Log in on a text console with Ctrl+Alt+F3 and run `./install.sh uninstall`. It restores your backed-up files |
| The shell (bar, dock) | `qs kill; qs &` restarts it; `qs log` shows errors; `desktop-reset shell` if a setting broke it |
| A Settings choice | `desktop-reset` (everything) or `desktop-reset shell` (theme, bar, dock, panels): your files are kept aside. One page: its **Reset to defaults** |
| An update | See below |

**Roll back an update** (Arch/CachyOS on btrfs): **snap-pac** snapshots `/` before and after every pacman or paru
run, and **limine-snapper-sync** lists them in the Limine boot menu. Reboot, open **Snapshots**, boot the "pre"
one, check it works, then `sudo limine-snapper-restore`. Snapshots cover `/` only, not `/home`, and sit on the same
disk. Fedora has no snapshots by default. The doctor warns when any of this is missing.

## Secrets

Never in this repo: SSH/GPG keys, API keys, tokens, `.env` files. `.gitignore` blocks the common names
and a gitleaks pre-commit hook (enabled by `install.sh`) scans every commit. Settings files never
land in the repo folder (configs are linked file by file).
