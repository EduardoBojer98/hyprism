# Research notes (2026-11-15)

Condensed from a sourced research pass. (U) = not confirmed from a primary source.

## Screenshots
- **Flameshot 15.0.0** (2026-11-07): captures through xdg-desktop-portal or an optional grim adapter
  (`useGrimAdapter=true`). On Hyprland it needs a window rule that floats, pins and sizes one window across all
  monitors; the docs assume equal-resolution monitors, and fractional scaling is a documented problem
  ([wayland help](https://flameshot.org/docs/guide/wayland-help/), [troubleshooting](https://flameshot.org/docs/guide/troubleshooting/)).
  This laptop runs at scale 1.2 next to a 1.0 monitor: the exact case Flameshot handles worst.
- **Satty 0.22** (2026-08): arrow, text, blur, pixelate, highlighter, block highlight, crop, brush; Ctrl+Z / Ctrl+Y;
  Enter/Ctrl+C copy, Ctrl+S save to a strftime path; `--fullscreen`, `--initial-tool` ([README](https://github.com/gabm/Satty)).
  slurp selects first, satty annotates second: no cross-monitor overlay window, so no scaling problem.
- Swappy 1.8 (2025-08, slow); Hyprshot dormant since 2024; Grimblast active in hyprwm/contrib but untagged.
- Pick: keep **grim + slurp + Satty** (already installed). Active window via `hyprctl activewindow -j` `at`/`size`.

## Recording
- gpu-screen-recorder: active, `-w portal` or KMS, `-a "default_output|default_input"` (U: one track or two).
  Cross-GPU (iGPU display, dGPU encode) is an open upstream item: encode on the AMD iGPU.
- wl-screenrec: VAAPI only, AMD known good, one audio device. wf-recorder 0.6 (installed): ffmpeg, simple.

## Clipboard
- cliphist 0.7 (text + images) or the project's own `clipstore`. Paste into the active app: `wl-copy`, then
  `wtype -M ctrl v -m ctrl` (no daemon; terminals need Ctrl+Shift+V).

## Weather: Open-Meteo
- No key. Forecast: current/hourly/daily `temperature_2m`, `apparent_temperature`, `precipitation_probability`,
  `weather_code`, `wind_speed_10m`, `relative_humidity_2m`, `uv_index` ([docs](https://open-meteo.com/en/docs)).
  Geocoding: `geocoding-api.open-meteo.com/v1/search?name=` ([docs](https://open-meteo.com/en/docs/geocoding-api)).
- Free tier: 10,000 calls/day, non-commercial, CC BY 4.0 attribution ([pricing](https://open-meteo.com/en/pricing)).

## Rainbow border (Hyprland 0.57, Lua)
- Gradient `active_border = { colors = {...}, angle = 45 }`; `hl.animation({ leaf = "borderangle", enabled = true,
  speed = N, bezier = "...", style = "loop" })` ([forum](https://forum.hypr.land/t/creating-linear-color-gradient-animations-for-the-active-window/2081)).
- The `loop` style redraws at the refresh rate even when nothing else moves (wiki): cost on battery. Off on battery,
  or a static rainbow gradient with no loop.

## ASUS power
- asusctl: Quiet / Balanced / Performance through `platform_profile`; asusd and power-profiles-daemon have fought
  over the profile (2024 report, may be fixed) ([forum](https://bbs.archlinux.org/viewtopic.php?id=301200)).
  One owner of the profile; test. Fan curves: Ryzen ROG only, `asusctl fan-curve` (U for GV301QC).
- Power draw: `/sys/class/power_supply/BAT*/power_now`; fans: hwmon `fan*_input`.
- Caffeine: hypridle honours `systemd-inhibit --what=idle` and Wayland idle-inhibit by default
  ([hypridle](https://wiki.hypr.land/0.56.0/Hypr-Ecosystem/hypridle/)).

## Apps
Nautilus, File Roller, Loupe, Papers, hyprpolkitagent 0.2, xdg-desktop-portal-hyprland 1.5 + -gtk, Quickshell's own
notification server, Overskride or Blueman, nm-connection-editor, pwvucontrol 0.5, Baobab, Mission Center (U).

## Design landscape
end-4 illogical-impulse (Material You, feature-heavy, heavy installs), Caelestia (Material, animated),
DankMaterialShell 2.1 (clean, multi-compositor), Noctalia 5.5 ("quiet by design"). Trends: Material 3 Expressive
(playful, wallpaper colour, springy), Liquid Glass (depth, blur cost), terminal/brutalist (keyboard-first, legible,
cheap), quiet minimal bars.
