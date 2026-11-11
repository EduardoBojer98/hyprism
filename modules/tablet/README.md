# Module: tablet

Touch screens and 2-in-1 laptops: an on-screen keyboard, and tablet mode (rotation, bigger controls) when the
screen is folded back.

- **On when:** a touch screen or a tablet-mode switch is found (`input.touchscreen`, `input.tablet_switch`).
- **Adds:** the on-screen keyboard (squeekboard; not packaged on Fedora), `iio-sensor-proxy` for rotation, and
  the hinge binds, using the switch's name from `hardware.toml`.
- **Tested on:** fixture `laptop-hybrid-nvidia`; the owner's Flow X13.
