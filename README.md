# linux-setup

My CachyOS + Hyprland desktop for the ASUS ROG Flow X13 (GV301QC, 2021), kept in one repo so the
whole setup can be rebuilt. KDE Plasma stays installed as a fallback session and is never modified.

- **Hyprland 0.56** with a modular **Lua** config (hyprlang is deprecated since 0.55)
- **Quickshell** shell written for this machine: top bar with tray, macOS-style Control Center,
  auto-hiding dock, Spotlight-style launcher (apps / files / clipboard), OSD, notifications, power menu
- **Dark liquid glass** look: translucent surfaces over Hyprland blur, hairline strokes,
  Catppuccin Macchiato accents across Hyprland, shell, Ghostty, Starship, fzf, lock screen and GTK
- **monswitch**: one key hands the shared Acer monitor to the work PC over DDC/CI and back
- Tablet mode (auto-rotate, on-screen keyboard button), lid handling, hibernation, 80 % charge limit

## Layout

| Path | What |
|---|---|
| `install.sh` | Links `home/` into `~` with GNU Stow; backs up anything in the way; `--undo` |
| `home/<package>/` | Stow packages, mirroring `~` (`hypr`, `quickshell`, `ghostty`, `fish`, `starship`, `scripts`, …) |
| `home/hypr/.config/hypr/hosts/` | Optional per-machine overrides (`<hostname>.lua`) |
| `packages/*.txt` | Package lists: `hardware`, `desktop`, `dev`, `apps` |
| `system/NN-*.sh` | System changes (sudo), safe to re-run, in order |
| `.githooks/pre-commit` | gitleaks secret scan, enabled by `install.sh` |

## Install (fresh CachyOS)

```bash
git clone git@github.com:EduardoBojer98/linux-setup.git ~/Documents/projects/linux-setup
cd ~/Documents/projects/linux-setup
./install.sh --system      # runs system/01..03 with sudo (asks first), then links the dotfiles
```

Then log out and pick **Hyprland** at the login screen. To only (re)link the dotfiles: `./install.sh`.
To preview: `./install.sh --dry-run`.

| Script | Changes |
|---|---|
| `01-hardware.sh` | asusctl + ROG Control Center, NVIDIA sleep services, nvidia-powerd off, `@swap` subvolume + 20 GB swapfile + resume params (hibernation) |
| `02-desktop.sh` | Hyprland and desktop packages, `/dev/dri/amd-igpu` udev link, lid behaviour (logind), Hyprland as default session |
| `03-apps.sh` | Shell tools, PHP/Composer, uv, gitleaks, Okular, OnlyOffice, Bitwarden |

Manual once per machine: battery limit (`asusctl battery limit 80`), Acer menu **DDC/CI on, Auto Source off**,
NVIDIA GPU on/off in **ROG Control Center → GPU Configuration** (needs a restart).

## Undo and rollback

| What broke | Do this |
|---|---|
| Dotfiles | `./install.sh --undo` removes the links and offers to restore the last backup (`~/.local/state/linux-setup/backups/`) |
| Hyprland session | Pick **Plasma** at the login screen. From a black screen: Ctrl+Alt+F3, log in, `sudo systemctl restart plasmalogin` |
| A package update / system script | Boot menu → **Snapshots** → pick the snapshot before the change, then `sudo limine-snapper-restore`. pacman takes snapshots automatically (snap-pac) |
| Hibernation | `sudo rm /etc/limine-entry-tool.d/50-hibernate.conf && sudo limine-update` |

## Keybinds (Super = Windows key)

| Keys | Action |
|---|---|
| `Super+Space` | Launcher, Apps tab: apps, calculator, system actions, `> command`, web search |
| `Super+Shift+Space` | Launcher, Files tab (search your home folder) |
| `Super+V` | Launcher, Clipboard tab |
| In the launcher | `Tab`/`Shift+Tab` or `Ctrl+1/2/3` switch tabs, `↑↓` move, `Enter` open, `Esc` close |
| `Super+Enter` | Terminal (Ghostty) |
| `Super+B` / `Super+E` | Firefox / Dolphin |
| `Super+Q` | Close window |
| `Super+F` / `Super+Shift+F` | Fullscreen / maximise |
| `Super+T` | Float / tile window |
| `Super+J` | Flip split direction |
| `Super+Arrows` / `Super+Shift+Arrows` | Focus / move window |
| `Super+1…0` / `Super+Shift+1…0` | Go to / send window to workspace (1–5 Acer, 6–10 laptop) |
| `Super+Tab` | Previous workspace |
| `Super+S` / `Super+Shift+S` | Scratchpad / send window to scratchpad |
| `Super+M` | Acer monitor → work PC / back |
| `Super+L` | Lock |
| `Super+Shift+E` | Log out |
| `Super+Shift+R` | Reload Hyprland config |
| `Super+Shift+C` | Colour picker |
| `Print` / `Shift+Print` | Screenshot area to file / area into the editor (satty) |
| `Alt+Shift` | Keyboard layout US ↔ Serbian Latin |
| `Super+drag` / `Super+right-drag` | Move / resize window |
| Touchpad 3-finger swipe | Switch workspace |

Bar: workspaces · clock · tray · keyboard layout · **status pill** (Wi-Fi, Bluetooth, volume, battery;
scroll = volume) · power menu. Clicking the status pill opens the **Control Center**: Wi-Fi and Bluetooth
(toggle + pick network/device), on-screen keyboard, Acer monitor, power mode, brightness, output and
microphone volume + device, shortcut to ROG Control Center. Dock: launcher button, pinned apps, running apps
(middle-click = new window). Push the pointer to the bottom edge to show the dock.

## Shared monitor (monswitch)

Laptop = Acer input HDMI 1 (`0x11`), work PC = HDMI 2 (`0x12`). `Super+M` or the bar button switches.
A watcher follows switches made with the monitor's buttons. While the PC has the monitor, Hyprland
mirrors the laptop onto that port (so the Acer doesn't drop the PC input) and moves workspaces to the laptop.

## Per-machine differences

Shared config describes this laptop. For another computer add `home/hypr/.config/hypr/hosts/<hostname>.lua`
(loaded last, can override anything) and keep machine-only packages out of the shared lists.

## Secrets

Never in this repo: SSH/GPG keys, API keys, tokens, `.env` files (`.gitignore` blocks the common names,
and the gitleaks pre-commit hook scans every commit). Keep them in `~/.ssh`, Bitwarden, or a local
`~/.config/secrets.env` sourced from outside the repo.

## Maintenance

- Conventional Commits (`feat:`, `fix:`, `chore:`), one change per commit.
- Tag working states (`v1.0`, `v1.1`, …) and note them in `CHANGELOG.md`.
- After a Hyprland or Quickshell update: `hyprctl configerrors` and `qs log` show breakage first.
