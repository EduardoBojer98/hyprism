# Module: nvidia-hybrid

Laptops with a built-in GPU plus an NVIDIA one: the desktop draws on the built-in GPU so the NVIDIA card can
power off, and sleep works.

- **On when:** a laptop has two cards and the second is NVIDIA (`gpu.hybrid`, `gpu.discrete`).
- **Adds:**
  - `/dev/dri/igpu`, a stable name for the built-in card (found by its PCI address in `hardware.toml`), which
    Hyprland uses to draw only there;
  - video memory kept across sleep: by the driver itself where it can (its kernel suspend notifiers, and
    NVIDIA's sleep services switched off, since their console switch could leave the laptop screen black on
    wake), else by NVIDIA's sleep services;
  - runtime power-off for the NVIDIA card when no app uses it.
- **Run an app on the NVIDIA card:** `nv APP`.
- **Check it:** `./install.sh doctor` says whether the card is asleep.
- **Tested on:** fixture `laptop-hybrid-nvidia`; the owner's Flow X13.
