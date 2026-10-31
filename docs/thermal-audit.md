# Thermal & power audit: ROG Flow X13 GV301QC (2026-10-31)

Phase 1 (read-only). Builds on the two fixes made earlier today (`~/thermal-debug/report.md`,
`system/hosts/rog-flow-x13/30-thermal.sh`): firmware/custom fan curves and the dGPU power-down.
This audit checks they still hold and finds what is still making the laptop hot.

Session: Hyprland 0.57 (Wayland), kernel `6.18.55-2-cachyos-lts`, on AC, charge limit 80 %.

## 1. Baseline

Sampled every 2 s (CPU temp `Tctl`, APU package power `PPT` from amdgpu, fan RPM, dGPU state).
Load = 16 busy threads for 90 s, then 90 s rest, per profile, with an abort at 97 °C (not hit).

| Scenario (AC, both screens) | Profile | CPU temp avg / max | Package power | Fans CPU / GPU (RPM) | Avg clock |
|---|---|---|---|---|---|
| Light desktop (3 Claude sessions, Chrome open) | Balanced | 75 / 82 °C | 25 W | 7,400 / 4,000 | 2.0 GHz |
| Same, after a load run | Quiet | 72 / 80 °C | 17 W | 5,900 / 5,300 | 1.9 GHz |
| Same, after a load run | Balanced | 74 / 79 °C | 22 W | 7,300 / 4,000 | 2.4 GHz |
| Same, after a load run | Performance | 80 / 94 °C | 33 W | 9,100 / 5,200 | 2.7 GHz |
| Full CPU load | Quiet | 84 / 87 °C | 31 W | 6,100 / 5,600 | 2.9 GHz |
| Full CPU load | Balanced | 85 / 90 °C | 34 W | 8,900 / 4,000 | 2.8 GHz |
| Full CPU load | Performance | 95 / 95 °C | 48 W | 9,200 / 5,300 | 3.2 GHz |

dGPU: `suspended` (D3cold, fully off) in **every** sample, including under load. Docker: daemon up,
0 containers (no measurable cost). Baloo: disabled.

**Not measured yet (need you at the machine, see section 4):** true idle with no Claude sessions,
laptop screen only, YouTube in Chrome, and battery drain per profile.
"Light desktop" above is not a true idle: this audit's own Claude sessions were streaming the whole time.

## 2. Causes, biggest first

### 1. Light work costs 17-25 W, so the CPU sits at 72-75 °C with fans at 6-7k RPM
A Ryzen 5800HS should draw well under 10 W on a quiet desktop. Here it draws 2-3x that.
- **The built-in GPU runs flat out.** `gpu_busy_percent` 53-59 %, shader clock at its 2000 MHz max,
  memory/fabric clock at 1600 MHz. Per-process GPU time (`/proc/*/fdinfo`) shows Hyprland as almost
  the only client (the compositor), Claude desktop a distant second.
- **It scales with how often the screens redraw, not with effects.** Turning blur off, colour management off,
  or pausing Quickshell changed nothing (53 % -> 53-54 %). Earlier today, the external monitor at 60 Hz
  instead of 144 Hz saved ~4 W. Both screens run at 120 Hz (the Acer was at 144 Hz until 18:29),
  so every animating window (Claude streaming text, Chrome) makes Hyprland redraw up to 240 frames/s
  across two screens.
- **The CPU still bursts to 4.4 GHz for small jobs.** Average clock ~2 GHz at ~8 % CPU use. Balanced uses
  EPP `balance_power`, which allows full boost; Tctl follows those short spikes.
- Hyprland itself uses 17-42 % of one core.

### 2. Two daemons fight over power settings, and plugging in AC jumps to Performance
`asusd` and `power-profiles-daemon` both run and both write the same knobs:
- Both set the platform profile and the CPU energy preference (EPP). ppd's Balanced = `balance_performance`,
  asusd's = `balance_power` (`/etc/asusd/asusd.ron`, `platform_profile_linked_epp: true`). Whichever
  writes last wins (currently asusd).
- `platform_profile_on_ac: Performance` with `change_platform_profile_on_ac: true`: **every time you plug in,
  asusd switches to Performance**, which holds 95 °C and 9,200 RPM under load. Today it is Balanced only
  because it was switched back by hand.
- No TLP, auto-cpufreq, tuned or thermald installed. KDE's powerdevil has no profile rules
  (`~/.config/powerdevilrc` absent), so it doesn't switch profiles on its own.

### 3. Quiet doesn't really limit power on AC
Quiet has no power-limit tuning on AC or battery (`ac_profile_tunings.Quiet.enabled: false`,
`dc_profile_tunings: {}`), so it ran a full load at 31 W and 2.9 GHz, nearly the same as Balanced (34 W).
It's only quieter because its fan policy is softer. Boost stays on in every profile.

### 4. Performance is pinned at the 95 °C limit under sustained load
By design: 45 W sustained / 80 W short-term in a 13" chassis. The firmware holds Tctl at 95 °C (safe; the
chip's maximum is 105 °C), fans at ~9,200 RPM. Fine for short bursts on AC; loud for long builds.

