# linux-setup

A polished Wayland desktop for **Arch/CachyOS and Fedora** (built on CachyOS): **Hyprland** with a **Quickshell**
shell in frosted Graphite Glass style — dark by default, light or auto-switching in Settings. Everything is free software,
and everything you'd want to change is in the **Settings app** (`Super+I`), not in config files. An existing KDE Plasma
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

## Install (one command)

Needs Arch Linux, CachyOS (or another Arch-based distro) or Fedora 44+, a normal user with sudo, and
a login screen that lists Wayland sessions. Clone it anywhere:

```bash
git clone https://github.com/EduardoBojer98/linux-setup.git ~/linux-setup
cd ~/linux-setup
./install.sh --dry-run     # see everything it would do; changes nothing
./install.sh               # do it (asks before system changes; safe to run again)
```

Log out and pick **Hyprland** at the login screen. KDE Plasma (or whatever you had) stays selectable.

| Step (in order) | What it does |
|---|---|
| `packages` | installs `packages/manifest.txt` + the host's `packages.txt`, using `packages/<distro>.txt` for the real names (Arch: repos + AUR via paru/yay; Fedora: repos, COPR, RPM Fusion) |
| `nvidia` | offers the NVIDIA driver when there's an NVIDIA GPU without one |
| `links` | links `config/<app>/` and `hosts/<host>/home/` into your home folder (GNU Stow, file by file); anything in the way is backed up to `~/.local/state/linux-setup/backups/` |
| `services` | Bluetooth, NetworkManager; Docker, if you have it, starts on first use instead of at boot |
| `session` | lid behaviour, Hyprland preselected on Plasma Login (asks) |
| `host` | the host's `steps/NN-*.sh`, each shown and asked separately |

Options: `--yes` (no questions), `--host <name>`, `--only <steps or modules>` (e.g. `--only links`, `--only shell`), `--dry-run`. `./install.sh undo` removes the links and offers the last backup back.

On Fedora, Hyprland 0.57 comes from the `sdegler/hyprland` COPR and Quickshell 0.3.2 from
`errornointernet/quickshell` (Fedora's own Quickshell is too old). A few packages have no Fedora
build (`squeekboard`): `packages/fedora.txt` says what to do instead.

This repo is the desktop only: Hyprland, the shell, their tools and look, a terminal and a file
manager. Your other apps (browser, editors, dev tools, Docker, Ollama, …) are yours to install; the
desktop works with whatever you pick in **Settings → Default Apps**. The cursor is your system's
default until you pick or add another in **Settings → Appearance → Cursor**.

## Update

```bash
./install.sh update
```

Pulls this repo (only when it has no local changes), updates the whole system (`paru -Syu` or
`pacman -Syu` / `dnf upgrade`, plus Flatpaks if you use them), installs packages the repo added,
relinks the configs and runs the doctor. Same as **Settings → System → About → Update**.

## Keep it in sync: doctor

```bash
./install.sh doctor
```

Lists missing packages, configs that aren't linked or were changed locally, files in the managed
folders that the repo doesn't know, services that are off, and uncommitted changes. Also in
**Settings → System → About → Run doctor**. Fix with `./install.sh` (or `--only links`), or commit
the change you made on purpose.

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
| `Super+Ctrl+Space` | Next keyboard layout (US ↔ Serbian Latin) |
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
| `install.sh` | the one command (install, doctor, undo) |
| `config/<app>/` | one folder per app, mirroring `~`: `hypr`, `quickshell`, `ghostty`, `fish`, `starship`, `fuzzel`, `scripts` (`~/.local/bin`), … |
| `config/quickshell/.config/quickshell/` | the shell; `ConfigData.qml` holds every default, `Theme.qml` every colour |
| `config/hypr/.config/hypr/` | Hyprland Lua config: `hyprland.lua` loads `modules/` (env, monitors, input, look, animations, binds, rules, autostart), then the host's `host.lua` |
| `hosts/<name>/` | one computer: `host.conf` (hostnames), `packages.txt`, `home/` (linked), `defaults/` (copied once), `steps/` (system steps). `default/` fits any PC; `flow-x13/` is the ROG Flow X13 |
| `packages/` | `manifest.txt` (logical name, module, why) and `arch.txt` / `fedora.txt` (real names and sources) |
| `distros/` | `arch.sh`, `fedora.sh`: install packages, enable repos, NVIDIA driver |
| `plugins/` | Hyprland plugin (title-bar minimise), built by `hypr-plugins` |
| `docs/` | `USER-GUIDE.md`, `AUDIT.md`, `RECOMMENDATIONS.md`, `thermal-audit.md` |
| `DESIGN.md` | design system: tokens, components, rules |

### A new computer

`cp -r hosts/default hosts/<name>`, put its hostname (`cat /etc/hostname`) in `hosts/<name>/host.conf`,
add monitors or workspace rules to `home/.config/hypr/host.lua` and extra packages to `packages.txt`.
Details: [hosts/README.md](hosts/README.md).

### Another distro

Add `distros/<id>.sh` (four functions) and `packages/<id>.txt` (every logical name mapped).
Details: [distros/README.md](distros/README.md).

### Changing common settings

Almost everything is in **Settings** (`Super+I`): displays, theme, wallpaper, icons, cursor, gaps
and borders, keyboard layouts, touchpad, shortcuts, default and startup apps, power and sleep.
Settings writes to `~/.config` only (list in the user guide). Defaults live in `ConfigData.qml`,
`config/hypr/.config/hypr/defaults/` and the Hyprland modules.

## Undo and recovery

| What broke | Do this |
|---|---|
| Dotfiles | `./install.sh undo` removes the links and offers to restore the last backup |
| The Hyprland session | Pick another session at the login screen, or Ctrl+Alt+F3 and log in on a text console |
| The shell (bar, dock) | `pkill -x qs; pkill -x quickshell; qs &` restarts it (exactly one copy); `qs log` shows errors |
| An update | See "Roll back an update" below |
| A Settings choice | Delete its file from the user guide's table to go back to defaults; several pages also have **Reset to defaults** |

### Roll back an update

On Arch/CachyOS with btrfs (the CachyOS default), **snap-pac** takes a snapshot of `/` before and
after every pacman or paru run, and **limine-snapper-sync** lists them in the Limine boot menu. The
doctor warns when any of this is missing.

1. Reboot. In the Limine menu open **Snapshots** and boot the one taken *before* the update
   ("pre", with the update's time).
2. Check everything works, then make it permanent: `sudo limine-snapper-restore` (or
   `limine-snapper-list` first to see them).

Snapshots cover `/` only, not `/home`, and they sit on the same disk: they undo a bad update, not a
dead SSD. Your configs are in this repo; for everything else in `/home`, keep a backup on another
disk (or add `sudo snapper -c home create-config /home` if you want `/home` snapshots too).
Fedora has no snapshots by default.

## Secrets

Never in this repo: SSH/GPG keys, API keys, tokens, `.env` files. `.gitignore` blocks the common names
and a gitleaks pre-commit hook (enabled by `install.sh`) scans every commit. Settings files never
land in the repo folder (configs are linked file by file).
