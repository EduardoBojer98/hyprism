# Distro backends

`install.sh` reads `/etc/os-release` and sources `distros/<ID>.sh` (or the first `ID_LIKE` that has one;
CachyOS, EndeavourOS and Manjaro use `arch.sh`). A backend only talks to the package manager. It defines:

| Function | Does |
|---|---|
| `distro_installed SOURCE PKG` | exit 0 if installed |
| `distro_prepare SOURCES...` | enable extra repos the sources need (COPR, RPM Fusion, Flathub, …) |
| `distro_install SOURCE PKGS...` | install a batch from one source; wrap commands in `run` (dry run) |
| `distro_nvidia` | install the NVIDIA driver |

Plus `packages/<ID>.txt`: every logical name from `packages/manifest.txt` mapped to real package names
and a source, checked against the real repos (write `none` with a comment when there is no package).

Adding Debian/Ubuntu: `distros/debian.sh` (apt) + `packages/debian.txt`. Nothing else changes.
