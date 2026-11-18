# Manual test checklist

CI proves the installer, detection, module choice and the Hyprland config on seven made-up computers
([hardware.md](../hardware.md)). It can't log in, sleep, or talk to real devices. This list covers that part.
Tick each line and note the date and machine at the bottom.

## A. Fresh install in a VM (Arch or CachyOS, then Fedora 44+)

Use a VM with 3D acceleration off, 4 GB of memory, one screen.

- [ ] `git clone`, then `./install.sh --dry-run`: it finishes, lists packages, and shows `form = "vm"` and no modules.
- [ ] `./install.sh`: finishes with "Done". A log file exists in `~/.local/state/hyprism/logs/`.
- [ ] `./install.sh` again: says all packages are installed and changes nothing.
- [ ] Log out, pick Hyprland, log in: bar, wallpaper and the welcome appear; no error notifications.
- [ ] `Super+Space` opens the launcher; `Super+I` opens Settings; `Super+/` lists the shortcuts.
- [ ] `./install.sh doctor`: no problems.
- [ ] Settings → Appearance → Themes: switch to two other themes; bar, windows, terminal and a GTK app follow.
- [ ] `./install.sh uninstall`: the links are gone and your earlier files are back.

## B. A real laptop

- [ ] `./install.sh detect` describes the machine correctly (form, graphics, internal screen, battery, touch).
- [ ] `./install.sh modules`: the modules that are on make sense for this laptop.
- [ ] Battery item shows; unplugging and plugging in changes it within a few seconds.
- [ ] Brightness keys and volume keys show the on-screen display.
- [ ] Close the lid with no external screen: it sleeps. Open: it wakes to the lock screen.
- [ ] Close the lid with an external screen connected: the session keeps running on that screen.
- [ ] Plug a second screen in and out twice: windows land on a visible screen every time.

## C. Hybrid graphics (built-in + NVIDIA)

- [ ] After a reboot and a minute idle, `./install.sh doctor` says the NVIDIA card is `suspended`.
- [ ] `nv glxinfo -B` (or `nv` with any app) names the NVIDIA card; without `nv` the built-in card is named.
- [ ] Sleep and wake three times: the screen comes back each time.

## D. 2-in-1 and touch

- [ ] Fold the screen back: controls grow, the screen rotates with the device, the on-screen keyboard button works.
- [ ] Unfold: everything returns to normal.
- [ ] Touch and stylus land on the laptop's own screen when an external screen is connected.

## E. Shared monitor (DDC)

- [ ] `ddcutil detect` lists the monitor.
- [ ] Settings → Displays → Shared Monitor: choose the two inputs. `Super+M` hands the monitor to the other
      computer and windows move to the laptop screen; `Super+M` again brings it back.
- [ ] Switch the input on the monitor's own buttons: the desktop follows within half a minute.

## F. Logitech

- [ ] Solaar is in the tray after login and lists the device.
- [ ] MX Master 4: `solaar config 'mx master 4' haptic-play 'HAPPY ALERT'` gives a pulse.

## G. Updating from 1.1

- [ ] On an install of tag `v1.1.0`: `./install.sh update`. Migrations 0001 and 0002 are named and run once.
- [ ] `./install.sh update` again: no migration runs.
- [ ] `./install.sh rollback`, then `./install.sh update`: back and forward without errors.

## Results

| Date | Machine | Sections run | Result | Notes |
|---|---|---|---|---|
| | | | | |
