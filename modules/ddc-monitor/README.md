# Module: ddc-monitor

Control an external monitor from the desktop over DDC/CI: switch its input, to share it with another computer.

- **On when:** an external screen is connected on a real computer (not a VM).
- **Adds:** `ddcutil`, and loads the `i2c-dev` kernel module that DDC needs.
- **Set up sharing:** Settings → Displays → Shared Monitor.
- **Find the inputs:** `monswitch inputs` lists each monitor and the inputs it reports (read only); `monswitch setup`
  asks in a terminal and writes `~/.config/monswitch.conf`. Settings reads the same list.
- **Not every monitor supports it:** `ddcutil detect` lists the ones that do. Some need DDC/CI switched on
  in their own menu.
- **Tested on:** the owner's Flow X13 with a 1440p monitor on HDMI; a fake config in `tests/scripts.sh`.