### 5. Cooling hardware: possible, not proven
Earlier today both fans at 100 % only gave ~2 °C. That points to heat not getting from the chip into the
heatsink (dried paste/dust on a ~5-year-old laptop). But causes 1-3 explain most of today's numbers,
so the deciding test is a **true idle** (section 4): if the CPU draws < 8 W and still sits above ~60 °C with
fans spinning up, that's hardware and cleaning/repasting is the next step.

### Checked and fine
| Area | Finding |
|---|---|
| dGPU (fixed earlier) | `runtime_status` suspended, `power_state` D3cold, "Runtime D3: Enabled (fine-grained)", `NVreg_DynamicPowerManagement=0x02`. HDMI is wired to the **AMD iGPU** (`card1`), so the external screen does not wake the dGPU. `nvidia-powerd` disabled (only matters for gaming boost). |
| dGPU users | `whatsie` keeps `/dev/nvidia0` open but doesn't wake it. `ollama` service is active: loading a model wakes the dGPU, which turns off again after ollama unloads it (5 min default). |
| Kernel | 6.18 LTS on purpose (NVIDIA power-down is broken on 7.3; see `30-thermal.sh`). Boot line clean, no thermal-related parameters. |
| CPU driver | `amd-pstate-epp` in active mode, governor `powersave` (correct for EPP mode). |
| Scheduler | No sched_ext scheduler running (scx_loader idle). Not a factor. |
| ASUS firmware | Supported on this model: profiles, custom fan curves (both fans), PPT limits PL1 15-45 W / PL2 65-80 W, charge limit (80 %), `dgpu_disable`. **No** MUX switch, no panel overdrive. `supergfxctl` not installed (not needed: hybrid mode + RTD3 works). |
| Journal | No crash loops. 2 one-off ACPI BIOS errors at boot (harmless), KWin modeset errors from a KDE login (harmless), firewall drops. |
| Display | eDP-1 1920x1200 @ 120 Hz, HDMI-A-1 2560x1440 @ 120 Hz; VRR off on eDP, fullscreen-only on HDMI. |
| Chrome | GPU process on the AMD iGPU (`renderD128`), VA-API libraries loaded. Whether YouTube really decodes in hardware needs the browsing test. |

## 3. Proposed fixes (as proposed; see section 4 for what was done)

In order of expected impact. Each is a commented file in this repo plus an install step, re-measured after.

