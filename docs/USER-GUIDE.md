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
    `~/.local/state/hyprism/actions.log`. While you type a command, a program that isn't installed (or a typo,
    with the closest name) shows under the field; Save then asks once more ("Save anyway").
- **Shortcuts from apps**: apps that ask for global shortcuts through the desktop portal (OBS, Discord, …) show
  in Settings → Keyboard Shortcuts → From apps once they have run. Give one keys there and it works while the app
  is in the background; a saved one stays listed ("not running now") when the app is closed.
- **Control Center** (`Super+C`): Wi-Fi, Bluetooth, Focus, Night Light, Caffeine, sliders, power mode.
  Settings > Control Center starts from a layout (Classic, Essentials, Mixer, Grid, Minimal, or one you kept),
  then lets you drag sections and tiles; `qs ipc call controlcenter layout <name>` switches layout from a key.
- **Notifications** have their own panel from the bell (`Super+N`): Do Not Disturb (`Super+Shift+N`), history by app.
  Click one to open the app that sent it; its own buttons (and a reply field, for chat apps that offer one) are on
  the card. Settings → Notifications → Size makes popups and the panel bigger or smaller.
- **Focus modes** (Settings > Focus, the Control Center's Focus tile, launcher actions such as *Focus: Work*):
  Work, Client call and Sleep to start, and any you add. Each can turn on Do Not Disturb while letting chosen apps
  through, set a wallpaper, open apps, and turn on Night Light or Caffeine; turning it off puts those back. A mode can
  run on a schedule (days and times, past midnight too); turned off by hand, it stays off until its next window. The
  bell shows the mode's icon and name. From a key: `qs ipc call focus set <name>`, `off`, `toggle`, `status`, `list`.
- **On-screen display**: a small pop-up that confirms volume, brightness, microphone, layout and caps lock changes.

Websites as apps are made in a terminal with `webapp add "Name" https://address`; there is no menu entry yet.

## Windows and workspaces

Keys: `Super+Q` close, `Super+F` fullscreen, `Super+T` float or tile (floated again, a window comes back where it was), `Super+H` minimise (restore from the dock),
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
misbehaves with mixed scaling such as 1.2 next to 1.0 (see `docs/history/audit/v3/research.md`).

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
Spotlight opens in each style's own place (Settings → Search & Launcher → Adjust → Open: or the middle, or at the
pointer), the same from the dock, the bar and the shortcuts; "Beside the button you click" opens it next to a bar or dock
button instead, and Settings → Dock → Launcher button hides the dock's. Picking a style starts it as designed; Adjust changes it and its Reset puts it back. Its styles each work differently: Spotlight (the macOS bar, one-line results once you type),
Launchpad (the whole screen darkened, every app as a big icon, category tabs; typing filters the apps), Drawer (today
at a glance, big rows), Sidebar (a dense one-line list), Terminal (a prompt and mono one-line rows). Every style shows
app icons; Adjust → Rows → Text gives plain text rows. Adjust also sets size, corners, the dim behind it, key hints and
how many results; Suggestions picks what shows before you type and which quick actions, in your order (Recent leaves
them out). Settings → Default Apps picks the default terminal.

**Quick Look.** In Spotlight's results, move onto a file or folder with ↑↓ and press Space (Ctrl+Y works any time):
a large preview opens (images, the first three PDF pages, a frame of a video, the first lines of text or code, a
folder's listing). ↑↓ go on to the next result, Enter opens the file, Space or Esc closes. Space only previews after
you have moved with the arrows, so it still types a space while you search. From a file manager, add a custom action
that runs `qs ipc call quicklook open %f` (Thunar: Edit → Configure custom actions; Nautilus: a script in
`~/.local/share/nautilus/scripts`). Turn it off in Search & Launcher → Search.

**Launchpad.** The Launchpad style shows your apps in pages; the dots under them say where you are. Turn pages with
a swipe, the scroll wheel or touchpad, ←→ past a page's edge, PageUp/PageDown, or a click on a dot. On All, with
nothing typed, the order is yours: hold an icon, then drag it where it should go (towards the screen's left or right
edge to reach another page). Drop it on another app to make a folder, or on a folder to add it. Click a folder to
open it, click its name to rename it, drag an app out of it to take it out; Esc closes it. Search & Launcher → Apps and results →
Launchpad arrangement → Reset goes back to A to Z.

**Converters.** Type a conversion and the answer is the top hit; Enter copies it. Units: `5 km in mi`, `70 f to c`,
`2 gb in mb`, `100 km/h in mph` (length, weight, volume, data, speed, time, area, energy, temperature). Money:
`100 eur to ron`, `$20 to eur`, with the European Central Bank's daily rates (fetched at most once a day, kept in
`~/.cache/hyprism/ecb-rates.xml`; offline the last ones are used and the result says how old they are). Time zones:
`time in new york`, `tokyo time`, `3pm tokyo`, `10:30 est`. Dates: `days until 25 dec`, `days since 1 jan 2020`,
`today + 90 days`, `in 3 months`. Search & Launcher → Search turns them off and refreshes the rates.

## Settings

`Super+I` (or from the Control Center). The search field finds a page by its name or by words like "dark",
"border", "update" or "timezone". Every control works by keyboard: Tab moves, Space or Enter presses, arrows
change a choice or a slider, Page Up and Page Down scroll the page.

