# Audit (2026-11-11)

A full review of the repo at commit `ea51fdf` against the overhaul brief. Read-only: nothing was changed while
auditing. The older `docs/AUDIT.md` and `docs/COUNCIL.md` are earlier reviews of a narrower goal (one laptop, 9.5
per part); this one measures "any PC or laptop, 10/10 with proof".

How to read it: each department has a score, why, the findings (where, how bad, the fix) and what 10/10 means.
Severity: **critical** breaks or endangers a machine, **high** blocks the goal, **medium** hurts, **low** polish.
Work items are in [ROADMAP.md](ROADMAP.md). Research is in [../research/feature-matrix.md](../research/feature-matrix.md).

Short paths: `QS/` = `config/quickshell/.config/quickshell/`, `HY/` = `config/hypr/.config/hypr/modules/`,
`BIN/` = `config/scripts/.local/bin/`, `X13/` = `hosts/flow-x13/`.

## Scores

| # | Department | Score | One line |
|---|---|---|---|
| 1 | Install & bootstrap | 7 | One command, dry run, idempotent in CI; no log, no preflight, says "Done" after failures |
| 2 | Updates & migrations | 3 | `update` works; no versioned migrations, no rollback of our own files |
| 3 | Uninstall / restore | 5 | Removes links, restores the last backup only; system files stay |
| 4 | Repo structure & readability | 6 | Clear top level; 115 QML files in one flat folder, 1,473-line file, stale docs |
| 5 | Consistency | 6 | One token set in the shell; three usage styles, copied helpers, two project names |
| 6 | Theming system | 5 | Strong tokens and live switch; wrong default, themes not folders, 6 targets missing |
| 7 | Bar & widgets | 4 | One engine, any edge, visual editor; items have no settings of their own, 3 fixed metrics |
| 8 | Launcher & central menu | 6 | Good launcher; three hubs, no themes / update / wifi / bluetooth / audio entries |
| 9 | Keybindings | 8 | One file, live cheat sheet, rebindable; two layout switches clash, binds for absent hardware |
| 10 | Settings panel | 7 | 31 pages, one `settings.json`; three pages keep state elsewhere |
| 11 | Displays & multi-monitor | 4 | Hotplug default is fine; `eDP-1` in core, DDC needs a hand-written file, no VRR |
| 12 | Input devices | 5 | Layouts and gestures; tablet mode and on-screen keyboard only on one laptop |
| 13 | Notifications & OSD | 6 | Centre, history, DND; OSD only for volume and brightness |
| 14 | Lock, idle, power, sleep | 6 | Themed lock, dim, lid logic; desktops suspend after 20 min, no generic charge limit |
| 15 | Screenshots & recording | 8 | Near-Flameshot editing, OCR; no pin, recording picks a fixed GPU node |
| 16 | Clipboard | 8 | History, images, pins, clear; store folder readable by other users |
| 17 | Audio / network / Bluetooth | 7 | Full pickers in the Control Center; not in the one menu |
| 18 | Laptop & hardware support | 3 | Works on the owner's laptop only, chosen by hostname |
| 19 | Gaming & local AI | 1 | Only `nv` (run on the dGPU); no Steam, gamemode, CUDA path or guide |
| 20 | Developer workflow | 4 | fish + starship + fzf; no version manager, Docker not installed, prompt ignores the theme |
| 21 | Apps & defaults | 5 | Runtime lookups work; nothing seeds defaults or MIME, Qt theming needs KDE |
| 22 | Performance | 7 | 0.4 % idle CPU measured; a 3 s DDC poll and an ungated 2 s stats poll |
| 23 | Reliability & diagnostics | 6 | Good drift doctor; no hardware checks, no logs, errors hidden |
| 24 | Security & privacy | 6 | No `curl \| sh`, pinned checksum, gitleaks; unpinned plugin build at login, no firewall |
| 25 | Accessibility | 5 | Contrast test, font scale, focus ring; no screen-reader names, accents untested |
| 26 | First-run experience | 2 | One notification |
| 27 | Documentation | 6 | Good README and user guide; no changelog, licence, contributing, Fedora notes, stale files |
| 28 | Testing & CI | 6 | Lint + install twice + doctor on Arch and Fedora, green; no hardware profiles, no migration test |
| 29 | Hardware coverage (added) | 3 | No detection layer; about ten owner-specific values in core |
| 30 | Distro abstraction (added) | 6 | Clean backend; `pacman`, `dnf`, Limine and Arch paths leak into scripts and steps |

