# Research (2026-11-04)

Ideas only: nothing below was copied. Each idea is re-implemented in this repo's own style.
Sources are each project's README / docs. "Unverified" = the source page didn't say.

## Well-known Hyprland setups

| Setup | Good at | Adopt? | Avoid |
|---|---|---|---|
| **Hyprland ecosystem** (hyprlock, hypridle, hyprpaper, hyprsunset) | First-party, small, same config style as the compositor | Already used for lock, idle, wallpaper, Night Light | — |
| **end-4 dots-hyprland** ([github](https://github.com/end-4/dots-hyprland)) | Quickshell shell; **`Super+/` keybind cheatsheet**; overview with live previews; installer prints every command before running it | ✅ the cheatsheet idea (ours reads binds live from Hyprland, so it can't drift) | Tied to exact Hyprland versions (its README ships a "pre-Lua" release for distros that lag); a dotfile set, not a system setup |
| **caelestia** ([github](https://github.com/caelestia-dots/caelestia)) | Launcher on a tap of Super; clean split between shipped config and user overrides (`hypr-user.lua`, `shell.json`) | Both already here (tap-Super Spotlight; `settings/*.lua` + `settings.json` overrides) | Arch/AUR only |
| **HyDE** ([github](https://github.com/HyDE-Project/HyDE)) | Many launcher styles; wallpaper-driven colours; restore manifest with automatic backups | Backups: already in `install.sh` | Installer edits the bootloader, display manager and `pacman.conf` and builds NVIDIA DKMS: too invasive for rule 5 |
| **ML4W** ([github](https://github.com/mylinuxforwork/dotfiles)) | Supports CachyOS and Fedora; dotfiles separated from the installer | Same split here (`config/` vs `install.sh` + `distros/`) | Large issue backlog; ISO installer beta |
| **JaKooLit** ([github](https://github.com/JaKooLit/Hyprland-Dots)) | A bar hint button opens a keybind list; per-distro installers incl. Fedora | Cheatsheet (see end-4) | Repo moving to a new home (archival announced); assumes 1440p unscaled |
| **Omarchy** ([github](https://github.com/basecamp/omarchy)) | Opinionated "one command" setup with a themes system | Theme switch in one step (`theme NAME`) | Details unverified (README is a table of contents); Arch only (a separate Fedora port exists) |

**Takeaways used here:** cheatsheet on `Super+/`; one command to switch theme; neon accents only on
state (focused workspace, focused window, selection), never on large areas; fast damped animations
(already present). **Rejected:** wallpaper-generated palettes (unpredictable contrast, an extra
dependency like matugen/pywal); per-app theming beyond GTK/terminal (Firefox/VS Code themes = more
moving parts than they earn).

## Screenshot tools (Phase 5b)

| Tool | What it is | Annotation | Mixed scale / two monitors | Verdict |
|---|---|---|---|---|
| **grim + slurp** | Capture + area picker, wlroots-native | none | grim captures any region across outputs at the highest scale; slurp spans both screens, touch works | ✅ capture base |
| **Satty** ([github](https://github.com/gabm/Satty)) | GTK4 editor, 0.22.0 here | pen, line, arrow, rectangle, ellipse, text, **numbered markers**, blur, highlighter, crop, undo/redo, colour + size; pixelate is on `main` for the next release | works on any image | ✅ editor. Arch: `extra/satty`. Fedora 44: `copr:mineiro/hyprland` (0.22.0, **verified with `dnf repoquery` in a fedora:44 container**). Not in Fedora's own repos ([packages.fedoraproject.org](https://packages.fedoraproject.org/search?query=satty)) |
| **Swappy** ([github](https://github.com/jtheoof/swappy)) | GTK3 editor | brush, text, rectangle, ellipse, arrow, blur | — | ✗ fewer tools (no numbered markers, no crop) |
| **grimblast** ([hyprwm/contrib](https://github.com/hyprwm/contrib)) / **hyprshot** ([github](https://github.com/Gustash/Hyprshot)) | Shell wrappers around grim + slurp | none | same as grim | ✗ our ~90-line script does the same with no extra package |
| **Ksnip** ([github](https://github.com/ksnip/ksnip)) | Qt editor with pin windows, OCR plugin | full set incl. pixelate, stickers | Wayland support documented for GNOME/Plasma only; global hotkeys don't work on Wayland; solo maintainer, 300+ open issues | ✗ fragile on Hyprland |
| **Gradia** ([github](https://github.com/AlexanderVanhee/Gradia)) | GTK4 "make screenshots pretty" | basic annotation, backgrounds | — | ✗ aimed at presentation, Flatpak-first |
| **Flameshot** ([github](https://github.com/flameshot-org/flameshot)) | Qt all-in-one | full set incl. pixelate | Wayland "experimental"; see `docs/AUDIT.md` audit 2 #1 for what went wrong here | ✗ replaced |

Grim and slurp are in Fedora's own repos (F44: grim 1.5.0, slurp 1.5.0; verified the same way).

**Pin to screen:** none of the Wayland-native tools has it; Ksnip does but is fragile on Hyprland.
Skipped. Workaround: open the saved shot (click the notification), then window menu (`Super+Z`) →
**On top, every desktop**.
**OCR:** already here as `screentext` (`Super+Shift+T`: grim + slurp + tesseract → clipboard).
**Pixelate:** Satty's blur covers redaction today; pixelate arrives with the next Satty release.