| # | Fix | Expected effect | Risk / needs your OK |
|---|---|---|---|
| 0 | Add `thermlog` (the sampler used here) to `home/scripts`, so before/after is measured the same way | none | none |
| 1 | **One owner per knob.** asusd: plug-in -> Balanced (not Performance), battery -> Quiet, and it owns EPP. ppd stays as the switch everyone talks to (Control Center, KDE, `powerprofilesctl`) but stops writing EPP itself (systemd drop-in `--block-driver=amd_pstate`). | No more surprise Performance on AC; settings stay put | Low. Undo: restore `asusd.ron`, delete the drop-in |
| 2 | **Per-profile refresh rate**: Quiet and battery -> 60 Hz on both screens; Balanced/Performance -> 120 Hz. A small user service watches the profile and applies it via `hyprctl` (Hyprland) or `kscreen-doctor` (KDE). | ~4 W less on light work in Quiet | Low. You may prefer Balanced at 60 Hz on the external screen too: your call |
| 3 | **Quiet = really quiet**: PL1 15 W / PL2 65 W on AC and battery (firmware limits via asusd, not ryzenadj), CPU boost off | Big drop in Quiet under load (est. 31 -> ~15 W) | **Power-limit change: needs your OK.** Undo: `asusctl profile tuning false` in Quiet |
| 4 | **Balanced**: keep PL1 25 W; test EPP `power` vs `balance_power` on light work and keep the cooler one if it doesn't feel slower | A few W at light load | Low |
| 5 | **Find what keeps the iGPU at 55 %** with a true-idle test (Claude closed). If it stays high with nothing on screen moving, track down the client | Possibly the biggest single win | Investigation only |
| 6 | **`powermode` command + keybind**: `powermode` (show), `powermode quiet|balanced|performance`, `powermode next` (cycle) for a Hyprland bind (the Fn+F5 fan key if it reaches Hyprland, else `Super+F5`). Works under KDE too (it only talks to ppd). | Easy switching | None |
| 7 | Performance: leave as is (it's for short heavy work on AC). Optional later: PL1 35 W | Cooler long builds | Power limit: ask |

Not proposed: undervolting (needs ryzenadj + stability testing), BIOS changes, kernel parameters,
removing packages. The dGPU setup already works; `nv <app>` (prime-run) stays the way to use it for AI/gaming.

## 4. Phase 2: what was changed (2026-10-31, evening)

Approved: everything except per-profile refresh rates (fix 2, declined). All changes live in the repo:
`system/hosts/rog-flow-x13/50-power.user.sh` (run by `./install.sh --system`, or directly), plus
`home/scripts/.local/bin/{powermode,thermlog}` and the shell/keybind edits below.

### Before / after (on AC, both screens, measured with `thermlog`)
| Scenario | Before | After |
|---|---|---|
| Quiet, full CPU load | 84 °C, 31 W, CPU fan 6,100 RPM | **65 °C, 15 W, 4,600 RPM** |
| Quiet, light desktop | 72 °C, 17 W, 5,900 RPM | **66 °C, 16.5 W, 5,100 RPM** |
| Plugging in the charger | switches to Performance (95 °C, 9,200 RPM under load) | stays **Balanced** (85 °C, 34 W under load) |
| Balanced / Performance | unchanged (both were tuned earlier today) | same |

Quiet's full-load clock drops from 2.9 to 1.8 GHz: it's for quiet, not for builds.

### Changes
| # | What and why | Undo |
|---|---|---|
| 1 | asusd: plug in -> **Balanced** (was Performance), battery -> Quiet | `asusctl profile set -a performance` |
| 2 | **Quiet**: own fan curves (gentle, CPU fan 10 % at 50 °C up to 100 % at 92 °C) and **PL1 15 W / PL2 65 W**. asusd only allows power limits while custom curves are on. Boost-off wasn't needed: the 15 W cap already holds 65 °C. | `asusctl profile set quiet; asusctl profile tuning false; asusctl fan-curve --mod-profile quiet --enable-fan-curves false` |
| 3 | All three modes' curves + limits are now in one script (`50-power.user.sh`). The old fan step in `30-thermal.sh` turned the Balanced curves **off**, which would have broken the 25 W limit on a re-run; removed. | `git revert` |
| 4 | EPP per mode set by asusd (Quiet `power`, Balanced `balance_power`, Performance `performance`) | `busctl --system set-property xyz.ljones.Asusd /xyz/ljones xyz.ljones.Platform PlatformProfileLinkedEpp b false` |
| 5 | power-profiles-daemon drop-in `--block-driver=amd_pstate`: it keeps working as the switch for KDE and `powerprofilesctl`, but stops overwriting asusd's EPP. Proven needed: during testing ppd reset Balanced to `balance_performance` on every switch. Applied and verified. | `sudo rm -r /etc/systemd/system/power-profiles-daemon.service.d && sudo systemctl daemon-reload && sudo systemctl restart power-profiles-daemon` |
| 6 | Control Center and Settings (Power, ASUS) switch modes through asusd (`PowerMode.qml` -> `powermode`) instead of power-profiles-daemon. They follow changes made anywhere (keybind, KDE, terminal, plugging in). Other computers still use power-profiles-daemon. | `git revert` |
| 7 | `powermode` command and **Super+F5** = next mode (rebind it in Settings > Keyboard Shortcuts, e.g. to the Fn+F5 fan key) | remove the bind / script |
| 8 | `thermlog LABEL [SECONDS]`: the sampler used for every number here | — |

### How to switch modes
- Control Center > Power mode, or Settings > Power & Battery
- `powermode` (shows it), `powermode quiet|balanced|performance`, `powermode next`
- Super+F5 in Hyprland (cycles). Under KDE, the Plasma battery widget still works (it goes through
  power-profiles-daemon, and asusd follows), or bind `powermode next` in KDE's shortcuts.

When to use which: **Quiet** for reading, browsing and battery; **Balanced** for daily work and builds
(holds ≤ 90 °C on its own); **Performance** for short heavy jobs and games on AC.
The dGPU stays off unless an app asks for it: `nv <app>` runs one app on it (AI, games).

## 5. Still open

1. **Battery power limits**: re-run `bash system/hosts/rog-flow-x13/50-power.user.sh` once while unplugged
   (asusd keeps limits per power source; the AC ones are set). The sudo step (change 5) is done and verified:
   ppd runs with `--block-driver=amd_pstate`, and switching from `powermode` or `powerprofilesctl` gives
   Quiet `power`, Balanced `balance_power`, Performance `performance` every time.
2. Balanced EPP tested after the fix (2 rounds x 2 min each, normal use): `balance_power` 73.1-73.6 °C, 23.5-24.3 W;
   `power` 72.4-73.6 °C, 25.6-27.9 W. No gain, so Balanced keeps `balance_power`.
3. **The built-in GPU stays ~55 % busy at idle** (cause 1). It keeps light-load power at 16-25 W in every mode;
   Quiet even sits on its 15 W cap at idle. The true-idle test below decides whether it's this session's
   streaming windows or something else.
4. Hardware: no verdict yet; same true-idle test.

## 6. Measurements that need you

Each takes ~5 minutes, one command each (`thermlog NAME 300`; results in `~/.local/state/thermlog/`):
1. **True idle**: in a terminal run `sleep 30; thermlog true-idle 300`, then close the Claude app and Chrome and don't touch anything for 5 min.
2. **Laptop screen only**: unplug HDMI, same idle.
3. **Browsing**: Chrome with several tabs + a YouTube video playing (also tells us if video decode is in hardware).
4. **Battery**: unplug the charger, light use, once in Quiet and once in Balanced (battery watts).
