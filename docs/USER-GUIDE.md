# User guide

## Where your settings live

Everything you change in **Settings** (`Super+I`) is saved in **one file on your computer**, never in git:
`~/.config/quickshell/settings.json`. The shell writes the files other programs read from it (and applies them
live), so those are outputs: edit Settings or `settings.json`, not them.

| File written from `settings.json` | For | Settings page |
|---|---|---|
| `~/.config/hypr/settings/hypridle.conf` | hypridle: dim, lock, screens off, sleep | Power → Lock & Sleep |
| `~/.config/hypr/settings/input.lua` | Hyprland: keyboard layouts, repeat, touchpad, pointer | Input → Keyboard & Touchpad |
| `~/.config/hypr/settings/displays.lua` | Hyprland: screen arrangement, modes, scale, rotation | Displays → Screens |
| `~/.config/monswitch.conf` (`.off` while off) | `monswitch`: a monitor shared with another computer | Displays → Shared Monitor |
| `~/.config/hypr/settings/keybinds.lua`, `windows.lua` | Hyprland: your shortcut changes, window behaviour | Input → Keyboard Shortcuts, Windows |
| `~/.config/hypr/settings/theme.lua`, `hyprlock-theme.conf` | Hyprland and the lock screen: the theme | Appearance → Themes |
| `~/.config/hypr/settings/language.lua` | apps' language and formats (next login) | About → Language & Region |
| `~/.config/ghostty/theme.conf`, `~/.config/fuzzel/theme.ini`, `gtk-3.0/` + `gtk-4.0/linux-setup.css` | terminal, emoji picker and GTK apps: the theme's colours | Appearance → Themes |
| `~/.config/hypr/settings/wallpaper` (a link), `shared.lua` (while a shared monitor is away) | hyprpaper; monitors.lua | Appearance → Wallpaper; Shared Monitor |

Kept outside `settings.json` on purpose: `~/.config/autostart/*.desktop` (Startup Apps; the standard autostart folder) and `~/.local/share/icons/` (Icons and Cursor → Add theme).

A missing file means "use the defaults", so deleting one resets that part (`./install.sh` puts back
the ones Hyprland needs). The defaults are in `config/quickshell/.config/quickshell/ConfigData.qml`,
`config/hypr/.config/hypr/defaults/` and the Hyprland modules. Configs are linked file by file, so
these settings files are real files in `~/.config`, never inside the repo folder.

## What you can change in Settings

Settings opens with `Super+I` (or from the Control Center). The search field finds any page by its name or
by words like "dark", "border", "update" or "timezone". Every control works by keyboard too: Tab moves
between them, Space or Enter presses, arrows change a choice or a slider.

