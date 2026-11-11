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
| `distro_pkg_owners FILE...` | print `FILE<TAB>PACKAGE` for each file a package owns (nothing for unowned files) |
| `distro_pkg_source PACKAGE...` | print `PACKAGE<TAB>LABEL` for each: where the app list says it came from (`pacman`, `aur`, `rpm`) |
| `distro_pkg_versions PACKAGE...` | print `PACKAGE<TAB>VERSION<TAB>SIZE` for each package (the app list) |
| `distro_pkg_info PACKAGE` | `Label<TAB>value` lines for the app details panel |
| `distro_pkg_url PACKAGE` | homepage URL, or nothing |
| `distro_pkg_remove_cmd PACKAGE` | the removal command as words on one line (run in a terminal by `installed-apps`) |

The `distro_pkg_*` functions are also used by `installed-apps`, which sources the backend on its own:
they must not call `run`, `warn`, `say` or `sys_write`, and sourcing a backend must not run anything.

Plus `packages/<ID>.txt`: every logical name from `packages/manifest.txt` mapped to real package names
and a source, checked against the real repos (write `none` with a comment when there is no package).

Adding Debian/Ubuntu: `distros/debian.sh` (apt) + `packages/debian.txt`. Nothing else changes.
