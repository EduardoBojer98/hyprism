# Decisions

Why things are the way they are, and what every dependency is for. New packages need an entry here first
(what it does, why existing tools can't, size, maintenance).

## The Settings app stays a Quickshell (QML) window (2026-11-05)

Considered: GTK4 (Python/C), a local web app, Quickshell. Quickshell wins:

- It is already the shell. The app shares the theme tokens (`Theme.qml`) live, with no generator step.
- It opens in the running process, with no second toolkit in RAM.
- Its "server" is Quickshell's local IPC (`qs ipc`, a Unix socket only you can open), with no network port.
- Every action it can run is fixed in code. Settings values are checked by `Config.set()` before they are
  saved. Commands get values as separate arguments, never spliced into a shell string.
- There is no sudo from the UI. Admin rights come only from `pkexec`, which asks in its own window, and the
  Settings row or action that uses it says so (2026-11-17: the charge limit, and your own actions).

A GTK4 rewrite would double the theme work (CSS generated from the same tokens) and gain nothing a user sees.

## No new packages in this round

Everything added (the Reactor theme, GTK accent CSS, `desktop-reset`, the lint and theme tests) uses what is
already installed: Qt 6 `qmlformat` and `luac` come with `qt6-declarative` and `lua`, which Quickshell and
Hyprland's Lua config already pull in, and Python 3 is part of the base system. CI installs them in its container only.

## Qt apps follow the theme: qt6ct (decided 2026-11-12)

Qt apps (Dolphin, pavucontrol-qt) used the KDE platform theme, which only themes them where Plasma's integration
is installed. Elsewhere they fell back to plain Fusion.

- What it does: `qt6ct` is a Qt platform theme that reads a colour scheme file. ThemeSync writes
  `~/.config/qt6ct/colors/hyprism.conf` from the theme, and `qt6ct.conf` only if there is none or Hyprism wrote it.
  `env.lua` picks `qt6ct` when its plugin is installed, else KDE's, else GTK3.
- Why existing tools can't: the KDE and GTK3 platform themes have no file we can generate; Fusion alone has no colours.
- Size: about 1 MB. Maintenance: in Arch extra and Fedora, maintained.
- Cost: one package; in Hyprland a KDE user's Qt look is replaced by the theme. Already-running Qt apps keep
  their old colours until restarted.

## btop follows the theme (decided 2026-11-12)

- What it does: `btop` is the terminal system monitor. ThemeSync writes `~/.config/btop/themes/hyprism.theme`.
  `btop.conf` is never edited; if there is none, a two-line one is written that picks the theme.
- Why existing tools can't: `top` and `htop` are not themed by us, and neither is as complete a monitor.
- Size: about 1.5 MB. Maintenance: in Arch extra and Fedora, maintained.
- Cost: one package; a theme file in `~/.config/btop/themes/`.

## Everyday apps are GTK4/libadwaita, not KDE (decided 2026-11-15)

Dolphin and the other KDE apps outside Plasma load Breeze Light over qt6ct's palette, so they looked broken in
dark themes; a generated KDE colour scheme fixes that (ThemeSync, `Hyprism.colors`), but KDE apps still pull
in KDE Frameworks and look different from the rest of the desktop.

- What it does: the `apps` group installs GNOME's apps: Nautilus, Text Editor, Loupe, Papers, File Roller,
  Celluloid, Amberol, Calculator, Disks, Baobab, Resources. Settings' file pickers use `zenity` instead of `kdialog`.
- Why: ThemeSync already writes `gtk-4.0/hyprism.css`, so libadwaita apps take the theme's surfaces, text and
  exact accent with no extra code. One toolkit, one look.
- Size: about 110 MB with their GNOME libraries. Maintenance: all in Arch extra; Fedora lacks Amberol and
  Resources (Flathub) and ReGreet.
- Cost: no split pane or terminal panel in the file manager (Dolphin's). Anyone who wants KDE apps can install
  them: qt6ct plus the Hyprism KDE scheme keep them themed.
- Login screen: the opt-in `greeter` module (greetd + ReGreet) replaces Plasma Login Manager / SDDM / GDM, with
  the theme's GTK colours and KDE Wallet still unlocked at login.

## Round 3 (decided 2026-11-17)

The audit and its research: `docs/audit/v4/AUDIT.md`.

- One action registry (`Actions.qml`) for Spotlight, bar clicks, hot corners, the Control Center and your own
  shortcuts: `docs/decisions/0002-action-registry.md`.
- Displays are saved by monitor (make, model, serial), not by port: `docs/decisions/0003-monitor-identity.md`.
- Restore points are copies of `settings.json` (it holds every setting), made by `settings-snapshot` before a
  displays, shortcuts or actions change. The write waits for the copy, so it holds the settings from before.
- Surfaces build their lists only while shown where that saves real memory (the launcher, the welcome: about
  60 MB). Measured per surface first; the rest cost under 5 MB each, so they stay as they are.
- Not done: idle-inhibit for any fullscreen window. It would stop auto-lock for a fullscreen editor, and video
  players and browsers already inhibit idle while playing.
- Only one starting Control Center layout (Essentials): the defaults already show every tile, so "Everything"
  would be Reset under another name.
