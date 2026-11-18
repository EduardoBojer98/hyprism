# Changelog

All notable changes to Hyprism. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## Unreleased (2.0.0)

### Added

- Launchpad: apps in pages with dots, turned by a swipe, the scroll wheel or touchpad, the arrows or PageUp/PageDown,
  instead of one long scroll. Hold an icon and drag it to move it; drop it on another app to make a folder (named for
  what they have in common), on a folder to add it. A click opens a folder in place, where its name can be edited
  and an app dragged out. Your order and folders are kept; Settings > Search & Launcher > Adjust resets them. The
  category tabs scroll sideways on a narrow screen, and a short screen gets smaller icons rather than one row.
- Converters in Spotlight, beside the calculator: units ("5 km in mi", "70 f to c", "2 gb in mb"), money ("100 eur to
  ron", rates from the European Central Bank fetched at most once a day and cached; offline it uses the last ones and
  says how old they are), time zones ("time in new york", "3pm tokyo") and dates ("days until 25 dec", "today + 90
  days"). Enter copies the answer. On/off and a rates refresh in Settings > Search & Launcher > Search.
- Quick Look: in Spotlight, move onto a file or folder with the arrows and press Space (or Ctrl+Y) for a large
  preview over the screen: images, the first PDF pages, a video frame, the first lines of text and code, a folder's
  listing. Arrows move to the next file, Enter opens it, Space or Esc closes. A file manager can call it too:
  `qs ipc call quicklook open PATH`. On/off in Settings > Search & Launcher > Search.
- Focus modes: Work, Client call and Sleep, or your own (Settings > Focus). Each sets Do Not Disturb with chosen apps
  let through, and optionally a wallpaper, apps to open, Night Light and Caffeine, put back when it ends. Switch from
  the Focus tile, the launcher, a schedule (days and times) or `qs ipc call focus set <name>|off|toggle`; the bell
  shows the mode on.
- Phone: link your phone through KDE Connect (Settings > Network & Bluetooth > Phone, a Control Center tile). Battery
  in the tile, ring the phone, send files (also as launcher actions), its notifications through the shell's own,
  clipboard sync and remote control switches, pairing and clear empty states with a one-click Install or Start.
  `kdeconnect` joins the apps package group; `qs ipc call phone ...`.
- Search & Launcher: the five styles now work differently, not just sit elsewhere: Spotlight is the macOS bar alone
  until you type, Launchpad lays every app on the dimmed screen with no sheet (dark themes), Drawer opens on today at a
  glance with big card rows, Sidebar is a dense one-line list, Terminal has plain text rows with a kind column and no
  icons. The style gallery draws each one that way. New Adjust settings: size (80-130 %), rows (standard, compact,
  cards, text), the screen behind it, corners, second lines, key hints and results at most; Suggestions chooses
  glance, frequent apps, recent and quick actions. "Before you type" now follows the style by default.
- Search & Launcher, round two: Launchpad redone as a full-screen grid on a dark scrim in every theme (light ones too),
  a small search field, text category tabs, large icons that lift and glow instead of a filled box, a quick wave as
  it opens and whole rows only; typing filters the apps. Spotlight follows macOS closer: "Spotlight Search", light
  query text, one-line rows with a larger Top Hit, solid selection, no key hints. Every style shows app icons by
  default (Terminal included; Rows → Text keeps plain text). Pick your quick actions in Suggestions
  (`launcher.quickActions`); Recent leaves them out.
- Motion: popups opened from a shortcut (launcher, Control Center, calendar and the rest) now fade and grow in
  quickly instead of snapping; the launcher's views and right-click menu fade in, its selection eases, and Settings
  pages fade up when you switch. "Motion: off" still turns all of it off.
- Control Center: a gallery of layouts in Settings > Control Center (Classic, Essentials, Mixer, Grid, Minimal),
  each drawn from its own sections, tiles and style; pick one, then edit it below. Keep an arrangement under a
  name (`controlCenter.layouts`); switching away from one you never kept saves it as "Previous" first. The panel
  styles are picture cards too, and `qs ipc call controlcenter layout <name>` switches layout.
- Windows: the maximise button (title bar, a double click on it, or an app's own button) floats a tiled window,
  centred, and fills the screen with a floating one, back on the next click; Window Look → Maximise button can make
  it always fill the screen. Drag a floating window to the left or right screen edge to fill that half, into a
  corner for that quarter, or to the top edge to maximise it, with an outline of where it will land
  (Windows → Snap to screen edges). Chrome's own maximise button works on a floating window, and a Chrome window
  dragged by its tab snaps too. A maximised floating window keeps the screen-edge gap, like a tiled one.
- Windows: new windows can open floating instead of tiled: the Control Center's Floating tile, a Floating
  windows menu bar item, or Windows → Open new windows floating.
- Menu bar: right-click empty space for a menu: Mission Control, a screenshot, the shortcut list, Do Not
  Disturb, Caffeine, your own actions (Settings > Actions, place "Menu bar right-click"), Show seconds, dock
  auto-hide, and the menu bar, dock and style settings.
- Displays: layouts are saved by monitor (make, model, serial) instead of port name, so they follow a monitor to
  any port (settings format 7 renames the old keys). Presets: save, apply, rename, delete, default, and an opt-in
  auto-switch when exactly a preset's screens are connected (with Undo). Identify, a Super+P display switcher, the
  `displays` IPC target, and the page updates when a screen is plugged or unplugged. Apply refuses overlapping
  screens or none left on. See `docs/decisions/0003-monitor-identity.md`.
- Actions: one list of every action the desktop offers, used by Spotlight, bar clicks, hot corners and the Control
  Center. Settings → Actions makes your own buttons and toggles (a command, app, snippet, link or a chain), tests
  them and shows which ask for an admin password; toggles show their real state. A failing action shows a
  notification and every run is logged in `~/.local/state/hyprism/actions.log`. Your launcher actions move there by
  themselves. Keyboard Shortcuts → Your shortcuts gives any action a key, with a clash check and Reassign.
  `qs ipc call actions run|toggle|list`.
- Control Center: your own actions as small tiles (Settings → Actions → Control Center), a Displays row in the
  Screen card that opens the display switcher, and an Essentials starting layout in Settings → Control Center.
  An action can show only while a display preset can be applied (`when: { preset: "<id>" }`), and a preset
  action runs it with the keep-or-revert countdown.
- Alt+Tab window switcher: the open windows, most recently used first; let go of Alt to switch.
- Restore points (Settings → About → Backups, `settings-snapshot`): a copy of `settings.json` at every start and
  before a display, shortcut or action change, the newest 10 kept; restore, export and import.
- System panel → Desktop health, shown only when a service failed or the Hyprland config has errors.
- Video wallpapers: .mp4, .webm, .mkv and .mov files in the wallpaper folders play with `mpvpaper` (new package,
  with `ffmpeg`) over a still frame that the lock screen, colours from the wallpaper and Settings use. Hardware
  decoding on the iGPU without waking a hybrid laptop's NVIDIA card. A playing video about doubles idle power even
  behind windows, so it pauses behind fullscreen windows (or any window) and on battery; Settings → Wallpaper →
  Video wallpapers. Measurements: `docs/research/live-wallpapers.md`.
- Settings → Wallpaper, redesigned: the wallpaper shown now on top (Next, Pause/Play for a video, Show in Files, why a
  video is paused); the library filters by All, Pictures, Videos or Themes and by name, tiles fill the row, hover a
  tile to use it on the lock screen or show it in Files; it rescans whenever the page opens (or Rescan) and names
  files in the folders it can't use. Folders show what they hold and open in Files. `qs ipc call wallpaper playPause`.
- File pickers (zenity and the GTK portal's Open/Save) float centred, so Browse… opens over Settings, not behind it.
- Menu bar item "Updates" (on by default, beside the tray): how many system packages, AUR and Flatpak updates
  and Hyprism changes are waiting, hidden when none are. Click runs the whole update in a terminal; right-click
  looks again. Checks hourly with `checkupdates` (Arch, new package `pacman-contrib`) or `dnf check-update`.
  `./install.sh update` now updates Flatpak apps too.
- Update channels: stable (branch `main`) and dev (branch `develop`, newest work first). `./install.sh channel dev`
  or Settings → About → Channel switches and updates. Settings → About says when Hyprism has new changes, lists them,
  and puts a dot on About in the sidebar.
- Window Look: border styles Neon (accent with a glow), Mono, Sunset, Ocean and your own two or three colours, each with a
  live preview; an angle for frames of several colours and an explicit "Turn the colours" switch (a saved turning
  rainbow keeps turning). Title bars follow the theme (surface, text, type, height from its density, dimmer titles and
  buttons on unfocused windows), with a size, button side and title alignment of your own.
- Control Center, rearranged: large tiles (Wi-Fi, Bluetooth), a Screen card (brightness and DDC monitors, hidden when
  nothing can be dimmed) and a Sound card (output and microphone) with thick sliders, a grid of same-size small
  buttons (Focus, Night Light, Caffeine, Record, Screenshot ...), media, power mode, and a footer with the battery,
  Arrange, Settings, Lock and Power. Any tile can be large or small: Settings → Control Center drags it between the
  two, reorders and hides sections (Screen and Sound separately), tiles and sliders, beside a live preview of the panel. `controlCenter.sliders`
  (the Sound card's rows) is new; `controlCenter.shortcuts` is gone (its buttons are small tiles now).
- Notifications: six popup styles (card, bubble, line, block, tag, compact) and six places, each picked from a
  drawing in Settings; a test notification (Settings, or `qs ipc call notifications test` / `testAs low|critical`)
  sent through the shell's own server; time on screen and sound per urgency; popups on screen at once; group by app
  (popups and history); app icons on or off; Do Not Disturb on a daily schedule (Focus ends it early).

- Desktop v3: three themes, one bar layout, one popup framework.
  - Themes: Pebble (calm, the default for new installs), Poster (loud) and Monolith (terminal). Theme token
    `shape.density` (`compact`, `regular`, `roomy`) scales spacing; `hypr.frame` (`accent`, `gradient`, `rainbow`) names the window frame.
  - Bar: one layout for every theme (`bar.layout`, empty = the theme's own); presets are "Start from" buttons;
    per-screen items in `bar.monitors`. New readings: per-core CPU, frequency, load, swap, disk I/O, shared GPU
    memory, dGPU state (a sleeping card is never woken), battery watts.
  - Popups: `Shift+F6` moves the keyboard to the dock. Panels open on the monitor of the item you clicked.
  - Weather: several saved places (Settings → Weather: search, add, rename, reorder, remove; the first is the
    default), a chip per place in the panel, a cache, an offline and stale state. Open-Meteo, no key.
  - System panel: real CPU, memory, GPU (iGPU and dGPU), storage, network and processes.
  - Screenshots: `Print` opens a capture bar (area, window, screen, delay, record with sound); new Settings →
    Screenshots page (after-capture action, folder, delay, notification, recording sound and folder). grim, slurp and
    Satty stay; Flameshot is not used because its single overlay window misbehaves with mixed scaling such as 1.2 + 1.0.
  - Window border colour (Settings → Window Look): Theme's, Accent, Gradient or Rainbow. Rainbow turns only with
    animations Full, power mode not Silent and on AC unless allowed on battery.
  - The launcher opens at the mouse pointer by default (Settings → Search & Launcher → Open). Default terminal in
    Settings → Default Apps.

- Bar item flyouts: volume, network, Bluetooth, brightness and media open a small panel with that one Control
  Center section; battery and power profile open a battery flyout (charge, draw, time left on battery, CPU
  temperature, fans, Silent / Balanced / Performance, Caffeine). The `status` item opens the flyout of the icon
  clicked. `panel:volume` (and network, bluetooth, brightness, media, battery) is a new click action;
  `qs ipc call flyout toggle <name>`.
- Keyboard everywhere in the panels: Escape closes every panel, menus (utility, tray, keyboard layout, dropdown
  lists) follow Up / Down / Home / End / Enter, notification cards take focus (Enter opens, Delete dismisses).
- Panels taller than the screen scroll inside their frame with a scroll bar and a fade at the cut edge
  (Calendar's "Coming up" no longer runs under the dock). Mission Control closes on a click on empty space.
- The notification history is kept in `~/.local/state/hyprism/notifications.json` and survives a shell restart.

- Full or base setup: the first install asks; `--profile full|base` changes it. Full adds the themed apps and
  login screen; base sets up only the desktop and keeps your own apps and login screen.
- Everyday apps that follow the theme (GTK4/libadwaita): Nautilus replaces Dolphin, plus Text Editor, Loupe,
  Papers, File Roller, Celluloid, Amberol, Calculator, Disks, Baobab and Resources. Settings' file pickers use zenity.
- Module `greeter` (opt-in): greetd + ReGreet login screen in the theme's colours, KDE Wallet unlocked at login.
- KDE apps follow the theme too: ThemeSync writes a Hyprism KDE colour scheme, picked in Hyprland only.

- `./install.sh update` restarts the shell after a pull, so new QML and moved fonts load at once (a running
  shell kept the old font files open and drew garbled text).
- `screenshot pin` (`Super+Ctrl+S`, and the menu): keep a picked area floating on top of the screen; drag, zoom, copy, close. `Pins.qml` shows them.
- `monswitch inputs` and `monswitch setup`: find a monitor's inputs over DDC instead of typing codes; Settings → Shared Monitor uses the same list.
- Sleep times that fit the computer: `idle.sleepOnPowerMin` (sleep when plugged in, default never) next to `idle.sleepMin` (on battery); the new `idle-sleep` script decides at the moment the listener fires. A desktop no longer sleeps by itself.
- Laptop module step `20-charge-limit.sh`: stop charging at 80% where the kernel allows it; the doctor shows the current limit.
- `./install.sh` sets default apps (folders, links, text, images, PDF) only where none is set (`--only defaults`).
- `tests/performance.sh`: a CPU, memory and helper-process budget for an idle shell; `tests/update-test.sh` now tests rollback.
- Documentation for newcomers: `docs/install.md`, `docs/how-to.md`, `docs/troubleshooting.md`, `docs/modules.md`, a docs index, and `tests/docs.sh`, which fails on a broken link, path or `./install.sh` command in the docs.
- Keys only for hardware that exists (brightness, keyboard backlight, power mode, shared monitor); `tests/keybinds.sh`
  fails on a key bound twice. The terminal key follows `apps.terminal` in settings.json.
- Settings → Displays → Advanced (adaptive sync, highest refresh rate, X11 sharpness, auto HDR, content type) and
  touchpad options in Settings → Keyboard & Touchpad (pause while typing, click method, scroll speed, middle click, drag lock).
- Full audit, roadmap and feature matrix (`docs/audit/`, `docs/research/`)
- Conventions (`docs/CONVENTIONS.md`)
- `LICENSE` (MIT), `CONTRIBUTING.md`, `VERSION`, this changelog

- The launcher's Actions mode is now the menu: grouped headings (Appearance, Screens & capture, Network & sound,
  System, Power) when nothing is typed. New actions: a theme per theme folder, light/dark, bar layouts,
  screen recording, Wi-Fi, Bluetooth and sound, Displays, Night Light, Do Not Disturb, keyboard shortcuts,
  Update, doctor, power menu, Welcome.
- First-run Welcome panel (`Welcome.qml`, `qs ipc call welcome open`) replaces the one-time notification.

- Hardware detection: `./install.sh detect` writes `~/.config/hyprism/hardware.toml` (form factor, graphics
  cards, screens, battery, touch, radios, known devices). Correct a wrong guess under `[override]`.
- Modules (`modules/<name>/`): `laptop`, `nvidia`, `nvidia-hybrid`, `asus`, `tablet`, `ddc-monitor`, `logitech`,
  `hibernate` (opt-in) and `quirk-flow-x13`. Each switches on when its hardware is found;
  `./install.sh modules` lists them, `--with` / `--without` override.
- Migrations (`migrations/`), `./install.sh rollback`, `./install.sh backups`, and a log of every run in
  `~/.local/state/hyprism/logs/`.
- `./install.sh uninstall` also undoes the system files and services it changed (kept in a manifest), and moves
  your generated settings aside instead of leaving them.
- `tests/nested.sh`: a test desktop in a window, from this checkout, kept apart from your real session.
- `tests/detect.sh` (seven made-up computers), `tests/format.sh` (shfmt + shellcheck for every shell file).
- A firewall step (`./install.sh --only firewall`): when none is active it asks, then turns on ufw (Arch) or
  firewalld (Fedora), blocking incoming connections. The doctor notes when there is none.
- `tests/update-test.sh` and a CI job `update`: install release 1.1.0, then update to this code, and check the
  migrations ran once, no link is dead and the doctor is clean.

- Optional modules, each on only when you ask (`./install.sh --with NAME`): `dev` (mise for Node / PHP / Python
  versions, Docker), `gaming` (Steam, GameMode, MangoHud) and `ai` (Ollama, with the CUDA build and the NVIDIA
  container toolkit where there is an NVIDIA card). Each module's README is its guide.

- The theme reaches Qt apps (`qt6ct`), btop (`btop` theme "hyprism") and the starship prompt
  (`~/.config/hyprism/starship.toml`, a copy of the repo file with the theme's palette).
- Accessibility: the shared controls (toggle, choice, chip, buttons, slider, dropdown, text field, bar
  items, notification card) carry screen-reader roles and names. `Super+F6` moves the keyboard to the bar
  (arrows or Tab, Enter or Space to open, Esc to leave); `tests/accessibility.sh` guards it.

- The doctor also checks the hardware file (and notices when the hardware changed), sound, network, the desktop
  portal, the keyring, the password-prompt helper and the shell, each with the command that fixes it. The
  container test breaks six things on purpose and checks each is reported with a fix.
- Optional "Colours from the wallpaper" (Settings → Wallpaper, off by default): the accents follow your own
  picture at 3:1 contrast, and the theme's own come back when it is off (`wallpaper-colours`, `docs/THEMES.md`).
- `docs/settings-reference.md`: every setting, its type, default and meaning, generated by
  `tests/settings-reference.py`; CI fails when it is out of date.

### Changed

- Dock (floating and in the menu bar): open apps and windows are ordered by workspace, then as they opened, and
  can be dragged into an order of your own (kept for the session, shared by both docks). The dock in the menu bar
  gets the right-click menu the floating one has: its windows, New window, Minimise / Restore, Pin, Quit.
- Mission Control: workspaces (named so, not "desktops") along the top, grouped by screen under each screen's
  name, each at its screen's shape, free of the glass bar, ending in a "New workspace" tile. A Settings page
  (Mission Control): every screen or just this one, click to go or to see the windows first, the New tile on or
  off, picture size.
- The shell uses about 60 MB less memory at idle: the launcher and the welcome build their lists only while
  shown.
- Caps Lock's notice comes from a key bind instead of a check every half second.
- Clipboard history is capped at 256 MB in all (oldest go first) and skips single items over 20 MB.
- The charge limit on laptops other than ASUS asks for the admin password (pkexec) once and keeps the limit
  after a reboot; a refusal shows why.
- `./install.sh update`: an untracked file in the repo no longer stops the pull, and a copy with commits the channel
  doesn't have is reported at the end instead of stopping the update.
- Power modes are named Silent, Balanced and Performance everywhere in Settings.
- The power-profile item opens the battery flyout instead of cycling blind; the power modes read Silent, Balanced,
  Performance (the asusctl id stays `quiet`). The battery item opens its flyout instead of Settings → Power; the
  media item's click opens the player (middle-click pauses or plays).
- One shared piece each for the popup frame and depth (`CursorPopup`, `PopupDepth`, now also on tray menus and
  dropdowns), menus (`MenuList`, `MenuRow`) and full-screen sheets (`Overlay`: power menu, cheat sheet, welcome).

- On Arch, packages the setup needs are marked as explicitly installed, so removing another desktop (KDE) can't
  take them along as its dependencies (ddcutil, iio-sensor-proxy, libqalculate did).
- `tests/hypr-config.sh` says "skipped" when Hyprland 0.57's `--verify-config` crashes, and checks the running
  session's config with `hyprctl configerrors` instead of failing every profile.
- The launcher is split into `Launcher*.qml` parts, and nearly every click target in the shell now has an accessible name and role; `tests/accessibility.sh` lists the rest.

- One name: the GTK colours file is `hyprism.css` (was `linux-setup.css`) and the bundled fonts folder is
  `fonts/hyprism/`; migration 0003 removes the old files, and 0005 the old import that shared a line in `gtk.css`
  (GTK apps warned about the missing file).
- Settings → App Rules: the button for the built-in rules says it opens a read-only file.

- Layouts switch with `Super+Ctrl+Space` only by default (no more Alt+Shift, which started the screenshot key);
  `Super+Shift+S` no longer takes a screenshot (`Alt+Shift+S` and `Print` do).

- Every script is formatted with `shfmt -i 4 -ci`
- Finished process notes moved to `docs/history/`

- `install.sh` is a short entry point over `lib/*.sh`. A run that hits a problem ends non-zero with a summary;
  a dry run lists the questions it would ask.
- Themes are folders (`themes/<id>/theme.json` + wallpaper). Copy `_template`, edit one file, `theme <id>`: no
  code changes. Yours go in `~/.config/hyprism/themes/`. Terminal colours come from the theme file. The contrast
  test also covers accents, status colours, bar text and the terminal palette. See `docs/THEMES.md`.
- A system-info bar item (`sysinfo`): pick any of 25 readings, their order, compact or detailed, levels per
  reading, "only above", and a trend in the tooltip. One `metrics` program feeds it, found by kind of device.
- Bar items can live in their own folder (`bar/items/<id>/`) and every item has its own settings in
  `settings.json` (`bar.items.<id>`): enabled, icon, format, click, right-click, scroll, tooltip, warn, critical.
  See `docs/bar.md`.
- Reactor (acid yellow and orange) is the default theme. Your own choice is kept.
- Hyprland reads the detected hardware (`modules/hardware.lua`): the laptop panel, touch mapping and
  workspace-per-screen rules no longer name `eDP-1` or `HDMI-A-1`.
- Module steps run inside the installer, so `--dry-run` shows each command they would run.
- The lid rule is `/etc/systemd/logind.conf.d/50-hyprism-lid.conf` and only laptops get it.
- Bluetooth is enabled only where there is an adapter.
- AUR packages, COPR repos and RPM Fusion are named and asked about before they are trusted (answered yes
  under `--yes`).
- The extra Hyprland plugins (title-bar buttons) are no longer downloaded and built at login. Login only loads
  what is built; `./install.sh update` runs `hypr-plugins build`, which builds the newest hyprland-plugins release
  for the running Hyprland (the same 0.X series when the patch release has no tag yet). No version is hard-coded.
- Autostart finds the polkit agent on Arch and Fedora, and unlocks KWallet or starts GNOME Keyring, whichever
  is installed.
- State moved from `~/.local/state/linux-setup` to `~/.local/state/hyprism` (migration 0001).
- README pictures retaken from the current code (`tests/screenshots.sh`): all seven themes in dark and light, plus the welcome panel, menu, system panel, bar system-info item and notification centre.

### Fixed

- Mission Control: "New workspace" now goes there. Closing the overview refocused the last window, which pulled
  Hyprland back to that window's desktop.
- The CI config check now verifies every machine profile: `hl.timer` crashed `--verify-config`, so each profile
  was skipped as "Hyprland's own crash".

### Removed

- Themes Atlas, Console, Glass and Reactor, the Theme Builder and "Save as a theme". Old ids map on their own
  (glass to Pebble, atlas to Poster, console and reactor to Monolith; `Config.qml` `renamedThemes`); migration 0006
  removes their links. Per-theme Adjust and a theme folder of your own still work.
- `StatusGlyph.qml` (unused); the private menu rows of UtilityMenu, TrayMenu, Keyboard and WindowMenu (replaced by
  `MenuRow` / `PillButton`).

- The emoji picker's use of KDE Plasma's emoji file. It reads Unicode's own list (package `unicode-emoji`).

- `hosts/` (computers picked by hostname). Replaced by detected modules; migration 0002 carries an existing
  install over.
- `--host` and `steps-done`. Not needed: nothing depends on the hostname any more.
- KDE Plasma guard and the login-screen preselect. Hyprism no longer keeps a KDE fallback.
- JuhRadial MX step for Logitech mice. Replaced by the `logitech` module (Solaar, in both distros' repos).
  An existing JuhRadial install keeps working until you remove it.
- The step that made the LTS kernel the boot default on one laptop (a workaround for a kernel bug). Nothing is
  undone on a computer where it already ran.
- Upgrading straight from before 1.1 (old whole-folder links). Update to 1.1 first.

## 1.1.0 (2026-11-06)

Seven themes with light and dark halves, modular bar and dock, Settings app with one settings file, installer with update, doctor and undo. See `docs/history/` for how it got here.

## 1.0 (2026-10-30)

First release: Quickshell glass shell, Control Center, launcher, tablet mode, installer.
