# Module: greeter

A themed login screen (greetd + ReGreet) in place of the desktop's own (Plasma Login Manager, SDDM, GDM, LightDM).

- **On when:** you chose the full setup at install (`--profile full`), or `./install.sh --with greeter`.
  The base setup keeps your login screen (`--without greeter` does too). Every system change is still asked first.
- **Adds:** `greetd`, `regreet`, `cage`; `/etc/greetd/config.toml`, `regreet.toml`, `regreet.css` (the active
  theme's colours, copied when the step runs: run it again after changing theme), and KDE Wallet unlock in
  `/etc/pam.d/greetd` so browser and Git passwords stay unlocked at login.
- **Takes effect:** at the next boot. The old login screen is disabled, not removed.
- **Undo:** `sudo systemctl disable greetd`, then `sudo systemctl enable` your old one (the step prints its name).
- **Fedora:** ReGreet is not packaged; the step stops with a note and changes nothing.
- **Tested on:** the owner's Flow X13 (CachyOS).
