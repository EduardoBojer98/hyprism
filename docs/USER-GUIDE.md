# User guide

## Where your settings live

Everything you change in **Settings** (`Super+I`) is saved on your computer only, never in git:

| File | Written by |
|---|---|
| `~/.config/quickshell/settings.json` | Most pages (appearance, gaps, dock, Spotlight, notifications, weather, …) |
| `~/.config/hypr/settings/displays.lua` | Display |
| `~/.config/hypr/settings/input.lua` | Input (layouts, repeat, touchpad, pointer) |
| `~/.config/hypr/settings/language.lua` | System > Language & Region |
| `~/.config/hypr/settings/keybinds.lua` | Keyboard Shortcuts |
| `~/.config/hypr/settings/theme.lua`, `hyprlock-theme.conf` | Appearance (accent, corners, borders, gaps; lock screen colours) |
| `~/.config/hypr/settings/hypridle.conf` | Power & Battery > Lock & Sleep |
| `~/.config/hypr/settings/wallpaper` (a link to the image) | Appearance > Wallpaper |

A missing file means "use the defaults", so deleting one resets that part (`./install.sh` puts back
the ones Hyprland needs). The defaults are in `home/quickshell/.config/quickshell/ConfigData.qml`,
`home/hypr/.config/hypr/defaults/` and the Hyprland modules. To keep your
own settings in your fork, remove the matching lines from `.gitignore`.

## What you can change in Settings

| Group | What's in it |
|---|---|
| **Display** | arrange screens, resolution and refresh rate, scale, rotation, adaptive sync, Night Light; Shared Monitor (input switch with the work PC) |
| **Appearance** | light or dark, accent colour, glass, window border, corners, space around windows, text size, font, animations; Wallpaper (folders, slideshow); Icons |
| **Desktop** | Dock, Search & Launcher (Spotlight), Control Center, Notifications, Clipboard, Weather, Calendar |
| **Input** | keyboard layouts, key repeat, touchpad and pointer; MX Master buttons (opens JuhRadial MX) |
| **Sound** | output and input devices, volumes, per-app volume |
| **Network & Bluetooth** | Wi-Fi, advanced network editor, Bluetooth devices |
| **Power & Battery** | battery health, charge limit, power mode, what the lid does (shown only), Lock & Sleep timings, ASUS hardware |
| **Keyboard Shortcuts** | click a shortcut's keys and press new ones; Esc cancels, taken combinations are refused, each can be turned off or reset |
| **Default Apps**, **Startup Apps** | which app opens links, files and folders; what starts at login |
| **System** | About this computer, Update from GitHub, Re-run the full install, Language & Region |

Everything applies right away except language (next login) and lid behaviour (a system file set by
`system/02-desktop.sh`).

## Another computer

Things that differ between computers go in files named after the computer's hostname
(`cat /etc/hostname`):

- `home/hypr/.config/hypr/hosts/<hostname>.lua`: Hyprland overrides, loaded last (for example which
  desktop starts on which screen). See `hosts/rog-flow-x13.lua`.
- `system/hosts/<hostname>/NN-*.sh` (+ `packages.txt`): system steps for that computer only, run by
  `./install.sh --system`. See `system/hosts/rog-flow-x13/` (ASUS tools, NVIDIA sleep, hibernation).

Hardware features detect themselves at start (`Machine.qml`):

| Feature | Appears when |
|---|---|
| ASUS Hardware page, charge limit, ROG action | `asusctl` is installed |
| Keyboard light button | a `/sys/class/leds/*kbd_backlight` exists |
| Shared monitor button, `Super+M` | `~/.config/monswitch.conf` exists |

### A monitor shared with another computer

`monswitch` hands a monitor to another computer over DDC/CI and back (`Super+M`, Control Center),
moving your desktops off it while it's away. Turn DDC/CI on in the monitor's menu, install `ddcutil`,
then create `~/.config/monswitch.conf`:

```sh
OUT=HDMI-A-1   # Hyprland output name (hyprctl monitors)
LAPTOP=0x11    # input this computer is on (ddcutil getvcp 60 while it shows this computer)
PC=0x12        # input of the other computer
```

Log out and in (or restart the shell) to see the button.

## Troubleshooting

| Problem | Try |
|---|---|
| Bar or dock missing / frozen | `pkill -x qs; pkill -x quickshell; qs &` and check `qs log` |
| Notifications stop showing | another daemon took over (e.g. mako started while the shell was down): `pkill mako` |
| A shortcut does nothing | Settings → Keyboard Shortcuts shows what it's set to; `hyprctl configerrors` |
| Hyprland config error after an update | `hyprctl configerrors`; fix or delete the named file in `~/.config/hypr/settings/` |
| Blurry X11 apps | already handled (`xwayland.force_zero_scaling`); they look slightly smaller on scaled screens |
