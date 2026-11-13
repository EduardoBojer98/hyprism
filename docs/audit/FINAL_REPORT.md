# Final report (2026-11-13)

What the overhaul did, measured against [AUDIT.md](AUDIT.md), with the proof for each score and an honest list
of what is still open. Work is on branch `overhaul` (pull request 1). Nothing has been applied to a real desktop.

## Scores, before and after

A 10 needs proof for every acceptance line in the audit. Where the proof needs real hardware that only the
owner can run, the score stops short and the reason is in the last column.

| # | Department | Before | After | Proof, and what is missing for 10 |
|---|---|---|---|---|
| 1 | Install & bootstrap | 7 | 9 | CI on Arch and Fedora: install twice, third run changes nothing, forced failure exits non-zero with a summary, log file. Missing: a fresh install on a real disk (checklist A). |
| 2 | Updates & migrations | 3 | 10 | CI job `update`: installs v1.1.0, moves to this code, three migrations run once, second run runs none, `rollback` returns to the earlier commit, doctor clean. |
| 3 | Uninstall / restore | 5 | 9 | CI: after uninstall the home folder is as it was. System undo is covered for the files the container can write; services are not testable there. |
| 4 | Repo structure & readability | 6 | 8 | No shell file over 400 lines (largest 397); modules, themes and bar items are folders. Missing: the shell's 164 QML files still sit in one folder (see "Decided not to do"). |
| 5 | Consistency | 6 | 9 | `tests/format.sh` clean on 87 shell files; one usage helper; one name; colours only in theme files (lint). |
| 6 | Theming | 5 | 9 | Themes are folders; copy and edit one file (shown in the test desktop); 14 halves pass the extended contrast test; `tests/theme-targets.sh` finds the accent in six generated files for three themes. Missing: login screen. |
| 7 | Bar & widgets | 4 | 9 | 24 item folders; per-item settings; presets; per-screen layouts; 25 readings; `tests/metrics.sh` (34 checks); round-trip test. Missing: items are clipped, not dropped, when a bar is too narrow; vertical bars not re-checked. |
| 8 | Launcher & central menu | 6 | 9 | Grouped menu with every item of the brief except "new web app" (needs a name and address: terminal command). Seen in the test desktop. |
| 9 | Keybindings | 8 | 10 | `tests/keybinds.sh`: 94 binds, 0 clashes; binds only for present hardware; one layout switch; cheat sheet reads them live. |
| 10 | Settings panel | 7 | 9 | `tests/settings-roundtrip.sh` (file and IPC agree both ways, invalid refused); generated reference checked in CI. Missing: 65 settings have no explanatory comment; the terminal has no row. |
| 11 | Displays | 4 | 8 | No screen name in core; adaptive sync, refresh preference, options; `monswitch inputs` reads real inputs (9 checks against captured output). Missing: real hand-off test (checklist E); saved layouts are per output name, not per set of monitors. |
| 12 | Input devices | 5 | 7 | Touchpad options; tablet switch by detected name; Solaar module. Missing: per-device settings; tablet mode and haptics on the real laptop (checklist D, F). |
| 13 | Notifications & OSD | 6 | 9 | Five OSDs with settings; seen in the test desktop. Mic, layout and caps OSDs were triggered through the test hook, not by real events. |
| 14 | Lock, idle, power, sleep | 6 | 8 | Idle times per power source (5 script tests); a desktop never sleeps by itself; opt-in charge limit. Missing: real sleep and lid tests (checklist B). |
| 15 | Screenshots & recording | 8 | 9 | Pin added (seen); recording uses the right card with a software fallback. Missing: both sound sources at once (the recorder takes one); real recording test. |
| 16 | Clipboard | 8 | 9 | Private folder (test). Listing speed not changed. |
| 17 | Audio / network / Bluetooth | 7 | 9 | In the menu, the Control Center and Settings; hidden without an adapter. |
| 18 | Laptop & hardware support | 3 | 7 | Detected modules replace the hostname folder; module choice tested on seven made-up computers. Missing: every module step has only run as a dry run (checklist C). |
| 19 | Gaming & local AI | 1 | 7 | Opt-in modules with guides; packages resolve on both distros in CI. Missing: a game and a model actually run (checklist). |
| 20 | Developer workflow | 4 | 8 | Opt-in `dev` module (mise, Docker); prompt follows the theme. Missing: editor theme hint. |
| 21 | Apps & defaults | 5 | 8 | Default apps set only where unset; Qt apps themed without KDE; own emoji list; keyring and polkit found on both distros. Missing: no viewer or office packages are installed for you. |
| 22 | Performance | 7 | 9 | `tests/performance.sh`: 0.37 % of one core idle, 299 MB, no reader running when no item needs one. Not run in CI (needs a desktop). |
| 23 | Reliability & diagnostics | 6 | 9 | Doctor with a fix on every finding; CI breaks six things and checks each is reported. Module checks are thin for `tablet` and `logitech`. |
| 24 | Security & privacy | 6 | 9 | Named AUR / COPR prompts; pinned plugin build on update only; firewall offer; secret scan of the whole history in CI. The pin table has no entry for Hyprland 0.57.2 (upstream has no such tag), so title-bar buttons stay on the copy already built. |
| 25 | Accessibility | 5 | 8 | Names and roles on every control and click target (CI fails on a new unnamed one); bar reachable by keyboard; contrast for accents and status colours. Missing: a screen-reader run. |
| 26 | First-run experience | 2 | 9 | Welcome panel seen in the test desktop; sets only `settings.json`. |
| 27 | Documentation | 6 | 9 | Install, how-to, troubleshooting, modules, hardware, themes, bar, settings reference; `tests/docs.sh` checks links, paths and commands. No outside reader has tried it yet. |
| 28 | Testing & CI | 6 | 10 | Six CI jobs, all green; 24 test scripts; `tests/all.sh` runs the same locally. |
| 29 | Hardware coverage | 3 | 8 | `hardware.toml`, overrides, seven profiles in CI, `tests/no-hardcode.sh`. Missing: real hardware beyond one laptop. |
| 30 | Distro abstraction | 6 | 9 | No package-manager command outside `distros/` (test). Boot-loader arguments cover Limine and Fedora only. |

