# Module: laptop

Lid behaviour for any laptop: sleep when the lid closes, keep running when an external screen is connected.

- **On when:** the computer is a laptop (`machine.form`).
- **Adds:** one system file, `/etc/systemd/logind.conf.d/50-hyprism-lid.conf`.
- **Hibernate:** used after sleep only where the computer can already do it (see the `hibernate` module).
- **Tested on:** fixtures `laptop-intel`, `laptop-hybrid-nvidia`, `hidpi-single`; the owner's Flow X13.

## Charge limit

On laptops whose kernel exposes `charge_control_end_threshold` (not ASUS: `asusctl` owns it there), the optional step
`20-charge-limit.sh` stops charging at 80%.

- **Adds:** `/etc/tmpfiles.d/hyprism-charge-limit.conf`, applied at every boot.
- **Change the number:** edit the last field of that file, then `sudo systemd-tmpfiles --create /etc/tmpfiles.d/hyprism-charge-limit.conf`.
- **Undo:** `./install.sh uninstall`, or delete the file and run `echo 100 | sudo tee /sys/class/power_supply/BAT*/charge_control_end_threshold`.
