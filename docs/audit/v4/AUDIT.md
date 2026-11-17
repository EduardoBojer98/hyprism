# Hyprism round 3: audit, research and roadmap (2026-11-17)

Stage 1 only. Nothing in the repo or the live desktop was changed; this file is the one thing written (uncommitted).
Evidence is `path:line` from `develop` @ `10222df`. **Verified** = read in code or run on this machine.
**Unverified** = stated by docs or reasoning, not tested here. Shell paths are under `config/quickshell/.config/quickshell/`.

---

## A. Executive summary

Hyprism is already past "rice" stage. It has a real installer with migrations and rollback, hardware detection,
one validated settings file with format migrations, one panel frame, shared state services (`Sys`, `Machine`,
`PanelState`), ~31 Settings pages, 29 IPC targets, CI with lint + container installs + nested-desktop tests.
Most features you listed exist in some form: display editor with keep-or-revert, Control Center editor with live
preview, keybind recorder with conflict refusal, custom launcher actions.

The weakness is not missing UI. It is that **the same idea is implemented five times with five vocabularies**:

| Where | What it can run | File |
|---|---|---|
| Launcher built-ins | ~40 hard-coded actions (`cmd` or JS `run`) | `Search.qml:115-152` |
| Launcher custom actions | `snippet` / `open` / `terminal` / shell | `Search.qml:184-200`, `Config.launcher.actions` |
| Bar clicks | `panel:` / `settings:` / `run:` | `BarActions.qml:5-20` |
| Hot corners | 6 fixed ids | `HotCornerActions.qml:6-13` |
| Control Center toggles | hard-coded ids + `available()` switch | `ControlCenter.qml:28-55` |
| Keybinds | 70 hard-coded `add()` calls, rebind/disable only | `hypr/modules/binds.lua:31+` |

So a user can make a launcher action but cannot put it in the Control Center, bind a key to it, or make it a toggle.
That is the root of requests 4.2-4.5. **Fix the foundation (one action registry) first; the requested features then
become small UI on top of it.**

Second structural issue: **displays are remembered by connector name** (`HDMI-A-1`, `eDP-1`) in one global layout
(`~/.config/hypr/settings/displays.lua`, `workspaces.lua`). A dock, a different USB-C port or a second external
monitor of the same port type gets the wrong layout. GNOME (Mutter) keys saved layouts per *set of connected
monitors*, each identified by connector + vendor + product + serial (verified in Mutter source). Presets need this.

Maturity: **good daily driver, architecture ~70% ready** for what you want. No P0 security or data-loss bug found.

---

## B. Architecture audit

```
install.sh ─ lib/*.sh ─ stow ─► ~ (file symlinks into this repo; develop = your live desktop)
Hyprland 0.57.2 (Lua) ─ hyprland.lua ─ modules/*.lua ─ settings/*.lua (written by the shell) ─ hardware/*.lua
Quickshell 0.3.2 (one process `qs`)
  Config.qml ◄─► settings.json (FileView, validated per key, format migrations, broken JSON kept as .broken)
  SettingsSync / ThemeSync ─► hypr/settings/*.lua, hyprlock, GTK/Qt/Ghostty/btop … ─► `hyprctl eval` or `hyprctl reload`
  Services: Sys (audio, battery, net, BT, media), Machine (hardware facts), Metrics, Weather, PowerMode, Caffeine, NightLight
  Surfaces: Bar(+items), Dock, ControlCenter(+Flyouts via PanelState), Launcher/Search, Notifications, OSD, Lock, Settings app
  IPC: 29 IpcHandler targets (`qs ipc call <target> <fn>`) — what keybinds call
```

What is good and should be kept:
- One settings file with validation and migrations (`Config.qml:175-200`, `:255-316`).
- Hyprland settings are generated Lua applied live (`SettingsSync.qml:9-10,89`), no hand-edited config drift.
- Event-driven state mostly via Quickshell's Hyprland/PipeWire/UPower bindings; polling timers are gated on
  visibility (`Sensors.qml:79`, `ControlCenter.qml:180`, `SettingsPageStartup.qml:52`).
