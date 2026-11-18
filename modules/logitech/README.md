# Module: logitech

Logitech mice and keyboards: buttons, gestures, scroll wheel, DPI, SmartShift and battery level, through OpenLogi.

- **On when:** a Logitech device or receiver is plugged in (`peripherals.logitech`).
- **Adds:** OpenLogi (`openlogi-bin` from the AUR on Arch; on Fedora install the `.rpm` from
  https://github.com/AprilNEA/OpenLogi/releases). Its agent (`openlogi-agent.service`) starts at login; open
  **OpenLogi** from the launcher to set buttons and gestures. Its udev rule gives you the device access, no group needed.
- **Coming from JuhRadial MX or Solaar:** remove them; run only one tool that grabs the mouse.
- **Tested on:** the owner's MX Master 4 (Bolt receiver).