| Group (sidebar) | Pages and what's in them |
|---|---|
| **Appearance** | Themes (gallery, light or dark, adjust accent, corners, gaps, frame, font, text size, motion, animations), Theme Builder (make your own), Wallpaper (folders, slideshow), Icons, Cursor |
| **Menu Bar** | edge, size, floating, per screen, battery percentage, clock; the items, by drag and drop |
| **Dock** | on/off, place (or inside the bar), size, icon size, auto-hide, pinned and open apps, per screen |
| **Lock Screen** | clock style and place, date, greeting, your picture, widgets, background, with a live preview |
| **Desktop & Widgets** | Control Center (rearrange sections and tiles), Notifications, Search & Launcher, Clipboard, Weather, Calendar, Hot Corners |
| **Windows** | Window Behaviour (layout, focus, snapping), Window Look (title bars, inactive opacity and dimming; gaps and frame are under Themes → Adjust), App Rules |
| **Displays** | Screens (arrange, resolution, refresh, scale, rotation, Night Light), Shared Monitor (advanced: a monitor shared with another computer) |
| **Input** | Keyboard & Touchpad (layouts, repeat, touchpad, pointer, MX Master), Keyboard Shortcuts (click a shortcut's keys and press new ones) |
| **Sound** | output and input devices (pick the one in use), volumes, per-app volume |
| **Network & Bluetooth** | Wi-Fi & Network, Bluetooth devices |
| **Power** | Battery & Power (health, charge limit, power mode, lid), Lock & Sleep (when to lock, screens off, sleep), ASUS Hardware (only on ASUS laptops) |
| **Apps** | Installed Apps, Default Apps (browser, files, terminal, task manager), Startup Apps |
| **About** | this computer, Update, Re-run the install, Run doctor; Language & Region |

Everything applies right away except language (next login) and lid behaviour (a system file set by the
installer's `laptop` module).

## The menu

`Super+Space`, then the Actions button (or Tab to Actions): with nothing typed it lists everything under
headings; type to find one. It reaches:

- **Appearance**: Themes…, one "Theme: name" per theme (a new theme folder appears by itself), Light mode,
  Dark mode, Theme's own light/dark, and a "Bar layout: name" for each bar preset.
- **Screens & capture**: screenshots, Record the screen / an area / Stop recording, text from the screen,
  colour picker, Mission Control, Night Light, Displays, the shared monitor (only when set up).
- **Network & sound**: Wi-Fi and Bluetooth (only where the computer has them), Sound output and input, and
  their Settings pages.
- **System**: Clipboard history, Keyboard shortcuts, Do Not Disturb, Caffeine, Welcome, Update the system and
  Hyprism, Check this computer (doctor), ROG Control Center (ASUS only). Update and doctor open a terminal
  that stays open at the end.
- **Power**: Lock, Sleep, Hibernate (where it works), Log out, Restart, Shut down, Power menu.

Websites as apps are made in a terminal with `webapp add "Name" https://address`; there is no menu entry yet.

The first time you log in, a Welcome panel offers a theme, light or dark, a bar layout and the keyboard
layouts, and lists the keys to know. It opens once; the "Welcome" action shows it again.

## Your hardware

- The installer looks at your computer and writes what it finds to `~/.config/hyprism/hardware.toml`.
- See it: `./install.sh detect` looks again, rewrites the file and prints it.
- A value is wrong? Add an `[override]` section at the end of the file, for example
  `display.internal = "eDP-2"`. Detection never changes that part.
- List the modules: `./install.sh modules`. It shows each one as on or off, and why.
- Turn one on or off: `./install.sh --with NAME` or `./install.sh --without NAME`. Your choice is kept under
  `[override]`; run `./install.sh` to apply it.

## Another computer

Nothing to set up for a new computer. The installer detects its hardware and turns on the modules that fit
(see Your hardware above). Modules live in `modules/<name>/`; each has a `README.md` that says what it adds.

Hardware features detect themselves at start (`Machine.qml`):

| Feature | Appears when |
|---|---|
| ASUS Hardware page, charge limit, ROG action | `asusctl` is installed |
| Keyboard light button | a `/sys/class/leds/*kbd_backlight` exists |
| Shared monitor button, `Super+M` | `~/.config/monswitch.conf` exists |

### A monitor shared with another computer

`monswitch` hands a monitor to another computer over DDC/CI and back (`Super+M`, Control Center),
moving your desktops off it while it's away (it mirrors a screen here so the monitor keeps a signal).
Turn DDC/CI on in the monitor's menu, then **Settings → Displays → Shared Monitor**: pick the monitor and
its two inputs, Save. It follows switches made on the monitor's own buttons too.

## Recovery

A broken setting or theme never needs a reinstall:

| What | Do |
|---|---|
| The desktop looks wrong or unusable after a change | `desktop-reset` in a terminal (`Super+Return`): your Settings files move to `~/.local/state/hyprism/reset-<time>/` (nothing is deleted), the shell and Hyprland restart on the defaults. `desktop-reset shell` resets only the bar, dock, theme and panels. Copy a file back to undo. |
| `settings.json` was damaged (a bad hand edit) | Nothing to do: the shell keeps it as `settings.json.broken` and starts on the defaults. Repair and copy it back, or leave it. |
| One part is wrong (keys, displays, input, idle) | Delete that file in `~/.config/hypr/settings/` (see the table above); Settings writes it again. |
| Hyprland shows a red error bar | `hyprctl configerrors` names the file and line. |
| No working screen at all | `Ctrl+Alt+F3` for a text console, log in, run `desktop-reset`, then `Ctrl+Alt+F1` (or reboot). To remove Hyprism, run `./install.sh uninstall` there instead. |
| Is everything in order? | `./install.sh doctor` checks links, packages, Hyprland errors, the generated files and stray background helpers, and says how to fix each. |
| Remove Hyprism | `./install.sh uninstall` removes the links, puts back the backed-up files and undoes the system changes. `./install.sh backups` lists the backups; `--backup NAME` picks one. |

## Troubleshooting

| Problem | Try |
|---|---|
| Bar or dock missing / frozen | `qs kill; qs &` and check `qs log`; still broken: `desktop-reset shell` |
| Notifications stop showing | another daemon took over (e.g. mako started while the shell was down): `pkill mako` |
| A shortcut does nothing | Settings → Keyboard Shortcuts shows what it's set to; `hyprctl configerrors` |
| Hyprland config error after an update | `hyprctl configerrors`; fix or delete the named file in `~/.config/hypr/settings/` |
| Blurry X11 apps | already handled (`xwayland.force_zero_scaling`); they look slightly smaller on scaled screens |