- Settings → shared modules → Control Center / flyouts reuse (`PanelState.qml`).

What should change:
1. **Actions** — no single registry (table above). Built-in actions mix `Quickshell.execDetached(["qs","ipc",…])`
   (the shell calling itself through a subprocess, `Search.qml:127,138,141`) with direct JS calls for the same features.
2. **Process execution** — almost every command is fire-and-forget `execDetached`; exit codes are checked in only
   4 places (`SettingsPagePower.qml:26`, `SettingsPageAsus.qml:74`, `ThemeCards.qml:46`, `SettingsPageWallpaper.qml:73`).
   A failing custom command is silent. No action log.
3. **Display logic lives inside a Settings page** (`SettingsPageDisplays.qml:13-133`: load, edits, apply, revert
   countdown). The Control Center cannot reuse it; it has only brightness/DDC and the monswitch hand-off tile.
4. **Monitor identity** by connector name everywhere (displays, workspaces, `bar.hiddenOn`, `dock.hiddenOn`).

---

## C. Functionality inventory

| Area | Status | Evidence / note |
|---|---|---|
| Installer, migrations, rollback, doctor | Working | `install.sh`, `migrations/`, `lib/migrate.sh` |
| Settings persistence + validation | Working | `Config.qml:175-200`; bad JSON → `settings.json.broken` |
| Display editor (drag, mode, scale, rotation, mirror, VRR, 10-bit, extend/mirror/only switch, 15 s keep-or-revert) | Working, needs improvement | `SettingsPageDisplays.qml:86-133`; no presets, no hotplug refresh while open (loads once via `hyprctl -j monitors all`, `:49`), keyed by connector |
| Display hotplug for unknown screens | Working | `monitors.lua` fallback rule `newScreen` (right/left/above/below/mirror) |
| Display presets | Missing | — |
| Control Center display control | Missing | only brightness + DDC + monswitch tile (`ControlCenter.qml:66,92`) |
| Shared-monitor hand-off (monswitch) | Working | `settings/shared.lua`; live now (HDMI-A-1 mirroring eDP-1) |
| Control Center editor (order, large/small, hide, style, width, fold, live preview) | Working, needs improvement | `SettingsPageControlcenter.qml`, `ConfigData.qml:104-116`; no custom tiles, no display card |
| Keybinds (70 binds, rebind, disable, conflict refusal, cheat sheet) | Working, needs improvement | `binds.lua`, `SettingsPageKeybinds.qml`; **cannot add** a bind |
| Custom launcher actions | Partial | 4 kinds, launcher only; no icon, toggle, state, error feedback |
| Custom buttons / toggles elsewhere | Missing | — |
| Context-aware visibility | Partial | hard-coded `available()` (`ControlCenter.qml:44-52`), `has` map in `Search.qml:175-178` |
| Launcher (apps, files via `fd`, calc via `qalc`, settings, actions, web, clipboard, usage ranking) | Working | `Search.qml` |
| Clipboard (cliphist-like store, images, password-manager hint skipped, chmod 700) | Working | `clipstore:22,55,60`; prune by count/age only, no byte cap |
| Notifications (DND + schedule, grouping, persisted history) | Working, needs improvement | `Notifications.qml:20-53,215`; no inline reply |
| Audio incl. per-app volume | Working | `ControlCenterSliders.qml:175` (`Sys.streams`) |
| Network / Bluetooth | Working, needs improvement | VPN and hidden SSID not in Settings (agent grep, unverified in UI) |
| Power modes, low battery | Working | `powermode`, `BatteryWarning.qml`; charge limit ASUS-only (`SettingsPagePower.qml:19-26`) |
| Lock before sleep, idle | Working | hypridle via `SettingsSync.qml:33-34` |
| Fullscreen idle inhibit | Requires investigation | no window rule; relies on apps using the idle-inhibit protocol |
| Window switcher (Alt+Tab) | Missing | `binds.lua:74` only "previous workspace"; Mission Control exists |
| Capture (screenshot, record, OCR, pin) | Working | `CapturePanel.qml`, `capture.sh` |
| Accessibility: focus ring, 415 `Accessible.` uses, motion full/reduced/off, font scale | Working (partial) | `FocusRing.qml`, `ConfigData.qml:15` |
| Config backup / export / restore from UI | Missing | only installer backups + `.broken` |
| Desktop diagnostics | Partial | Sensors panel, `./install.sh doctor`, `hypr-crashlog`; no "failed services" view |
| Dev workflow helpers | Partial | `modules/dev` = Docker only |

