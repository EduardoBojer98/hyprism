<div align="center">

# Hyprism

**One Wayland desktop, seven complete designs.**
Hyprland + a Quickshell shell for Arch, CachyOS and Fedora, switched in one step and set up from a Settings app instead of config files.

[![CI](https://github.com/EduardoBojer98/hyprism/actions/workflows/ci.yml/badge.svg)](https://github.com/EduardoBojer98/hyprism/actions/workflows/ci.yml)
![Hyprland 0.57](https://img.shields.io/badge/Hyprland-0.57-58E1FF?logo=hyprland&logoColor=white)
![Quickshell 0.3](https://img.shields.io/badge/Quickshell-0.3-7E57C2)
![Arch / CachyOS](https://img.shields.io/badge/Arch%20%2F%20CachyOS-supported-1793D1?logo=archlinux&logoColor=white)
![Fedora 44+](https://img.shields.io/badge/Fedora%2044%2B-supported-51A2DA?logo=fedora&logoColor=white)

[Themes](#themes) · [Features](#features) · [Quick start](#quick-start) · [Keys](#keys) · [Customise](#customise) · [Recovery](#uninstall-and-recovery) · [Docs](docs/README.md)

<img src="docs/screenshots/themes/reactor-dark.webp" alt="Hyprism desktop with the Reactor theme: acid yellow on near-black with hot orange, a floating bar with an inverse clock block" width="100%">

</div>

## Why Hyprism

- **Your hardware is detected.** The installer looks at the computer once and writes what it found to a small
  file. Laptop, desktop, NVIDIA, touch screen: each gets the right setup, and nothing for hardware you do not have.
- **Modules.** Parts for particular hardware or uses (gaming, dev tools, ASUS, tablets) are folders you can switch
  on or off. See [docs/modules.md](docs/modules.md).
- **Themes are folders.** Seven whole-desktop designs, each with a light and a dark half. Make your own by
  copying one folder. See [docs/THEMES.md](docs/THEMES.md).
- **The bar is modular.** Each item is its own folder, on any screen edge, with its own settings.
- **One settings file.** Everything you change in Settings (`Super+I`) is in `~/.config/quickshell/settings.json`,
  never in the repo.
- **Free software only.** No paid apps, trials or subscriptions.
- **Arch, CachyOS and Fedora 44+**, both tested in CI.

## Themes

`theme` lists them, `theme atlas` switches, or **Settings → Appearance → Themes**. Each theme's own default half is on the left.

| Theme | The idea | Bar | Motion |
|---|---|---|---|
| **Pebble** | soft and round, glass, coral and sea green | three floating glass pills at the top | soft, a touch of spring |
| **Monolith** | the desktop as tmux, acid lime | a mono status line at the top with your apps and an inverse lime clock | near-instant |
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
    <td><img src="docs/screenshots/features/cheatsheet.webp" alt="Keyboard shortcut cheatsheet grouped by apps, windows, workspaces, screen, media and session"></td>
    <td><img src="docs/screenshots/features/welcome.webp" alt="First-run welcome panel with a theme picker, light or dark choice, bar layout and keyboard layouts"></td>
  </tr>
  <tr>
    <td><b>Shortcut cheatsheet</b> (<code>Super+/</code>): every binding on screen, type to filter, all rebindable in Settings.</td>
    <td><b>Welcome</b>: on first start, pick a look, light or dark, a bar layout and your keyboard layouts.</td>
  </tr>
  <tr>
    <td><img src="docs/screenshots/features/menu.webp" alt="Grouped menu listing actions under headings, starting with the Appearance group of themes and light or dark mode"></td>
    <td><img src="docs/screenshots/features/system.webp" alt="System panel under the bar with the processor temperature, a table of the top processes and an Open System Monitor button"></td>
  </tr>
  <tr>
    <td><b>Menu</b>: one grouped menu for every action.</td>
    <td><b>System panel</b>: processor temperature and the top processes, one click from the bar.</td>
  </tr>
  <tr>
    <td><img src="docs/screenshots/features/bar-sysinfo.webp" alt="Menu bar with a system-info item showing processor, temperature, memory and network next to the weather and status icons"></td>
    <td><img src="docs/screenshots/features/notifications.webp" alt="Notification centre panel on the right side of the screen"></td>
  </tr>
  <tr>
    <td><b>System-info bar item</b>: pick the metrics it shows.</td>
    <td><b>Notification centre</b>: everything you missed, in one place.</td>
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

## Quick start

Needs Arch, CachyOS (or another Arch-based system) or Fedora 44+, and a user with `sudo`.

```bash
git clone https://github.com/EduardoBojer98/hyprism.git ~/hyprism && cd ~/hyprism
./install.sh --dry-run     # shows everything it would do; changes nothing
./install.sh               # does it; asks before every system change
```

Then log out and pick **Hyprland** at the login screen. The installer does not set up a login manager: how to
start Hyprland without one is in [docs/install.md](docs/install.md). `./install.sh doctor` checks the result;
`./install.sh update` updates; `./install.sh uninstall` removes it. All commands: `./install.sh --help`.

## Keys

`Super` = Windows key. All of these can be changed in **Settings → Keyboard Shortcuts**; **`Super+/` shows every
one on screen**. Generated from `config/hypr/.config/hypr/modules/binds.lua`.

**Apps**

| Keys | Action |
|---|---|
| tap `Super` | Spotlight |
| `Super+Return` | Terminal |
| `` Super+` `` | Drop-down terminal |
| `Super+Space` | Spotlight |
| `Super+E` | File manager |
| `Super+I` | Settings |
| `Super+B` | Web browser |
| `Super+V` | Clipboard history |
| `Super+.` | Emoji picker |
| `Super+Shift+Space` | Spotlight: files |
| `Super+A` | All applications |
| `Super+C` | Control Center |
| `Super+N` | Notification centre |
| `Super+Shift+N` | Do Not Disturb on / off |
| `Super+/` | Keyboard shortcuts (this list) |
| `Ctrl+Shift+Esc` | Task manager |

**Keyboard**

| Keys | Action |
|---|---|
| `Super+Ctrl+Space` | Next keyboard layout |

**Windows**

| Keys | Action |
|---|---|
| `Super+W` | Mission Control |
| `Super+Q` | Close window |
| `Super+F` | Fullscreen |
| `Super+Shift+F` | Maximise |
| `Super+T` | Float / tile |
| `Super+J` | Swap split direction |
| `Super+H` | Minimise (restore from the dock) |
| `Super+Z` | Window menu: snap, move, opacity |
| `Super+Arrows` | Focus left, right, up, down |
| `Super+Shift+Arrows` | Move window |
| `Super+left-drag` / `Super+right-drag` | Drag / resize window |

**Workspaces**

| Keys | Action |
|---|---|
| `Super+1` to `Super+0` | Go to workspace 1 to 10 |
| `Super+Shift+1` to `Super+Shift+0` | Send window to workspace 1 to 10 |
| `Super+Tab` | Previous workspace |
| `Super+Ctrl+Down` | Next empty workspace |
| `Super+mouse wheel` | Next / previous workspace |
| `Super+S` | Show / hide scratchpad |
| `Super+Alt+S` | Send window to scratchpad |

**Screen**

| Keys | Action |
|---|---|
| `Alt+Shift+S`, `Print` | Screenshot an area (editor) |
| `Ctrl+Print` | Screenshot an area, copy only |
| `Shift+Print` | Screenshot this screen |
| `Super+Print` | Screenshot the focused window |
| `Ctrl+Shift+Print` | Screenshot both screens |
| `Alt+Print` | Screenshot in 5 seconds |
| `Super+Ctrl+S` | Pin an area of the screen on top |
| `Super+Shift+T` | Copy text from the screen |
| `Super+Alt+R` | Record the screen (again: stop) |
| `Super+Alt+Shift+R` | Record an area (again: stop) |
| `Super+Shift+C` | Colour picker |
| `Super+M` | Hand the shared monitor over and back (only when a shared monitor is set up) |

**Hardware, desktop, session, media**

| Keys | Action |
|---|---|
| `Super+F5` | Next power mode (where the computer has power modes) |
| `Super+F6` | Move the keyboard to the bar (arrows, Enter, Esc) |
| `Super+L` | Lock the screen |
| `Super+Shift+R` | Reload Hyprland |
| `Super+Shift+E` | Log out |
| Volume, mute, microphone mute, play / pause, next, previous keys | Media |
| Brightness keys | Brightness (where the hardware exists) |
| Keyboard backlight keys | Keyboard backlight (where the hardware exists) |
| Lid closed / opened | Fixed: lock and sleep handling |

Three-finger swipe sideways switches desktop; three fingers up opens Mission Control.

## Where to go next

- [Install](docs/install.md): the full steps for Arch and Fedora, update, remove, virtual machines.
- [User guide](docs/USER-GUIDE.md): the desktop, Settings and recovery.
- [How do I change...](docs/how-to.md): theme, bar, keys, screens, power, with the Settings way and the file way.
- [Themes](docs/THEMES.md), [the bar](docs/bar.md), [hardware](docs/hardware.md), [modules](docs/modules.md).
- [Troubleshooting](docs/troubleshooting.md): when something does not work.
- All docs: [docs/README.md](docs/README.md). To contribute: [CONTRIBUTING.md](CONTRIBUTING.md).

## Customise

The top level of this repo:

| Path | What |
|---|---|
| `install.sh` | the one command (install, update, doctor, detect, modules, rollback, backups, uninstall) |
| `config/` | one folder per app, mirroring `~`: `hypr`, `quickshell`, `ghostty`, `fish`, `scripts` (`~/.local/bin`), `themes`, … |
| `distros/` | `arch.sh`, `fedora.sh`: package install, repos, NVIDIA driver ([distros/README.md](distros/README.md)) |
| `docs/` | the documentation ([docs/README.md](docs/README.md)) |
| `lib/` | the installer's parts, one file each |
| `migrations/` | one-time changes that carry an old install to a newer layout ([migrations/README.md](migrations/README.md)) |
| `modules/` | optional hardware or uses; copy `modules/_template/` to add one |
| `packages/` | `manifest.txt` (what and why), `arch.txt` and `fedora.txt` (real names) |
| `plugins/` | the Hyprland title-bar minimise plugin, built by `hypr-plugins` |
| `tests/` | the checks (`tests/lint.sh`, `tests/all.sh`) |
| `themes` | a shortcut link to `config/themes/.local/share/hyprism/themes`: one folder per theme |

- **A new theme:** copy `themes/_template` to `~/.config/hyprism/themes/<id>`, edit `theme.json`, run `theme <id>`.
- **A new module:** [docs/modules.md](docs/modules.md). **A new bar item:** [docs/bar.md](docs/bar.md).
- **Another distro:** `distros/<id>.sh` and `packages/<id>.txt`.
- Fonts the themes use that distros do not ship are in `config/fonts/` (SIL Open Font License).

## Uninstall and recovery

| What broke | Do this |
|---|---|
| Dotfiles | `./install.sh uninstall` removes the links and puts back backed-up files (`./install.sh backups` lists them) |
| The Hyprland session | Ctrl+Alt+F3 for a text console, then `desktop-reset` or `./install.sh uninstall` |
| The shell (bar, dock) | `qs kill; qs &`; `qs log` shows errors; `desktop-reset shell` |
| A Settings choice | `desktop-reset`, or one page's **Reset to defaults** |
| An update | `./install.sh rollback` |

More: [docs/troubleshooting.md](docs/troubleshooting.md).

## Secrets

Never in this repo: SSH/GPG keys, API keys, tokens, `.env` files. `.gitignore` blocks the common names and a
gitleaks pre-commit hook scans every commit. Settings files never land in the repo folder.