**Average 5.4.** The desktop itself is polished. The gaps are the ones the new brief adds: any hardware, a
modular bar, themes as packages, migrations, and proof.

## Static checks run

| Check | Result |
|---|---|
| `tests/lint.sh` (QML parse, Lua parse, colours only in theme files, 14 theme halves, script tests) | pass |
| shellcheck `-S warning`, 34 scripts | pass (0 findings) |
| shellcheck `-S style` | 15 notes (SC2016 ×7, SC2015 ×4, SC2012 ×2, SC2086, SC1091) |
| `shfmt -d -i 4 -ci` | 31 of 34 scripts differ: no formatter has ever been applied |
| `fish --no-execute` on both fish files | pass |
| `hyprctl configerrors` (Hyprland 0.57.2, live) | none |
| `.github/workflows/ci.yml` parses; JSON files parse | pass |
| `./install.sh doctor` | no problems, 5 notes (host steps not recorded as run) |
| `./install.sh --dry-run --yes` | completes, lists every change |
| GitHub Actions, last 3 runs on `main` | green |
| `Accessible.` in the QML | 0 uses |
| Missing files | `CHANGELOG.md`, `CONTRIBUTING.md`, `LICENSE`, `docs/CONVENTIONS.md` |

Not installed locally: shellcheck, shfmt, actionlint, yamllint (run through Docker or CI instead).

## Things the brief says that the repo disagrees with (owner decisions)

