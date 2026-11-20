<div align="center">

# Hyprism

**One Wayland desktop, three complete designs.**
Hyprland and a Quickshell shell for Arch, CachyOS and Fedora: one install command, one Settings app, no config files to edit.

[![CI](https://github.com/EduardoBojer98/hyprism/actions/workflows/ci.yml/badge.svg)](https://github.com/EduardoBojer98/hyprism/actions/workflows/ci.yml)
![Hyprland 0.57](https://img.shields.io/badge/Hyprland-0.57-58E1FF?logo=hyprland&logoColor=white)
![Quickshell 0.3](https://img.shields.io/badge/Quickshell-0.3-7E57C2)
![Arch / CachyOS](https://img.shields.io/badge/Arch%20%2F%20CachyOS-supported-1793D1?logo=archlinux&logoColor=white)
![Fedora 44+](https://img.shields.io/badge/Fedora%2044%2B-supported-51A2DA?logo=fedora&logoColor=white)

[Themes](#themes) · [Features](#features) · [Settings](#settings) · [Quick start](#quick-start) · [Keys](#keys) · [Recovery](#uninstall-and-recovery) · [Docs](docs/README.md)

<img src="docs/screenshots/themes/pebble-dark.webp" alt="Hyprism with the Pebble theme: river-stone greys with a lichen-green accent, a floating bar and the launcher open" width="100%">

</div>

## Why Hyprism

- **Set up for your hardware.** The installer looks at the computer once (`./install.sh detect`) and writes what
  it found to `~/.config/hyprism/hardware.toml`. Laptop, desktop, NVIDIA, hybrid graphics, touch screen, ASUS:
  each gets what it needs, and nothing is installed for hardware you do not have.
- **Modules.** Hardware support and optional extras (dev tools, gaming, local AI, a themed login screen) are
  folders that switch on by themselves or with `--with`. See [docs/modules.md](docs/modules.md).
- **Themes are whole designs.** Each one sets the bar, panels, type, shapes, colours, motion, window frames, lock
  screen, terminal, wallpaper, icons and cursor, in a light and a dark version. Make your own by copying one folder.
- **A modular bar.** Every item is its own folder with its own settings, on any screen edge, as many times as you
  like.
- **One settings file.** Everything you change in Settings (`Super+I`) is saved to
  `~/.config/quickshell/settings.json`, never in the repo. [docs/settings-reference.md](docs/settings-reference.md)
  lists every key.
- **Free software only.** No paid apps, trials or subscriptions.
- **Arch, CachyOS and Fedora 44+.** CI installs on both and tests an update from the last release.

## Themes

Switch with **Settings → Appearance → Themes**, the menu, or `theme pebble` in a terminal (`theme` lists them).
The left picture is each theme's own default mode.

| Theme | The idea | Bar | Motion |
|---|---|---|---|
| **Pebble** (default) | calm and matte: river-stone greys, one lichen accent, light numerals, room to breathe | floating, at the top, clock in the middle | gentle ease-out |
| **Poster** | loud and graphic: paper and ink, red, cobalt and yellow, heavy type, hard shadows | a tall paper bar with big workspace blocks and a display clock | slams in |
| **Monolith** | a neon terminal HUD: mono type, blue-black, acid lime and an electric-blue second colour, corner brackets instead of shadows | a slim floating status line: workspace reticles, your apps, media in the middle | near-instant |

<table>
  <tr>
    <th>Pebble</th>
    <th>Poster</th>
    <th>Monolith</th>
  </tr>
  <tr>
    <td><img src="docs/screenshots/themes/pebble-dark.webp" alt="Pebble, dark"><br><img src="docs/screenshots/themes/pebble-light.webp" alt="Pebble, light"></td>
    <td><img src="docs/screenshots/themes/poster-light.webp" alt="Poster, light"><br><img src="docs/screenshots/themes/poster-dark.webp" alt="Poster, dark"></td>
    <td><img src="docs/screenshots/themes/monolith-dark.webp" alt="Monolith, dark"><br><img src="docs/screenshots/themes/monolith-light.webp" alt="Monolith, light"></td>
  </tr>
</table>

What you can change on top of a theme, kept separately for each theme:

- **Light or dark:** the theme's own, Light or Dark for every theme (also a Control Center button).
- **Adjust:** accent and second colour, corners, gaps between windows and at the screen edge, window frame, font,
  text size, window motion, window shadow, blur behind windows and terminal colours. **Reset** puts it back.
- **Animations:** Full, Reduced (short fades, nothing moves) or Off.
- **Bar shape:** edge, size, floating or attached and the dock's place follow the theme you are on.
- **Icons and cursor:** each theme brings a matching pack (Pebble: Breeze and Capitaine; Poster and Monolith:
  Papirus with a Breeze cursor). Settings → Appearance → Icons / Cursor picks another or adds your own.
- **Colours from the wallpaper** (Settings → Wallpaper, off by default): the accents follow your own picture.

## Features

<table>
  <tr>
    <td width="50%"><img src="docs/screenshots/features/launcher.webp" alt="Launcher with every app in a grid and category filters"></td>
    <td width="50%"><img src="docs/screenshots/features/control-center.webp" alt="Control Center with Wi-Fi and Bluetooth tiles, a sound slider, a grid of small buttons and the power mode"></td>
  </tr>
  <tr>
    <td><b>Spotlight</b> (tap <code>Super</code>): suggestions first, then apps, files, calculator, settings, actions and web search. Every app by category; right-click an app to pin it, run its actions, show it in Files, see its info or uninstall it.</td>
    <td><b>Control Center</b> (<code>Super+C</code>): Wi-Fi, Bluetooth, screen and sound sliders, Focus, Night Light, Caffeine, Dark mode, microphone, recording, screenshot, power mode, and more you can show. Rearrange it in Settings: any tile large or small, sections and buttons hidden.</td>
  </tr>
  <tr>
    <td><img src="docs/screenshots/features/settings-themes.webp" alt="Settings app, Themes page with the three themes and the Adjust controls"></td>
    <td><img src="docs/screenshots/features/settings-bar.webp" alt="Settings app, Menu Bar page with three zones of bar items and a list of items to add"></td>
  </tr>
  <tr>
    <td><b>Settings</b> (<code>Super+I</code>): 37 pages in 13 groups (38 with ASUS hardware), searchable, applied live, each with Reset to defaults.</td>
    <td><b>Menu bar</b>: drag items between three zones, any item more than once, each copy with its own settings; "Start from" presets and different items per screen.</td>
  </tr>
  <tr>
    <td><img src="docs/screenshots/features/calendar.webp" alt="Calendar panel with a month grid, week numbers and upcoming holidays"></td>
    <td><img src="docs/screenshots/features/lock-screen.webp" alt="Settings app, Lock Screen page with a live preview"></td>
  </tr>
  <tr>
    <td><b>Calendar</b> (click the clock): public holidays for your country, observances, moon phases, week numbers, what's coming up.</td>
    <td><b>Lock screen</b>: clock style and position, date, greeting, your picture, widgets, background, blur and brightness, with a live preview.</td>
  </tr>
  <tr>
    <td><img src="docs/screenshots/features/system.webp" alt="System panel with CPU, memory, graphics, battery, processor cores and storage"></td>
    <td><img src="docs/screenshots/features/bar-sysinfo.webp" alt="Desktop with a system-info item in the bar showing CPU, temperature, memory and network"></td>
  </tr>
  <tr>
    <td><b>System panel</b>: CPU per core, memory, each graphics card by name (a sleeping dGPU stays asleep), battery, storage, network and the top processes.</td>
    <td><b>System-info bar item</b>: pick from 25 readings, their order, compact or detailed, and warning levels.</td>
  </tr>
  <tr>
    <td><img src="docs/screenshots/features/notifications.webp" alt="Notification centre panel under the bell"></td>
    <td><img src="docs/screenshots/features/menu.webp" alt="Grouped menu of actions, starting with the Appearance group"></td>
  </tr>
  <tr>
    <td><b>Notifications</b>: a centre with history grouped by app, six popup styles, six places, Do Not Disturb on a schedule, per-urgency time and sound.</td>
    <td><b>Menu</b>: every action in one grouped list: themes, light or dark, bar layouts, capture, network, sound, update, power.</td>
  </tr>
  <tr>
    <td><img src="docs/screenshots/features/cheatsheet.webp" alt="Keyboard shortcut cheatsheet grouped by apps, windows and workspaces"></td>
    <td><img src="docs/screenshots/features/welcome.webp" alt="First-run welcome panel with a theme picker, light or dark, bar layout and keyboard layouts"></td>
  </tr>
  <tr>
    <td><b>Shortcut cheatsheet</b> (<code>Super+/</code>): every binding on screen; type to filter. All rebindable in Settings.</td>
    <td><b>Welcome</b>: on first start, pick a look, light or dark, a bar layout and your keyboard layouts.</td>
  </tr>
  <tr>
    <td><img src="docs/screenshots/features/power.webp" alt="Power menu with lock, sleep, hibernate, log out, restart and shut down"></td>
    <td></td>
  </tr>
  <tr>
    <td><b>Power menu</b>: lock, sleep, hibernate, log out, restart, shut down.</td>
    <td></td>
  </tr>
</table>

<details>
<summary><b>Everything else</b></summary>

- **Bar items:** apps (the dock in the bar), apps button, quick tools, workspaces, active window, clock (choose what
  it shows, or a date pattern of your own), date, weather, media, tray, keyboard layout, notifications, status icons,
  network, Bluetooth, volume, brightness, battery, power mode, CPU, memory, GPU, system info, recording, power menu.
  Each works on a horizontal or vertical bar. Volume, network, Bluetooth, brightness, media and battery open their
  own small flyout. More in [docs/bar.md](docs/bar.md).
- **Dock:** on a screen edge or inside the bar. Pinned apps (drag to reorder), open windows as icons or names, one
  tile per window or combined into the app icon, live window previews on hover, auto-hide, size, spacing and mark
  style, small widget tiles, per screen.
- **Mission Control** (`Super+W`, three fingers up): every window at a glance.
- **Screenshots:** `Print` opens a capture bar (area, window, screen, delay, record with sound), edited in Satty.
  Pin an area on top of the screen, copy text from the screen, pick a colour.
- **Weather:** several saved places, cached for offline use (Open-Meteo, no API key).
- **Clipboard history** with images (`Super+V`), an emoji picker (`Super+.`), an on-screen keyboard.
- **Window behaviour:** tiling (split, main + stack or scrolling) or floating, focus follows the mouse, snapping,
  per-app rules; title bars and window borders that follow the theme (theme's, accent, gradient, rainbow, neon or
  your own colours).
- **Hot corners**, workspaces made as needed or fixed per screen, a scratchpad, touchpad gestures.
- **Small tools:** `record` (screen recording), `dropterm` (drop-down terminal), `webapp add "Name" URL` (a site as
  its own app), `remind 20m "Stand up"` (a reminder notification), `nv app` (run one app on the NVIDIA card),
  `powermode`, `monswitch` (hand a shared monitor to another computer over DDC/CI).
- **The theme reaches your apps:** GTK4/libadwaita, Qt and KDE apps, the Ghostty terminal, btop and the starship
  prompt.

</details>

## Settings

`Super+I`, or type a setting's name in Spotlight. Every page is listed with its keys in
[docs/settings-reference.md](docs/settings-reference.md); [docs/how-to.md](docs/how-to.md) shows the Settings way
and the file way.

| Group | Pages |
|---|---|
| **Appearance** | Themes (light or dark, Adjust, animations), Wallpaper (folders, slideshow, blur, colours from the wallpaper), Icons, Cursor |
| **Menu Bar & Dock** | Menu Bar (edge, size, items, presets, per screen), Dock (place, pinned apps, previews, auto-hide, widgets), Control Center, Weather, Calendar |
| **Notifications** | Notifications (and the on-screen volume and brightness pop-up), Focus |
| **Windows & Workspaces** | Window Behaviour (layout, focus, snapping), Window Look (title bars, border, opacity), Workspaces, Mission Control, Hot Corners, App Rules |
| **Displays** | Displays (resolution, scale, rotation, arrangement, Night Light, adaptive sync, HDR), Shared Monitor |
| **Keyboard & Mouse** | Keyboard (layouts, repeat, Caps Lock, Num Lock), Mouse & Touchpad (speed, acceleration, wheel, touchpad, gestures), Touch & Tablet (touchscreen, tablet mode, on-screen keyboard), Keyboard Shortcuts |
| **Sound** | output, input, volumes, devices |
| **Network & Bluetooth** | Wi-Fi & Network, Bluetooth, Phone |
| **Power** | Battery & Power (power mode, charge limit, low battery, lid), ASUS Hardware (only with asusctl) |
| **Lock Screen** | Lock Screen (clock, picture, widgets, background), Lock & Sleep (lock and sleep times, Caffeine) |
| **Search & Tools** | Search & Launcher, Actions, Clipboard, Screenshots |
| **Apps** | Installed Apps (where each came from, uninstall), Default Apps, Startup Apps, Terminal |
| **System** | About (the system, update and doctor), Language & Region |

## Quick start

Needs Arch, CachyOS, EndeavourOS or Fedora 44+ on x86_64, and a user with `sudo`. Other Arch-based systems (Manjaro) and
other processors install with a warning: they are untested.

One command: installs git if missing, clones Hyprism to `~/hyprism` and runs the installer.

```bash
curl -fsSL https://raw.githubusercontent.com/EduardoBojer98/hyprism/main/bootstrap.sh | bash
```

Look first without changing anything (any `install.sh` option goes after `--`):

```bash
curl -fsSL https://raw.githubusercontent.com/EduardoBojer98/hyprism/main/bootstrap.sh | bash -s -- --dry-run
```

`HYPRISM_DIR=...` clones somewhere else; `HYPRISM_BRANCH=develop` takes the dev channel. Running it again updates
the clone and re-runs the install. By hand instead:

```bash
git clone https://github.com/EduardoBojer98/hyprism.git ~/hyprism && cd ~/hyprism
./install.sh --dry-run     # shows everything it would do; changes nothing
./install.sh               # does it; asks before every system change
```

After the install, `hyprism` works from any folder: it is `install.sh` with the same commands and options
(`hyprism update`, `hyprism doctor`, `hyprism --help`).

The first run asks **full or base**:

- **Full** also installs everyday apps that follow the theme (Nautilus, Text Editor, Loupe, Papers, File Roller,
  Celluloid, Amberol, Calculator, Disks, Disk Usage Analyzer, Resources) and offers a themed login screen (greetd +
  ReGreet, asked before it replaces yours).
- **Base** sets up only the desktop and keeps your own apps and login screen.

Change it later with `./install.sh --profile full` or `--profile base`; nothing is uninstalled either way.

Then log out and pick **Hyprland** at the login screen (starting it without one: [docs/install.md](docs/install.md)).

| Command | What it does |
|---|---|
| `./install.sh doctor` | checks this computer against the repo, with the fix for each problem; changes nothing |
| `./install.sh update` | pulls Hyprism, updates the system, runs new migrations, relinks, restarts the shell |
| `./install.sh detect` | looks at the hardware again |
| `./install.sh modules` | lists the modules and which are on; `--with NAME` / `--without NAME` override |
| `./install.sh channel [stable\|dev]` | shows the update channel, or switches to it and updates (stable = `main`, dev = `develop`) |
| `./install.sh rollback` | goes back to the version before the last update |
| `./install.sh uninstall` | removes the links, puts backups back, undoes the system changes |

All commands and flags: `./install.sh --help`. Each also runs as `hyprism <command>` once installed.

### Modules

| Switches on by itself when found | Only when you ask (`--with NAME`) |
|---|---|
| `laptop`, `nvidia`, `nvidia-hybrid`, `asus`, `tablet`, `ddc-monitor`, `logitech`, `quirk-flow-x13` | `greeter` (themed login screen), `hibernate`, `dev` (mise, Docker), `gaming` (Steam, GameMode, MangoHud), `ai` (Ollama) |

## Keys

`Super` = Windows key. All of these can be changed in **Settings → Input → Keyboard Shortcuts**; **`Super+/` shows
every one on screen**. Generated from `config/hypr/.config/hypr/modules/binds.lua`.

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
| `Print` | Capture bar: area, window, screen, delay, record |
| `Alt+Shift+S` | Screenshot: drag an area or click a window (editor) |
| `Ctrl+Print` | Screenshot an area, copy only |
| `Shift+Print` | Screenshot this screen |
| `Super+Print` | Screenshot a window (click it) |
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
| `Super+Shift+F6` | Move the keyboard to the dock (arrows, Enter, menu key, Esc) |
| `Super+L` | Lock the screen |
| `Super+Shift+R` | Reload Hyprland |
| `Super+Shift+E` | Log out |
| Volume, mute, microphone mute, play / pause, next, previous keys | Media |
| Brightness keys | Brightness (where the hardware exists) |
| Keyboard backlight keys | Keyboard backlight (where the hardware exists) |
| Lid closed / opened | Fixed: lock and sleep handling |

Three fingers sideways switch workspace; three fingers up open Mission Control.

## Where to go next

- [Install](docs/install.md): the full steps for Arch and Fedora, update, remove, virtual machines.
- [User guide](docs/USER-GUIDE.md): the desktop, Settings and recovery.
- [How do I change...](docs/how-to.md): theme, bar, keys, screens, power, with the Settings way and the file way.
- [Themes](docs/THEMES.md), [the bar](docs/bar.md), [hardware](docs/hardware.md), [modules](docs/modules.md),
  [every setting](docs/settings-reference.md).
- [Troubleshooting](docs/troubleshooting.md): when something does not work.
- All docs: [docs/README.md](docs/README.md). To contribute: [CONTRIBUTING.md](CONTRIBUTING.md).

## Customise

The top level of this repo:

| Path | What |
|---|---|
| `install.sh` | the one command (install, update, doctor, detect, modules, rollback, backups, uninstall) |
| `bootstrap.sh` | the one-line install: installs git, clones or updates the repo, runs `install.sh` |
| `config/` | one folder per app, mirroring `~`: `hypr`, `quickshell`, `ghostty`, `fish`, `scripts` (`~/.local/bin`), `themes`, … |
| `distros/` | `arch.sh`, `fedora.sh`: package install, repos, NVIDIA driver ([distros/README.md](distros/README.md)) |
| `docs/` | the documentation ([docs/README.md](docs/README.md)) |
| `lib/` | the installer's parts, one file each |
| `migrations/` | one-time changes that carry an old install to a newer layout ([migrations/README.md](migrations/README.md)) |
| `modules/` | hardware support and optional extras; copy `modules/_template/` to add one |
| `packages/` | `manifest.txt` (what and why), `arch.txt` and `fedora.txt` (real names) |
| `plugins/` | the Hyprland title-bar minimise plugin, built by `hypr-plugins` |
| `tests/` | the checks (`tests/lint.sh`, `tests/all.sh`); `tests/nested.sh` runs a test desktop in a window |
| `themes` | a shortcut link to `config/themes/.local/share/hyprism/themes`: one folder per theme |

- **A new theme:** copy `themes/_template` to `~/.config/hyprism/themes/<id>`, edit `theme.json`, run `theme <id>`.
  See [docs/THEMES.md](docs/THEMES.md).
- **A new module:** [docs/modules.md](docs/modules.md). **A new bar item:** [docs/bar.md](docs/bar.md).
- **Another distro:** `distros/<id>.sh` and `packages/<id>.txt`.
- Fonts the themes use that distros do not ship are in `config/fonts/` (SIL Open Font License).

## Uninstall and recovery

| What broke | Do this |
|---|---|
| Dotfiles | `./install.sh uninstall` removes the links and puts back backed-up files (`./install.sh backups` lists them) |
| The Hyprland session | Ctrl+Alt+F3 for a text console, then `desktop-reset` or `./install.sh uninstall` |
| The shell (bar, dock) | `qs kill; qs &`; `qs log` shows errors; `desktop-reset shell` |
| A Settings choice | `desktop-reset` (puts your settings aside, nothing is deleted), or one page's **Reset to defaults** |
| An update | `./install.sh rollback` |

More: [docs/troubleshooting.md](docs/troubleshooting.md).

## Secrets

Never in this repo: SSH/GPG keys, API keys, tokens, `.env` files. `.gitignore` blocks the common names and a
gitleaks pre-commit hook scans every commit. Settings files never land in the repo folder.

## License

[MIT](LICENSE).
