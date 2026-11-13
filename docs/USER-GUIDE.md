# User guide

How to live on the desktop after [installing it](install.md). To change one thing, see [how-to.md](how-to.md).

## First login and the welcome

Log in and pick **Hyprland**. The first time, a **Welcome** panel offers a theme, light or dark, a bar layout and
your keyboard layouts, and lists the keys to know. It opens once; the "Welcome" action in the menu shows it again.

The three keys to know: **tap `Super`** to search for anything, **`Super+I`** for Settings, **`Super+/`** for
every shortcut. The full key list is in the [README](../README.md#keys).

## The desktop

- **The bar** holds items (workspaces, clock, tray, battery and more). One engine draws it for every theme, on any
  screen edge. See [bar.md](bar.md).
- **The dock** shows pinned and open apps, on its own edge or inside the bar.
- **The launcher and the menu.** `Super+Space` opens Spotlight. The **Actions** button (or Tab to Actions) is the
  menu: with nothing typed it lists everything under headings; type to find one.
  - **Appearance**: Themes, one "Theme: name" per theme (a new theme folder appears by itself), Light mode, Dark
    mode, Theme's own light/dark, and a "Bar layout: name" for each bar preset.
  - **Screens & capture**: screenshots, record the screen or an area, stop recording, text from the screen, colour
    picker, Mission Control, Night Light, Displays, the shared monitor (only when set up).
  - **Network & sound**: Wi-Fi and Bluetooth (only where the computer has them), Sound output and input.
  - **System**: Clipboard history, Keyboard shortcuts, Do Not Disturb, Caffeine, Welcome, Update the system and
    Hyprism, Check this computer (doctor), ROG Control Center (ASUS only). Update and doctor open a terminal that
    stays open at the end.
  - **Power**: Lock, Sleep, Hibernate (where it works), Log out, Restart, Shut down, Power menu.
- **Control Center** (`Super+C`): Wi-Fi, Bluetooth, Focus, Night Light, Caffeine, sliders, power mode.
- **Notifications** have their own panel from the bell (`Super+N`): Do Not Disturb (`Super+Shift+N`), history by app.
- **On-screen display**: a small pop-up that confirms volume, brightness, microphone, layout and caps lock changes.

Websites as apps are made in a terminal with `webapp add "Name" https://address`; there is no menu entry yet.

## Windows and workspaces

Keys: `Super+Q` close, `Super+F` fullscreen, `Super+T` float or tile, `Super+H` minimise (restore from the dock),
`Super+Arrows` move focus, `Super+Shift+Arrows` move the window, `Super+1` to `0` go to a workspace,
`Super+Shift+1` to `0` send the window there, `Super+W` Mission Control, `Super+drag` and `Super+right-drag` move
and resize. A three-finger swipe sideways switches workspace. The full list: `Super+/`.

### Screenshots

`Alt+Shift+S` (or `Print`): drag an area (works across screens, and with touch), then annotate (arrow, shapes, pen,
highlighter, text, numbered markers, blur, crop). **Enter** copies and saves, **Ctrl+S** saves, **Esc** cancels.
Files land in `~/Pictures/Screenshots/`. In a terminal: `screenshot area|screen|window|all|delay N`; add `--copy`
to skip the editor.

`Super+Ctrl+S` (or `screenshot pin`): drag an area and it stays on top of the screen. Drag it to move, scroll to zoom,
middle or double click to close, right click to copy. Up to 12 pins; the menu has "Remove all pinned screenshots".

## Settings

`Super+I` (or from the Control Center). The search field finds a page by its name or by words like "dark",
"border", "update" or "timezone". Every control works by keyboard: Tab moves, Space or Enter presses, arrows
change a choice or a slider.

| Group (sidebar) | Pages |
|---|---|
| **Appearance** | Themes, Theme Builder, Wallpaper, Icons, Cursor |
| **Menu Bar** | Menu Bar |
| **Dock** | Dock |
| **Lock Screen** | Lock Screen |
| **Desktop & Widgets** | Control Center, Notifications, Search & Launcher, Clipboard, Weather, Calendar, Hot Corners |
| **Windows** | Window Behaviour, Window Look, App Rules |
| **Displays** | Screens, Shared Monitor |
| **Input** | Keyboard & Touchpad, Keyboard Shortcuts |
| **Sound** | Sound |
| **Network & Bluetooth** | Wi-Fi & Network, Bluetooth |
| **Power** | Battery & Power, Lock & Sleep, ASUS Hardware (only with `asusctl`) |
| **Apps** | Installed Apps, Default Apps, Startup Apps |
| **About** | About (this computer, Update, Run doctor), Language & Region |

Everything applies right away except language (next login) and lid behaviour (a system file set by the `laptop` module).

## Your files

Everything you change in Settings is saved in **one file on your computer**, never in git:
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
| `~/.config/ghostty/theme.conf`, `~/.config/fuzzel/theme.ini`, `gtk-3.0/` + `gtk-4.0/hyprism.css` | terminal, emoji picker and GTK apps: the theme's colours | Appearance → Themes |
| `~/.config/hypr/settings/wallpaper` (a link), `shared.lua` (while a shared monitor is away) | hyprpaper; monitors.lua | Appearance → Wallpaper; Shared Monitor |

Kept outside `settings.json` on purpose: `~/.config/autostart/*.desktop` (Startup Apps; the standard autostart
folder) and `~/.local/share/icons/` (Icons and Cursor → Add theme). Your own themes: `~/.config/hyprism/themes/`.

A missing file means "use the defaults", so deleting one resets that part (`./install.sh` puts back the ones
Hyprland needs). The defaults are in `config/quickshell/.config/quickshell/ConfigData.qml`,
`config/hypr/.config/hypr/defaults/` and the Hyprland modules. These files are real files in `~/.config`, never
inside the repo folder.

## Screens

- Plug a screen in and it works. Arrange and scale screens in Settings → Displays.
- Each screen's mode, scale and position are remembered by its output name (for example `DP-1`), so a monitor you
  plug in again comes back as you left it.
- Settings → Displays → Advanced: adaptive sync (off, on, fullscreen only), start new screens at their highest
  refresh rate, sharp old X11 apps, automatic HDR colour, and telling the screen what is playing. They sit under
  `_options` in `~/.config/hypr/settings/displays.lua`.
- Old X11 apps look slightly smaller on scaled screens (`xwayland.force_zero_scaling`); that is on purpose.

### A monitor shared with another computer

`monswitch` hands a monitor to another computer over DDC/CI and back (`Super+M`, Control Center), moving your
desktops off it while it is away (it mirrors a screen here so the monitor keeps a signal). Needs the
`ddc-monitor` module. Turn DDC/CI on in the monitor's menu, then **Settings → Displays → Shared Monitor**: pick the
monitor and its two inputs, Save. It follows switches made on the monitor's own buttons too.

## Keyboard and screen readers

- `Super+F6` moves the keyboard to the bar: Left / Right (Up / Down on a side bar) or Tab move along it, Enter or
  Space opens the item, Esc leaves.
- In panels and Settings, Tab moves between controls (a ring shows where you are), Space or Enter presses,
  Left / Right changes a slider or a choice, Up / Down a dropdown.
- Settings → Appearance has the text size and the cursor size.
- The shared controls (switches, choices, buttons, sliders, dropdowns, bar items, notifications) have names for
  screen readers. Quickshell's layer-shell panels are only partly exposed to screen readers, and this has not
  been tested with Orca.

## Your hardware

- The installer looks at your computer and writes what it finds to `~/.config/hyprism/hardware.toml`.
- `./install.sh detect` looks again, rewrites the file and prints it.
- A value is wrong? Add it under `[override]` at the end of the file, for example `display.internal = "eDP-2"`.
  Detection never changes that part.
- `./install.sh modules` lists the modules as on or off, and why. `./install.sh --with NAME` or `--without NAME`
  turns one on or off; your choice is kept under `[override]`; run `./install.sh` to apply it.
- Details: [hardware.md](hardware.md), [modules.md](modules.md).

Hardware features appear on their own (`Machine.qml`):

| Feature | Appears when |
|---|---|
| ASUS Hardware page, charge limit, ROG action | `asusctl` is installed |
| Keyboard light button | a `/sys/class/leds/*kbd_backlight` exists |
| Shared monitor button, `Super+M` | `~/.config/monswitch.conf` exists |

## Recovery

A broken setting or theme never needs a reinstall. More: [troubleshooting.md](troubleshooting.md).

| What | Do |
|---|---|
| The desktop looks wrong or unusable | `desktop-reset` in a terminal (`Super+Return`): your Settings files move to `~/.local/state/hyprism/reset-<time>/` (nothing is deleted), and the shell and Hyprland restart on the defaults. `desktop-reset shell` resets only the bar, dock, theme and panels. Copy a file back to undo. |
| `settings.json` was damaged | The shell keeps it as `settings.json.broken` and starts on the defaults. Repair it and copy it back, or leave it. |
| One part is wrong (keys, displays, input, idle) | Delete that file in `~/.config/hypr/settings/`; Settings writes it again. |
| Hyprland shows a red error bar | `hyprctl configerrors` names the file and line. |
| Bar or dock missing or frozen | `qs kill; qs &`, check `qs log`; still broken: `desktop-reset shell`. |
| Notifications stop showing | Another daemon took over (for example `mako`): `pkill mako`. |
| A shortcut does nothing | Settings → Keyboard Shortcuts shows what it is set to; `hyprctl configerrors`. |
| No working screen at all | `Ctrl+Alt+F3` for a text console, log in, run `desktop-reset`, then `Ctrl+Alt+F1` (or reboot). |
| Is everything in order? | `./install.sh doctor` |
| Remove Hyprism | `./install.sh uninstall` (`./install.sh backups` lists backups; `--backup NAME` picks one). |