| Brief | Repo | Proposed |
|---|---|---|
| Terminal is Alacritty | Ghostty is configured, themed and bound; Alacritty appears nowhere | Keep Ghostty (already themed live); say so if Alacritty is wanted |
| KDE need not be kept | KDE is guarded, and used: KWallet keyring, Dolphin, kdialog, Qt theming, the emoji list | Drop the fallback and the guard; replace the KDE-only pieces so a machine without Plasma works |
| Reactor is the default theme | Pebble is the default (`QS/ConfigData.qml:8`) | Make Reactor the default |
| MX Master haptics via Solaar / logiops | JuhRadial MX, installed by a third-party script | Move to Solaar (in both distros' repos, haptics supported) |
| Repo is `linux-setup` | GitHub repo and README say Hyprism; state folder and CSS files say `linux-setup` | One name everywhere: Hyprism |

---

## 1. Install & bootstrap: 7

Has: one command, `--dry-run`, `--yes`, `--only`, backups, stow file by file, CI proves a third run changes nothing.

| Where | Sev | Problem | Fix |
|---|---|---|---|
| `install.sh:19` | medium | No log file and no failure summary; the first failing command ends the run | Log to the state folder; on error print what failed and how to resume |
| `install.sh:403-410` | medium | No preflight (network, sudo, disk, hardware summary) | Run `detect` first and print the plan |
| `install.sh:116,410` | medium | Prints "Done" even when package installs failed | Exit non-zero and list what failed |
| `install.sh:44` | low | In a dry run every question is silently "yes" | Print "would ask: …" |
| `install.sh:192` | low | Links the wallpaper without checking the file exists | Check first |
| `packages/manifest.txt:60` | medium | `ddcutil` is installed but nothing loads `i2c-dev` or grants access | Do it in the DDC module when a DDC monitor is found |
| `install.sh` (412 lines) | low | One file holds install, update, doctor, undo, links, services | Split into `lib/*.sh` |

**10/10:** fresh Arch, CachyOS and Fedora containers install with exit 0; a second run reports zero changes;
a forced package failure exits non-zero with a summary; every run leaves a log; the dry run prints questions.

## 2. Updates & migrations: 3

| Where | Sev | Problem | Fix |
|---|---|---|---|
| `install.sh:155-166,204-213`, `QS/Config.qml` (old-theme renames) | high | "Migrations" are one-off code that runs forever, in three places | `migrations/NNNN-name.sh`, run once in order, ids kept in the state folder |
| `install.sh:274-290` | high | A bad update of our own files can't be undone | Record the commit before pulling; `./install.sh rollback` returns to it and relinks |
| — | medium | No version number anywhere | `VERSION` file + `CHANGELOG.md`; the doctor prints it |
| `.github/workflows/ci.yml` | medium | Nothing tests updating from an older release | CI: install the previous tag, update to HEAD, doctor |

**10/10:** CI installs the last release, runs `update`, every migration runs once and a second update runs none;
`rollback` restores the earlier commit and links; snapshots stay an optional extra.

## 3. Uninstall / restore: 5

| Where | Sev | Problem | Fix |
|---|---|---|---|
| `install.sh:382-391` | medium | `undo` leaves the lid file, session change, Docker unit change, generated settings and state behind | Record every system file written; `uninstall` reverts each (asks first) |
| `install.sh:389` | low | Only the latest backup can be restored | List backups, choose one |
| `X13/steps/10-hardware.sh:37,44` | high | Appends to `/etc/fstab` with no backup and no undo | Back up first; every module step gets an undo part |

**10/10:** in a container, install then uninstall leaves the home folder and `/etc` byte-identical to before
(checked by a file listing with checksums).

## 4. Repo structure & readability: 6

| Where | Sev | Problem | Fix |
|---|---|---|---|
| `QS/` | medium | 115 QML files in one folder | Sub-folders: `bar/`, `panels/`, `settings/`, `controls/`, `services/` |
| `QS/ControlCenter.qml` (1,473), `Dock.qml` (715), `Launcher.qml` (664) | medium | Too long to read | One file per section |
| `docs/` | medium | Six files describe finished or paused work (`PROGRESS`, `RESUME-PROMPT`, `REDESIGN-PLAN`, `RECOMMENDATIONS`, old `AUDIT`, `COUNCIL`) | Move to `docs/history/` |
| `hosts/` | high | Machines are folders picked by hostname | Replace with detected `modules/` (dept 29) |
| `BIN/asusfan`, `BIN/thermlog` | medium | Vendor tools sit among the core scripts | Move into their module |
| `.council/`, `feat/settings-desktop-customisation` branch | low | Leftovers (the branch is fully merged) | Remove |

**10/10:** the README's layout table matches `ls`; no source file over 400 lines; each setting has exactly one
home, listed in "how to change X".

## 5. Consistency: 6

| Where | Sev | Problem | Fix |
|---|---|---|---|
| all scripts | medium | Never formatted (shfmt differs in 31 of 34) | Format once, enforce in CI |
| `BIN/screenshot:30`, `record:21`, `clipstore:112`, `monswitch:141` | low | Three ways to print usage, with line ranges that drift | One `usage` helper that prints the header comment |
| `BIN/asusfan:98` + `thermlog:11`; `startup-apps:21` + `installed-apps:17`; `screenshot:39` + `record:37` | low | Copied helpers | One shared `lib/common.sh` |
| `QS/BarStats.qml:23`, `QS/Sensors.qml:60,101` | medium | Two CPU-load readers | One metrics service (dept 7) |
| repo-wide | low | `linux-setup` vs Hyprism in paths, CSS names, state folder | One name, with a migration |
| `config/starship/.config/starship.toml:46` | medium | Fixed hex colours outside the tokens | Generate from the theme |
| — | medium | No written conventions | `docs/CONVENTIONS.md`, checked in CI where possible |

**10/10:** `shfmt -d` and shellcheck `-S style` are clean in CI; a grep finds no hex colour outside theme
packages; one usage helper; one name.

## 6. Theming system: 5

Has: 13 colour keys + shape, type and motion tokens (`QS/Theme.qml`); 7 themes × light/dark; live switch
(`theme NAME`, Settings gallery with previews); a Theme Builder; a contrast test in CI. `ThemeSync` writes Hyprland,
hyprlock, GTK 3/4, Ghostty, fuzzel, cursor, icons and wallpaper.

| Where | Sev | Problem | Fix |
|---|---|---|---|
| `QS/ConfigData.qml:8` | high | Default theme is Pebble | Reactor |
| `QS/Themes.qml:36-190`, `config/ghostty/…/themes/`, `BIN/theme-wallpaper` | high | A theme is spread over three places; adding one needs code edits | `themes/<id>/theme.json` + wallpaper + optional overrides; terminal palette generated from tokens |
| `QS/ThemeSync.qml:11` | high | Not themed: Qt apps, login screen, btop, starship/fish, editor | One small writer per target, same tokens |
| — | medium | No wallpaper-colour mode | Optional mode; output goes through the contrast fixer |
| `tests/themes.py` | high | Doesn't test accent, accent2, ok/warn/err, lines or bar ink on bar fill | Add those pairs |
| `QS/ThemeSync.qml` | low | Rewrites every file on every change | Skip unchanged text (SettingsSync already does) |

**10/10:** `cp -r themes/reactor themes/mine`, edit one file, and `theme mine` works with no code change; a test
asserts every target file exists and carries the accent for every theme; every theme half passes the extended
contrast test; Reactor is what a fresh install shows.

## 7. Bar & widgets: 4

Has: one engine on any edge, three sections, 23 items, drag-and-drop editor, hide per monitor.

| Where | Sev | Problem | Fix |
|---|---|---|---|
| `QS/BarWidget.qml:12-28` | high | Items are components inside one 425-line file; no folder, config or README each | `bar/items/<id>/` with `Item.qml`, `defaults.json`, `README.md` |
| `QS/ConfigData.qml:157-166` | high | Per item only order and section exist | Per item: enabled, section, order, icon, format, interval, click / right-click / scroll, tooltip, warn / critical |
| `QS/Themes.qml:221-243` | medium | The item list lives in the theme file | Built from the item folders |
| `QS/ConfigData.qml:157` | high | No presets, no layout per monitor | `bar.presets` (minimal, full, laptop, external) and `bar.monitors` |
| `QS/BarStats.qml`, `QS/Sensors.qml` | high | Bar metrics are CPU %, RAM %, iGPU % only, fixed | A system-info item over a metric registry (below) |
| `QS/Sensors.qml:62,116,118,119` | high | Sensors assume AMD (`k10temp`, `amdgpu`), ASUS fans, one Wi-Fi driver and `BAT0` | Find by device class; show nothing when absent |
| `QS/Sensors.qml:107-109` | medium | Disk is `/` only; no I/O, per-core, load average, uptime, battery time or watts in the bar | Add as registry entries |
| `QS/BarStats.qml:51` | medium | 2 s poll runs while locked or hidden | Gate on a visible bar; interval per metric |

System-info metrics today vs wanted: have CPU %, CPU temp (AMD), CPU freq, iGPU load/VRAM/power (AMD), NVIDIA
(without waking it: good), RAM, swap, disk `/`, net speed (computed, unused), power profile, ASUS fans. Missing:
per-core, Intel sensors, disk per mount, disk I/O, connection, battery rate / time / watts, generic fans, uptime,
load average, sparkline, "only above a threshold", user-chosen order and format.

**10/10:** every item is a folder with config and README; `settings.json` and the Settings page edit the same
per-item block (a test round-trips it); four presets and per-monitor layouts switch live; every metric in the
brief is selectable, ordered and formatted by the user; adding a metric is one registry entry plus a doc line
(shown by a test metric); the dGPU stays suspended while the bar shows its state.

## 8. Launcher & central menu: 6

| Where | Sev | Problem | Fix |
|---|---|---|---|
| `QS/Search.qml:77-134` | medium | Actions lack: switch theme, update, wifi, bluetooth, audio device, displays, record, web app | Add them; hardware ones only when detected |
| `QS/UtilityMenu.qml`, `QS/ControlCenter.qml`, `QS/Launcher.qml` | low | Three hubs with overlapping content | The launcher's Actions mode is "the menu"; the others link into it |

**10/10:** from `Super+Space` every item in the brief's list is reachable in at most two steps, shown by a
checklist with screenshots.

## 9. Keybindings: 8

| Where | Sev | Problem | Fix |
|---|---|---|---|
| `HY/input.lua:5` vs `HY/binds.lua:35` | medium | `Alt+Shift` switches layout and is also the prefix of `Alt+Shift+S` | One switch (`Super+Ctrl+Space`); drop the XKB toggle |
| `HY/binds.lua:82,87,96-102` | medium | Monitor switch, power mode and brightness keys are bound on machines without that hardware | Bind from `hardware.toml` |
| `HY/binds.lua:6` | low | Terminal name is fixed | Read the default-apps setting |
| `HY/binds.lua:67-69` | low | Three keys for the same screenshot | Keep two |
| — | medium | No test for clashes | CI: load the bind table, fail on duplicates |

**10/10:** CI fails on a duplicate combo; the cheat sheet lists only binds that work on this machine; overrides
live in the one config file.

## 10. Settings panel: 7

| Where | Sev | Problem | Fix |
|---|---|---|---|
| `QS/SettingsPageApps.qml:52` | low | Default apps live only in `mimeapps.list` | Keep (it is the standard file); document as the source of truth |
| `QS/SettingsPageStartup.qml:38-50` | low | Old migration path still in the page | Move to a migration |
| `QS/SettingsPageApprules.qml:201` | medium | Opens a repo file in an editor | Rules in `settings.json`, generated like the others |
| `QS/SettingsPageBar.qml` | high | No per-item settings, presets or per-monitor layouts | Follows dept 7 |
| `~/.config/quickshell/settings.json` | medium | JSON has no comments; the brief wants a readable file | Ship a commented reference (`docs/settings-reference.md`, generated from `ConfigData.qml`) and keep names plain |

**10/10:** a test changes each setting through IPC and through the file and sees the same result both ways; no
page writes any file except through the one sync path; the reference doc is generated and checked in CI.

## 11. Displays & multi-monitor: 4

| Where | Sev | Problem | Fix |
|---|---|---|---|
| `HY/monitors.lua:33-34`, `HY/input.lua:24-25` | high | `eDP-1` hardcoded for rotation and touch mapping | Use the detected internal panel; skip when none |
| `BIN/monswitch:21-33`, `X13/defaults/.config/monswitch.conf` | high | Input switching needs a hand-written file with one monitor's codes | `monswitch setup` reads each monitor's inputs over DDC and offers them; Settings page uses the same |
| `QS/ConfigData.qml:217-218` | medium | Shared-monitor mirror defaults to `eDP-1`, `1920x1080@60` | Empty; pick at runtime |
| `HY/monitors.lua:139-147` | medium | No DPI-based scale, no highest-refresh choice, no VRR option | Scale from physical size, `highrr` option, VRR toggle |
| `hosts/*/home/.config/hypr/host.lua` | high | Workspace-to-monitor rules exist only for the owner's two outputs | Generic rule from detected monitors, editable in Settings |
| `HY/look.lua:63-76` | medium | Fixes for one monitor (auto-HDR off, content type off) apply to everyone | Make them options with safe defaults |
| — | medium | No saved profiles per set of connected monitors | Save the arrangement per monitor set; re-apply on hotplug |
| `BIN/monswitch:126` | medium | Polls DDC every 3 s forever | Longer interval with back-off, pause when the screen is off |

**10/10:** grep finds no output name in core; with a headless Hyprland and fake outputs, a test adds and removes
monitors and the saved profile returns; `monswitch setup` works on any DDC monitor (tested with a fake
`ddcutil`); owner checklist confirms the real hand-off.

## 12. Input devices: 5

| Where | Sev | Problem | Fix |
|---|---|---|---|
| `X13/home/.config/hypr/host.lua:5-8` | high | Tablet mode keyed to one device name; other 2-in-1s get nothing | Detect any tablet-mode switch; tablet module |
| `BIN/panel:15-34` | medium | Rotation needs `iio-sensor-proxy`, which no package list has | Add to the tablet module |
| `HY/input.lua:184-187` | medium | Touchpad has two options, no per-device settings | Disable-while-typing, click method, speed; per-device blocks from Settings |
| `X13/steps/40-mx-master.user.sh`, `HY/rules.lua:73`, `HY/autostart.lua:18`, `HY/plugins.lua:8` | medium | JuhRadial is wired into core and installed by a third-party script | Logitech module with Solaar; nothing in core |
| — | low | Bar layout indicator exists; no OSD on switch | Dept 13 |

**10/10:** a machine with no touchpad, touchscreen or Logitech device shows none of those settings or errors
(tested with a fake `hardware.toml`); tablet mode works from any switch (owner checklist on the X13).

## 13. Notifications & OSD: 6

| Where | Sev | Problem | Fix |
|---|---|---|---|
| `QS/Osd.qml:39-48` | medium | No OSD for mic mute, caps lock, keyboard layout | Add the three |
| `QS/Osd.qml:50` | low | Timeout and size fixed | `osd` settings block |

**10/10:** each of the five OSDs appears on its event (IPC test + screenshots); DND silences toasts but keeps
history.

## 14. Lock, idle, power, sleep: 6

| Where | Sev | Problem | Fix |
|---|---|---|---|
| `config/hypr/.config/hypr/defaults/hypridle.conf` | medium | Suspends after 20 minutes on AC and on desktops | Separate battery and AC times; desktops default to never |
| — | medium | Battery charge limit only through `asusctl` | Generic writer for `charge_control_end_threshold`, shown only where the file exists |
| `BIN/powermode:12-18` | medium | Picks ASUS by the presence of the binary, not a running daemon | power-profiles-daemon first; vendor backend only when its service is active |
| `X13/steps/10-hardware.sh` | medium | Hibernate setup exists only for one laptop | Optional generic hibernate module (swap sized from RAM, any bootloader) |
| — | low | Login screen isn't themed | Dept 6 |

**10/10:** on a no-battery profile there is no suspend timer, battery item or charge limit; on a battery profile
all three exist; lid closed with an external monitor keeps the session (owner checklist).

## 15. Screenshots & recording: 8

| Where | Sev | Problem | Fix |
|---|---|---|---|
| `BIN/record:44` | high | Always encodes on `/dev/dri/renderD128`, which can be the wrong GPU | Pick the compositor's GPU; fall back to software encoding |
| `BIN/record:19-20` | medium | System sound or microphone, never both | Allow both |
| — | medium | No pin-to-screen | `screenshot pin`: a small always-on-top window from the shell |
| `BIN/screenshot:78`, `BIN/screentext:9` | low | Editor crash and OCR errors are hidden | Notify with the reason |

**10/10:** every item in the brief's list (annotate, arrows, text, blur, copy, save, pin; area + audio
recording) is demonstrated; recording works on a single-GPU and a hybrid profile.

