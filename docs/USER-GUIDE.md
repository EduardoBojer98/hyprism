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
- **Right-click empty menu bar space** for quick things (Mission Control, a screenshot, Do Not Disturb, …) and
  its settings. Add your own there: Settings > Actions, place "Menu bar right-click".
- **The dock** shows pinned and open apps, on its own edge or inside the bar. Right-click an app for its windows
  and actions (new window, minimise, pin, quit). Drag an app to move it: pinned apps keep their order; open apps
  start in workspace order and keep yours until you log out.
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
  - **Your actions**: buttons and toggles you make in Settings → Actions (a command, an app, a snippet to paste, a
    folder or link to open, a chain of actions). Show them in Spotlight, on a bar click or a hot corner, or give one
    a key in Keyboard Shortcuts → Your shortcuts. A failing action shows a notification; every run is logged in
    `~/.local/state/hyprism/actions.log`.
- **Control Center** (`Super+C`): Wi-Fi, Bluetooth, Focus, Night Light, Caffeine, sliders, power mode.
  Settings > Control Center starts from a layout (Classic, Essentials, Mixer, Grid, Minimal, or one you kept),
  then lets you drag sections and tiles; `qs ipc call controlcenter layout <name>` switches layout from a key.
- **Notifications** have their own panel from the bell (`Super+N`): Do Not Disturb (`Super+Shift+N`), history by app.
- **On-screen display**: a small pop-up that confirms volume, brightness, microphone, layout and caps lock changes.

Websites as apps are made in a terminal with `webapp add "Name" https://address`; there is no menu entry yet.

## Windows and workspaces

Keys: `Super+Q` close, `Super+F` fullscreen, `Super+T` float or tile, `Super+H` minimise (restore from the dock),
`Super+Arrows` move focus, `Super+Shift+Arrows` move the window, `Super+1` to `0` go to a workspace,
`Super+Shift+1` to `0` send the window there, `Super+W` Mission Control, `Super+drag` and `Super+right-drag` move
and resize. A three-finger swipe sideways switches workspace. The full list: `Super+/`.

`Alt+Tab` shows the open windows, most recently used first: hold Alt and press Tab again (Shift+Tab goes back),
let go of Alt to switch. One Alt+Tab goes back to the window before. Escape or a click outside cancels.

Mission Control (`Super+W`, a three-finger swipe up) lays out this workspace's windows, with every screen's
workspaces along the top, grouped under each screen's name. Click a workspace to go there, or "New workspace" to
start one; drag a window onto either to move it. Settings > Mission Control: which screens, what a click does
("See its windows" first), the New tile, and the picture size.

### Screenshots

`Alt+Shift+S`: the screen freezes (menus and tooltips stay); drag an area or click a window, then annotate (arrow, shapes,
pen, highlighter, text, numbered markers, blur, crop). **Enter** copies and saves, **Ctrl+S** saves, **Esc** cancels.
`Print` opens the capture bar: Area / Window / Screen, a delay, Record (area or screen) and the sound to record
(none, desktop, microphone). After a capture the picture is annotated, copied, or saved and copied, as set in
`capture.after`; folders, delay and sound are `capture.*` in settings.json. Files land in `~/Pictures/Screenshots/`.
In a terminal: `screenshot area|screen|window|all|delay N`; add `--edit`, `--copy` (clipboard only) or `--save`.

`Super+Ctrl+S` (or `screenshot pin`): drag an area and it stays on top of the screen. Drag it to move, scroll to zoom,
middle or double click to close, right click to copy. Up to 12 pins; the menu has "Remove all pinned screenshots".

Settings → Screenshots: what happens after a capture, the folder, the delay, the notification, and the recording's
sound and folder. Screenshots use grim, slurp and Satty. Flameshot is not used: its single overlay window
misbehaves with mixed scaling such as 1.2 next to 1.0 (see `docs/audit/v3/research.md`).

### Panels, menus and flyouts

- Every panel closes on Escape and on a click outside it. It opens on the monitor of the item you clicked.
- A panel taller than the room scrolls inside its frame, with a fade at the cut edge.
- Menus follow Up, Down, Home, End and Enter.
- Volume, network, Bluetooth, brightness, media and battery / power items open a small flyout with just that
  control. The status item opens the flyout of the icon you click. Battery shows charge, draw in watts, time left,
  CPU temperature, fans, the power mode (Silent / Balanced / Performance) and Caffeine.
- `F6` moves the keyboard to the bar, `Shift+F6` to the dock.
- The notification history is kept in `~/.local/state/hyprism/notifications.json` and survives a restart.

### Weather

Settings → Weather: search a place, add it, rename, reorder or remove it. The first place is the default. The panel
shows a chip per place. The last answer is cached, so with no network the panel shows it marked as old. Data comes
from Open-Meteo; no key needed.

### System panel

Click the CPU, memory or GPU item (or open the System panel). It shows real CPU use per core, frequency and load,
memory and swap, the integrated GPU and a separate GPU (shown as "Sleeping" while it is off; it is never woken to
look), storage, disk reads and writes, network and the top processes.