---

## D. Issues and technical debt

| # | Pri | Issue | Evidence | Impact |
|---|---|---|---|---|
| D1 | P1 | Five action vocabularies, no registry | table in A | Blocks 4.2-4.5; duplicated logic; inconsistent behaviour |
| D2 | P1 | Display/workspace layout keyed by connector name, one global layout | `~/.config/hypr/settings/displays.lua`, `workspaces.lua` | Wrong layout when ports/docks change; no per-setup memory |
| D3 | P1 | CI's Hyprland config check is skipped on **all 6** fixture machines (`hyprland --verify-config` segfaults, Hyprland bug) | `tests/lint.sh` output today; journal shows same crash in `Config::Lua::CConfigManager` destructor | A broken `*.lua` would ship; only `luac -p` syntax is checked |
| D4 | P1 (investigate) | `qs` uses **553 MB RSS (353 MB anon), 69 threads** after 1h26m | `/proc/1681/status`; only 2 `LazyLoader`s (`shell.qml`) | Laptop memory; unknown which surfaces stay resident |
| D5 | P2 | Silent command failures | 4 `onExited` checks in the whole shell | User can't tell why a toggle/action did nothing |
| D6 | P2 | Caps-lock OSD spawns `cat` every 500 ms, **on by default** | `Osd.qml:80,92`, `ConfigData.qml:88` | ~170k process spawns/day; small but constant battery cost. Event-driven fix: `bindn` on `Caps_Lock` → IPC read |
| D7 | P2 | Displays page goes stale on hotplug while open | `SettingsPageDisplays.qml:49` one-shot load, no `Hyprland` connection | Apply could write a layout for screens that left |
| D8 | P3 | Dock trash/downloads widgets shell out every 5 s while shown | `DockWidget.qml:427` | Minor; `FolderListModel` watches dirs |
| D9 | P3 | Clipboard store has no byte cap for images | `clipstore:32-42` | Disk growth with big screenshots |
| D10 | P3 | Battery charge limit only via `asusctl` | `SettingsPagePower.qml:19-26` | Non-ASUS laptops (generic `charge_control_end_threshold`) get nothing |
| D11 | P3 | Stale allow rule for removed `hosts/flow-x13/...` | `.claude/settings.local.json:6` | Harmless, exact-match; clean up |

No P0 found: settings writes are debounced and validated, secrets aren't in files, nothing runs as root by default.

---

## E. Requested features — implementation plans

### E1. Display management (4.1) — P1, L

**Reuse:** editor UI, keep-or-revert countdown, `monitors.lua` `apply_displays()` via `hyprctl eval`, `newScreen` fallback.
**Redesign:** move the logic out of the page into a `Displays.qml` singleton (one source of truth). Settings page,
Control Center card, presets, `Super+P` and the auto-switch all call it.

- **Identity.** Key each output by `description` (make model serial; Quickshell `HyprlandMonitor.description`,
  Hyprland `monitoraddedv2` carries it — both verified present in the installed versions). Connector name is the
  fallback when two identical monitors have no serial. Hyprland's `desc:` monitor selector exists in the 0.57.2
  binary; **spike needed** to confirm it works through `hl.monitor({ output = "desc:…" })`. If not, resolve
  description → connector in Lua from `hl.get_monitors()` before applying (same result).
