# Roadmap (2026-11-11)

The work that takes every department in [AUDIT.md](AUDIT.md) to 10/10. Foundations first, then features, then
polish. Nothing here has started: it waits for the owner's OK at the checkpoint.

**Tiers:** **L** = lead (architecture, tricky hardware, security, every review). **M** = mid-tier agent (a feature
with a clear spec). **C** = cheap agent (mechanical work). Every item is reviewed by the lead before it counts.

**Rules for every item:** a branch commit per logical change on `overhaul`; `tests/lint.sh` and the container
test stay green; nothing is applied to the live session, and no package or system file changes, without asking.

## Order at a glance

```
A foundations ──► B hardware layer ──► C theme packages ──► D modular bar ──► E features ──► F proof and docs
   (A1–A6)          (B1–B6)              (C1–C5)              (D1–D5)          (E1–E12)        (F1–F6)
```

B, C and D each depend on A. D depends on C (items read tokens) and on B (hardware items hide themselves).
E items depend on B and D where marked. F runs last, but its tests are added with each item.

## A. Foundations

| ID | Goal | Files | Done when | Verify | Tier |
|---|---|---|---|---|---|
| A1 | Conventions written down: naming, script header, usage helper, QML layout, commit style, how to add a module / theme / bar item / setting | `docs/CONVENTIONS.md` | Every later brief can link it | Read-through by the lead | L |
| A2 | Repo hygiene: `LICENSE`, `CHANGELOG.md`, `CONTRIBUTING.md`, `VERSION`; old process docs to `docs/history/`; delete `.council/` and the merged branch | root, `docs/` | Files exist; README links resolve | docs-link check (F2) | C |
| A3 | One name: Hyprism in paths, state folder, CSS names (the old state folder is moved by the first migration) | repo-wide | grep finds `linux-setup` only in the migration and history | grep in CI | C |
| A4 | Format and lint: `shfmt` once, shared `lib/common.sh` (usage, log, repo path, helpers that are copied today), shellcheck at style level | all scripts, `lib/` | `shfmt -d` and shellcheck `-S style` clean | CI | C |
| A5 | Installer split and hardened: `install.sh` becomes a thin entry over `lib/*.sh`; log file, failure summary, non-zero exit on failed packages, preflight, dry run prints questions | `install.sh`, `lib/` | Audit dept 1 criteria | container test + a forced-failure test | L |
| A6 | Distro layer complete: backend gains owner / info / remove, kernel arguments, initramfs, doctor extras, firewall; all leaks removed | `distros/`, `BIN/installed-apps`, steps | grep for `pacman\|dnf\|rpm\|paru\|limine` outside `distros/` and `packages/` is empty | grep test + both containers | L |
| A7 | Migrations and rollback: `migrations/NNNN-name.sh` run once in order; existing one-off moves become migrations 0001–0003; `rollback` returns to the commit before the last update; real `uninstall` from a manifest of written files | `install.sh`, `lib/`, `migrations/` | Audit depts 2 and 3 criteria | CI: previous tag → update → doctor; install → uninstall → tree unchanged | L |
| A8 | QML folders: `bar/`, `panels/`, `settings/`, `controls/`, `services/`; split `ControlCenter`, `Dock`, `Launcher` | `QS/` | No file over 400 lines; shell starts with no log errors | lint + nested Hyprland session | M |

## B. Hardware layer (depends on A5, A6)

