# Distro backends

`install.sh` reads `/etc/os-release` and sources `distros/<ID>.sh` (or the first `ID_LIKE` that has one:
CachyOS, EndeavourOS and Manjaro say `ID_LIKE=arch`). A backend only talks to the package manager. It defines:

| Function | Does |
|---|---|
| `distro_installed SOURCE PKG` | exit 0 if installed |
| `distro_prepare SOURCES...` | enable extra repos the sources need (COPR, RPM Fusion, …) |
| `distro_update` | update the whole system (`./install.sh update`) |
| `distro_install SOURCE PKGS...` | install a batch from one source; wrap commands in `run` (dry run) |
| `distro_nvidia` | install the NVIDIA driver |
| `distro_supported` | exit 0 when this release is new enough (says why when not) |
| `distro_doctor` | extra doctor checks (for example snapshots before updates) |
| `distro_kernel_args NAME ARGS` | add kernel boot arguments (the `hibernate` module) |

Plus `packages/<ID>.txt`: every logical name from `packages/manifest.txt` mapped to real package names
and a source, checked against the real repos (write `none` with a comment when there is no package).

Adding Debian/Ubuntu: `distros/debian.sh` (apt) + `packages/debian.txt`. Nothing else changes.
