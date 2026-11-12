# Troubleshooting

Find the symptom, check the thing named, apply the fix.

## Three tools

### The doctor

```bash
./install.sh doctor
```

Changes nothing. It checks: every package is installed; every config file is linked to the repo (and none is a
copy or edited in place); dead links; services (NetworkManager, Bluetooth, Docker not started at boot); a firewall;
snapshots for rollback (Arch on btrfs); each module's own checks and module steps that have not run; whether
`hardware.toml` still matches the computer; inside a session: sound, network, the desktop portal, the password
prompt helper, the keyring, UPower, whether the shell is running; Hyprland's config errors; Settings' generated
files; `settings.json` being valid JSON; stray notification daemons. Each problem prints the command that fixes it.

### Logs

- Installer: `~/.local/state/hyprism/logs/` (one file per run).
- The shell: `qs log`.
- Hyprland config: `hyprctl configerrors`.

### Getting back to a working desktop

| Situation | Do |
|---|---|
| A setting or theme made the desktop unusable | `desktop-reset` (everything) or `desktop-reset shell` (bar, dock, theme, panels). Files are moved aside, not deleted. |
| An update broke it | `./install.sh rollback`, then see "An update broke something" below. |
| No working screen | Ctrl+Alt+F3 for a text console, log in, run `desktop-reset`. Ctrl+Alt+F1 goes back (or reboot). |
| You want Hyprism gone | `./install.sh uninstall` (works from a text console too). |

## No bar after login

Check `qs log` for the error. Restart the shell: `qs kill; qs &`. The doctor reports "the shell isn't running".
Still broken: `desktop-reset shell`. If notifications also stay silent, another daemon may have taken over
(the doctor warns about `mako`, `dunst`, `swaync`): stop it.

## Black screen after waking (hybrid NVIDIA laptop)

The `nvidia-hybrid` module's second step (`20-sleep-and-power.sh`) keeps video memory across sleep; without it the
screen can come back black. Check `./install.sh modules` shows `nvidia-hybrid` on. Run the step:
`./install.sh --step nvidia-hybrid/20-sleep-and-power.sh`, then reboot (it applies from the next boot).

## The second graphics card never sleeps

`./install.sh doctor` prints `nvidia card is: ...`; `suspended` is good when idle. If `/dev/dri/igpu` is missing
the doctor warns: run `./install.sh --only modules`. Something is using the card: `nvidia-smi` lists it. With the
`ai` module, `systemctl stop ollama` lets it sleep. The bar's `dgpu` readings never wake the card.

## No sound

The doctor checks that `pipewire` and `wireplumber` run. Fix: `systemctl --user enable --now pipewire wireplumber`
(and `pipewire-pulse`). Then pick the output in Settings → Sound.

## No password prompt appears

Apps ask for admin rights through `hyprpolkitagent`. The doctor warns when none runs. Log out and back in; if it
persists, `./install.sh --only packages`.

## The monitor input switch does nothing

Needs the `ddc-monitor` module (on for an external screen on a real computer). Check: the `i2c-dev` kernel module
is loaded (the doctor checks; `./install.sh --only modules` loads it); `ddcutil detect` lists your monitor; DDC/CI
is switched on in the monitor's own menu. Not every monitor supports it.

## Tablet mode does not rotate

Needs the `tablet` module and a tablet-mode switch in `hardware.toml` (`input.tablet_switch`):
`./install.sh detect`. Rotation uses `iio-sensor-proxy`. Wrong or missing switch: set it under `[override]`.

## Logitech device not listed

The `logitech` module is on only when a Logitech device or receiver is plugged in when the installer looks.
Plug it in, then `./install.sh detect`, or force it: `./install.sh --with logitech`. Solaar starts hidden in the tray.

## A theme I made does not show up

It must be a folder `~/.config/hyprism/themes/<id>/` with a `theme.json`, and an id that does not start with `_`.
`theme` reads the folders again each time: run it. Compare your file with `_template`. `python3 tests/themes.py`
checks the shipped themes in the repo only. If no theme folder can be read at all, the shell shows a built-in "Safe
mode" theme.

## A setting I typed into settings.json was ignored

The shell checks every value. A bad one is replaced by the default and logged: `qs log` says
`settings.json: SECTION.KEY was invalid, using the default`. Allowed ranges are in `Config.qml`'s schema.

## settings.json is broken

The shell keeps the damaged file as `~/.config/quickshell/settings.json.broken` and starts on defaults. Repair
the copy and move it back, or leave it. The doctor notes it.

## An update broke something

`./install.sh rollback` returns Hyprism itself to the version from before the last update. System packages are
not touched. On Arch with btrfs, snapshots taken by `snap-pac` can be booted (the doctor warns when they are
missing). Fedora has no snapshots by default.

## Qt apps ignore the theme

Qt apps follow the theme through `qt6ct`. Restart the app. The file `~/.config/qt6ct/qt6ct.conf` is written only
if you have none, so one of your own is never changed: delete it to let Hyprism write its own. Check the `qt6ct`
package is installed.

## Fedora: a package is "not available"

The installer warns `no package for fedora` for the `none` lines in `packages/fedora.txt`: `squeekboard`,
`ollama-gpu`, `nvidia-container-toolkit`. They are not packaged in Fedora 44 (see [install.md](install.md#fedora)).