## 16. Clipboard: 8

| Where | Sev | Problem | Fix |
|---|---|---|---|
| `BIN/clipstore:17` | medium | History folder is created readable by other users | Mode 700 |
| `BIN/clipstore:75-92` | low | Two processes per entry when the panel opens | One pass |
| `QS/Clipboard.qml:56-60` | low | Terminal list is fixed in code | Setting |

**10/10:** store is 700 (test); 300 entries list in under 100 ms; images show thumbnails.

## 17. Audio / network / Bluetooth: 7

| Where | Sev | Problem | Fix |
|---|---|---|---|
| `QS/Search.qml` | medium | Not reachable from the one menu | Dept 8 |
| `QS/BarStatus.qml` | low | Bar items open the whole Control Center, not their own picker | Per-item click action (dept 7) |
| `install.sh:219` | low | Bluetooth is enabled even with no adapter | From `hardware.toml` |

**10/10:** wifi, Bluetooth and audio pickers open from the bar item, the menu and Settings; none appears on a
machine without that hardware.

## 18. Laptop & hardware support: 3

| Where | Sev | Problem | Fix |
|---|---|---|---|
| `X13/steps/20-igpu.sh:11` | critical | The udev rule names one laptop's PCI address | Find the iGPU by vendor and boot flag; generic `/dev/dri/igpu` |
| `hosts/default/` | high | A generic hybrid-NVIDIA laptop gets none of: iGPU rendering, NVIDIA sleep services, runtime power-down | `nvidia-hybrid` module, detected from two GPUs |
| `config/fish/…/hyprland-igpu.fish:8` | high | Keeping the dGPU asleep depends on fish being the login shell | Set it in the session environment |
| `X13/host.conf` | high | ASUS support is tied to one hostname | `asus` module, detected from the vendor and `asusd` |
| `BIN/asusfan:100-104`, `BIN/thermlog:12-24` | high | AMD sensor names, PCI address and `BAT0` hardcoded | Detect, or move into the module |
| `X13/steps/10-hardware.sh:35,48-57`, `30-thermal.sh:22-36` | high | Assume btrfs, Limine and pacman | Bootloader and filesystem helpers in the distro layer |
| `HY/binds.lua:94-106` | medium | No generic keyboard-backlight keys | brightnessctl on the detected LED |
| `BIN/nv` | low | NVIDIA only | Also `DRI_PRIME` for AMD dGPUs |

