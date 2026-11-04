# linux-setup

A Wayland desktop for **Arch/CachyOS and Fedora** (built on CachyOS): **Hyprland** with a **Quickshell** shell
that comes in **13 rices**, whole desktop designs you switch in one step. Everything is free software,
and everything you'd want to change is in the **Settings app** (`Super+I`), not in config files. An existing KDE Plasma
install stays untouched and selectable at the login screen.

| Rice | The idea | Bar | Launcher |
|---|---|---|---|
| **Pebble** (default) | soft and round, glass | three floating pills, stretching dots, a dock | rounded panel, app grid |
| **Monolith** | the desktop as a terminal | bottom text strip, mono | a command strip across the top |
| **Console** | amber HUD | no bar: a readout on the top edge, corner brackets | large mono query |
| **Workstation** | familiar | bottom taskbar: Start, search, running apps, clock | start menu from the corner |
| **Poster** | loud and flat | paper bar, huge workspace blocks | half the screen, huge query |
| **Glass** | the classic | translucent menu bar, glass dock | split glass pieces |
| **Canvas** | GNOME manners | black bar, centred clock, one status pill | a large sheet over a dark screen |
| **Atlas** | Swiss | black rail on the right, square blocks | heavy type |
| **Noir** | the screen as a film | letterbox bands, serif credits, subtitle notifications | serif sheet |
| **Garden** | one island | a pale capsule at the bottom with apps, workspaces, clock | rises from the island |
| **Zen** | almost nothing | the time and dots in the corner | small centred list |
| **Mist** | light, monochrome | one thin top line with ticks | small centred list |
| **Halo** | one pill | a small floating pill at the bottom | small centred list |

Each rice also brings its own fonts, corners, window frames, shadows, motion, notification style, lock
screen, terminal palette and wallpaper. `rice` lists them, `rice garden` switches; or Settings → Rices,
where **Adjust** changes any rice's accent colours, corners, gaps, frame, bar size, font, text size, motion,
shadow and blur (kept per rice; Reset puts it back).

- **The bar** (its place and shape come from the rice): workspaces, the focused app, clock (calendar), tray,
  keyboard layout, status (Control Center), notifications; marks while recording (click the red dot to stop),
  in Do Not Disturb and with Caffeine on. The utility menu (system logo, where the rice has one) holds the power menu
- **Control Center**: Wi-Fi, Bluetooth, Focus (Do Not Disturb), Night Light, Caffeine, touchpad and touchscreen on/off,
  screen recording, media, power mode, display, sound and microphone; rearrange its sections and tiles in Settings
- **Spotlight** (tap `Super`): suggestions first (weather, next event, last copied, most used apps, recent items, quick actions), then a Top Hit and results grouped apps → files →
  calculator → settings → actions → web; Files, Actions and clipboard history modes
- **Calendar** (click the clock): month grid with public holidays for your country, worldwide
  observances and moon phases (each switchable in Settings > Calendar), the selected day and what's coming up
- **Notification centre** with history, grouping and Do Not Disturb; **Mission Control**
  (`Super+W`, three fingers up); **dock**: all-apps button, pinned apps (drag to reorder), then each open window as its own live picture (click to bring up or minimise, middle-click to close, right-click for more)
- Keyboard shortcuts, displays, a shared monitor, sound, network, Bluetooth, power, wallpaper folders
  and slideshow, startup apps, lock and sleep, default apps, weather, rices and their adjustments: all editable in Settings
- Small tools: `record` (screen recording, Super+Alt+R), `dropterm` (drop-down terminal, Super+\`),
  `webapp add "Name" URL` (a site as its own app), `remind 20m "Stand up"` (a reminder notification)
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

All of these can be changed in **Settings → Keyboard Shortcuts**. **`Super+/` shows every shortcut on screen** (type to filter).

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
| `Super+/` | Keyboard shortcut cheatsheet |
| ``Super+` `` | Drop-down terminal (again: hide it) |
| `Super+Alt+R` / `Super+Alt+Shift+R` | Record the screen / an area (again: stop and save to ~/Videos/Recordings) |
| `Super+Ctrl+↓` | Next empty workspace |
| `Alt+Shift+S` (also `Print`, `Super+Shift+S`) | Screenshot an area, then annotate (see Screenshots) |
| `Ctrl+Print` / `Shift+Print` / `Super+Print` / `Ctrl+Shift+Print` / `Alt+Print` | Area straight to clipboard / this screen / focused window / both screens / in 5 seconds |
| `Super+Shift+T` | Copy text from the screen (OCR) |
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
| `docs/` | `ARCHITECTURE.md` (how it fits together), `DESIGN.md` (rices and design rules), `REDESIGN-PLAN.md`, `rice-concepts.html`, `AUDIT.md`, `RESEARCH.md`, `USER-GUIDE.md`, `RECOMMENDATIONS.md`, `thermal-audit.md` |

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

### Rices, colours and fonts

All of it is data in `config/quickshell/.config/quickshell/Rices.qml`; `Theme.qml` turns the active rice into
tokens, `ThemeSync.qml` carries it to Hyprland (frames, gaps, shadow, blur, motion), the lock screen, GTK,
Ghostty, fuzzel and the wallpaper. Design rules: `docs/DESIGN.md`.

- Switch: `rice NAME` or Settings → Rices. Adjust a rice there (accent colours, corners, gaps, frame, bar size,
  font, text size, motion, shadow, blur); `Everywhere` holds what stays the same in every rice (text scale,
  animations, terminal colours, the rice's wallpaper or yours).
- Add a rice: one entry in `Rices.list` (copy the closest one), a terminal palette in
  `config/ghostty/.config/ghostty/themes/<Name>`, a wallpaper design in `config/scripts/.local/bin/rice-wallpaper`,
  and if it needs a new bar shape, a layout in `Bar.qml`.
- Fonts the rices use and the distros don't ship are bundled in `config/fonts/` (SIL Open Font License).
- Monitors: Settings → Displays (arrangement, scale, refresh, mirror); per-computer defaults in `hosts/<name>/home/.config/hypr/host.lua`.

### Screenshots

`screenshot` (`~/.local/bin`) = **grim** (capture) + **slurp** (pick an area) + **Satty** (editor).

1. `Alt+Shift+S`, drag an area (works across both screens, and with touch).
2. Annotate: arrow, line, rectangle, ellipse, pen, highlighter, text, numbered markers, blur, crop.
   Colours and stroke size sit in the bottom bar; `Ctrl+Z` / `Ctrl+Y` undo / redo.
3. **Enter** copies and saves, **Ctrl+S** saves, **Esc** cancels. Files land in
   `~/Pictures/Screenshots/Screenshot_YYYY-MM-DD_HH-MM-SS.png`; click the notification to open it.

`screenshot area|screen|window|all|delay N`, add `--copy` to skip the editor. Editor look:
`config/satty/.config/satty/config.toml`.

## Undo and recovery

| What broke | Do this |
|---|---|
| Dotfiles | `./install.sh undo` removes the links and offers to restore the last backup |
| The Hyprland session | **Fall back to KDE:** log out (`Super+Shift+E`), pick **Plasma (Wayland)** at the login screen. This repo never links over KDE's config, so KDE stays as it was. No login screen at all: Ctrl+Alt+F3, log in on the text console, `./install.sh undo` |
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
