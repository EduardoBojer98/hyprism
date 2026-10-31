# linux-setup

A macOS-style desktop for Arch-based Linux (built on CachyOS): **Hyprland** with a **Quickshell**
shell in frosted Graphite Glass style (dark by default, light in Settings). Everything is free software, and everything a user would
want to change is in the **Settings app** (`Super+I`), not in config files. An existing KDE Plasma
install stays untouched and selectable at the login screen.

- **Menu bar**: desktops and the app name on the left; weather, date and time (calendar) in the
  centre; tray, CPU and NVIDIA GPU temperatures (click for CPU, both GPUs, memory, disk, fans and top processes), keyboard layout (its own list of layouts), status (Control Center), notifications bell on the right;
  utility menu behind the system logo at the left end (its **Power…** entry opens the power menu: lock, sleep,
  hibernate, log out, restart, shut down). Arrange it in Settings > Menu Bar: move any item left, centre or
  right, hide it, or add network speed, CPU use, memory and now playing
- **Control Center**: Wi-Fi, Bluetooth, Focus (Do Not Disturb), Night Light, Caffeine, dark mode, media, power
  mode, display, sound and microphone; rearrange, show or hide its sections and tiles in Settings
- **Spotlight** (tap `Super`): suggestions first (weather, next event, last copied, most used apps, recent items, quick actions), then a Top Hit and results grouped apps → files →
  calculator → settings → actions → web; Files, Actions and clipboard history modes
- **Calendar** (click the clock): month grid with public holidays for your country, worldwide
  observances and moon phases (each switchable in Settings > Calendar), the selected day and what's coming up
- **Notification centre** with history, grouping and Do Not Disturb; **Mission Control**
  (`Super+W`, three fingers up); **dock**: all-apps button, pinned apps (drag to reorder), then each open window as its own live picture (click to bring up or minimise, middle-click to close, right-click for more)
- Keyboard shortcuts, displays, a shared monitor, sound, network, Bluetooth, power, wallpaper folders
  and slideshow, startup apps, lock and sleep, default apps, weather, appearance (13 colour themes:
  Midnight, Graphite, Cocoa, Catppuccin, Tokyo Night, Dracula, Nord, Gruvbox, Rosé Pine, Everforest,
  Kanagawa, One Dark and Solarized, each light or dark or switching at sunset, and the terminal follows;
  accent palette or any custom colour, glass, corners, gaps, font and text size): all editable in Settings
- Hardware extras that switch themselves on where the hardware exists: ASUS fan curves and charge
  limit (asusctl), keyboard light, a monitor shared with another computer (DDC/CI)

## Install

Needs an Arch-based system (pacman) with a login screen that lists Wayland sessions.

```bash
git clone <this repo's URL> ~/linux-setup
cd ~/linux-setup
./install.sh --dry-run     # see what would be linked and backed up
./install.sh --system      # install packages (asks once, uses sudo), then link the dotfiles
```

Log out and pick **Hyprland** at the login screen. To only (re)link the dotfiles later: `./install.sh`.
To remove everything: `./install.sh --undo` (puts your previous files back).

| Step | What it does |
|---|---|
| `system/02-desktop.sh` | Hyprland, Quickshell and desktop packages (`packages/desktop.txt`), lid behaviour, Hyprland as default session on Plasma Login |
| `system/03-apps.sh` | Shell tools and everyday apps (`packages/dev.txt`, `packages/apps.txt`): edit the lists first if you don't want them |
| `system/hosts/<hostname>/` | Steps for one specific computer, run only on the computer with that hostname |

First run: open **Settings** (`Super+I`) and set the weather city, wallpaper, keyboard layouts and
displays. Your choices are saved on your computer only (see [docs/USER-GUIDE.md](docs/USER-GUIDE.md)).

## Keys (Super = Windows key)

All of these can be changed in **Settings → Keyboard Shortcuts**.

| Keys | Action |
|---|---|
| tap `Super`, `Super+Space` | Spotlight (`Super+Shift+Space` files, `Super+A` all apps) |
| `Super+V` | Clipboard history at the pointer |
| `Super+C` / `Super+N` / `Super+Shift+N` | Control Center / notification centre / Do Not Disturb |
| `Super+W`, three fingers up | Mission Control |
| `Super+I` | Settings |
| `Super+Enter` / `Super+E` / `Super+B` | Terminal / files / browser |
| `Super+.` | Emoji picker |
| `Super+Q` / `Super+H` | Close / minimise window (restore from the dock) |
| `Super+F` / `Super+Shift+F` / `Super+T` | Fullscreen / maximise / float |
| `Super+Arrows` / `Super+Shift+Arrows` | Focus / move window |
| `Super+1…0` / `Super+Shift+1…0` | Go to / send window to desktop; `Super+Tab` previous |
| `Super+S` / `Super+Alt+S` | Scratchpad / send window there |
| `Super+Shift+S` or `Print` / `Shift+Print` / `Super+Shift+T` | Screenshot an area on the screen under the mouse (Flameshot: annotate, Enter copies and saves) / whole screen / copy text from screen (OCR) |
| `Super+Shift+C` | Colour picker |
| `Super+L` / `Super+Shift+E` | Lock / log out |
| `Super+F5` | Next power mode: Quiet → Balanced → Performance (also `powermode` in a terminal) |
| `Super+drag` / `Super+right-drag` | Move / resize window |
| Three-finger swipe sideways | Switch desktop |

## Layout

| Path | What |
|---|---|
| `home/<package>/` | GNU Stow packages mirroring `~`: `hypr`, `quickshell`, `ghostty`, `fish`, `starship`, `scripts`, … |
| `home/quickshell/.config/quickshell/` | The shell; `ConfigData.qml` holds every default |
| `home/hypr/.config/hypr/` | Hyprland Lua config; `modules/` shared, `hosts/<hostname>.lua` per computer |
| `packages/*.txt`, `system/` | Package lists and system steps (`system/hosts/<hostname>/` per computer) |
| `docs/USER-GUIDE.md` | Configuring, other computers, troubleshooting |
| `docs/thermal-audit.md` | ROG Flow X13 temperatures and power modes: what each mode does, how to switch, how to undo |
| `DESIGN.md` | Design system: tokens, components, rules |

## Undo and recovery

| What broke | Do this |
|---|---|
| Dotfiles | `./install.sh --undo` removes the links and offers to restore the last backup |
| The Hyprland session | Pick another session at the login screen, or Ctrl+Alt+F3 and log in on a text console |
| The shell (bar, dock) | `pkill -x qs; pkill -x quickshell; qs &` restarts it (exactly one copy); `qs log` shows errors |
| A Settings choice | Delete its file from the user guide's table to go back to defaults; several pages also have **Reset to defaults** |

## Secrets

Never in this repo: SSH/GPG keys, API keys, tokens, `.env` files. `.gitignore` blocks the common names
and a gitleaks pre-commit hook (enabled by `install.sh`) scans every commit.
