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

## Decisions (2026-10-31)

| Topic | Decision | Done |
|---|---|---|
| Terminal | Ghostty stays; Alacritty goes | `sudo pacman -Rns alacritty` (needs your password); `~/.config/alacritty/` can then be deleted |
| Overheating fix (made earlier today, see `~/thermal-debug/report.md`) | Keep it, put it in the repo | `system/hosts/rog-flow-x13/30-thermal.sh`: firmware fan control in Balanced, `/etc/modprobe.d/nvidia-rtd3.conf` (0x02), **temporary** LTS kernel as default boot entry. Verified live: kernel 6.18.55-lts, dGPU `suspended`, "Runtime D3: Enabled (fine-grained)", both fan curves off. The script itself was not re-run (needs sudo; the system already has these settings). |
| MX Master 4 | JuhRadial MX from github.com/JuhLabs/juhradial-mx | `system/hosts/rog-flow-x13/40-mx-master.user.sh` runs upstream's installer as your user (skips when installed; tested: skips). `install.sh --system` now runs `*.user.sh` steps without sudo. |
| Layout switch key | None; the bar widget is enough | no change |
| VS Code twice | Not a duplicate: `visual-studio-code-bin` *provides* `code`, only one package is installed | nothing to remove; `~/.config/Code - OSS` and `~/.vscode-oss*` are leftovers from an older OSS install |

Watch: asusd's **AC profile is Performance** (`asusctl profile get`). The thermal load test hit 95 °C in
Performance within 10 s. Right now the active profile is Balanced; if plugging in switches you to
Performance, set the AC profile to Balanced in ROG Control Center or Settings > Power.

## Findings (Phase 2) — tested live on 2026-10-31

✅ works · ⚠️ works but messy · ❌ broken · 🔧 fixed in this branch · 🖐 needs your hands

