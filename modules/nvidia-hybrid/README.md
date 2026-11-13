# Module: nvidia-hybrid

Laptops with a built-in GPU plus an NVIDIA one: the desktop draws on the built-in GPU so the NVIDIA card can
power off, and sleep works.

- **On when:** a laptop has two cards and the second is NVIDIA (`gpu.hybrid`, `gpu.discrete`).
- **Adds:**
  - `/dev/dri/igpu`, a stable name for the built-in card (found by its PCI address in `hardware.toml`), which
    Hyprland uses to draw only there;
  - NVIDIA's sleep services and the option that keeps video memory across sleep;
  - runtime power-off for the NVIDIA card when no app uses it.
- **Run an app on the NVIDIA card:** `nv APP`.
- **Check it:** `./install.sh doctor` says whether the card is asleep.
- **Tested on:** fixture `laptop-hybrid-nvidia`; the owner's Flow X13.
