# Module: logitech

Logitech mice and keyboards: buttons, scroll wheel, DPI, battery level and haptics, through Solaar.

- **On when:** a Logitech device or receiver is plugged in (`peripherals.logitech`).
- **Adds:** Solaar (free, in both distros' own repos), started hidden in the tray at login.
- **MX Master 4 haptics:** supported by Solaar 1.1.17 and newer. Try one:
  `solaar config 'mx master 4' haptic-play 'HAPPY ALERT'`. Solaar's rules can play one on any event.
- **Coming from JuhRadial MX (before 2.0):** it keeps working until you remove it with its own uninstaller.
  Run only one of the two.
- **Tested on:** the owner's MX Master 4 (see the checklist in the final report).
