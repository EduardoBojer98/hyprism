# Audit (2026-10-31, branch `audit/2026-10-31`)

Machine: ROG Flow X13 GV301QC, CachyOS, kernel 6.18.55-2-cachyos-lts, Hyprland 0.57.0 (Lua config).
Legend: ✅ works / ⚠️ works but messy / ❌ broken / 🖐 needs your hands (can't be tested from a script without disrupting the session).

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

## Findings (Phase 2, before fixes)

Tested live on 2026-10-31 in the running Hyprland session. Each row names the evidence I saw.

### Top problems (fix first)

| # | Status | Finding | Where |
|---|---|---|---|
| 1 | ❌ | **Secret service not reachable in Hyprland.** `ksecretd` runs, but nothing owns `org.freedesktop.secrets` and `secret-tool` reports "The name is not activatable". As a result `gh` keeps its token in plain text (`~/.config/gh/hosts.yml`), and libsecret apps can't store passwords. | `modules/autostart.lua:7` (`pam_kwallet_init` only) |
| 2 | ❌ | **No shortcut to switch keyboard layout.** US + Serbian Latin are loaded and `hyprctl switchxkblayout` works, but `kb_options` is empty. | `~/.config/hypr/settings/input.lua:5`, default `modules/input.lua:5` |
| 3 | ❌ | **`./install.sh --system` stops on a fresh install.** It exits with "GNU Stow is missing" *before* the step that would install stow. | `install.sh:22` before `case` at `:61` |
| 4 | ❌ | **Cursor theme name is wrong.** `XCURSOR_THEME=oreo_white`, but the folder is `~/.icons/oreo_white_cursors`, so apps fall back to Adwaita (`/usr/share/icons/default`) while GTK's `settings.ini` asks for `oreo_white_cursors`. The theme also sits in `~/.icons` from no package and no repo, so a fresh install won't have it. Verify by eye. | `modules/env.lua:14` |
| 5 | ⚠️ | **Two Flameshot daemons** (PIDs started in the same second at login). One comes from `startup-apps` (`gtk-launch org.flameshot.Flameshot`, Settings > Startup Apps), the other is D-Bus activated (`dbus-:1.2-org.flameshot.Flameshot@0.service`). Likely a race at login. | `home/scripts/.local/bin/startup-apps:8`, `settings.json` `startup.apps` |
| 6 | ⚠️ | **`nvidia-powerd` runs although the repo disables it.** It started at 21:37:54, one second after asusd saw AC plugged in. Something activates it on power-source changes. The repo's own comment says it keeps the dGPU awake. The dGPU still reached `suspended` afterwards. | `system/hosts/rog-flow-x13/10-hardware.sh:26` |
| 7 | ⚠️ | **`Super+B` runs `firefox`**, but the default browser (Settings > Default Apps → `xdg-mime`) is Chrome. PDFs also open in **Chrome**, not Okular (declared in `apps.txt`). | `modules/binds.lua:24`, `~/.config/mimeapps.list` |
| 8 | ⚠️ | **No USB auto-mount.** `udisks2` is installed, so Dolphin mounts drives on click, but nothing mounts them when plugged in and there's no notification. | none |
| 9 | ⚠️ | **Third-party `curl … \| bash`** for JuhRadial MX, unpinned. It also enables `ydotool` and adds udev rules and the `input` group, all outside the repo. | `system/hosts/rog-flow-x13/40-mx-master.user.sh:13` |
| 10 | ⚠️ | **Host step is tied to one disk.** `ROOT_UUID` is hardcoded. After a reinstall, the `mount … by-uuid` fails and `set -e` stops the step. That's safe, but it doesn't set up hibernation. | `system/hosts/rog-flow-x13/10-hardware.sh:9,32` |

### Architecture and modularity

| Status | Finding | Where |
|---|---|---|
| ✅ | Hyprland is split into `env`, `monitors`, `input`, `look`, `animations`, `binds`, `rules`, `autostart`, all loaded from one entry file, with a per-host file last. | `hyprland.lua:4-17` |
| ✅ | One module per app (Stow package per app), readable comments in every file. | `home/*` |
| ⚠️ | **Two places for per-machine config, both keyed on hostname**: `home/hypr/.config/hypr/hosts/<hostname>.lua` and `system/hosts/<hostname>/`. No generic default host, no `--host` flag. | `hyprland.lua:11-17`, `install.sh:63-66` |
| ⚠️ | **Machine-specific values in shared modules** (harmless on other machines, but not separated): touchscreen/stylus pinned to `eDP-1` (`input.lua:25-26`, `monitors.lua:22-25`), AMD SFH tablet switch and lid binds (`binds.lua:72-75`), squeekboard started on every machine (`autostart.lua:11`), AMD iGPU link (`env.lua:6-10`, guarded), JuhRadial (`autostart.lua:23-25`, guarded). | as listed |
| ⚠️ | `env.lua:3-4` says the iGPU link "comes from system/02-desktop.sh"; it actually comes from `system/hosts/rog-flow-x13/20-igpu.sh:9`. | `modules/env.lua:4` |
| ⚠️ | **Theme isn't in one place.** The real source is `Theme.qml:34+` (13 themes). `ThemeSync.qml` carries it to `settings/theme.lua`, `hyprlock-theme.conf`, `ghostty/theme.conf` and gsettings. That part is good. But `modules/colors.lua:1` claims to be "the one place colours are defined" and is only used for one gradient stop (`look.lua:18`). `fuzzel.ini:12-18` hardcodes Catppuccin Macchiato, and `hyprlock.conf:15-42` hardcodes rgba values. | as listed |
| ⚠️ | **Distro-specific commands are mixed in.** `pacman` appears in `system/02-desktop.sh:12`, `03-apps.sh:9`, `hosts/rog-flow-x13/10-hardware.sh:16`, `30-thermal.sh:22` and the hint at `install.sh:22`, plus a Settings hint at `SettingsPageApps.qml:66`. Package lists use Arch names. No Fedora path. | as listed |
| ⚠️ | **Undeclared runtime dependencies of the shell/scripts**: `kdialog` (Wallpaper "Browse…", `SettingsPageWallpaper.qml:42`), `gtk-launch` (gtk3, `startup-apps:8`), `ksecretd`/kwallet (`autostart.lua:7`), `power-profiles-daemon` (non-ASUS power modes), `upower`, `networkmanager`, `wireplumber`, `udisks2`, `noto-fonts-emoji`, `mesa-utils` (none needed), `nvidia-prime` (`prime-run` in `nv`). They're present only because CachyOS + KDE installed them. | as listed |
| ✅ | No hardcoded `/home/eduardo` or repo path in tracked files. `install.sh` and the About page find the repo themselves (`SettingsPageAbout.qml:25`). | — |
| ⚠️ | Stow folds whole dirs (`~/.config/hypr`, `quickshell`, `ghostty` …) into links. Moving the clone breaks them until you re-run `./install.sh`. Settings files written there live inside the repo folder (gitignored). | `install.sh:106` |
| ✅ | shellcheck (`koalaman/shellcheck:stable`, in a container) on `install.sh`, `system/**/*.sh`, `.githooks/pre-commit` and all 12 scripts: **0 errors, 0 warnings**, 8 style notes (SC2086 ×3, SC2012 ×3, SC2015, SC2035). | — |

### Does it work (live)

| Area | Status | Evidence |
|---|---|---|
| Hyprland reload | ✅ | `hyprctl reload` → `ok`; `hyprctl configerrors` empty; no WARN/ERR lines in the log except aquamarine skipping the non-KMS NVIDIA card (expected). |
| Monitors | ✅ | `HDMI-A-1` 2560×1440@120 scale 1 at 0,0; `eDP-1` 1920×1200@120 scale 1.2 at 480,1440 (centred under the Acer). Workspace 1 on the laptop, 2 on the Acer (`hosts/rog-flow-x13.lua`). |
| Hotplug, `monswitch` input switch | 🖐 | Running it would hand the Acer to the work PC. Logic read only. |
| Hyprland on the iGPU | ✅ | Log: "Explicit device list /dev/dri/amd-igpu … Found 1 GPUs … amdgpu". `__EGL_VENDOR_LIBRARY_FILENAMES=50_mesa.json` in the session. |
| NVIDIA on demand | ✅ | `nv glxinfo -B` → "NVIDIA GeForce RTX 3050 Laptop GPU". Runtime PM went `active` → `suspended` afterwards. |
| Suspend / resume | 🖐 | No suspend in the last 4 boots' journals (1 exit in boot −5). `mem_sleep=[s2idle]`; nvidia-suspend/hibernate/resume enabled; lid drop-in present. Needs a real close-the-lid test. |
| Flicker | 🖐 | Visual. |
| Keyboard layouts | ⚠️ | Both load, `switchxkblayout` cycles US ↔ Serbian (Latin), but no shortcut (#2). |
| Keychron Q1 HE | ✅ | Detected (USB 3434:0b10, keyboard + mouse interfaces). |
| MX Master 4 | ✅/🖐 | Bolt receiver present; `juhradiald`, overlay and `juhradialmx-daemon.service` active, no warnings in its journal. Buttons/haptics need a hand test. |
| Touchpad | ✅ | natural scroll on; 3-finger gestures defined (`input.lua:34-36`). Gestures 🖐. |
| Bar, dock, launcher, notifications, OSD | ✅ | One `qs` process; it owns `org.freedesktop.Notifications` and `org.kde.StatusNotifierWatcher`. No competing daemon (mako/dunst/swaync not running). |
| Lock / idle | ✅ | `hypridle` running with `settings/hypridle.conf`; `hyprlock` installed. Locking itself 🖐. |
| Power menu | ✅ | In the Quickshell utility menu (`PowerMenu.qml`); `hyprshutdown` installed. |
| Audio | ✅ | PipeWire + WirePlumber; sinks: laptop analog + Acer HDMI (default); mic analog source. `wpctl set-volume … 5%-` worked and was restored. Keys call the same `wpctl` (`binds.lua:86-89`). Mic config `51-flow-x13-mic.conf` linked. |
| Brightness | ✅ | `brightnessctl` on `amdgpu_bl1`. ⚠️ No brightness control for the Acer (DDC/CI could do it; `ddcutil` is installed). |
| Media keys | ✅ | playerctl binds present; nothing playing to test. |
| Battery | ✅ | upower: 52 %, charging; charge limit 60 % (`charge_control_end_threshold`) survived reboot. ⚠️ Battery health 69 % of design (42.8/62.0 Wh). |
| Power profiles | ✅ | asusctl `Balanced`, powerprofilesctl `balanced`, in agreement. |
| Wi-Fi / Bluetooth | ✅ | `wlan0` connected (NetworkManager); BT adapter powered. |
| Flameshot Alt+Shift+S | ✅/⚠️ | Bound (`binds.lua:63` → `screenshot`). Two daemons (#5). Capture itself 🖐. |
| Clipboard history | ✅ | `wl-paste --watch clipstore store` running. |
| File manager | ✅ | `inode/directory` → Dolphin. |
| Default apps | ⚠️ | https → Chrome, PDF → Chrome, images → Gwenview, text → micro (a terminal app; opening a text file from Dolphin/xdg-open may not find a terminal, 🖐). See #7. |
| Screen sharing / file pickers | ✅/🖐 | `xdg-desktop-portal`, `-hyprland` and `-gtk` running; `hyprland-portals.conf` = `hyprland;gtk`; ScreenCast, Screenshot, FileChooser and Settings interfaces exported. An actual share in a browser 🖐. |
| GTK / Qt / icons / fonts | ✅/⚠️ | gsettings: `adw-gtk3-dark`, `prefer-dark`, `Papirus-Dark`, `Inter 11` (set at each Hyprland start, `autostart.lua:13-17`). Qt uses `QT_QPA_PLATFORMTHEME=kde`. Inter installed. Cursor broken (#4). |
| Polkit agent | ✅ | `hyprpolkitagent` running. |
| Keyring / secret service | ❌ | #1. |
| USB auto-mount | ⚠️ | #8. |
| Settings panel persistence | ✅/⚠️ | See below. |
| Docker without sudo | ✅ | `docker run --rm hello-world` OK as user; user in `docker`. |
| Node / npm / PHP / Composer / Python / uv / Git / gh / VS Code / Lando | ✅ | node 24.22.1 (nvm.fish), npm 11.19.1, PHP 8.5.12, Composer 2.11.1, Python 3.14.8, uv 0.13.6, git 2.56.0, gh 2.102.1, code 1.144.0, lando present. ⚠️ nvm.fish, VS Code and Lando aren't installed by the repo. |
| KDE fallback | ✅/🖐 | `plasma.desktop` session present, Plasma Login lists it; `[Autologin]` has no `User=`, so no autologin loop if Hyprland breaks. Hyprland env lives in Lua (not seen by KDE), the fish iGPU snippet checks `XDG_SESSION_DESKTOP=Hyprland`, and the KDE guard in `install.sh:24-28` blocks Plasma files. Shared on purpose: `wireplumber` mic fix, `chrome-flags.conf`, gsettings (KDE reapplies its own). Logging into KDE 🖐. ⚠️ A `hyprland-uwsm.desktop` session also exists; picking it would run XDG autostart under systemd and double-start apps. |

### Settings panel

The groups already match the brief: Display, Appearance, Desktop, Input, Sound, Network &
Bluetooth, Power & Battery, Keyboard Shortcuts, Default Apps, Startup Apps, System
(`SettingsApp.qml:22-32`). The brief has no "Desktop" group; the dock, bar, launcher, notifications,
clipboard, weather and calendar pages sit there.

| Status | Finding | Where |
|---|---|---|
| ✅ | Persisted settings go to `~/.config/quickshell/settings.json` or one named file in `~/.config/hypr/settings/` (`displays.lua`, `input.lua`, `keybinds.lua`, `theme.lua`, `hyprlock-theme.conf`, `hypridle.conf`, `language.lua`, `wallpaper`), and `~/.config/ghostty/theme.conf`, `~/.config/monswitch.conf`, `mimeapps.list` (xdg-mime). They apply live via `hyprctl eval`, `hyprctl reload`, gsettings or restarting the daemon. Language applies at next login. | `SettingsApp.qml:94-96`, `ThemeSync.qml:34-66` |
| ✅ | Hardware state (sound devices and volumes, Wi-Fi, Bluetooth, charge limit, power mode, fan curves) is handed to the owning daemon (WirePlumber, NetworkManager, BlueZ, asusd), which persists it. Charge limit 60 % survived a reboot. The others weren't reboot-tested 🖐. | `SettingsPageSound.qml`, `SettingsPagePower.qml:53` |
| ⚠️ | Wallpaper "Browse…" calls `kdialog` (KDE package, undeclared). Could use the portal file chooser instead. | `SettingsPageWallpaper.qml:42` |
| ⚠️ | "Re-run the full install" runs `./install.sh --system` → `pacman`. Not distro-neutral until there are backends. "Update from GitHub" = `git pull --ff-only && ./install.sh` ✅. No "Run doctor" yet. | `SettingsPageAbout.qml:65,70` |
| ⚠️ | Task-manager hint text says `sudo pacman -S mission-center`. | `SettingsPageApps.qml:66` |
| ⚠️ | Input page has "Switch layouts with", but it's empty right now (#2), and nothing stops picking Alt+Shift, which collides with `Alt+Shift+S`. | `SettingsPageInput.qml:94` |

### Reproducibility

| Status | Finding | Where |
|---|---|---|
| ✅ | Linking is idempotent (`stow -R`), backs up clashes with timestamps, has `--undo`, never overwrites Settings choices (`cp -n`). | `install.sh:80-111` |
| ❌ | Fresh install can't start (#3). | `install.sh:22` |
| ⚠️ | `--dry-run` shows links and backups only, not packages, services or system steps. | `install.sh:82-88` |
| ⚠️ | No `--host`, `--only`, `--yes`, no `doctor`. `--system` asks once, then runs every step. | `install.sh:61-77` |
| ⚠️ | Order: system steps (packages → services → groups) run before linking. That's right. But post-install steps a new machine needs are missing: fisher + nvm.fish + a Node version, VS Code, Chrome, Ollama, cursor theme, flatpaks, Lando. | — |
| ⚠️ | Pacman lists are applied with `--noconfirm`. Host steps change the kernel, bootloader order, fstab, swap and modprobe without a separate prompt (one "Run them now?" for all). Phase 3 should keep those behind an explicit question, per the brief's rule 7. | `install.sh:69`, `30-thermal.sh:16-36`, `10-hardware.sh:28-55` |
| ✅ | Works from any clone path (paths are resolved at runtime). | `install.sh:14` |

### Needs your hands (can't test from here without disrupting you)

Close the lid / suspend + resume (with the Acer connected and without); unplug and replug the Acer;
`Super+M` input switch and back; MX Master buttons, gestures and haptics; a screen share in Chrome;
a file picker in Chrome; `Alt+Shift+S` capture; log out and into KDE Plasma; cursor looks the same in
Ghostty, Chrome and Dolphin; open a `.txt` from Dolphin.
