# Audit (2026-10-31, branch `audit/2026-10-31`)

Machine: ROG Flow X13 GV301QC, CachyOS, kernel 6.18.55-2-cachyos-lts, Hyprland 0.57.0 (Lua config).
Legend: ✅ works / ⚠️ works but messy / ❌ broken. Phase 1 only so far; Phase 2 findings follow.

> **Brief vs. reality.** The task brief mentions Alacritty, a bar/launcher/notification daemon and a
> hyprlang config. The live setup is different and this audit follows the live setup:
> terminal **Ghostty**, bar + dock + launcher + notifications + OSD + lock UI + Settings app all in
> **Quickshell** (`home/quickshell`), Hyprland config in **Lua** (`hyprland.lua` + `modules/*.lua`),
> configs linked with **GNU Stow**. Fish is the login shell, but CachyOS's own fish config is the base.

## Inventory

### Repo tree

| Path | What it is |
|---|---|
| `install.sh` | Entry point. Stow-links every `home/<pkg>/` into `~`, backs up clashes to `~/.local/state/linux-setup/backups/<ts>/`, seeds `~/.config/hypr/settings/` from `defaults/`, sets `core.hooksPath`. `--dry-run`, `--undo`, `--system` (runs `system/NN-*.sh` + `system/hosts/<hostname>/`). |
| `home/<pkg>/` | Stow packages mirroring `~` (13 packages, below). |
| `packages/desktop.txt`, `dev.txt`, `apps.txt` | pacman package lists, one per line with a "why" comment. |
| `system/02-desktop.sh` | Installs `desktop.txt`, enables bluetooth, writes logind lid drop-in, makes Hyprland the default Plasma Login session. |
| `system/03-apps.sh` | Installs `dev.txt` + `apps.txt`, enables docker, adds user to `docker`. |
| `system/hosts/rog-flow-x13/` | Host-only system steps: `10-hardware.sh` (asusctl, NVIDIA sleep services, swapfile + hibernate, Limine cmdline), `20-igpu.sh` (udev link for the AMD iGPU), `30-thermal.sh` (NVIDIA RTD3, LTS kernel, Limine boot order), `40-mx-master.user.sh` (JuhRadial MX installer), `50-power.user.sh` (power modes, PPD drop-in), `packages.txt`. |
| `plugins/minimize/main.cpp` | Hyprland plugin: makes title-bar minimise buttons work. Built by `hypr-plugins`. |
| `.githooks/pre-commit` | gitleaks scan of staged changes. |
| `.gitignore` | Secret patterns + the Settings app's local files. |
| `README.md`, `DESIGN.md`, `docs/USER-GUIDE.md`, `docs/thermal-audit.md` | Docs: overview/keys, design tokens, settings file map + troubleshooting, X13 thermal work. |

### Configs the repo manages (all via Stow symlinks)

Stow "folds" a directory into one symlink when nothing else lives there. So `~/.config/hypr`,
`quickshell`, `ghostty`, `fuzzel`, `fastfetch`, `arch-update` and `wireplumber` are **whole-directory
links into the repo**. Files the apps write there land in the repo folder (gitignored).

| Stow package | Ends up at | Link type |
|---|---|---|
| `arch-update` | `~/.config/arch-update/` | dir link |
| `chrome` | `~/.config/chrome-flags.conf` | file link |
| `fastfetch` | `~/.config/fastfetch/` | dir link |
| `fish` | `~/.config/fish/conf.d/{hyprland-igpu,tools}.fish` | file links (`fish/` is a real dir) |
| `fuzzel` | `~/.config/fuzzel/` | dir link |
| `ghostty` | `~/.config/ghostty/` | dir link (`theme.conf` written by Settings, gitignored) |
| `hypr` | `~/.config/hypr/` | dir link (`settings/` written by Settings, gitignored) |
| `quickshell` | `~/.config/quickshell/` | dir link (`settings.json` written by Settings, gitignored) |
| `scripts` | `~/.local/bin/{asusfan,clipstore,emojipick,hypr-plugins,monswitch,nv,panel,powermode,screenshot,screentext,startup-apps,thermlog}` | file links |
| `starship` | `~/.config/starship.toml` | file link |
| `wallpapers` | `~/Pictures/Wallpapers/{glass-night,macchiato-glow}.png` | file links |
| `wireplumber` | `~/.config/wireplumber/` | dir link |

Files the repo writes outside `~` (system steps, not linked, so not tracked for drift):

