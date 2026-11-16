# Bar item: Updates

How many updates are waiting: system packages (on Arch also AUR and Flatpak), and new Hyprism changes on your
channel. Hidden while there are none. Click runs the whole update in a terminal (`./install.sh update`: system,
Flatpak, Hyprism); right-click looks again now. It looks every hour (Hyprism every 6 hours); the tooltip says what
is waiting.

Its own settings (put their defaults in `defaults.json` under `settings`):

- `always` (false): show the icon even when nothing is waiting.

Shared settings: [docs/bar.md](../../../../../../../docs/bar.md).