**10/10:** every row of `docs/hardware.md` is detected and tested from a fixture; on the owner's laptop the
doctor passes with the modules found by detection, not by hostname; the dGPU reads `suspended` at idle.

## 19. Gaming & local AI: 1

Nothing exists except `nv`. Fix: an optional `gaming` module (Steam, gamemode, MangoHud, 32-bit drivers per
distro) and an `ai` module (NVIDIA container toolkit, Ollama, a guide), both off by default and offered by the
installer when a dGPU is found.

**10/10:** both modules install in CI dry runs on both distros; the guide's commands are checked on the owner's
laptop (checklist: a game on the dGPU, a model answering with the GPU in use).

## 20. Developer workflow: 4

| Where | Sev | Problem | Fix |
|---|---|---|---|
| `packages/manifest.txt` | medium | No Node / PHP / Python version manager | `mise` (one tool for all three) in an optional `dev` module |
| `install.sh:225-231` | medium | Docker is tuned if present but never installed; no group step | In the `dev` module |
| `config/starship/.config/starship.toml:46` | medium | Prompt colours are fixed | From the theme |
| — | low | No editor integration | Theme hint for VS Code-family editors; documented |

**10/10:** with the `dev` module on, `mise`, Docker and the themed prompt work in both containers.

## 21. Apps & defaults: 5

