# Audit — 2026-10-31

Machine: ROG Flow X13 (GV301QC), CachyOS, Hyprland 0.57.0 (Lua config), Quickshell shell.
Status keys: ✅ works · ⚠️ works but messy · ❌ broken.

## Inventory

### Repo layout

| Path | What it is | Where it ends up |
|---|---|---|
| `install.sh` | One entry point: `--dry-run`, default (link dotfiles), `--system` (packages + system steps, then link), `--undo` | — |
| `home/<pkg>/` | GNU Stow packages, each mirrors `$HOME` | symlinked into `~` by `stow -d home -t ~` |
| `home/hypr/` | Hyprland (`hyprland.lua` → `modules/*.lua`, then `hosts/<hostname>.lua`), hypridle, hyprlock, hyprpaper | `~/.config/hypr` (whole dir is one symlink) |
| `home/hypr/.config/hypr/settings/*.lua` | Written by the Settings app (displays, input, keybinds, theme); gitignored | same dir |
| `home/quickshell/` | The whole shell: bar, dock, launcher (Spotlight), notifications, OSD, lock-free UI, Settings app (`SettingsApp.qml` + `SettingsPage*.qml`), theme tokens (`Theme.qml`) | `~/.config/quickshell` (whole dir) |
| `home/scripts/.local/bin/` | Helper scripts: `asusfan`, `clipstore`, `emojipick`, `monswitch`, `nv`, `panel`, `screenshot`, `screentext`, `startup-apps` | `~/.local/bin/*` (per-file links) |
| `home/fish/` | `conf.d/tools.fish`, `conf.d/hyprland-igpu.fish` (hides NVIDIA EGL in Hyprland only) | `~/.config/fish/conf.d/*` |
| `home/fuzzel/` | Fuzzel (emoji picker UI) | `~/.config/fuzzel` |
| `home/ghostty/` | Terminal config (Ghostty, not Alacritty) | `~/.config/ghostty` |
| `home/starship/`, `home/fastfetch/` | Prompt, system info | `~/.config/…` |
| `home/wireplumber/` | `51-flow-x13-mic.conf` (internal mic fix) | `~/.config/wireplumber/wireplumber.conf.d/` |
| `home/wallpapers/` | Two bundled wallpapers | `~/Pictures/Wallpapers/` |
| `packages/desktop.txt` | Hyprland session packages | installed by `system/02-desktop.sh` |
| `packages/dev.txt`, `packages/apps.txt` | Dev tools, everyday apps | installed by `system/03-apps.sh` |
| `system/02-desktop.sh` | Packages + `/etc/systemd/logind.conf.d/50-lid.conf` + default session in `/etc/plasmalogin.conf` | `/etc` (sudo) |
| `system/03-apps.sh` | Packages only | — |
| `system/hosts/rog-flow-x13/` | `10-hardware.sh` (asusctl, NVIDIA sleep services, btrfs swap + hibernate, Limine resume cmdline, sleep.conf), `20-igpu.sh` (udev `/dev/dri/amd-igpu` link), `packages.txt` | `/etc`, `/boot`, `/etc/fstab` (sudo, only on that hostname) |
| `.githooks/pre-commit` | gitleaks secret scan; `install.sh` sets `core.hooksPath` | — |
| `README.md`, `DESIGN.md`, `docs/USER-GUIDE.md` | Docs | — |

Verified: `./install.sh --dry-run` → 0 files to back up, all 10 packages already linked.
Secrets: `gitleaks git` (53 commits) and `gitleaks dir` → no leaks.
Hyprland: `hyprctl configerrors` → empty.

### Sync gaps (on this machine, not in the repo)

Checked by subagent, key items re-verified with `pacman -Qo` / `ls`.

| Path | Note |
|---|---|
| **Juhradial MX** (MX Master 4 buttons/haptics): `~/.config/juhradial/`, `~/.config/systemd/user/juhradialmx-daemon.service`, `~/.config/autostart/juhradial-mx.desktop`, `/etc/udev/rules.d/70-juhradialmx-uaccess.rules`, `99-juhradialmx.rules`, `/etc/modules-load.d/juhradial-uinput.conf` | Whole stack is hand-installed; no package owns the `/etc` files. Biggest gap. |
| **ydotool**: `/etc/udev/rules.d/60-ydotool-uinput.rules`, user unit enabled | Not created or enabled by any script |
| `/etc/modprobe.d/nvidia-rtd3.conf` (`NVreg_DynamicPowerManagement=0x02`) | Not in repo, and contradicts `system/hosts/rog-flow-x13/10-hardware.sh:22-25` ("Runtime D3 not supported", removes a similar file). Drift; needs a decision. |
| `~/.config/autostart/org.flameshot.Flameshot.desktop`, `…rog-control-center.desktop` | Autostart entries outside `modules/autostart.lua` |
| `~/.config/monswitch.conf` | Config for repo script `monswitch`; no example in repo |
| `~/.config/libinput-gestures.conf` | Probably dead (Hyprland has native gestures); check |
| `~/.config/alacritty/` | You said Alacritty; repo ships **Ghostty**. Pick one. |
| `~/.config/flameshot/`, `gtk-3.0/`, `gtk-4.0/`, `xsettingsd/` | Theming/screenshot settings (GTK partly written live by `ThemeSync.qml`) |
| `~/.config/mimeapps.list`, `user-dirs.dirs` | Default apps; Settings app writes mimeapps — should stay local |
| `~/.config/git/`, `~/.config/Code/` | Personal (email/tokens possible) — keep out, or ship a template only |
| `~/.config/fish/conf.d/nvm.fish`, `~/.local/bin/{node,npm,npx,claude}` | Installed by nvm / Claude Code itself — fine outside repo |
| `/etc/X11/xorg.conf.d/00-keyboard.conf` | localectl-generated, X11 only — fine |
| `/etc/environment` | Not inspected (values) |