- **Hotplug.** `Hyprland.rawEvent` on `monitoraddedv2` / `monitorremovedv2` / `configreloaded` → `refreshMonitors()`.
  No polling. Editor refreshes live and warns "screen X left, changes discarded".
- **Presets.** `Config.displays.presets: [{ id, name, outputs: { "<desc>": { mode, position, scale, transform, mirror, disabled, vrr, bitdepth } }, auto, workspaces? }]`.
  Built-ins generated from what is connected, never stored with fixed names: *Laptop only*, *External only*, *Extend*,
  *Mirror*. User presets: save current, rename, delete, set default, apply.
  A preset is *available* when every enabled output in it is connected; unavailable ones show greyed with "needs <name>".
- **Auto-switch (optional, per preset).** On a monitor-set change, if exactly one `auto` preset matches the
  connected set, apply it with an OSD "Switched to Desk · Undo" (5 s). Otherwise keep today's `newScreen` rule.
  Same model as GNOME (layout per monitor set) and kanshi (profile active when all its outputs are connected; verified man page).
- **Control Center.** One compact *Displays* row (current mode chip + chevron) shown only when >1 screen is
  connected or a preset exists. Dropdown: each screen with on/off, Extend / Mirror / Only <screen>, presets,
  "Display settings…". Controls built from what is connected.
- **Editor additions.** Identify (big number overlay on each screen for 2 s), "primary" mapped to what Hyprland
  actually has (no primary concept in Hyprland): workspace 1 + where bar/dock/notifications go — label it
  "Main screen" with that explanation. Mode list only from `availableModes`; scale list only values Hyprland accepts
  for that mode (it silently rounds otherwise). Validate no overlap / no gap before Apply.
- **Migration 0007:** rewrite `displays.lua`, `workspaces.lua`, `bar.hiddenOn`, `dock.hiddenOn` keys from
  connector to description (keep connector when unknown).
- **Risk:** `hyprctl eval` of a mode the screen refuses → existing countdown covers it. Auto-switch must never
  disable the only working screen: refuse a preset that leaves zero enabled outputs.

### E2. Control Center customization (4.2) — P2, M

Already: reorder, large/small, hide, styles, width, fold, live preview. Add only:
- **Custom tiles** from the action registry (E4): any user button or toggle can be placed as small or large tile.
- **Displays card** (E1) and a **Presets** dropdown entry.
- **Layouts:** "Reset to default" + 2 starting layouts (*Laptop compact*, *Everything*). No free-form grid: keeps it compact.
- Cap visible small toggles per row by width (already responsive); overflow goes to a "More" fold, not a scroll.

### E3. Global keyboard shortcuts (4.3) — P1, M

Keep **one** system: `binds.lua` + `settings/keybinds.lua`. Reject adding Quickshell `GlobalShortcut` as a second path.
- `Config.keybinds.custom: [{ keys, action: "<action id>" }]`; written into `settings/keybinds.lua`;
  `binds.lua` binds each to `qs ipc call actions run <id>`. Every action (built-in, app, preset, toggle) is bindable.
- Conflict check covers built-in + custom; on conflict show who owns the combo with **Reassign** (moves it) instead of refusing.
- Settings → Keyboard Shortcuts gets "Add shortcut" (pick action, record keys). App launch = an action of kind `app`.
- Applying still needs `hyprctl reload` (current behaviour, `SettingsPageKeybinds.qml:113`); acceptable, one reload per save.

### E4. Central actions, buttons and toggles (4.4) — P1, L (foundation)

`Actions.qml` singleton = the registry. **One action, many surfaces.**

