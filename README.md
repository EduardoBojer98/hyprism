# linux-setup

My CachyOS + Hyprland setup for the ASUS ROG Flow X13 (GV301QC). KDE Plasma stays installed as a fallback session.

## Layout

| Path | What |
|---|---|
| `home/<app>/` | Stow packages, symlinked into `~` (`.config/hypr`, `.config/fuzzel`, ...) |
| `packages/*.txt` | Package lists by purpose |
| `system/NN-*.sh` | System changes (need sudo), safe to re-run, run in order |

## Install

```bash
sudo bash system/01-hardware.sh   # asusctl, charge limit tooling, hibernation
sudo bash system/02-desktop.sh    # Hyprland + tools, AMD-only GPU link, lid behaviour
stow -d home -t ~ hypr fuzzel mako scripts
```

Then log out, pick **Hyprland** at the login screen.

## Undo

- Dotfiles: `stow -d home -t ~ -D hypr fuzzel mako scripts` removes the links.
- Back to KDE: pick **Plasma** at the login screen. Nothing here changes KDE's config.

Secrets never go in this repo (see `.gitignore`).
