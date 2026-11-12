# Modules

A module is an optional part for hardware or a use that not every computer has. It is on when its `detect` file
says the hardware is here, or when you turned it on yourself. `./install.sh modules` lists them.

```bash
./install.sh --with NAME
```

```bash
./install.sh --without NAME
```

Your choice is remembered in `~/.config/hyprism/hardware.toml` under `[override]`. Run `./install.sh` to apply it.
Each module has a README in its folder: `modules/<name>/README.md`.

| Module | What it is for | On when | What it changes on the system | Undo |
|---|---|---|---|---|
| `ai` | Ollama, models on your own computer | you ask | packages; on NVIDIA also the CUDA build and container toolkit | `./install.sh --without ai`; `systemctl stop ollama` |
| `asus` | ASUS charge limit, power modes, fan curves, keyboard light | ASUS laptop | packages (`asusctl`, ROG Control Center); enables `asusd` | `./install.sh uninstall` disables the service |
| `ddc-monitor` | switch an external monitor's input over DDC/CI | external screen on a real computer | `ddcutil`; `/etc/modules-load.d/hyprism-i2c.conf` | `./install.sh uninstall` |
| `dev` | mise (Node, PHP, Python versions), Docker | you ask | packages; Docker starts on first use; optional `docker` group (asked) | uninstall; `sudo gpasswd -d $USER docker` |
| `gaming` | Steam, GameMode, MangoHud | you ask | packages only (Fedora: RPM Fusion) | `--without gaming`; remove packages |
| `hibernate` | hibernate with a swap file | you ask (btrfs root) | `/etc/fstab`, a swap subvolume, kernel boot arguments | `./install.sh uninstall` restores files, lists the rest |
| `laptop` | lid: sleep on close, run with an external screen | laptop | `/etc/systemd/logind.conf.d/50-hyprism-lid.conf` | `./install.sh uninstall` |
| `logitech` | Solaar for Logitech devices | a Logitech device | package `solaar`; tray entry at login | `--without logitech` |
| `nvidia` | the NVIDIA driver | NVIDIA card | the driver, if none is loaded (reboot after) | remove with your package manager |
| `nvidia-hybrid` | draw on the built-in GPU so the NVIDIA card sleeps | laptop with built-in + NVIDIA | `/etc/udev/rules.d/90-hyprism-igpu.rules`, `/etc/modprobe.d/hyprism-nvidia.conf`, NVIDIA sleep services, masks `nvidia-powerd` | `./install.sh uninstall` |
| `quirk-flow-x13` | microphone and fan fixes for one model | product name has `GV301QC` | a WirePlumber rule; asusctl power-mode settings | `--without quirk-flow-x13` |
| `tablet` | on-screen keyboard, rotation, tablet mode | touch screen or tablet switch | packages (`squeekboard`, `iio-sensor-proxy`); hinge binds | `--without tablet` |

Step files that change `/etc` or services are asked one by one, and recorded so `./install.sh uninstall` can undo
them.

## How a module is built

A folder `modules/<name>/` with these files. Only `detect` and `README.md` are needed.

| File | What it is |
|---|---|
| `detect` | bash; exit 0 when this computer has the hardware (reads `hardware.toml` with `hw_get`) |
| `packages.txt` | extra packages by logical name, one per line with the reason |
| `home/` | files linked into `~`, like `config/` |
| `steps/NN-*.sh` | system changes, asked one by one; they use `run`, `sys_write`, `sys_enable`, so `--dry-run` shows them and uninstall can undo them |
| `doctor` | extra checks for `./install.sh doctor` |
| `README.md` | what it is for; line 3 is the one-line summary `./install.sh modules` shows |

A step runs once; it is offered again when its file changes, or with `./install.sh --step NAME/NN-file.sh`.

## Write a module

1. Copy the template: `cp -r modules/_template modules/NAME`.
2. Write `detect`, fill in `packages.txt` (and map each name in `packages/arch.txt` and `packages/fedora.txt`), add
   `home/`, `steps/` or `doctor` if needed.
3. Write the README (line 3 is the summary) and run `./install.sh modules`, then `tests/lint.sh`.

Rules: no hardware names outside `modules/` ([CONVENTIONS.md](CONVENTIONS.md)). Add the module to the expected
list of its fixture in `tests/container-test.sh`.
