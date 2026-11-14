# Module: nvidia

The NVIDIA driver, installed the way your distro recommends.

- **On when:** an NVIDIA card is found (`gpu.vendors`).
- **Adds:** the driver, only if it isn't loaded yet. CachyOS uses its hardware tool, plain Arch the open
  modules, Fedora the RPM Fusion driver.
- **Sleep:** where the driver can save video memory itself (kernel suspend notifiers), that is switched on and
  NVIDIA's sleep services are switched off: their switch to a text console before every sleep could leave the
  screen black on wake. Older drivers keep the services. File: `/etc/modprobe.d/hyprism-nvidia-sleep.conf`.
- **Needs:** a reboot afterwards. With Secure Boot on Fedora, enroll the key (the step tells you how).
- **Tested on:** fixture `desktop-nvidia`; the owner's Flow X13 (driver already present).
