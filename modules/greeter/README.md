# Module: greeter

A themed login screen (greetd + ReGreet) in place of the desktop's own (Plasma Login Manager, SDDM, GDM, LightDM).

- **On when:** you chose the full setup at install (`--profile full`), or `./install.sh --with greeter`.
  The base setup keeps your login screen (`--without greeter` does too). Every system change is still asked first.
- **Adds:** `greetd`, `regreet`, `cage`, `wlr-randr`; `/etc/greetd/config.toml`, `session.sh` (the login screen
  shows on the laptop panel when its lid is open, else on the last screen plugged in), `regreet.toml`,
  `regreet.css` (the active theme's colours, copied when the step runs: run it again after changing theme), and
  KDE Wallet unlock in `/etc/pam.d/greetd` so browser and Git passwords stay unlocked at login.
- **Takes effect:** at the next boot. The old login screen is disabled, not removed.
- **Undo:** `./install.sh uninstall` switches greetd off and your old login screen back on (from the next boot), and puts the files in `/etc/greetd` back.
- **Fedora:** ReGreet is not packaged; the step stops with a note and changes nothing.
- **Tested on:** the owner's Flow X13 (CachyOS).
