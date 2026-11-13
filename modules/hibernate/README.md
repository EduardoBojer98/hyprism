# Module: hibernate

Hibernation (save to disk, power off) with a swap file, so a sleeping laptop stops using battery after an hour.

- **On when:** only when you ask: `./install.sh --with hibernate`. It changes `/etc/fstab` and the kernel
  boot line, so it is never automatic.
- **Needs:** a btrfs root. The swap file is sized from your memory.
- **Boot loaders:** Limine and Fedora's (through `grubby`) are set up for you; for others the step prints the
  line to add.
- **Undo:** `./install.sh uninstall` restores the files and lists what is left to do by hand.
- **Tested on:** the owner's Flow X13 (CachyOS, Limine).