| Group (sidebar) | Pages |
|---|---|
| **Appearance** | Themes, Wallpaper, Icons, Cursor |
| **Menu Bar & Dock** | Menu Bar, Dock, Control Center, Weather, Calendar |
| **Notifications** | Notifications, Focus |
| **Windows & Workspaces** | Window Behaviour, Window Look, Workspaces, Mission Control, Hot Corners, App Rules |
| **Displays** | Displays, Shared Monitor |
| **Keyboard & Mouse** | Keyboard, Mouse & Touchpad, Touch & Tablet (with a touchscreen or the on-screen keyboard), Keyboard Shortcuts |
| **Sound** | Sound |
| **Network & Bluetooth** | Wi-Fi & Network, Bluetooth, Phone |
| **Power** | Battery & Power, ASUS Hardware (only with `asusctl`) |
| **Lock Screen** | Lock Screen, Lock & Sleep |
| **Search & Tools** | Search & Launcher, Actions, Clipboard, Screenshots |
| **Apps** | Installed Apps, Default Apps, Startup Apps, Terminal |
| **System** | About (this computer, Update, Run doctor), Language & Region |

Everything applies right away except language (next login) and lid behaviour (a system file set by the `laptop` module).

## Your files

Everything you change in Settings is saved in **one file on your computer**, never in git:
`~/.config/quickshell/settings.json`. The shell writes the files other programs read from it (and applies them
live), so those are outputs: edit Settings or `settings.json`, not them.

| File written from `settings.json` | For | Settings page |
|---|---|---|
| `~/.config/hypr/settings/hypridle.conf` | hypridle: dim, lock, screens off, sleep | Power → Lock & Sleep |
| `~/.config/hypr/settings/input.lua` | Hyprland: keyboard layouts, repeat, touchpad, pointer | Keyboard & Mouse |
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
  screen. A layout that would leave no screen on, or with overlapping screens, is refused. Screens that don't
  touch get a warning under the drawing (the pointer can't cross a gap) and a Snap together button.
- Settings → Displays → Main screen: notifications, volume and brightness messages show there, and workspace 1
  and the pointer start there at login; "Where I'm working" (the default) follows the focused screen. "Menu bar
  only on the main screen" gives the others the whole height.
- Super+P opens the display switcher: Extend, Mirror, Only one screen, or a preset. From a terminal:
  `qs ipc call displays preset <name>`, `displays mode extend|mirror|only:<screen>`, `displays list`,
  `displays identify`, `displays save <name>`, `displays snap`.
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
monitor and its two inputs, Save. It follows switches made on the monitor's own buttons too. Several monitors going to
the same other computer: **Also switch** adds up to three more; they hand over and come back with the first one, whose
input decides which side is showing (its own buttons are the ones followed).

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

### Your phone

Settings > Network & Bluetooth > **Phone** links an Android phone (or an iPhone) through KDE Connect. Install the
KDE Connect app on the phone; on this computer `kdeconnect` comes with the full setup, or click **Install** on the
Phone page or tile. Open the app on the phone on the same Wi-Fi, then **Pair** on either side and accept on the other.

- The Control Center's **Phone** tile shows the phone's battery; its list rings the phone, sends files and has the
  switches below. The launcher has *Ring my phone* and *Send files to my phone*.
- **Notifications**: the phone's appear as normal notifications here, so Do Not Disturb and Focus apply to them.
- **Clipboard**: copy on one, paste on the other. **Remote**: the phone's KDE Connect app plays, pauses and skips
  this computer's music and video. The phone's own player shows in the Control Center's media card.
- `qs ipc call phone status | ring | pick | send <file> | refresh`.
- Phone not found with a firewall on? KDE Connect uses ports **1714-1764, TCP and UDP**. Hyprism doesn't change
  firewall rules; allow them yourself, e.g. `sudo ufw allow 1714:1764/udp && sudo ufw allow 1714:1764/tcp`, or
  `sudo firewall-cmd --permanent --add-service=kdeconnect && sudo firewall-cmd --reload`.

## Your own config

The files Hyprism links into `~/.config` are the repo's own: editing one changes the repo, and `hyprism update` then
won't pull until you commit or undo it. Put your own changes in these files instead. They are yours, not links, so
updates and `./install.sh uninstall` leave them alone, and they load last, so they win:

| For | Your file | What goes in it |
|---|---|---|
| Hyprland | `~/.config/hypr/user.lua` | Lua, like the files in `~/.config/hypr/modules/`: binds, rules, settings. A mistake shows in `hyprctl configerrors`. |
| Ghostty | `~/.config/ghostty/user.conf` | Ghostty settings, e.g. `font-size = 13`. |
| Fish | any new file in `~/.config/fish/conf.d/` | aliases, functions, variables; `~/.config/fish/config.fish` is yours too. |
| Starship | a copy of `~/.config/starship.toml` under another name | point fish at it: `set -gx STARSHIP_CONFIG ~/.config/my-starship.toml` in a `conf.d` file. |

Most things have a place in Settings, which keeps them in `~/.config/quickshell/settings.json` (yours as well).
`./install.sh doctor` lists any other file you added to a folder Hyprism manages.

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
