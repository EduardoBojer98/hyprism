# Module: logitech

Logitech mice and keyboards: buttons, gestures, scroll wheel, DPI, SmartShift and battery level, through OpenLogi.

- **On when:** a Logitech device or receiver is plugged in (`peripherals.logitech`).
- **Adds:** OpenLogi (`openlogi-bin` from the AUR on Arch; on Fedora install the `.rpm` from
  https://github.com/AprilNEA/OpenLogi/releases). Its agent (`openlogi-agent.service`) starts at login; open
  **OpenLogi** from the launcher to set buttons and gestures. Its udev rule gives you the device access, no group needed.
- **OpenLogi 0.9.0 bug:** its Actions Ring overlay can crash on a screen change at a fractional scale and
  busy-loop ([#1989](https://github.com/AprilNEA/OpenLogi/issues/1989)). The module restarts the overlay on every
  monitor change and caps the agent's journal output (`openlogi-agent.service.d/hyprism.conf`).
- **Gestures on Hyprland:** OpenLogi's own Mission Control and Show Desktop actions do nothing here. Use
  **Run shell command** with `qs ipc call actions run overview` (or any id from `qs ipc call actions list`).
- **Coming from JuhRadial MX or Solaar:** remove them; run only one tool that grabs the mouse.
- **Tested on:** the owner's MX Master 4 (Bolt receiver).
