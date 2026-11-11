# Council scoreboard

Seven independent reviewers score each part from their own angle, with evidence (file:line, screenshots,
command output). A part passes at **9.5 from every member that judges it**. The chair (the lead agent) fixes,
re-captures and re-convenes until each part passes or hits a logged hard limit. Raw reports and the reason for
every rejected finding: `.council/feedback.md` (local working notes, not in git). Brief each member gets:
`.council/brief.md`.

Members: **D** design lead · **U** UX / newcomer · **S** systems engineer · **P** performance & stability ·
**C** code quality · **A** accessibility & input · **X** security. "—" = not that member's part.

## Round 1: baseline (2026-11-05)

| # | Part | D | U | S | P | C | A | X |
|---|---|---|---|---|---|---|---|---|
| 1 | Settings app | 8.5 | 7.5 | 7.0 | 8.0 | 8.5 | 6.5 | 8.0 |
| 2 | Theme system | 8.5 | 8.0 | 7.5 | 8.5 | 8.5 | — | — |
| 3 | Layout system | 8.5 | 8.0 | 8.5 | — | 8.5 | 8.5 | — |
| 4 | Hyprland core | — | — | 8.0 | — | 8.5 | 8.0 | — |
| 5 | Bar + Control Center | 8.5 | — | — | 8.0 | 8.0 | 7.0 | — |
| 6 | Launcher, power menu, cheat sheet | 8.5 | 8.5 | — | — | 8.5 | 8.0 | — |
| 7 | Notifications + OSD | 8.0 | — | — | 8.5 | — | 8.5 | — |
| 8 | Lock, idle, dim, suspend | 8.5 | 8.0 | — | 8.5 | — | 9.0 | 8.5 |
| 9 | Multi-monitor + input switching | — | 7.5 | 6.5 | — | — | — | 8.5 |
| 10 | Screenshot + annotation | — | 8.5 | — | — | 9.0 | — | 8.5 |
| 11 | Input devices | — | 8.0 | — | — | — | 8.0 | — |
| 12 | Power, thermals, GPU | — | — | 5.5 | 8.0 | — | — | 9.0 |
| 13 | App theming | 7.5 | — | 6.0 | — | — | — | — |
| 14 | Installer, doctor, hosts, first run | — | 7.5 | 7.5 | 8.5 | 8.5 | — | 8.5 |
| 15 | Documentation | — | 7.0 | — | — | — | — | — |
| 16 | Code quality + CI | — | — | 6.5 | — | 7.5 | — | 7.5 |

Lowest: power/GPU on non-X13 machines (5.5), app theming (6.0), monitor switching (6.5), CI (6.5), Settings by
keyboard and touch (6.5), docs (7.0).

### Fixed after round 1

- **Security**: Settings and ThemeSync wrote files through shell heredocs. Path and text now go in as arguments,
  written to a temp file and moved (`SettingsApp.writeConfigFile`). GTK settings are passed as arguments with
  no shell string. The touchpad name is quoted with `JSON.stringify`; window-menu dispatches go one argument each.
  `monswitch` reads `KEY=value` lines instead of running its config as shell, and Settings refuses unsafe
  monitor names.
- **Stability**:
  - About 50 `powermode watch` processes and 200 `gdbus monitor` processes had piled up, one per shell
    reload. The watcher now ends once nothing reads it.
  - Sensors polling (and `nvidia-smi`) only runs while a panel shows it.
  - The `settings.json.broken` backup can no longer race the reset.
- **Systems**:
  - Login no longer forces dark GTK; ThemeSync applies the whole look once settings load, monospace font included.
  - The default host gets plain suspend where hibernation isn't set up (lid, idle, Settings).
  - The ASUS "recommended" reset finds the host profile.
  - A dead resume unit is removed, and `monswitch` finds the monitor's bus on every call.
  - The file-manager key follows the default app.
  - Stale paths and comments are corrected.
- **App theming**: GTK 3/4 get the exact accent (`gtk-*/linux-setup.css`, imported once).
- **Installer and doctor**: the doctor checks Hyprland config errors, the generated Lua files, duplicate
  watchers and rival notification daemons, and treats a dirty repo as a note. Host steps are tracked by
  checksum, so `update` offers new or changed steps. A third install run is checked to change nothing.
- **Recovery**: `desktop-reset` (Settings files put aside, defaults restored, nothing deleted) and a Recovery
  section in the user guide.
- **CI**: `tests/lint.sh` checks QML syntax (Qt 6 qmlformat), Lua syntax, no colours outside the theme files,
  and every theme half (`tests/themes.py`: colours present, WCAG contrast, palette and wallpaper exist). It runs
  in an Arch container job. Checkout is v5.
