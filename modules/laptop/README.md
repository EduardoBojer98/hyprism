# Module: laptop

Lid behaviour for any laptop: sleep when the lid closes, keep running when an external screen is connected.

- **On when:** the computer is a laptop (`machine.form`).
- **Adds:** one system file, `/etc/systemd/logind.conf.d/50-hyprism-lid.conf`.
- **Hibernate:** used after sleep only where the computer can already do it (see the `hibernate` module).
- **Tested on:** fixtures `laptop-intel`, `laptop-hybrid-nvidia`, `hidpi-single`; the owner's Flow X13.