Desktop health shows only when something is wrong: a failed service (yours or the system's) or errors in the
Hyprland config. Details opens a terminal with the failed services, the config errors and the latest crashes.

### Window frame and launcher

Settings → Window Look → Border: Theme's, Accent, Gradient, Neon (the accent with a glow), Mono, Rainbow, Sunset, Ocean or
your own two or three colours, each shown as a small preview. A frame of several colours runs at the angle you set, and
turns only when you switch "Turn the colours" on, with animations on Full, the power mode not Silent, and on AC unless
you allow it on battery. Its width is the theme's (Themes → Adjust → Window frame).
Title bars (on apps that draw no buttons of their own) take the theme's surface, text and type; Window Look sets their
size, which side the buttons sit on and where the title goes. The buttons themselves keep one neutral look in every
theme: the title-bar plugin can't recolour a button until Hyprland next starts, so they are solid discs that read on
any bar. Unfocused windows' buttons turn to the theme's quiet tone. The maximise button (and a double click on a
title bar, and an app's own button) floats a tiled window, centred, and fills the screen with a floating one, which
the next click brings back; Super+T tiles it again. Window Look → Maximise button switches it to always filling the
screen. Drag a floating window to the left or right edge of the screen to fill that half, into a corner for that
quarter, or to the top edge to maximise it, as on Windows or GNOME: an outline shows where it will land before you
let go (Windows → Snap to screen edges). Chrome works the same, dragged by its tab strip or by a tab. A maximised
window keeps the gap at the screen edges. To have every new window open floating instead of tiled, use the Control
Center's Floating tile, add the Floating windows item to the menu bar, or Windows → Open new windows floating.
Spotlight opens at the mouse pointer by default (Settings → Search & Launcher → Open); choose the theme's place to
get strips and edges back. Settings → Default Apps picks the default terminal.

## Settings

`Super+I` (or from the Control Center). The search field finds a page by its name or by words like "dark",
"border", "update" or "timezone". Every control works by keyboard: Tab moves, Space or Enter presses, arrows
change a choice or a slider.

| Group (sidebar) | Pages |
|---|---|
| **Appearance** | Themes, Wallpaper, Icons, Cursor |
| **Menu Bar** | Menu Bar |
| **Dock** | Dock |
| **Lock Screen** | Lock Screen |
| **Desktop & Widgets** | Control Center, Notifications, Search & Launcher, Actions, Clipboard, Weather, Calendar, Screenshots, Hot Corners |
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
| `~/.config/hypr/settings/wallpaper` (a link; for a video, to its still frame in `~/.cache/hyprism/live`), `shared.lua` (while a shared monitor is away) | hyprpaper and hyprlock (a video plays in mpvpaper over it); monitors.lua | Appearance → Wallpaper; Shared Monitor |

Kept outside `settings.json` on purpose: `~/.config/autostart/*.desktop` (Startup Apps; the standard autostart
folder) and `~/.local/share/icons/` (Icons and Cursor → Add theme). Your own themes: `~/.config/hyprism/themes/`.

A missing file means "use the defaults", so deleting one resets that part (`./install.sh` puts back the ones
Hyprland needs). The defaults are in `config/quickshell/.config/quickshell/ConfigData.qml`,
`config/hypr/.config/hypr/defaults/` and the Hyprland modules. These files are real files in `~/.config`, never
inside the repo folder.

## Screens

- Plug a screen in and it works. Arrange and scale screens in Settings → Displays.
- Each screen's mode, scale and position are remembered by the monitor itself (its make, model and serial), so it
  comes back as you left it on any port. Two identical monitors without a serial fall back to the port name.
- Settings → Displays → Presets: save the layout on screen as a preset, apply it later, mark one as the default,
  or let it apply itself when exactly its screens are connected (a notice with Undo shows). Quick layouts
  (Extend, Mirror, Laptop only, External only) are made from what is plugged in. Identify shows a number on each
  screen. A layout that would leave no screen on, or with overlapping screens, is refused.
- Super+P opens the display switcher: Extend, Mirror, Only one screen, or a preset. From a terminal:
  `qs ipc call displays preset <name>`, `displays mode extend|mirror|only:<screen>`, `displays list`,
  `displays identify`, `displays save <name>`.
- Settings → Displays → Advanced: adaptive sync (off, on, fullscreen only), start new screens at their highest
  refresh rate, sharp old X11 apps, automatic HDR colour, and telling the screen what is playing. They sit under
  `_options` in `~/.config/hypr/settings/displays.lua`.
- The Control Center's Screen card shows how the screens are used (Extended, Mirrored, Only one) with more than
  one screen or a saved preset; a click opens the display switcher.
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
| A settings change went wrong | Settings → About → Backups: restore points are made at every start and before a change of displays, shortcuts or actions (the newest 10 are kept). Restore one, or export your settings to a file and import them on another computer. `settings-snapshot list` / `restore ID` from a terminal. |
| `settings.json` was damaged | The shell keeps it as `settings.json.broken` and starts on the defaults. Repair it and copy it back, or leave it. |
| One part is wrong (keys, displays, input, idle) | Delete that file in `~/.config/hypr/settings/`; Settings writes it again. |
| Hyprland shows a red error bar | `hyprctl configerrors` names the file and line. |
| Bar or dock missing or frozen | `qs kill; qs &`, check `qs log`; still broken: `desktop-reset shell`. |
| Notifications stop showing | Another daemon took over (for example `mako`): `pkill mako`. |
| A shortcut does nothing | Settings → Keyboard Shortcuts shows what it is set to; `hyprctl configerrors`. |
| No working screen at all | `Ctrl+Alt+F3` for a text console, log in, run `desktop-reset`, then `Ctrl+Alt+F1` (or reboot). |
| Is everything in order? | `./install.sh doctor` |
| Remove Hyprism | `./install.sh uninstall` (`./install.sh backups` lists backups; `--backup NAME` picks one). |