### Dead config

None found. Every Lua module is required from `hyprland.lua`, every QML file is used by name
(Settings pages load as `"SettingsPage" + section + ".qml"`, `SettingsApp.qml:198`), every script is
called from a bind, QML or autostart. Wallpapers are found by folder scan. `settings/language.lua`
is loaded by `env.lua:20` but only exists after the Settings app writes it (expected).

### Keybinds

All defined in `home/hypr/.config/hypr/modules/binds.lua` (Mod = Super). `settings/keybinds.lua`
(user overrides from Settings) is empty. Live `hyprctl binds` = 80 binds, identical to config,
**no duplicates, no conflicts**. No global shortcuts in QML.

| Keys | Action | Line |
|---|---|---|
| Super (tap) / Super+Space | Spotlight | 20-21 |
| Super+Shift+Space | Spotlight: files | 27 |
| Super+A | All applications | 28 |
| Super+Return | Terminal (Ghostty) | 18 |
| Super+E | File manager (Dolphin) | 22 |
| Super+B | Browser (Firefox) | 24 |
| Super+I | Settings | 23 |
| Super+V | Clipboard history | 25 |
| Super+. | Emoji picker | 26 |
| Super+C | Control Center | 29 |
| Super+N / Super+Shift+N | Notifications / Do Not Disturb | 30-31 |
| Super+W | Mission Control | 32 |
| Super+Q | Close window | 35 |
| Super+F / Super+Shift+F | Fullscreen / maximise | 36-37 |
| Super+T | Float / tile | 38 |
| Super+J | Swap split direction | 39 |
| Super+H | Minimise | 40 |
| Super+arrows / Super+Shift+arrows | Focus / move window | 41-44 |
| Super+left/right mouse drag | Move / resize window | 45-46 |
| Super+1…0 / Super+Shift+1…0 | Go to / send to workspace | 49-53 |
| Super+Tab | Previous workspace | 54 |
| Super+wheel | Prev/next workspace | 55-56 |
| Super+S / Super+Shift+S | Scratchpad show / send | 57-58 |
| Print / Shift+Print | Screenshot area / whole screen (Flameshot) | 61-62 |
| **Alt+Shift+S** | Screenshot area (Flameshot) ✅ | 63 |
| Ctrl+Shift+Esc | Task manager | 64 |
| Super+Shift+T | Copy text from screen (OCR) | 65 |
| Super+Shift+C | Colour picker | 66 |
| Super+M | Hand the Acer over to the work PC and back (DDC/CI) | 69 |
| Tablet / lid switches | Tablet mode, lid handling | 72-75 |
| Super+L | Lock | 78 |
| Super+Shift+R | Reload Hyprland | 79 |
| Super+Shift+E | Log out | 80 |
| Volume, mic mute, brightness, media keys | wpctl / brightnessctl / playerctl | 85-94 |

Issue: **no keyboard-layout switch key.** `settings/input.lua` has `kb_options = ""` (you picked
"None" in Settings > Keyboard), so US ↔ Serbian Latin only switches from the bar widget. The default
in `modules/input.lua:5` is Alt+Shift — which would also clash in spirit with Alt+Shift+S. Decision needed.

### Packages

Declared: 50 names in `packages/{desktop,dev,apps}.txt` + `system/hosts/rog-flow-x13/packages.txt`,
all from official/CachyOS repos (no AUR helper needed). **All 50 are installed.** 11 of them are only
installed as dependencies (curl, ddcutil, fd, fzf, grim, jq, libnotify, libqalculate,
nm-connection-editor, slurp, tesseract) — fine, `pacman -S --needed` marks them on a fresh install.

Installed (276 explicit, 3 AUR) but **not declared**, that the setup relies on or you use daily:

| Package | Why it matters |
|---|---|
| `satty` | Used by `modules/rules.lua` (screenshot annotate window) |
| `firefox`, `dolphin` | Super+B / Super+E and defaults in `ConfigData.qml` |
| `git`, `docker`, `docker-compose`, `github-cli`, `python` | Dev tools (docker service is enabled by hand, not by a script) |
| `bluez`, `bluez-utils` | Bluetooth (service enabled by hand) |
| `power-profiles-daemon` | **disabled**; asusd handles profiles — confirm that's intended |
| `udisks2` | **disabled as a service** (it's D-Bus activated, so probably fine) — test USB auto-mount |
| `ydotool`, `alacritty`, `hyprshot` | Not referenced by any repo config → probably leftovers |
| `google-chrome`, `visual-studio-code-bin`, `open-webui-desktop-bin` (AUR) | Your apps; `code` *and* `visual-studio-code-bin` are both installed |
| Nvidia stack (`nvidia-utils`, `linux-cachyos*-nvidia-open`, `nvidia-prime`, `switcheroo-control`) | CachyOS installs these itself (chwd); keep undeclared, note in host docs |

Not installed: `gnome-keyring` (secret service comes from **KWallet** — works for browsers in KDE,
must be tested in Hyprland), `udiskie`, `cliphist` (clipboard history is the repo's own `clipstore`).
Groups: user is in `docker`, `input`, `video`; not in `i2c`, but `ddcutil detect` works without it.