```
{ id, name, icon, description,
  kind: "button" | "toggle",
  run:  { type: "app"|"command"|"terminal"|"open"|"snippet"|"internal"|"preset"|"sequence"|"shell", argv: [...], cwd?, steps? },
  off?: { … },                         // toggles: action when turning off
  state?: { type: "internal"|"command"|"unit"|"process", … },   // toggles: how real state is read
  confirm?: bool, timeoutSec?: 30, when?: <condition>, showIn: ["launcher","controlcenter","bar","corner"] }
```
- **Built-ins migrate in** from `Search.systemActions`, `BarActions.panels`, `HotCornerActions.list`, Control Center
  toggles. Old strings (`run:`, `panel:`) keep working as aliases (migration for `settings.json`).
- **Runner** (one place): `argv` arrays executed without a shell by default; `shell` is an explicit, labelled type.
  Timeout, exit code, stderr tail → toast on failure, line in `~/.local/state/hyprism/actions.log` (rotated, 256 KB).
  Long-running: tracked process with Stop in the toast; detached only for `app`.
- **Toggle state, real not visual:** `internal` binds to a shell property (Caffeine, Night Light, DND);
  `unit` = `systemctl --user is-active` (or system); `process` = `pgrep -x`; `command` = exit 0 means on.
  Re-checked after running, when a surface opens, and on an optional interval **only while visible**. No background polling.
- **Security:** never root by default. `sudo`/`su`/`doas` refused (no TTY); `pkexec` allowed with an "asks for admin
  password" badge. Arguments never string-concatenated into a shell. Validation on save (binary exists on `PATH`,
  icon valid). Settings is the only editor; the file is yours, so no further sandbox (stated in docs).
- **Sequence** (covers your "Development mode"): ordered steps of other actions with optional wait; no loops,
  no branches. That is the line before over-engineering.
- **Settings → Actions** page: list, create, edit, test-run (shows output), where-shown chips.
- IPC: `qs ipc call actions run|toggle|list <id>`.

### E5. Context-aware controls (4.5) — P2, S-M

