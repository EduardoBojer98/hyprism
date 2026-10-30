# User guide

## Where your settings live

Everything you change in **Settings** (`Super+I`) is saved on your computer only, never in git:

| File | Written by |
|---|---|
| `~/.config/quickshell/settings.json` | Every Settings page (appearance, dock, Spotlight, notifications, weather, …) |
| `~/.config/hypr/settings/displays.lua` | Displays |
| `~/.config/hypr/settings/input.lua` | Keyboard & Touchpad |
| `~/.config/hypr/settings/keybinds.lua` | Keyboard Shortcuts |
| `~/.config/hypr/settings/theme.lua`, `hyprlock-theme.conf` | Appearance (accent and corners for windows and the lock screen) |

A missing file means "use the defaults", so deleting one resets that part. The defaults themselves
are in `home/quickshell/.config/quickshell/ConfigData.qml` and the Hyprland modules. To keep your
own settings in your fork, remove the matching lines from `.gitignore`.

## What you can change in Settings

- **Appearance**: accent colour, how much of the blur shows through the glass, corners, text size,
  font, animations
- **Desktop & Dock**: icon size, auto-hide, running apps, pinned apps
- **Search & Launcher**: where Spotlight opens, what it shows before you type, result order and
  which kinds of results appear, clipboard inside Spotlight or as its own popup, web search engine
- **Clipboard**, **Notifications** (Do Not Disturb, how long popups stay, history size),
  **Control Center** (which modules show)
- **Displays** (arrange, resolution, scale, rotation, VRR, Night Light), **Sound**, **Wi-Fi &
  Network**, **Bluetooth**, **Keyboard & Touchpad** (layouts, repeat, touchpad)
- **Keyboard Shortcuts**: click a shortcut's keys and press new ones; Esc cancels, taken
  combinations are refused, each can be turned off or reset
- **Battery & Power**, **Wallpaper** (images in `~/Pictures/Wallpapers`), **Lock & Sleep**,
  **Default Applications**, **Weather**, **About**

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