| Where | Sev | Problem | Fix |
|---|---|---|---|
| `install.sh` | medium | Nothing sets default apps or MIME types on a fresh system | Seed only where unset |
| `HY/env.lua:10-20` | high | Qt apps are themed only where KDE Plasma is installed | qt6ct + generated colours (new dependency, ~1 MB) |
| `BIN/emojipick:8` | medium | Emoji list comes from a Plasma file | Ship our own list (Unicode data, free licence) |
| `HY/autostart.lua:4,22` | medium | Arch-only paths for the polkit agent and keyring helper | Find by command; keyring via gnome-keyring or KWallet, whichever exists |
| `packages/manifest.txt` | low | No image viewer, PDF viewer or office suite named | Small defaults in the `apps` module; office optional |

**10/10:** on a fresh container with no KDE, opening a file, link, image and PDF each starts a themed app
(asserted with `xdg-mime query`); Qt and GTK sample apps show the accent (screenshots).

## 22. Performance: 7

Measured before: shell 0.40 % of one core idle, 337 MB.

| Where | Sev | Problem | Fix |
|---|---|---|---|
| `BIN/monswitch:126` | medium | DDC query every 3 s | Dept 11 |
| `QS/BarStats.qml:51` | medium | Poll not tied to visibility | Dept 7 |
| `BIN/hypr-plugins` | low | May compile at login | Build on update only |
| `HY/autostart.lua:22-23` | low | `sleep 1`, `sleep 3` timing | Order by events |

