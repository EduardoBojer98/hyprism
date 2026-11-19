# ADR 0002: one action registry

Date: 2026-11-17. Status: accepted (round 3, phase 1; spec in `docs/history/audit/v4/AUDIT.md` E3–E5).

## Question

Spotlight, the bar, hot corners and the Control Center each had their own list of what they can do (Search's
system actions and menu actions, BarActions, HotCornerActions, the Control Center's `run`/`active` per tile), and
user actions lived only in the launcher (`launcher.actions`, a shell string). Toggles guessed their state. How do
the surfaces, user actions and shortcuts share one model?

## Decision

- `Actions.qml` is the one registry: built-ins (`BuiltinActions.qml`) plus your actions (`actions.list` in
  settings.json), each `{ id, name, icon, kind: button|toggle, run, off?, state?, when?, showIn, confirm? }`.
  A built-in wins over a user action with the same id. Surfaces only list `Actions.forSurface(...)` and call
  `Actions.run(id)`; old ids keep working through `Actions.aliases`.
- `when` is a structured object checked by `Conditions.qml` (screens, external, app, battery, wifi, powerMode,
  hardware, recording, preset). No string evaluation; an unknown key never holds.
- One runner for user commands: a managed Process with a 30 s limit (`timeoutSec`, 0 = none; TERM then KILL),
  exit code and the stderr tail, a notification through the shell's own notification server on failure, and a line
  in `~/.local/state/hyprism/actions.log` (kept to 256 KB plus one `.1`). Built-in commands stay detached, as before.
- `sudo`, `su` and `doas` are refused (no terminal to ask in); `pkexec` is allowed and marked "asks for admin
  password". Commands run as an argv without a shell unless the action says `shell` (then always shown as such).
- Toggle state is real: `internal` (a service property), `unit` (systemctl is-active), `process` (pgrep -x) or
  `command` (exit 0 = on). Read again after a run and when a surface opens; `interval` polls only while visible.
- Your shortcuts are `keybinds.custom` (`{ keys, action }`), written into `hypr/settings/keybinds.lua` by ThemeSync
  and bound in `binds.lua` as `custom-<n>` running `qs ipc call actions run <id>`; keys and id are checked again in
  Lua (plain characters only).
- Settings format 7 moves `launcher.actions` into `actions.list` and renames launcher history keys
  `custom:<name>` → `action:<id>`. A bad action is dropped alone, with a warning.

## Consequences

- One place to add an action; every surface and IPC (`actions run|toggle|list`) gets it.
- Confirmation from a surface other than Spotlight opens Spotlight to ask.
- Not yet: user actions as Control Center tiles (phase 3), the `preset` run type (a stub), a check that a command
  exists on PATH (Test in Settings shows exit 127 instead).