| File | Written by | On this machine |
|---|---|---|
| `/etc/systemd/logind.conf.d/50-lid.conf` | `system/02-desktop.sh:19` | present |
| `/etc/plasmalogin.conf` (`Session=hyprland`) | `system/02-desktop.sh:27` | present |
| `/etc/udev/rules.d/90-amd-igpu.rules` | `hosts/rog-flow-x13/20-igpu.sh:9` | present |
| `/etc/modprobe.d/nvidia-rtd3.conf` | `hosts/rog-flow-x13/30-thermal.sh:16` | present |
| `/etc/default/limine` (`BOOT_ORDER`) | `hosts/rog-flow-x13/30-thermal.sh:24` | present (`*lts` first) |
| `/etc/limine-entry-tool.d/50-hibernate.conf` | `hosts/rog-flow-x13/10-hardware.sh:47` | present |
| `/etc/systemd/sleep.conf.d/50-hibernate.conf` | `hosts/rog-flow-x13/10-hardware.sh:54` | present |
| `/etc/fstab` (`/swap` subvol + swapfile) | `hosts/rog-flow-x13/10-hardware.sh:30,42` | present (fstab:17-18) |
| `/etc/systemd/system/power-profiles-daemon.service.d/50-asusd-owns-epp.conf` | `hosts/rog-flow-x13/50-power.user.sh:58` | present |

### Drift (in both places, different)

✅ **None.** All 123 tracked files under `home/` resolve to the repo copy; no copies, no missing links.
The Settings app's local files (`settings.json`, `hypr/settings/*`, `ghostty/theme.conf`) are
intentionally untracked.

### Sync gaps (on the system, not in the repo)

| Item | Path | Should it be in the repo? |
|---|---|---|
| Fish main config | `~/.config/fish/config.fish` | ⚠️ Yes, partly. Only sources CachyOS's config and adds `export PATH="/home/eduardo/.lando/bin:$PATH"` (hardcoded home path; Lando's installer wrote it). Move the Lando line into `tools.fish` using `$HOME`. |
| Fish plugins | `~/.config/fish/fish_plugins` (`jorgebucaran/nvm.fish`) + `functions/`, `completions/` | ⚠️ `fish_plugins` yes (nvm is how Node is installed, `dev.txt` header says so) and the install must bootstrap fisher; the generated `functions/` no. Nothing installs fisher/nvm today. |
| Git config | `~/.gitconfig` (gh credential helper), `~/.config/git/ignore` | ⚠️ Credential-helper part yes, as a template without name/email. |
| Default apps | `~/.config/mimeapps.list` | ⚠️ Written by Settings > Default Apps. Browser is **google-chrome**, images gwenview, text **micro**. These conflict with the repo: `Super+B` runs `firefox` (`binds.lua:24`), and `apps.txt` declares firefox, not Chrome. |
| GTK settings | `~/.config/gtk-3.0/settings.ini`, `gtk-4.0/settings.ini` | ⚠️ They come from KDE (`gtk-theme-name=Breeze`, cursor `oreo_white_cursors`, `colorreload-gtk-module`). The repo declares `adw-gtk-theme` and sets the theme over gsettings (`autostart.lua`, `ThemeSync.qml`). Shared with KDE, so keep out of the repo. Phase 2 checks GTK theming in Hyprland. |
| Autostart entries | `~/.config/autostart/{juhradial-mx,org.flameshot.Flameshot,…rog-control-center}.desktop` | ⚠️ XDG autostart, used by KDE (and Hyprland only if something runs them). Created by the apps, not the repo. Check for double-starts in Phase 2. |
| Shared-monitor config | `~/.config/monswitch.conf` | ✅ Host-specific, written by Settings; documented in USER-GUIDE. Belongs in `hosts/flow-x13/` as a default. |
| MX Master | `~/.config/juhradial/`, `~/.config/systemd/user/juhradialmx-daemon.service`, `/etc/udev/rules.d/{70,99}-juhradialmx*.rules`, `/usr/local/bin/juhradiald` | ⚠️ Installed by the third-party `curl … \| bash` in `40-mx-master.user.sh:13`. Not a package; not in any manifest; button config not in repo. |
| ydotool | user unit `ydotool.service` enabled, `/etc/udev/rules.d/60-ydotool-uinput.rules` | ❓ Nothing in the repo uses ydotool (git grep finds nothing). Probably pulled in by JuhRadial. Check before removing. |
| Ollama | `/usr/local/bin/ollama` (no package owns it), `ollama.service` enabled, `ollama` group | ❌ For local AI, installed by hand with the upstream script. Nothing in the repo. |
| Open WebUI | `open-webui-desktop-bin` (AUR), `~/.config/open-webui/` | ⚠️ Not declared. |
| Flameshot config | `~/.config/flameshot/` | ⚠️ Not in repo. `screenshot` passes options on the command line; check whether the ini matters. |
| X11 keyboard | `/etc/X11/xorg.conf.d/00-keyboard.conf` | ✅ From the installer (Xorg only), not needed by Hyprland. |
| Fonts | `~/.local/share/fonts` | ✅ Doesn't exist; all fonts come from packages. |
| `.desktop` files | `~/.local/share/applications/` | ✅ Only Claude's own entries; nothing the setup needs. |
| `~/.local/bin` extras | `claude`, `node`, `npm`, `npx` | ✅ Not setup files (Claude Code; nvm.fish symlinks). |