**10/10:** a script measures idle CPU, RAM and time-to-bar and CI or the doctor compares against a written
budget (idle under 1 % of a core, no helper waking more than once a minute while idle).

## 23. Reliability & diagnostics: 6

| Where | Sev | Problem | Fix |
|---|---|---|---|
| `install.sh:293-380` | high | The doctor checks no hardware module, portal, sound server, polkit agent or keyring | One check per module from `hardware.toml`, reporting pass / skip / fail |
| `install.sh:300` and others | medium | Many findings have no fix line | Every finding prints its fix |
| scripts | medium | No log location; errors hidden by `\|\| true` and `2>/dev/null` (`monswitch:47`, `panel:17-26`, `install.sh:240`) | One log folder; log instead of hiding |
| — | low | Doctor lives inside the installer | Also `hyprism doctor` on the PATH |

**10/10:** the doctor passes on the owner's machine and prints "skipped: not present" for absent hardware on the
fixtures; a test breaks ten things on purpose and each is reported with a working fix line.

## 24. Security & privacy: 6

| Where | Sev | Problem | Fix |
|---|---|---|---|
| `BIN/hypr-plugins:38` | high | Clones and compiles upstream plugin code at login with no pinned commit, then loads it into the compositor | Pin a commit per Hyprland version; build only on update |
| `distros/arch.sh:28` | medium | AUR builds run with `--noconfirm` | Name each AUR package and ask |
| `distros/fedora.sh:19` | medium | COPR repos enabled with `-y` | Name each repo and its owner in the question |
| `X13/steps/40-mx-master.user.sh` | medium | Runs a third-party installer (checksum-pinned, but with sudo) | Replaced by Solaar |
| — | medium | No firewall offered | Enable the distro's own (firewalld / ufw) after asking |
| `BIN/clipstore:17` | medium | Dept 16 | |
| `.githooks/pre-commit` | low | Secret scan is skipped silently when gitleaks is missing; CI doesn't run it | gitleaks job in CI |

**10/10:** no unpinned download executes anything (grep + review listed in the report); gitleaks runs in CI;
every third-party repo is named before it is enabled; the doctor reports firewall, polkit agent and keyring.

## 25. Accessibility: 5

| Where | Sev | Problem | Fix |
|---|---|---|---|
| `QS/` (all) | high | No accessible names or roles | Add to the shared controls and bar items |
| `tests/themes.py` | high | Dept 6: accents and status colours untested | Extend |
| `QS/Sensors.qml:243,275` | medium | Warning shown by colour only | Add a glyph |
| `QS/BarItem.qml` | medium | The bar can't be reached by keyboard | A key to focus the bar, arrows to move |

**10/10:** the extended contrast test passes for every theme half; every shared control has a name and role
(lint); font scale 0.85–1.5 and cursor 16–64 work without clipping (screenshots); the bar is keyboard-reachable.

## 26. First-run experience: 2

`QS/shell.qml:28-34` sends one notification. Fix: a welcome panel on first login (theme, light/dark, keyboard
layouts, bar preset, detected modules), then the cheat sheet once. It writes only `settings.json`.

