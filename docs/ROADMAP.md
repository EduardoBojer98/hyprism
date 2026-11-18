# Roadmap

What is left, newest decisions first. Done work moves to `CHANGELOG.md`; the reasons to `DECISIONS.md`.

## Open

- Displays: the bar's per-screen settings (`bar.monitors`) still keyed by port name. The launcher still opens on
  the focused screen; `Displays.popupScreen` (the main screen, else the focused one) is there for it.
- Displays: matching by description is untested on real hardware (test desktops have no descriptions).
- Actions: no check that a command exists (Test shows exit 127); Control Center tiles are small only.
- Memory: the shell is about 400 MB on a test desktop, mostly Qt and the theme's images; the surfaces are
  measured, nothing big is left there.
- Test desktops (`tests/nested.sh`) don't load `~/.config/hypr/settings/*.lua` (Hyprland follows the
  `hyprland.lua` link into the repo), so binds and settings written there can't be tested there yet.
- `qs ipc call config set … '[…]'`: the command line drops the outer brackets of a list; start the value with a
  space (`' [ … ]'`).

## Later

- Global shortcuts through the portal (XDPH implements it) for apps that ask.