**Average: 5.4 before, 8.7 after.** Three departments are at 10. The rest are not, and the gap is named in each
row: most need the manual checklist, a few are real unfinished items (below).

## Biggest changes and decisions

- **Hardware is detected** (`./install.sh detect` → `hardware.toml`); **modules** replace `hosts/`. [hardware.md](../hardware.md)
- **The bar stays on Quickshell** ([ADR 0001](../decisions/0001-bar-technology.md)) and became modular: [bar.md](../bar.md).
- **Themes are folders**; Reactor is the default; five more programs follow the theme. [THEMES.md](../THEMES.md)
- **Installer**: split into `lib/`, migrations, rollback, real uninstall, a log of every run.
- **Removed**: `hosts/`, the KDE fallback, JuhRadial (Solaar instead), the LTS-kernel workaround, 14 hand-kept
  terminal palettes, the second sensor reader. Each is in `CHANGELOG.md`.
- **New packages**: `qt6ct`, `btop`, `unicode-emoji` in core; `solaar`, `iio-sensor-proxy` and the optional
  modules' packages only where their module is on. Reasons in [DECISIONS.md](../DECISIONS.md).

## Decided not to do

- **Sub-folders for the shell's QML.** Every file is under 400 lines and named by its panel, so files are easy
  to find. Moving 164 files into folders changes every import and risks a broken shell for no gain a user sees.
- **Saved layouts per set of monitors.** Each output's mode, scale and place is already remembered by name and
  comes back when it is plugged in.
- **Theming the login screen.** It runs as another user before login and differs per display manager.

## Still open (real unfinished work)

1. Bar items are clipped when a bar is too narrow for them; they should drop out in a set order.
2. Per-device input settings (one touchpad or mouse differently from another).
3. 65 settings have no explanatory comment, so their rows in the settings reference are empty.
4. No row in Settings for the default terminal (file key `apps.terminal` works).
5. The plugin pin table needs an entry once upstream tags a release for Hyprland 0.57.2.
6. The second `screenshot` audio source, and the "new web app" menu entry.

## What only you can check

Run [testing/vm-checklist.md](../testing/vm-checklist.md) on the laptop and write the result in its table. The
short version, in order:

1. `./install.sh update` in the main checkout (it pulls, runs three migrations, relinks, then asks before each
   package and system step). Until this runs, your desktop is exactly as before.
2. `./install.sh doctor`: expect no problems; the NVIDIA card should read `suspended` when idle.
3. Fold the screen back: tablet mode. On this kernel the switch is reported by "Asus WMI hotkeys"; the old
   config named a different device, so tablet mode may not have been working before.
4. `Super+M` with the monitor connected: the hand-off. Settings → Displays → Shared Monitor should now list the
   monitor's inputs by name; this monitor refuses the "capabilities" query, so it may fall back to the usual codes.
5. Solaar: `solaar config 'mx master 4' haptic-play 'HAPPY ALERT'`. Remove JuhRadial once Solaar works.
6. Sleep, wake, lid with and without the monitor; a screen recording; `nv glxinfo -B`.
7. Optional: `./install.sh --with gaming` and `--with ai`, then one game and `ollama run llama3.2`.

## Good next ideas

- A stranger test: someone who has never seen the repo installs it from the docs in a VM and notes every stumble.
- A second real laptop (Intel or Framework) to prove the detection beyond fixtures.
- openSUSE Tumbleweed: one backend file and one package map.
- Run `tests/performance.sh` and the screenshot retake on a schedule, so drift shows up.