**10/10:** with an empty config the welcome opens once, its choices land in `settings.json`, and it never
reopens (test via IPC + screenshots).

## 27. Documentation: 6

| Where | Sev | Problem | Fix |
|---|---|---|---|
| root | high | No `LICENSE` in a public repo; no `CHANGELOG.md`, `CONTRIBUTING.md` | Add (licence is the owner's choice; MIT proposed) |
| `docs/` | medium | No install guide per distro, "how to change X", module docs, hardware matrix, troubleshooting | Write them |
| `README.md` | medium | Says seven themes with Pebble default, KDE kept, hosts by name | Update with the overhaul |
| `docs/ARCHITECTURE.md`, `INVENTORY.md` | low | Counts and layout will go stale | Regenerate the counts in CI or drop them |

**10/10:** a reader can install and change theme, bar, keys and monitors from the docs alone (stranger test with
a fresh reviewer who may not open the source); CI checks every path and command named in the docs exists.

## 28. Testing & CI: 6

| Where | Sev | Problem | Fix |
|---|---|---|---|
| `.github/workflows/ci.yml` | high | No hardware profiles, migrations, uninstall or settings round-trip tests | Add (depts 2, 3, 10, 29) |
| CI | medium | No shfmt, actionlint, gitleaks, docs-link or keybind-clash checks | Add |
| `tests/themes.py` | medium | Parses QML with regular expressions | Reads theme packages once they are JSON |
| — | medium | No VM checklist for what CI can't do | `docs/testing/vm-checklist.md` |

**10/10:** CI is green with all the checks above on Arch and Fedora; the VM checklist exists and its last run is
recorded.

## 29. Hardware coverage (added): 3

Owner-specific values in core today:

| Where | Value |
|---|---|
| `HY/monitors.lua:33-34`, `HY/input.lua:24-25`, `BIN/monswitch:33`, `QS/ConfigData.qml:217` | `eDP-1` |
| `QS/ConfigData.qml:218` | `1920x1080@60` |
| `BIN/asusfan:104`, `BIN/thermlog:14` | PCI `0000:01:00.0` |
| `BIN/asusfan:100`, `BIN/thermlog:12`, `QS/Sensors.qml:62` | `k10temp`, `amdgpu` |
| `QS/Sensors.qml:116,118,119`, `BIN/thermlog:24` | `asus` fans, `iwlwifi_1`, `BAT0` |
| `BIN/record:44` | `/dev/dri/renderD128` |
| `HY/env.lua` | `/dev/dri/amd-igpu` |
| `HY/rules.lua:17,73`, `HY/plugins.lua:8`, `HY/autostart.lua:18` | ROG Control Center, JuhRadial |
| `BIN/theme-wallpaper:6` | `2560x1600` canvas |
| `QS/Search.qml:77`, comments in `HY/look.lua`, `HY/autostart.lua`, `BIN/monswitch`, satty config | "Acer", "Keychron" wording |

Root cause: `install.sh:66-74` chooses a machine folder by hostname. There is no detection layer. Good parts to
reuse: `QS/Machine.qml` (ASUS, NVIDIA, keyboard light), `BIN/panel:12` (internal panel), the lid check in
`install.sh:240`.

**10/10:** `detect` writes a readable `hardware.toml`; installer steps, Hyprland config, binds, bar items, menu
entries and doctor checks read it; the user can override any value; seven fixture profiles (AMD desktop, NVIDIA
desktop, Intel laptop, hybrid-NVIDIA laptop, HiDPI single screen, multi-monitor, VM) pass install dry run + doctor
in CI; `tests/no-hardcode.sh` greps core for the values above and finds none; `docs/hardware.md` lists each
hardware type, how it is detected, its module and how it was tested.

## 30. Distro abstraction (added): 6

| Where | Sev | Problem | Fix |
|---|---|---|---|
| `BIN/installed-apps:53-166` | high | Package-manager branches inside a script | Backend functions: owner, info, remove |
| `X13/steps/30-thermal.sh:22,25`, `10-hardware.sh:48-57` | high | pacman and Limine called directly | Backend functions: kernel arguments, initramfs |
| `install.sh:336-338` | medium | Arch-only checks inside the doctor | `distro_doctor` |
| `HY/autostart.lua:4,22` | medium | Arch paths | Dept 21 |
| `install.sh:55-58` | low | Lists Arch derivatives by name | `ID_LIKE` only |

**10/10:** a grep for `pacman`, `dnf`, `rpm`, `paru`, `limine` outside `distros/` and `packages/` returns
nothing; both containers pass.