- **Monitor sharing**: while the other computer has the Acer, the hand-off is in `settings/shared.lua`, which
  `monitors.lua` reads, so a theme change or a reload keeps the mirror. Before, every change released it again.
  Taking it back re-applies only the monitor rules, with no full reload.
- **Keyboard and touch**: one `FocusRing`. Every shared control (switch, choice, button, slider, dropdown, chip)
  takes Tab focus and works with Space, Enter and the arrows. Tablet mode (`panel tablet on` → `qs ipc call
  tablet set true`) makes controls finger-sized (40 px).
- **Newcomer**:
  - A one-time welcome names tap-Super, Super+I and Super+/.
  - Settings search finds common words (dark, border, update, timezone, screenshot…).
  - Light or dark is at the top of Themes, and "Theme's" is now "Default".
  - Owner-specific or wrong hints are fixed (hibernate only where it works, "both screens", the 13" panel,
    US/Serbian, the system/ path, the charge-limit text).
  - The doctor's verdict counts notes.
  - The user guide's Settings table matches the app; README has First run and Recovery.
- **Design**:
  - Join buttons are quiet; the chosen theme card has a check.
  - Toasts wait while the Control Center or the notification centre is open.
  - The bell badge no longer hangs off the bar.
  - Reactor's light wallpaper keeps the acid hazard tape.
  - The lock-screen grey is a token.
- **Themes**: Reactor added (radioactive acid yellow + orange, both halves), with `docs/THEMES.md`.

### Rejected in round 1 (with evidence)

- `keybinds.lua` "not pcall'd": it is (`modules/binds.lua:10`).
- Notification list "uncapped": capped by `notifications.historyMax` (`Notifications.qml:106`).
- "8.7 % idle CPU": measured while the screenshot run was switching themes. Quiet: 0.40 % (INVENTORY.md).
- squeekboard "host-only": the shell's on-screen keyboard button uses it on any touch screen.
- Keybind recorder dispatch "string-built": a fixed string (`SettingsPageKeybinds.qml:108`).
- "Grey status box" (design): the bar item's open state, because the Control Center was left open during that
  capture. The capture now closes every panel before each shot.
- Monolith launcher "empty strip": the theme's dmenu-style launcher, with a placeholder and mode buttons.
- Qt theming through `kdeglobals`: that file is KDE Plasma's own, so writing it would change the owner's Plasma
  session too. The alternative (qt6ct) needs a new package, so it waits for the owner (DECISIONS.md).

## Round 2 (2026-11-05)

| # | Part | D | U | S | P | C | A | X |
|---|---|---|---|---|---|---|---|---|
| 1 | Settings app | 9.0 | 8.5 | 7.5 | 8.5 | 8.5 | 7.5 | 8.5 |
| 2 | Theme system | 9.0 | 9.0 | 8.5 | 8.5 | 8.5 | — | — |
| 3 | Layout system | 9.0 | 8.5 | 9.0 | — | 8.5 | 8.5 | — |
| 4 | Hyprland core | — | — | 8.0 | — | 8.5 | 8.0 | — |
| 5 | Bar + Control Center | 9.0 | — | — | 8.5 | 7.5 | 7.0 | — |
| 6 | Launcher, power menu, cheat sheet | 8.5 | 8.5 | — | — | 8.5 | 8.5 | — |
| 7 | Notifications + OSD | 8.5 | — | — | 9.0 | — | 8.0 | — |
| 8 | Lock, idle, dim, suspend | 9.0 | 8.0 | — | 9.0 | — | 9.0 | 9.0 |
| 9 | Multi-monitor + input switching | — | 8.5 | 7.5 | — | — | — | 9.0 |
| 10 | Screenshot + annotation | — | 9.0 | — | — | 9.0 | — | 9.0 |
| 11 | Input devices | — | 8.5 | — | — | — | 8.0 | — |
| 12 | Power, thermals, GPU | — | — | 7.0 | 8.5 | — | — | 9.0 |
| 13 | App theming | 8.0 | — | 7.0 | — | — | — | — |
| 14 | Installer, doctor, hosts, first run | — | 8.5 | 8.5 | 8.0 | 8.5 | — | 9.0 |
| 15 | Documentation | — | 8.0 | — | — | — | — | — |
| 16 | Code quality + CI | — | — | 8.0 | — | 7.5 | — | 8.5 |

### Fixed after round 2

- **Hibernate** appears only where logind says it can work (power menu, Spotlight; `Machine.canHibernate`).
  The lid script falls back to plain sleep. The ASUS/NVIDIA row on About shows only on that hardware.
