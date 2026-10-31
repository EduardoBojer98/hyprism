# Hosts: what differs between computers

`install.sh` picks one host: `--host <name>`, else the folder whose `host.conf` lists this computer's
hostname (`cat /etc/hostname`), else `default`. Everything in a host folder is optional:

| File | What it does |
|---|---|
| `host.conf` | `HOSTNAMES="name1 name2"`: which computers use this host |
| `packages.txt` | extra packages by logical name (mapped in `packages/<distro>.txt`) |
| `home/` | files linked into your home folder like `config/`; `home/.config/hypr/host.lua` runs last in Hyprland (monitors, workspaces, hardware switches) |
| `defaults/` | files copied into your home folder once, if missing (the Settings app may change them later) |
| `steps/NN-*.sh` | system steps, run in order after asking (`*.user.sh` run as you, the rest with sudo) |

New computer: `cp -r hosts/default hosts/<name>`, put its hostname in `host.conf`, then `./install.sh`.
`flow-x13/` is the ASUS ROG Flow X13: tablet switch, workspaces per screen, microphone fix, shared
Acer monitor, ASUS tools, NVIDIA/iGPU and power steps.
