# Hardware

Hyprism is built for any normal PC or laptop. It looks at the computer once, writes what it found to a small
file, and everything optional reads that file. Nothing in the core names a device.

## How it works

```bash
./install.sh detect
```

prints `~/.config/hyprism/hardware.toml`. The installer runs it for you on every install and update.

```toml
[machine]
form = "laptop"            # laptop | desktop | vm
[gpu]
primary = "amd"            # draws the desktop
discrete = "nvidia"        # the second card ("" when there is one)
hybrid = true
[display]
internal = "eDP-1"         # the laptop's own screen ("" on a desktop)
external = ["HDMI-A-1"]
[power]
battery = "BAT0"
...
[override]
# your corrections go here; detect never changes this part
```

**A wrong guess?** Add a line under `[override]` with the section and key, for example
`display.internal = "eDP-2"` or `module.tablet = false`. It wins over detection and survives every update.

**Modules** are the optional parts. Each one has a `detect` file that reads `hardware.toml`:

```bash
./install.sh modules
```

lists them with on / off. `./install.sh --with NAME` and `--without NAME` set your own choice.

## Support matrix

"Fixture" means one of the seven made-up computers in `tests/detect.sh`. CI runs detection, module selection,
an installer dry run and Hyprland's own config check on every one, on Arch and Fedora.

| Hardware | What you get | Detected from | Module | Tested on |
|---|---|---|---|---|
| Desktop, laptop, VM | The right defaults for each (no lid rule or battery things on a desktop; no hardware extras in a VM) | DMI chassis type and vendor, a battery | — | all fixtures |
| AMD or Intel graphics, one card | Nothing to set up: the kernel drivers are enough | DRM cards (`/sys/class/drm`), PCI vendor | — | fixtures `desktop-amd`, `laptop-intel`, `hidpi-single`, `multi-monitor` |
| NVIDIA graphics | The driver your distro recommends, if none is loaded | PCI vendor `0x10de` | `nvidia` | fixture `desktop-nvidia`; owner's laptop |
| Hybrid laptop (built-in + NVIDIA) | Desktop on the built-in card, NVIDIA card powers off when idle, sleep works, `nv APP` runs an app on it | Two cards on a laptop; the built-in one is the card with the laptop panel | `nvidia-hybrid` | fixture `laptop-hybrid-nvidia`; owner's laptop |
| VM without 3D | Installs and starts; no hardware modules | DMI vendor (QEMU, VirtualBox, VMware…), a virtual DRM card | — | fixture `vm`; CI runners |
| Any monitor, any resolution | Preferred mode, automatic scale, plug in and it works | Hyprland at run time | — | Hyprland config check; owner's 1920×1200 + 1440p |
| Several monitors | A laptop starts on workspace 1 and the first other screen on 2; arrange them in Settings → Displays | Connected DRM outputs | — | fixtures `multi-monitor`, `laptop-hybrid-nvidia` |
| Monitor shared with another computer | Switch its input from the desktop, windows move over | An external screen on a real computer | `ddc-monitor` | owner's laptop with a 1440p monitor on HDMI |
| Laptop lid | Sleep on close, keep running with an external screen | `machine.form` | `laptop` | fixtures; owner's laptop |
| Battery | Battery item, low-battery warning, charge limit where the kernel offers it | `/sys/class/power_supply` (type Battery) | — (shell reads `hardware.toml`) | fixtures with and without a battery |
| Screen brightness | Brightness keys and slider | `/sys/class/backlight` | — | owner's laptop |
| Keyboard backlight | Shown where a keyboard light exists | `/sys/class/leds/*kbd_backlight*` | — | owner's laptop |
| Touchpad | Tap, natural scroll, three-finger gestures | Input devices with the "pointer" property | — | fixtures `laptop-*` |
| Touchscreen, 2-in-1 | On-screen keyboard; tablet mode with rotation when folded | Input devices with the "direct" property; a tablet-mode switch; a rotation sensor | `tablet` | fixture `laptop-hybrid-nvidia`; owner's laptop |
| Any mouse or keyboard | Works through libinput, nothing to set up | — | — | — |
| Logitech devices | Buttons, DPI, battery, MX Master 4 haptics (Solaar) | A Logitech HID device (`046D`) | `logitech` | owner's MX Master 4 |
| Bluetooth, Wi-Fi | Service and controls only where there is an adapter | `/sys/class/bluetooth`, `/sys/class/net/*/wireless` | — | fixtures with and without |
| ASUS laptops | Charge limit, power modes, fan curves, keyboard light (`asusctl`) | DMI vendor | `asus` | owner's laptop |
| One model's fixes | For example the Flow X13's microphone and fan curves | DMI product name | `quirk-<model>` | owner's laptop |
| Hibernation | Swap file and resume, when you ask for it | never automatic | `hibernate` | owner's laptop (CachyOS, Limine) |

Vendors with no module yet (Lenovo, Dell, Framework, HP) are recognised (`machine.tools`) and work through the
standard interfaces above: battery through UPower, power modes through power-profiles-daemon, brightness through
brightnessctl.

## What can't be tested automatically

Real drivers, sleep and resume, a real monitor's DDC, haptics and touch need the real hardware. Those are on the
checklist in [testing/vm-checklist.md](testing/vm-checklist.md).

## Add support for something

1. If detection needs a new fact, add it to `detect_hardware` in `lib/detect.sh` and a line to a fixture in
   `tests/detect.sh`.
2. `cp -r modules/_template modules/<name>`, write `detect` (one line that reads `hardware.toml`), and fill in
   what it adds: `packages.txt`, `home/`, `steps/`, `doctor`, `README.md`.
3. Add the module to the expected list for its fixture in `tests/container-test.sh`.