| ID | Goal | Files | Done when | Verify | Tier |
|---|---|---|---|---|---|
| B1 | `detect` writes `~/.config/hyprism/hardware.toml`: form factor, CPU vendor, GPUs (vendor, driver, which one drives the screen), internal panel, monitors, battery, backlight, keyboard light, touchpad, touchscreen, tablet switch, rotation sensor, Bluetooth, wifi, DDC monitors, vendor tools, known peripherals. A `[override]` section wins. Reads only `/sys` and standard tools, so it can run against a fake root | `lib/detect.sh`, `tests/fixtures/<profile>/` | Seven fixture profiles produce the expected file | `tests/detect.sh` in CI | L |
| B2 | Module system replaces `hosts/`: `modules/<name>/` with `detect` (yes/no from `hardware.toml`), `packages.txt`, `home/`, `steps/` (each with an undo part), `doctor`, `README.md`. The X13 folder is dissolved into modules; a migration carries the owner's machine over | `modules/`, `install.sh`, `lib/` | Renaming the laptop changes nothing; default install on fixtures picks the right modules | fixture tests | L |
| B3 | Modules: `nvidia`, `nvidia-hybrid` (iGPU found by vendor and boot flag, generic `/dev/dri/igpu`, sleep services, runtime power-down, session environment not tied to fish), `amd`, `intel` | `modules/` | Hybrid fixture selects it; single-GPU fixtures don't; the owner's dGPU reads `suspended` at idle | fixtures + owner checklist | L |
| B4 | Modules: `laptop` (battery, lid, charge limit where the kernel file exists, keyboard light keys, AC / battery idle times), `asus` (asusctl, fans; `asusfan`, `thermlog` move here), `tablet` (any tablet switch, rotation, on-screen keyboard), `hibernate` (optional) | `modules/`, `HY/`, `BIN/` | No battery / touch / ASUS thing appears on the desktop fixture | fixtures + owner checklist | L |
| B5 | Modules: `ddc-monitor` (`monswitch setup` reads inputs from any DDC monitor; i2c access; slower, smarter polling) and `logitech` (Solaar, MX Master 4 haptics; JuhRadial removed from core) | `modules/`, `BIN/monswitch`, `HY/` | Works against a fake `ddcutil`; no Logitech text in core | script test + owner checklist | L |
| B6 | Core reads the file: Hyprland Lua (`eDP-1` gone, binds only for present hardware), `Machine.qml`, sensors by device class, recording GPU, wallpaper canvas from the largest screen | `HY/`, `QS/services/`, `BIN/` | `tests/no-hardcode.sh` passes | CI | M |

## C. Theme packages (depends on A8)

| ID | Goal | Files | Done when | Verify | Tier |
|---|---|---|---|---|---|
| C1 | Token format and loader: `themes/<id>/theme.json` (palette, accent, fonts, sizes, radius, gaps, borders, opacity, motion, bar layout), wallpapers beside it, optional overrides; `themes/_template/`; user themes in `~/.config/hyprism/themes/` | `themes/`, `QS/services/Themes.qml`, `BIN/theme` | Copy a folder, edit one file, `theme mine` works with no code change | test that loads a copied theme | L |
| C2 | Port the seven themes; Reactor becomes the default; review each and cut any that isn't excellent (cuts need the owner's OK) | `themes/*` | 14 halves render as before (screenshot diff) | nested session screenshots | M |
| C3 | Generate every target from the tokens: terminal palette, Qt (qt6ct colours), btop, starship / fish, login screen, editor hint, plus the existing ones; write only changed files | `QS/services/ThemeSync.qml`, `BIN/` | A test finds each target file with the accent, per theme | `tests/theme-targets.sh` | M |
| C4 | Contrast test extended: accents, status colours, lines, bar ink on bar fill, terminal palette; reads the JSON | `tests/themes.py` | Every half passes | CI | M |
| C5 | Wallpaper-colour mode (optional): dominant colours via ImageMagick, pushed through the contrast fixer | `BIN/theme-wallpaper`, Settings page | Any image gives a passing palette | test with three images | M |

## D. Modular bar (depends on C1; hardware items on B6)

| ID | Goal | Files | Done when | Verify | Tier |
|---|---|---|---|---|---|
| D1 | Item contract: `bar/items/<id>/{Item.qml,defaults.json,README.md}`; registry built from the folders; `bar.items.<id>` settings (enabled, section, order, icon, format, interval, click / right-click / scroll, tooltip, warn / critical) with schema checks | `QS/bar/`, `QS/services/Config*.qml` | Two items ported as the pattern; ADR 0001 accepted | lint + nested session | L |
| D2 | Port the other 21 items to the contract | `QS/bar/items/*` | `BarWidget.qml` is gone; each item has a README | lint + screenshots | C (pattern from D1) |
| D3 | `Metrics` service: a registry (id, read, format, unit, thresholds, history for sparklines), one poll per interval, gated on a visible reader; device-class lookups; never wakes the dGPU | `QS/services/Metrics.qml` | Every metric in the brief is an entry; a doc shows adding one | unit-style test with fake `/sys` + `/proc` | L |
| D4 | System-info item: pick metrics, order, format; compact / detailed / sparkline tooltip / only-above-threshold | `QS/bar/items/sysinfo/` | All listed metrics selectable | screenshots + settings round-trip | M |
| D5 | Presets (minimal, full, laptop, external) and per-monitor layouts; Settings bar page edits per-item settings, presets and monitors | `QS/settings/`, config | Switching preset is live; file and panel agree | round-trip test (F3) | M |

