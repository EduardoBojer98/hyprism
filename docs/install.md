# Install Hyprism

One command sets up the desktop. It asks before every change to your system, and it is safe to run again.

## What you need

- A working Arch-family system (Arch, CachyOS, EndeavourOS, Manjaro) or Fedora 44 or newer. Older Fedora is
  refused: its Hyprland and Quickshell are too old.
- A normal user with `sudo`, and an internet connection. Do not run the installer as root: it refuses, and asks
  for `sudo` itself when it needs it.
- A way to start Hyprland (see below).

**What the installer does not do.** It does not install or set up a login manager (the screen where you type your
password). It installs the `hyprland` package, and on Arch that package adds a "Hyprland" entry to
the session list of managers that read `/usr/share/wayland-sessions` (GDM, SDDM and similar). If you already have
a login manager, pick Hyprland there after the install.

With no login manager, start Hyprland from a text console (Ctrl+Alt+F3, log in), with the command Hyprland's
own documentation gives (upstream's instruction, not something Hyprism adds):

```bash
start-hyprland
```

## Arch and CachyOS

Clone the repo anywhere you like. This page uses `~/hyprism`.

```bash
git clone https://github.com/EduardoBojer98/hyprism.git ~/hyprism
```

```bash
cd ~/hyprism
```

**1. Look first.** A dry run shows everything and changes nothing.

```bash
./install.sh --dry-run
```

How to read it:

- The first lines name your distro, the computer (laptop, desktop or VM), its graphics and the modules that
  fit it (see [Optional modules](#optional-modules)).
- `would run: ...` is a command the real run would execute.
- `would ask: ...` is a question the real run would put to you. A dry run lists the questions and does not ask them.
- Packages are listed by where they come from, for example `repo:` followed by the names.

**2. Install.**

```bash
./install.sh
```

In order, it:

1. looks at the hardware and writes `~/.config/hyprism/hardware.toml`;
2. installs the packages that are missing (one question: "Install these?");
3. links the files in `config/` and the active modules into your home folder, one file at a time. A file of
   yours that is in the way is moved to `~/.local/state/hyprism/backups/<time>/`, never deleted;
4. turns on NetworkManager, and Bluetooth when there is an adapter;
5. offers a firewall when none is active (one question; blocks incoming connections, allows outgoing);
6. runs the system steps of each module that is on, one question per step.

Every change to `/etc`, to a service or to your repos is asked first. Answer `n` and that part is skipped; the
end of the run lists what was skipped and how to do it later. `--yes` answers yes to everything: use it only
when you have read the dry run.

**AUR note.** Packages from the AUR are user-submitted recipes. If a package line says `aur`, the installer lists
the names, asks "Build and install these from the AUR?" and needs `paru` or `yay` (CachyOS ships paru). Today every
package in `packages/arch.txt` is in the official repos, so this question normally does not appear.

## Fedora

The steps are the same as on Arch: clone, `./install.sh --dry-run`, `./install.sh`. The difference is where
packages come from. Fedora does not ship Hyprland, so the installer needs other repos. It names each one and asks
before enabling it ("Enable it?"). If you answer no, the packages from that repo are skipped.

| Repo | Why | Packages (from `packages/fedora.txt`) |
|---|---|---|
| COPR `sdegler/hyprland` | Fedora has no Hyprland | Hyprland, its portal, polkit agent, lock screen, idle daemon, wallpaper, Night Light, colour picker, `hyprshutdown`, `satty` |
| COPR `errornointernet/quickshell` | Fedora's own Quickshell is too old | `quickshell` |
| COPR `scottames/ghostty` | not in Fedora | the Ghostty terminal |
| COPR `atim/starship` | not in Fedora | the shell prompt |
| COPR `lukenukem/asus-linux` | only for the `asus` module | `asusctl`, ROG Control Center |
| COPR `jdxcode/mise` | only for the `dev` module | `mise` |
| RPM Fusion (free and nonfree) | software Fedora does not ship | Steam (`gaming` module), the NVIDIA driver (`nvidia` module) |

A COPR is a third-party repo: anyone can publish one. RPM Fusion is a long-running community repo. Read the names
the installer prints before you say yes.

**Not packaged on Fedora** (the `none` lines in `packages/fedora.txt`):

- `squeekboard`, the on-screen keyboard of the `tablet` module. The comment there suggests `maliit-keyboard` or none.
- `ollama-gpu`: Fedora's `ollama` package already uses the graphics card when the NVIDIA driver is there.
- `nvidia-container-toolkit`: only in NVIDIA's own repo, which is not added for you.

The installer prints a warning for each and carries on.

## After installing

1. Log out. Pick **Hyprland** at the login screen (or run `start-hyprland` from a text console).
2. The first time, a **Welcome** panel offers a theme, light or dark, a bar layout and your keyboard layouts, and
   lists the keys to know. Tap `Super` to search, `Super+I` for Settings, `Super+/` for every shortcut. The
   "Welcome" action in the launcher shows it again.
3. The installer sets a default app for folders, links, text, images and PDFs, only where you have none yet
   (`./install.sh --only defaults` runs it again; it never changes a choice you made).
4. Check the result:

```bash
./install.sh doctor
```

The doctor compares this computer with the repo and changes nothing. Each problem comes with the command that fixes
it. See [troubleshooting.md](troubleshooting.md#the-doctor).

## Optional modules

A module adds support for hardware or a use that not every computer has. Some switch on by themselves when the
installer finds the hardware; some only when you ask.

```bash
./install.sh modules
```

lists them as `on` or `off`, and why. Turn one on or off (your choice is remembered):

```bash
./install.sh --with gaming
```

```bash
./install.sh --without gaming
```

| Module | What it adds | On when |
|---|---|---|
| `ai` | Ollama, with the CUDA build on NVIDIA | you ask: `--with ai` |
| `asus` | `asusctl`, charge limit, fan curves, keyboard light, ASUS page in Settings | ASUS laptop |
| `ddc-monitor` | `ddcutil`, so an external monitor's input can be switched | an external screen on a real computer |
| `dev` | `mise` (Node, PHP, Python versions), Docker | you ask: `--with dev` |
| `gaming` | Steam with Proton, GameMode, MangoHud | you ask: `--with gaming` |
| `hibernate` | a swap file and the kernel resume setting | you ask: `--with hibernate` (btrfs only) |
| `laptop` | sleep on lid close, keep running with an external screen | a laptop |
| `logitech` | Solaar for Logitech mice and keyboards | a Logitech device is plugged in |
| `nvidia` | the NVIDIA driver | an NVIDIA card |
| `nvidia-hybrid` | desktop on the built-in GPU so the NVIDIA card can power off | laptop with built-in + NVIDIA |
| `quirk-flow-x13` | microphone and fan fixes for one model | the ASUS ROG Flow X13 (GV301QC) |
| `tablet` | on-screen keyboard, rotation, tablet mode | a touch screen or tablet-mode switch |

Details, and what each one changes and how to undo it: [modules.md](modules.md).

## Updating

```bash
./install.sh update
```

It pulls Hyprism (only when the repo has no local changes), updates the whole system, runs new migrations, adds
new packages, relinks, runs module steps that are new or changed (asked first), and ends with the doctor. The same
thing is **Settings → About → Update**.

A migration is a one-time change that moves your files to a newer layout. Each runs once and is listed before it runs.

```bash
./install.sh rollback
```

goes back to the Hyprism version from before the last update. It does not touch system packages: on Arch with
btrfs, use your snapshots for those (the doctor says whether you have them).

## Removing

```bash
./install.sh uninstall
```

What it does, in order:

1. Removes the links it made. Your own files stay.
2. Offers to put back the files that were backed up when they were in the way (the newest backup, or
   `--backup NAME`; `./install.sh backups` lists them).
3. Lists the system changes it made (`/etc` files, services it enabled or masked) and asks before undoing them:
   files go back to what they were, services to their earlier state. Things it cannot undo by itself, such as
   the docker group, are listed for you to do by hand.
4. Moves your generated settings (`~/.config/hypr/settings`, `~/.config/quickshell/settings.json`, the Ghostty and
   fuzzel theme files, `~/.config/hyprism`) into `~/.local/state/hyprism/removed-<time>/`. Nothing is deleted.

What it leaves: installed packages, and the repo folder. Delete the folder yourself when you are done.

## In a virtual machine

Hyprism installs and starts in a VM. The installer sees the VM and turns on no hardware modules.

- Works: install, update, doctor, themes, the bar, Settings, the launcher, keys.
- A VM without 3D installs and starts (this is what `docs/hardware.md` lists as supported). The manual checklist ([testing/vm-checklist.md](testing/vm-checklist.md)) uses a VM with 3D off, 4 GB of memory
  and one screen for the install part.
- Cannot be tested in a VM: sleep, lid, battery, brightness, touch, a real monitor's DDC, Logitech devices and
  graphics drivers. These are in the same checklist and need real hardware.
