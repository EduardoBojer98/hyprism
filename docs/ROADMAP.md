# Roadmap

What is left, newest decisions first. Done work moves to `CHANGELOG.md`; the reasons to `DECISIONS.md`.

## Open

- Displays: the bar's per-screen settings (`bar.monitors`) still keyed by port name. The launcher still opens on
  the focused screen; `Displays.popupScreen` (the main screen, else the focused one) is there for it.
- Displays: matching by description is untested on real hardware (test desktops have no descriptions).
- Actions: Control Center tiles are small only.
- Memory: the shell is about 400 MB on a test desktop, mostly Qt and the theme's images; the surfaces are
  measured, nothing big is left there.
- Test desktops (`tests/nested.sh`) don't load `~/.config/hypr/settings/*.lua` (Hyprland follows the
  `hyprland.lua` link into the repo), so binds and settings written there can't be tested there yet.
- `qs ipc call config set … '[…]'`: the command line drops the outer brackets of a list; start the value with a
  space (`' [ … ]'`).
- Themes, look and feel pass (asked 2026-11-20; contrast and the system panel's overflow are done):
  - Every popup in every theme, light and dark, side by side from `tests/nested.sh`: spacing, alignment and the
    type scale the same across the system panel, Control Center, calendar, weather, power, launcher and
    notifications; nothing clipped or elided at 12 px caption / 13 px label.
  - Wide display fonts (Poster, Monolith): the system panel shrinks big numbers and halves stat grids; check
    the other popups for the same squeeze (calendar header, weather, Control Center tile labels).
  - Choose: one theme reworked in depth first, or a polish pass over all three. Not started; needs your pick.