Part of E4, not a separate service: a small `Conditions` helper with **structured** predicates (no string eval):
`screens >= n`, `external`, `preset available <id>`, `app running <class>` (Hyprland toplevels), `on battery`,
`wifi <ssid>`, `power mode`, `hardware <flag>` (replaces `ControlCenter.available()` and Search's `has` map).
All reactive bindings on existing services → event-driven by construction.

---

## F. Independent recommendations

| # | Name | Cat. | Problem → benefit | Proposal | Deps | Cx | Perf / maint | Risk | Pri | Verdict |
|---|---|---|---|---|---|---|---|---|---|---|
| F1 | Fix CI Hyprland check | Reliability | D3: config errors ship | Start a headless nested Hyprland per fixture in CI (`tests/nested.sh` already does it) and fail on Lua errors in its log | none | S | CI +1-2 min | flaky headless | P1 | Implement |
| F2 | Memory profile of `qs` | Perf | D4 553 MB | Measure RSS with surfaces disabled one at a time; wrap heavy, rarely used ones (Settings app, Mission Control, Calendar, Weather panel, Welcome) in `LazyLoader` with `active` on open | none | M | likely −100-250 MB (unverified until measured) | first-open delay | P1 | Implement after measuring |
| F3 | Display switcher `Super+P` | UX | Fast projector-style switch (Windows Win+P, Plasma) | Overlay listing Extend/Mirror/Only X/presets, keyboard driven | E1 | S | none | — | P2 | Implement |
| F4 | Settings snapshots + export/import | Recovery | Heavier customization = more to lose | Before Apply of displays/keybinds/actions and on every migration: copy `settings.json` + `hypr/settings/` to `~/.local/state/hyprism/snapshots/<time>/` (keep 10). Settings → About: Restore, Export (.tar.gz), Import (validated through `Config.repair`) | none | M | tiny | import of foreign paths | P2 | Implement |
| F5 | Caps-lock event-driven | Perf | D6 | `bindn = , Caps_Lock` → `qs ipc call osd caps` reads LED once | none | S | removes 2 spawns/s | — | P2 | Implement |
| F6 | Alt+Tab window switcher | Productivity | Missing; Mission Control is heavier | Hold-Alt list of windows (MRU from Hyprland focus history), current workspace first | none | M | none idle | key-release edge cases | P2 | Your call (J5) |
| F7 | Desktop health view | Diagnostics | Failures are invisible | In System panel: failed user units (`systemctl --user --failed`), last Hyprland crash (`hypr-crashlog`), last action errors (E4 log), shell warnings count. On open only | E4 log | S | none | — | P2 | Implement |
| F8 | Project launcher source | Dev | Opening a repo = several steps | Launcher source `projects`: git repos under configurable roots; Enter = editor, Ctrl+Enter = terminal there; actions for `docker compose up/down` when a compose file exists | E4 | M | `fd` once per open, cached | — | P3 | Implement later |
| F9 | Generic charge limit | System | D10 | Use `charge_control_end_threshold` when present; needs a udev rule for write access (system step, asks first) | udev | S | none | firmware quirks | P3 | Implement |
| F10 | Fullscreen idle inhibit | System | Video in some apps lets the screen sleep | Window rule `idle_inhibit fullscreen` for all windows, toggle in Settings > Idle | none | S | none | — | P3 | Implement |
| F11 | Clipboard byte cap | Reliability | D9 | Skip images > N MB, prune by total size | none | S | — | — | P3 | Implement |
| F12 | Notification inline reply | UX | Chat apps' reply action | Text field when the notification has an `inline-reply` action | none | S | — | — | P3 | Defer |
| F13 | Action arguments | Productivity | "search Jira for X" style | Raycast-style typed argument prompts on an action (Raycast documents `argument1 {type, placeholder}`, verified) | E4 | M | — | UI complexity | Exp | Defer |
| F14 | Workspace profiles (save/restore app windows) | Workflow | 6.3 | Not now: Hyprland can't restore app state; a *sequence* action (E4) + display preset covers the useful 80% | E4 | L | — | flaky restore | — | Reject (use E4) |
| F15 | kanshi/shikane daemon | Display | — | Duplicates E1 with a second config; Quickshell already gets the events | — | — | +1 daemon | conflicting writers | — | Reject |
| F16 | Quickshell `GlobalShortcut` as 2nd shortcut path | Keys | — | Two shortcut systems | — | — | — | conflicts | — | Reject |
| F17 | Generic automation (triggers, loops, rules) | Automation | 6.2 | Only auto-applied display presets are automatic; everything else user-triggered. Predictable | — | — | — | — | — | Reject for now |

### Documentation (section 12)
Already present: `docs/ARCHITECTURE.md`, `docs/DECISIONS.md` + `docs/decisions/`, `CONTRIBUTING.md`, `docs/testing/`,
per-round `docs/audit/*`. So add only: **`docs/FEATURES.md`** (the inventory table from C, kept current per change)
and a **living `docs/ROADMAP.md`** (replaces per-round roadmaps). New ADRs: 0002 action registry, 0003 monitor identity.
No `DEVELOPMENT.md` (would duplicate `CONTRIBUTING.md` + `docs/testing`).

---

## G. Research findings

| Source | Finding | Used in |
|---|---|---|
| Mutter `meta-monitor-config-store.c` (verified) | `~/.config/monitors.xml`, one configuration per monitor set; monitor = connector + vendor + product + serial | E1 identity + per-set presets |
| kanshi(5)/(1) man pages (verified) | outputs matched by name or "make model serial"; a profile activates when all its outputs are connected | E1 auto-switch |
| KDE KScreen | per-output-set saved configs and Meta+P OSD — **unverified** (sources 404) | F3 (pattern also in Windows Win+P) |
| Raycast script-commands docs (verified) | `@raycast.schemaVersion/title/mode/icon`, modes `fullOutput/compact/silent/inline`, typed arguments | E4 schema, F13 |
| xdg-desktop-portal GlobalShortcuts v2 (verified); XDPH implements `CGlobalShortcutsPortal` (source, strongly implied) | apps can register global shortcuts through Hyprland | E3: list portal-registered shortcuts read-only later |
| Hyprland 0.57.2 binary (verified locally) | events `monitoradded(v2)`, `monitorremoved(v2)`, `configreloaded`; `desc:` selector present | E1 |
| Quickshell 0.3.2 qmltypes (verified locally) | `Hyprland.rawEvent`, `refreshMonitors()`, `HyprlandMonitor.description/lastIpcObject`, `GlobalShortcut(appid)` | E1, F16 |
| GNOME quick settings, macOS Control Center (domain knowledge, not re-fetched) | tile = toggle + chevron to a submenu; a module shows only when relevant | E1 CC row, E5 |
| Earlier rounds: `docs/research/feature-matrix.md` (HyDE, Omarchy, ML4W) | already adopted; not repeated | — |

Note: a free-model research pass returned unsourced claims and was discarded; only the items marked verified above
were checked against fetched sources or the installed binaries.

---

## H. Architecture proposal

```
                 ┌──────────── Settings (only editor) ────────────┐
                 │ Actions · Shortcuts · Displays/Presets · CC   │
                 └───────────────┬───────────────────────────────┘
                          Config (settings.json, snapshots F4)
          ┌──────────────┬───────┴────────┬─────────────────┐
     Actions.qml     Displays.qml     Conditions        existing services
  (registry+runner)  (state, apply,   (predicates over  (Sys, Machine, PowerMode,
          │           presets, events) services)          Caffeine, NightLight…)
          └───── used by ─────┬──────────┬──────────┬───────────┬──────────┐
                         Launcher   Control Center  Bar clicks  Hot corners  binds.lua → `qs ipc call actions run`
```
Rules: one registry, one runner, one display service; surfaces never run commands themselves; every apply path
goes through Config → SettingsSync → Hyprland as today. No new daemon, no new dependency.

---

## I. Prioritized roadmap

| Phase | Items | Depends on | Size |
|---|---|---|---|
| 0 Foundation | F1 CI check · F2 measure memory · E1 spike (`desc:` via `hl.monitor`) · runner + action log (part of E4) | — | M |
| 1 Actions | E4 registry; migrate built-ins (Search, BarActions, HotCorners, CC toggles) behind aliases; Settings → Actions; E3 custom shortcuts | 0 | L |
| 2 Displays | `Displays.qml` extraction (no visible change) → hotplug refresh (D7) → identity + migration 0007 → presets → CC Displays row → F3 `Super+P` → auto-switch | 0 | L |
| 3 Context + CC | E5 conditions; E2 custom tiles, layouts | 1, 2 | M |
| 4 Polish | F5, F4, F7, F2 LazyLoaders, F10, F11, F9, F6 (if wanted), docs FEATURES/ROADMAP + ADRs | 1 | M |
| Later | F8, F12, F13 | 1 | M |

Each phase: worktree branch → `tests/all.sh` + nested-desktop screenshots → merge to `develop` (= your live desktop).

---

## J. Decisions required

1. **Monitor identity by description** with migration 0007 rewriting saved layouts — OK?
2. **Auto-switch presets on hotplug:** off by default (opt-in per preset, with Undo toast) — or on?
3. **Shell commands in custom actions:** allow an explicit "Shell command" type (recommended), or argv-only?
4. **`pkexec` in actions:** allow with an admin-password badge (recommended), or forbid?
5. **Alt+Tab switcher (F6):** want it?
6. **Work branch:** develop is your live desktop. Recommend one worktree branch per phase, merged to develop when green.
7. Scope: approve phases 0-2 now and decide 3-4 after, or all at once?