### Dead config (in the repo, nothing uses it)

| Item | Status |
|---|---|
| Every script in `home/scripts/.local/bin/` | ✅ Each is referenced somewhere else in the repo. |
| `SettingsPage*.qml` | ✅ Loaded by name at `SettingsApp.qml:279`. |
| `home/fuzzel/.config/fuzzel/fuzzel.ini` | ⚠️ Header says "stopgap until the Quickshell launcher". Now only the emoji picker uses it (`emojipick`). Fix the comment, or move emoji into Quickshell and drop fuzzel. |
| `macchiato-glow.png` | ✅ Pickable wallpaper, nothing references it by name (on purpose). |
| `ttf-firacode-nerd` (`desktop.txt`) | ⚠️ Its own comment says "nothing in the repo needs it". It's only a font choice. Keep or drop. |
| `hyprshot`, `satty` (installed, undeclared) | ⚠️ `satty` only appears in a window rule (`rules.lua`); `hyprshot` nowhere. Leftovers from before Flameshot. |
| `home/chrome/.config/chrome-flags.conf` | ⚠️ Used by Chrome, which is the real default browser but isn't declared anywhere (see Packages). |

### Packages

All 72 declared packages are installed ✅ (none declared-but-missing). Sources, verified with `pacman -Sl` / `pacman -Qm`:

