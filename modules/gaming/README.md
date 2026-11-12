# Module: gaming

Steam with Proton, GameMode and an on-screen performance overlay (MangoHud).

- **On when:** only when you ask: `./install.sh --with gaming`.
- **Adds:** Steam (Arch: from `multilib`, which CachyOS has on and plain Arch needs enabled in
  `/etc/pacman.conf`; Fedora: from RPM Fusion, named before it is enabled), `gamemode`, `mangohud`.
- **Windows games:** in Steam, Settings → Compatibility → "Enable Steam Play for all other titles".
- **Per game** (Properties → Launch Options):
  - `gamemoderun %command%` asks the system for performance while the game runs;
  - `mangohud %command%` shows frame rate, temperatures and load;
  - on a laptop with two graphics cards, `nv %command%` runs the game on the powerful one. All three:
    `nv gamemoderun mangohud %command%`.
- **Check the card in use:** MangoHud names the GPU; `./install.sh doctor` shows whether the second card is awake.
- **Tested on:** package names on Arch and Fedora; play-tested by the owner (see the manual checklist).