## E. Features

| ID | Goal | Depends | Verify | Tier |
|---|---|---|---|---|
| E1 | One menu: launcher Actions gains themes, update, wifi, Bluetooth, audio, displays, record, web apps; hardware entries from detection | B6 | checklist + screenshots | M |
| E2 | Keys: one layout switch, binds only for present hardware, terminal from default apps, clash test | B6 | CI clash test | M |
| E3 | OSD for mic mute, caps lock, layout; OSD settings | — | IPC test + screenshots | M |
| E4 | Displays: DPI-based default scale, highest-refresh option, VRR toggle, profiles per monitor set, generic workspace rules, monitor-specific fixes become options | B6 | headless Hyprland test | L |
| E5 | Input: touchpad options, per-device settings | B4 | fixture + screenshots | M |
| E6 | First run: welcome panel (theme, mode, layouts, bar preset, detected modules), cheat sheet once | C2, D5 | IPC test + screenshots | M |
| E7 | Screenshots and recording: pin, both audio sources, right GPU, errors shown | B6 | script tests + checklist | M |
| E8 | Accessibility: names and roles on shared controls and bar items, glyphs beside colour states, keyboard path into the bar | D2 | lint rule + checklist | M |
| E9 | Apps and defaults: seed default apps where unset; small viewer set; own emoji list; keyring and polkit found on either distro; KDE fallback and guard removed | A6 | container assertions | M |
| E10 | Optional modules: `dev` (mise, Docker, themed prompt), `gaming` (Steam, gamemode, MangoHud), `ai` (NVIDIA container toolkit, Ollama, guide) | B2, B3 | CI dry runs + owner checklist | M |
| E11 | Security: pinned plugin build on update only, named AUR / COPR prompts, firewall offer, clipboard store 700, gitleaks in CI | A6 | CI + review | L |
| E12 | Settings: app rules in `settings.json`, stale paths removed, generated settings reference | D5 | round-trip test | M |

## F. Proof and docs

| ID | Goal | Verify | Tier |
|---|---|---|---|
| F1 | Doctor: one check per module (pass / skip / fail), a fix line on every finding, logs in one folder, `hyprism doctor` on the PATH | break-ten-things test; owner's machine clean | L |
| F2 | CI: shfmt, style-level shellcheck, actionlint, gitleaks, docs-link check, no-hardcode grep, fixtures, migrations, uninstall, performance budget | green on Arch and Fedora | M |
| F3 | Settings round-trip test: every setting through IPC and through the file gives the same state | CI (headless shell) | M |
| F4 | Docs: README, install guides (Arch, Fedora), "how to change X", module docs, `docs/hardware.md`, troubleshooting, settings reference, VM checklist | stranger test: a fresh reviewer who may not read the source | C drafts, L reviews |
| F5 | Owner checklist run on the real laptop (hybrid GPU, tablet mode, monitor hand-off, haptics, sleep, gaming, AI) | results recorded in the final report | owner + L |
| F6 | Re-score every department with evidence; `docs/audit/FINAL_REPORT.md`; PR with before / after | all 10s backed by proof | L |

## Removals proposed (each noted in the changelog when done)

| Removed | Replaced by | Needs the owner's OK |
|---|---|---|
| `hosts/` (machines by hostname) | detected `modules/` | no (same features, found automatically) |
| KDE fallback, the KDE guard, KDE-only pieces | own emoji list, either keyring, qt6ct | yes: changes what the login screen offers |
| JuhRadial MX step | Solaar module | yes: his mouse setup changes |
| `.council/`, old process docs, merged branch | `docs/history/` | no |
| Any theme that fails review in C2 | — | yes, per theme |

## New dependencies proposed (each gets its line in the docs)

| Package | Why | Where |
|---|---|---|
| `qt6ct` | Qt apps follow the theme without KDE | core |
| `solaar` | Logitech settings and MX Master 4 haptics | `logitech` module only |
| `iio-sensor-proxy` | screen rotation | `tablet` module only |
| `btop` | themed system monitor behind the system-info item | core (small) |
| `mise`, Docker | language versions, containers | `dev` module only |
| Steam, gamemode, MangoHud | gaming | `gaming` module only |
| NVIDIA container toolkit, Ollama | local AI | `ai` module only |
| shfmt, actionlint | checks | CI only |