| Source | Declared packages |
|---|---|
| CachyOS repos (`cachyos`, `cachyos-*-v3`) | most of `desktop.txt`/`dev.txt` (they shadow Arch's `extra`/`core`; on plain Arch the same names come from `extra`); `onlyoffice-bin` is **CachyOS-only** (AUR on Arch) |
| `extra` | adw-gtk-theme, asusctl, rog-control-center, brightnessctl, cantarell-fonts, composer, ddcutil, inter-font, noto-fonts, papirus-icon-theme, pipewire-audio, sound-theme-freedesktop, starship, stow, tesseract-data-eng, ttf-firacode-nerd, ttf-jetbrains-mono-nerd, xdg-utils |
| `core` | base-devel, curl |

**Installed but undeclared (276 explicit, 224 undeclared).** Most are the CachyOS base, KDE Plasma
and drivers, which is fine because the brief wants KDE kept. The ones the *desktop* depends on that
need a decision:

| Package | Source | Why it matters |
|---|---|---|
| `google-chrome` | AUR | Actual default browser (mimeapps), has `chrome-flags.conf` in the repo, listed in `ConfigData.qml` |
| `visual-studio-code-bin` | AUR | Editor; `dev.txt` says "VS Code from the AUR" but nothing installs it |
| `open-webui-desktop-bin` | AUR | Local AI front end |
| ollama | manual `/usr/local/bin` | Local AI; could be `ollama-cuda` (extra / cachyos-extra-v3) |
| JuhRadial MX | curl \| bash | MX Master 4 buttons/haptics |
| `nvidia-utils`, `lib32-nvidia-utils`, `linux-cachyos{,-lts}-nvidia-open`, `nvidia-settings`, `nvidia-prime`, `libva-nvidia-driver`, `egl-wayland` | cachyos / extra | GPU stack. Installed by CachyOS's `chwd` and by `30-thermal.sh:22` (LTS only); not in a manifest |
| `power-profiles-daemon`, `switcheroo-control`, `upower` | cachyos / cachyos-extra | Used by power modes / GPU switching / battery in the shell |
| `gtk4-layer-shell` | cachyos-extra | Not used by the repo (probably a JuhRadial dependency) |
| `networkmanager`, `iwd`, `wireplumber`, `pipewire-pulse`, `pipewire-alsa` | base | The shell talks to them directly; must be declared for non-CachyOS installs |
| `noto-fonts-emoji`, `noto-fonts-cjk` | extra | Emoji picker / fallback glyphs |
| `micro` | cachyos-extra | Default text editor in mimeapps and referenced in `binds.lua`/`ConfigData.qml` |
| `gwenview`, `kate`, `spectacle`, `haruna`, `ark` … | KDE apps | Gwenview is the default image viewer; the rest belong to KDE |
| `hyprshot`, `satty`, `ydotool`, `glances`, `btop`, `htop` | various | Leftovers / personal; decide keep or drop |
| `ufw`, `snapper`, `limine-snapper-sync`, `btrfs-assistant` | cachyos | Firewall + snapshots from the CachyOS install; Phase 5 material |

Flatpak (flathub): `com.ktechpit.whatsie`, `io.github.flattool.Warehouse`. Not declared.

### Services

| Service | Scope | Needed for | Enabled by repo? | State |
|---|---|---|---|---|
| `bluetooth` | system | Bluetooth in shell | ✅ `02-desktop.sh:15` | enabled, active |
| `docker` | system | dev | ✅ `03-apps.sh:12` | enabled, active; user in `docker` ✅ |
| `asusd` | system | fans, charge limit | ✅ `10-hardware.sh:17` | static, active |
| `nvidia-{suspend,hibernate,resume}` | system | GPU suspend | ✅ `10-hardware.sh:20` | enabled |
| `nvidia-powerd` | system | — | repo **disables** it (`10-hardware.sh:26`) | ⚠️ disabled but **running** (started at 21:37 tonight by D-Bus activation or a manual start). Phase 2. |
| `power-profiles-daemon` | system | power modes | ❌ not enabled by repo; drop-in only | disabled but active (D-Bus activated) |
| `NetworkManager` | system | Wi-Fi | ❌ not by repo (CachyOS default) | enabled, active |
| `plasmalogin` | system | login screen | ❌ not by repo (only its config) | enabled, active |
| `switcheroo-control` | system | GPU choice for apps | ❌ not by repo | enabled, active |
| `ollama` | system | local AI | ❌ manual | enabled |
| `ufw`, `snapper-cleanup.timer`, `limine-snapper-sync` | system | firewall / snapshots | ❌ CachyOS defaults | enabled |
| `pipewire`, `pipewire-pulse`, `wireplumber` | user | audio | ❌ (distro default) | enabled |
| `arch-update.timer` | user | update notifier (`home/arch-update`) | ❌ config in repo, unit not enabled by repo | enabled |
| `juhradialmx-daemon` | user | MX Master | via third-party installer | enabled |
| `ydotool` | user | unknown (see above) | ❌ | enabled |
| hypridle, hyprpaper, polkit agent, quickshell, flameshot | session | — | started from `modules/autostart.lua` (not systemd, on purpose) | Phase 2 |

User groups: `docker`, `input`, `video`, `audio`, `wheel`, `ollama`, `nopasswdlogin` and others.
Only `docker` is added by the repo; `input` is added by JuhRadial.

### Keybinds

All binds live in `home/hypr/.config/hypr/modules/binds.lua`. Each one has an id that Settings >
Keyboard Shortcuts can override in `~/.config/hypr/settings/keybinds.lua` (empty here, so
defaults apply). Checked against `hyprctl binds -j`: 81 live binds, all from `binds.lua`,
**no duplicate combos**.

| Keys | Action | Line |
|---|---|---|
| `Super+Return` | Terminal (Ghostty, new window in running instance) | 18 |
| tap `Super` / `Super+Space` | Spotlight | 20 / 21 |
| `Super+Shift+Space` / `Super+A` | Spotlight files / all apps | 27 / 28 |
| `Super+E` | Dolphin | 22 |
| `Super+B` | **firefox** (default browser is Chrome) | 24 |
| `Super+I` | Settings | 23 |
| `Super+V` | Clipboard history | 25 |
| `Super+.` | Emoji picker | 26 |
| `Super+C` / `Super+N` / `Super+Shift+N` | Control Center / notifications / Do Not Disturb | 29–31 |
| `Super+W` | Mission Control | 32 |
| `Super+Q` | Close window | 35 |
| `Super+F` / `Super+Shift+F` | Fullscreen / maximise | 36 / 37 |
| `Super+T` | Float / tile | 38 |
| `Super+J` | Swap split | 39 |
| `Super+H` | Minimise to dock | 40 |
| `Super+←↑→↓` / `Super+Shift+←↑→↓` | Focus / move window | 41–44 |
| `Super+LMB drag` / `Super+RMB drag` | Move / resize window | 45 / 46 |
| `Super+1…0` / `Super+Shift+1…0` | Go to / send to workspace | 49–53 |
| `Super+Tab` | Previous workspace | 54 |
| `Super+wheel` | Next / previous workspace | 55 / 56 |
| `Super+S` / `Super+Shift+S` | Scratchpad / send to scratchpad | 57 / 58 |
| `Print`, `Alt+Shift+S` | Flameshot region (`screenshot`) | 61, 63 |
| `Shift+Print` | Whole screen | 62 |
| `Ctrl+Shift+Esc` | Task manager | 64 |
| `Super+Shift+T` | Copy text from screen (OCR) | 65 |
| `Super+Shift+C` | Colour picker | 66 |
| `Super+M` | Hand shared monitor over / back (`monswitch`) | 69 |
| `Super+F5` | Next power mode | 76 |
| `Super+L` | Lock | 79 |
| `Super+Shift+R` | Reload Hyprland | 80 |
| `Super+Shift+E` | Log out (`hyprshutdown`) | 81 |
| Volume / mute / mic mute keys | wpctl | 86–89 |
| Brightness keys | brightnessctl + OSD | 90–91 |
| Next / prev / play / pause keys | playerctl | 92–95 |
| Lid / tablet-mode switches | `panel` | 72–75 |
| `Ctrl+Alt+Esc` | Leave key-recording submap (Settings only) | 112 |
| 3-finger swipe sideways / up | Workspace / Mission Control | gestures, `input.lua` (Phase 2) |

Conflicts and gaps:
- ✅ No combo is bound twice; Print and Alt+Shift+S on purpose share one action.
- ❌ **No keyboard-layout switch shortcut.** `modules/input.lua:5` defaults to `grp:alt_shift_toggle`, but
  `~/.config/hypr/settings/input.lua` sets `kb_layout="us,rs"`, `kb_variant=",latin"`, `kb_options=""`
  (live `hyprctl getoption input:kb_options` is empty). US + Serbian Latin are loaded, but you can only switch
  from the bar. (Restoring `alt_shift_toggle` would fight `Alt+Shift+S`. Phase 3 picks a free combo, e.g.
  `Super+Ctrl+Space` or `grp:win_space_toggle`, which needs moving Spotlight.)
- ⚠️ `Super+B` opens Firefox while the default browser is Chrome. Make it run `xdg-open https:` or the
  Default Apps choice.
- ⚠️ In-popup keys (Esc, arrows, Enter) are handled in QML (`Launcher.qml:154`, `Clipboard.qml:131`,
  `MissionControl.qml:119`, `PowerMenu.qml:74`, `CursorPopup.qml:101`, `ControlCenter.qml:1074`) and only work while
  that popup has focus. That's expected.

### Secrets and hardcoded paths (quick pass, details in Phase 2)

- ✅ `gitleaks git` over all 114 commits: no leaks. No tokens, keys or Wi-Fi passwords in tracked files.
- ⚠️ All 114 commits use the author email `ediboieru@gmail.com`. That's git metadata, not config, and only
  rewriting history could remove it (not allowed by the rules). Option for the future: use GitHub's `noreply` address.
- ✅ No `/home/eduardo` or repo-path literals in tracked files. `install.sh` resolves its own location.
  ⚠️ But stow's directory links point at wherever the repo is, so moving the clone breaks them until `./install.sh` re-runs.
- ❌ Security: `40-mx-master.user.sh:13` pipes a third-party GitHub script straight into `bash`
  without pinning a version.

### Gaps against the brief's goals (input for Phase 2/3)

1. Arch/CachyOS only: package lists use pacman names, every `system/` script calls `pacman`, and `install.sh:23` says "sudo pacman -S stow". No Fedora path, no distro backends.
2. Host handling exists twice: `home/hypr/.config/hypr/hosts/<hostname>.lua` and `system/hosts/<hostname>/`. Both key off `/etc/hostname`; there's no generic default host and no `--host` flag.
3. No `doctor`, no `--only`, no `--yes`. `--dry-run` covers only the links, not packages or system steps.
4. Theme: `modules/colors.lua` says it's "the one place colours are defined", but Quickshell has `Theme.qml`/`ConfigData.qml` with 13 themes, and Ghostty, fuzzel and hyprlock carry their own colours. Phase 2 checks whether Quickshell writes the others (`ThemeSync.qml`) or they're duplicated.
5. GPU stack, fisher/nvm, VS Code, Chrome, Ollama and JuhRadial aren't installed by any manifest, so a fresh install won't bring them back.