- **Laptop-specific code made generic**:
  - The lid script finds the internal panel (`eDP-*`) and works with any external screen.
  - `powermode next` cycles through only the profiles this machine has.
  - The polkit agent starts through its user unit (same on Arch and Fedora).
  - Qt falls back to GTK3 styling where KDE's integration is missing (no new package).
  - `Machine.qml` reads the shared monitor's name as text, never running its config.
- **GTK apps** get the theme's surfaces and text (window, view, header bar, card, popover, dialog), not just
  the accent.
- **Panels**:
  - Cheat sheet labels wrap to two lines, with a scroll bar and a "more below" fade; `` ` `` and `\` are named.
  - Notification peek cards sit below the card (no grey bars through glass); the "line" style is a 1 px rule.
  - The OSD shows the level as a number.
  - Safe power-menu actions use ink, not the accent, when the accent is red.
- **Copy**:
  - Search finds US spellings and gestures.
  - The layout-switch hint names Super+Ctrl+Space.
  - Dock "Spacing", and a plain Position hint.
  - The welcome explains that Super is the Windows key.
  - "Screenshot all screens".
  - The user guide's file table uses the real page names, and README recovery points to `desktop-reset`.
- **Installer**:
  - It names the supported distros, and checks the Fedora version.
  - The doctor counts duplicate watchers and host steps never applied, or changed, as problems.
  - `./install.sh steps-done` records steps that ran before tracking.
- **Tests**:
  - `tests/themes.py` also checks that Hyprland's first-login defaults match the default theme.
  - `tests/scripts.sh`: monswitch runs nothing from its config; `desktop-reset` keeps your files and seeds the
    defaults.

- **Late in round 2**:
  - A CI shellcheck warning in the new tests is fixed, and `tests/lint.sh` now runs shellcheck too.
  - The power watcher also exits when its parent is gone; the doctor flags stray `gdbus` processes, and the old
    ones were stopped.
  - A host step that hasn't run is a note, not a problem.
  - The Dock edge default is set.
  - The Settings sidebar and search results work by keyboard (Tab, Up/Down, Enter, focus ring) and are
    finger-sized in tablet mode.

- **After the security review**:
  - The theme's strings going into Hyprland's Lua are quoted (`JSON.stringify`) and its numbers forced to
    numbers. A hand-edited or shared theme could otherwise run code at login; this was the one real path
    found.
  - The lock wallpaper path is limited to plain characters.
  - monswitch values must start with a letter or digit (a leading "-" could reach ddcutil as an option),
    and it reports values it ignores.
  - The wallpaper blur only takes absolute paths.
  - CI runs with `permissions: contents: read`.
- **Keyboard**: Control Center tiles and shortcut buttons take Tab focus (Space switches, Enter opens the list).
- **Watcher, for good**: `gdbus` runs under `setpriv --pdeathsig`, so even a watcher killed outright on a shell
  reload takes it along (tested with SIGKILL).

### Rejected or deferred in round 2

- "Default" vs "Theme's choice": round 1 asked to replace "Theme's"; the hint under each row names the theme.
  Kept "Default".
- ~~Idle, input, displays and language into `settings.json`~~: done at the start of round 3 (below).
- Splitting ControlCenter.qml (1457 lines, code quality part 5): the header now says why it is one file; the
  split goes with the next Control Center change.
- Bar items by keyboard (accessibility part 5): the bar is a layer surface without keyboard focus; it needs a
  "focus the bar" key first. Next round.

## Round 3 (in progress)

### Fixed before round 3's review

- **One source of truth**: Lock & Sleep, Keyboard & Touchpad, Displays and Shared Monitor now edit `settings.json`
  (`idle`, `input`, `displays`, `monitorShare`). Each value is checked by `Config.set` (plain names, input codes,
  modes, one to four layouts). `SettingsSync.qml` writes hypridle.conf, input.lua, displays.lua and monswitch.conf
  from it, and applies them live. It only writes when the text differs from what is on disk, and only after reading
  the old file once, so nothing set before is lost. Checked on this laptop: input and displays came out identical,
  and the monitor share differed by one blank line.
  Language already lived there. The pages no longer write or parse those files.
- **Dim before lock**: the screen dims 30 s before locking; any input brings it back.
- **Doctor**: checks that settings.json parses, notes a kept `.broken` copy, checks the lid file is set, and that
  hypridle runs with Settings' file.

## Hard limits (so far)

- **The CI on GitHub** stays red on `main` until this work is pushed. The owner reviews before anything is
  committed, so nothing is pushed yet.
- **Host steps 10 to 50** need sudo, so only the owner can re-apply them (`./install.sh --only host`). The
  doctor lists them until then.