| Area | Status | Evidence / file |
|---|---|---|
| Hyprland starts, config | ✅ | `hyprctl configerrors` empty after every change; log has only the normal "wayland backend" probe error |
| Monitors | ✅ | eDP-1 1920x1200@120 ×1.2 at 480x1440, HDMI-A-1 2560x1440@144 ×1 at 0x0 (from `settings/displays.lua`) |
| Hotplug, input switch (Super+M) | 🖐 | `ddcutil detect` sees the Acer on i2c-6 without root; switching not exercised |
| GPU | ✅ | Hyprland on the AMD iGPU (`AQ_DRM_DEVICES=/dev/dri/amd-igpu`), NVIDIA EGL hidden, dGPU `suspended`; `nv <app>` runs one app on NVIDIA |
| Overheating | 🔧 | `system/hosts/rog-flow-x13/30-thermal.sh` (see Decisions) |
| Suspend / resume, lid | 🖐 | NVIDIA sleep services enabled; not exercised |
| Keyboard layouts | ✅ | us + rs(latin) on all keyboards; switch from the bar widget (no hotkey, your choice) |
| Keychron Q1 HE, touchpad | ✅ | listed by `hyprctl devices` |
| MX Master 4 | ✅/🖐 | juhradialmx-daemon active, HID++ connected, DPI applied; haptics need a physical check |
| **Minimise button in app title bars** | ❌→🔧 | Hyprland 0.57 drops `xdg_toplevel.set_minimized` (read in its source). New `plugins/minimize` + `~/.local/bin/hypr-plugins` (built and loaded at login). Tested on GTK3 and GTK4 windows in a nested Hyprland, then live. Wayland apps only; XWayland apps still ignore the button |
| Super+H / dock minimise | ✅ | Moves to `special:minimized` and back (tested) |
| Bar, dock, launcher, notifications, OSD | ✅ | Quickshell running, no QML errors in `qs log` after edits |
| Lock / idle | ✅/🖐 | hypridle restarted on its new config path; lock screen not opened (press Super+L once to check the wallpaper shows) |
| Audio | ✅ | PipeWire + WirePlumber, default out = Acer HDMI, mic = internal (with `51-flow-x13-mic.conf`) |
| Brightness, media, volume keys | ✅ | bound in `binds.lua:85-94`; tools present |
| Battery, power profiles | ⚠️ | Balanced, charge limit 80 %. asusd's **AC profile is Performance**, which hit 95 °C in 10 s in the load test |
| Wi-Fi, Bluetooth | ✅ | NetworkManager connected, adapter powered |
| Advanced network settings | ✅ | `nm-connection-editor` was declared but missing; installed 2026-10-31 |
| Flameshot (Print, Alt+Shift+S) | ❌→🔧 | With both monitors on, Flameshot 14 showed a broken "pick a monitor" screen: the script's XWayland setting never applied (the capture went to Flameshot's Wayland background copy), and under XWayland it crops the wrong part of the desktop. Now `flameshot screen -n N -e` for the monitor under the mouse; tested on both monitors. `screenshot all` saved twice; fixed |
| Clipboard history | ✅ | `wl-paste --watch clipstore store` running |
| Default apps | ⚠️ | https → Chrome, **PDF → Chrome** (Okular is installed), text → micro, images → Gwenview, folders → Dolphin. Change in Settings > Default Apps if you want Okular |
| Portals | ✅/🖐 | xdg-desktop-portal, -hyprland, -gtk active; browser screen share not exercised |
| Polkit agent | ✅ | hyprpolkitagent running |
| **Keyring / Secret Service** | ❌→🔧 | No `org.freedesktop.secrets` in Hyprland: Plasma runs `pam_kwallet_init` from an autostart entry that only shows in KDE. Added to `modules/autostart.lua`; after running it, `ksecretd` owns the name. 🖐 Check Chrome still shows your saved passwords |
| USB auto-mount | ⚠️ | No auto-mount daemon (udiskie not installed); Dolphin mounts on click |
| Settings app → tracked files | ❌→🔧 | Wallpaper, lock theme and idle timings were written into tracked files (the dirty tree at the start). Now in gitignored `hypr/settings/`, defaults in `hypr/defaults/`, seeded by `install.sh` |
| Hardcoded paths | ❌→🔧 | `SettingsPageAbout.qml` assumed `~/Documents/projects/linux-setup`; now resolved from the link |
| Secrets in repo | ✅ | gitleaks clean (history + tree); pre-commit hook active |
| Docker, Node, PHP, Python, Git, VS Code | ✅ | `docker ps` without sudo; node 24.22.1, npm 11.19.1, PHP 8.5.12, Python 3.14.8, git 2.56.0, VS Code 1.144.0 |
| KDE fallback | ✅/🖐 | `plasma.desktop` still listed; Hyprland-only bits are guarded (fish snippet checks `XDG_SESSION_DESKTOP`, autostart lives in Hyprland's config). Shared: GTK dconf (KDE re-applies Breeze). Log into Plasma once to confirm |
| Autostart entries in `~/.config/autostart` | ⚠️ | flameshot, rog-control-center, juhradial: only KDE runs these (Hyprland has no XDG autostart) |
| Package lists | 🔧 | all commented, missing ones declared (see Packages); `hyprshot` and `ttf-firacode-nerd` unused |
| Duplicate Flameshot background copies | ⚠️ | Two start at login (one by D-Bus activation, one from the session); harmless, the shortcut works with either |

## Phase 3 and 4 — fixes, restructure, verification (2026-10-31)

| Change | Status | Evidence |
|---|---|---|
| Settings: 24 pages grouped into 11 sections (Display, Appearance, Desktop, Input, Sound, Network & Bluetooth, Power & Battery, Keyboard Shortcuts, Default Apps, Startup Apps, System) | 🔧 | `SettingsApp.qml`; old page ids still open the right section (`qs ipc call settings open bluetooth`); screenshots of each group |
| New rows: Space around windows, lid behaviour (read only), MX Master buttons, Update from GitHub | 🔧 | gaps were rejected by the config schema at first; fixed and tested through the real save path (`gaps_out` 10 → 18 → 10) |
| Reset buttons | ❌→🔧 | Icons' Reset wiped all of Appearance, Appearance's wiped the icon theme; now each resets only its own options. Idle, Displays and Default Apps have no Reset (their files can be deleted, see the user guide) |
| Power menu | 🔧 | One **Power…** entry in the utility menu and the Control Center's power button open a centred card; 3/2 columns of tiles, compact rows on narrow screens, keyboard control; tested at 1600, 781 and 180 px wide |
| Bar temperatures and system dropdown | 🔧 | CPU + NVIDIA GPU in the bar ("Off" while it sleeps). Dropdown: CPU, built-in GPU, NVIDIA GPU, memory ("16 GB installed": Linux sees 15 GB because 0.5 GB goes to the built-in GPU), both GPUs' memory, disk, power, fans. The old dropdown asked the NVIDIA GPU every 2 s, which kept it awake; now every 10 s and only when already awake (tested: stays `suspended` with the dropdown open) |
| Fresh install | ✅ | Arch container, repo at a different path: `--dry-run`, install, re-run (idempotent), backups. Found and fixed: stow linked `~/.local`, `~/Pictures`, `~/.config/fish` as whole folders into the repo on an empty home. `onlyoffice-bin` is AUR on plain Arch |
| Unlisted packages | 🔧 | xdg-utils, glib2, fastfetch, cantarell-fonts, noto-fonts declared |
| Live shell restarts | ⚠️ | `qs kill` stops one copy only; restarting with `pkill -x qs; pkill -x quickshell; qs &` avoids two bars (README) |

### Still needs your hands 🖐
- Super+L once (wallpaper on the lock screen), Chrome saved passwords, minimise from a Chrome title bar
- Monitor hotplug, Super+M input switch, suspend/resume, lid close, MX haptics, browser screen share
- Log into KDE Plasma once to confirm the fallback
- Decide: asusd AC profile (Performance hit 95 °C), PDF default app (Chrome or Okular)
- After a reboot: the LTS kernel stays the default (`30-thermal.sh`, temporary until the NVIDIA driver works on 7.x)

