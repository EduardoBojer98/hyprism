# Live wallpapers (2026-11-16)

Research, spike and plan for video wallpapers. Built 2026-11-16 (steps 1-5 below); "unverified" = not tested on
this machine.

## Today

- `hyprpaper` (static only) draws the desktop. `Wallpapers.qml` lists images, sets one with
  `hyprctl hyprpaper wallpaper`, keeps a blurred copy in `~/.cache/wallpaper-blur`, runs the slideshow.
- `~/.config/hypr/settings/wallpaper` (a symlink) is the single source for hyprpaper.conf, hyprlock,
  MissionControl, the lock-screen preview and `wallpaper-colours`. All of them need a **still image**.

## Options

| Option | Video | HW decode | Pause when covered | Arch / Fedora | Verdict |
|---|---|---|---|---|---|
| **mpvpaper** (libmpv) | yes | mpv `hwdec=vaapi` | IPC `set pause yes` (own `-p/-s` is a self-described hack) | `cachyos` repo 1.9, AUR / solopasha COPR (check sdegler) | **pick** |
| Quickshell + QtMultimedia `Video` on `WlrLayer.Background` | yes | Qt FFmpeg backend, VA-API possible | trivial (same process) | `qt6-multimedia-ffmpeg` (extra) / `qt6-qtmultimedia` | fallback; spike it |
| awww (ex swww) | GIF/APNG/WebP only | no (CPU) | none | extra / ? | no: CPU-heavy, no video |
| gSlapper (GStreamer) | yes | GStreamer | unverified | AUR / ? | no: young, packaging unclear |
| linux-wallpaperengine | WE scenes | unverified | built-in | AUR | no: needs Steam Wallpaper Engine, heavy |
| hyprpaper 0.8 | no | – | – | in use | keep for stills |
| Qt `ShaderEffect` in Quickshell | procedural only | GPU | trivial | nothing new | later, if themes want animated art |

Why mpvpaper over QtMultimedia:
- Decoding lives in its own process: a bad file or decoder leak can't take down the bar, dock and lock.
  A Quickshell reload (every config edit) would also restart a QML video.
- mpv loops gaplessly (`loop-file=inf`), has the most mature VA-API path, and Noctalia's video plugin
  tells users to fall back to mpvpaper when the Qt backend misbehaves.
- Quickshell still owns the logic (when to play, pause, stop), so pausing is just as easy over IPC.

Sources: [mpvpaper](https://github.com/GhostNaN/mpvpaper) (README, man page),
[awww](https://codeberg.org/LGFae/awww), [Qt FFmpeg config](https://doc.qt.io/qt-6/advanced-ffmpeg-configuration.html),
[QTBUG-122757](https://bugreports.qt.io/browse/QTBUG-122757), [Noctalia video plugin](https://noctalia.dev/plugins/video-wallpaper),
[gSlapper](https://nomadcxx.github.io/gSlapper), [linux-wallpaperengine](https://github.com/almamu/linux-wallpaperengine).

## Spike results (2026-11-16, ROG Flow X13: Ryzen 5000 Vega iGPU + RTX 3050, eDP-1 1920x1200@120)

20 s H.264 loops made with ffmpeg: 1080p at 8 Mbit/s, 4K at 19 Mbit/s. W = APU package power
(amdgpu `power1_input`, on AC); background apps make it swing ±5 W, so read iGPU % and CPU first.
Same conditions, back to back:

| Run | W | iGPU | CPU (1 core) | RSS | RTX |
|---|---|---|---|---|---|
| idle | 7.2 | 6% | – | – | asleep |
| mpvpaper 1080p, default | 20.6 | 50% | 5.1% | 188 MB | asleep* |
| mpvpaper 1080p, `profile=fast` | 14.4 | 35% | 4.1% | 195 MB | asleep* |
| Quickshell `Video` 1080p | 13.7 | 35% | 6.9% | 386 MB | asleep** |
| mpvpaper 4K, default | 28.0 | 65% | 5.0% | 263 MB | asleep* |
| mpvpaper 4K, `profile=fast` | 15.4 | 35% | 4.4% | 270 MB | asleep* |
| Quickshell `Video` 4K | 15.9 | 34% | 6.9% | 558 MB | asleep** |
| mpvpaper 4K, paused over IPC | 7.4 | 9% | 0.5% | 258 MB | asleep |

\* only with `gpu-hwdec-interop=vaapi`. Without it mpv loads `libcuda` and the Vulkan loader and **wakes the RTX**
(+several W). \*\* only with `CUDA_VISIBLE_DEVICES= VDPAU_DRIVER=radeonsi VK_DRIVER_FILES=…/radeon_icd.json`
on the whole Quickshell process: Qt probes VDPAU, CUDA and Vulkan at start whatever
`QT_FFMPEG_DECODING_HW_DEVICE_TYPES` says.

Findings:
- **mpvpaper confirmed.** With `profile=fast` it matches Qt on power and GPU, uses less CPU and half the RAM,
  and keeps decoding out of the shell process. Qt would add 200-400 MB to Quickshell and need NVIDIA-hiding env
  on the whole shell.
- **A playing wallpaper roughly doubles idle power (+7-8 W)**, even when windows fully cover it: Hyprland keeps
  drawing a covered background layer. Paused = idle. So pausing is the feature, not a nice-to-have.
- **mpvpaper's `-p` does nothing on Hyprland** (no change in CPU or GPU while covered). Pause must come from
  Quickshell over the IPC socket; `set_property pause` works and is instant.
- mpvpaper on the background layer draws above hyprpaper (later surface on top), confirmed by screenshot.
- VA-API on this iGPU: H.264, HEVC, VP9. No AV1, so AV1 clips would decode on the CPU: list them but warn.
- Not checked: whether the loop has a visible gap (the test clips don't loop seamlessly by content), Fedora
  packaging, multi-monitor, a Hyprland session that runs on the NVIDIA card.

Spike leftovers: `qt6-multimedia` and `qt6-multimedia-ffmpeg` were installed only for this test (nothing else
needs them); `mpvpaper` and `libva-utils` stay.

## Design

hyprpaper stays. A video is a **layer on top**: mpvpaper draws on the background layer above hyprpaper,
and hyprpaper keeps showing the video's first frame (the "poster") underneath. So:

- no black flash while mpv starts, and the poster stays if mpvpaper dies;
- the symlink points at the poster, so hyprlock, MissionControl, blur, `wallpaper-colours` and the
  lock-screen page keep working unchanged;
- `Config.wallpaper.current` holds the real video path.

Pause (Quickshell drives mpv over `input-ipc-server=$XDG_RUNTIME_DIR/hyprism-wall.sock`):
- a fullscreen or maximised window on that monitor's active workspace (`Quickshell.Hyprland`). Open
  question from the spike: tiled windows that fill the screen cost the same power, so a stricter
  "play only when the workspace is empty" mode may be the better default on battery;
- screen locked or idle-off;
- on battery, unless `wallpaper.liveOnBattery` is on (`UPower.onBattery`, already used in `ThemeSync.qml`).

Hybrid GPU: Hyprland runs on the AMD iGPU and `nvidia-hybrid.lua` keeps EGL off the RTX, so mpv should
decode on the iGPU with `hwdec=vaapi`. Verify the RTX stays suspended while a video plays.

## Plan

0. ~~Spike~~ done, see results above. mpv options to use:
   `hwdec=vaapi gpu-hwdec-interop=vaapi profile=fast loop-file=inf no-audio panscan=1.0 input-ipc-server=…`
   (on an NVIDIA-only session `hwdec=auto-safe` and no interop limit). Never use mpvpaper's `-p`/`-s`.
1. **Packages.** `manifest.txt`: `mpvpaper  desktop  live (video) wallpapers`; `arch.txt`: `cachyos`
   source; `fedora.txt`: check the sdegler COPR, else solopasha COPR or `none` (feature hides).
   `ffmpeg` for posters (add to manifest if not pulled in already).
2. **`Wallpapers.qml`.**
   - lister: add `*.mp4 *.webm *.mkv *.mov`; `isVideo(path)` by extension.
   - `apply(path)`: for a video, make the poster once
     (`ffmpeg -ss 1 -i v -frames:v 1 ~/.cache/hyprism/live/<md5>.jpg`), `show()` + symlink the poster,
     then start/replace mpvpaper; for an image, stop mpvpaper (as today otherwise).
   - one `Process` running mpvpaper for all outputs; restart on output hot-plug.
   - pause/resume: one `readonly property bool paused` from the three rules above; on change send
     `{"command":["set_property","pause",true]}` to the socket (`socat`, already a dependency).
   - slideshow: unchanged, videos are just items in the pool.
3. **Settings > Wallpaper.** Tiles show the poster for videos plus a small play badge; one toggle
   "Play on battery" (`wallpaper.liveOnBattery`, default off) in `ConfigData.qml`. Blur applies to the
   poster only (hint text says so).
4. **Login start.** Nothing new in `autostart.lua`: Quickshell starts mpvpaper when `current` is a video.
5. **Tests and docs.** A `tests/` check that the poster is made and the symlink points at it;
   `docs/settings-reference.md`, `USER-GUIDE.md`, `CHANGELOG.md`; `graphify update .`.

Skipped on purpose: video blur (costly per frame), audio, per-monitor different videos, Wallpaper Engine
scenes, themes shipping videos. Each can come later without changing the design.

Risks: mpvpaper's Fedora packaging; mpv on NVIDIA if a user's Hyprland runs on the dGPU (`hwdec=auto-safe`
there); battery drain is real even when paused-on-cover works, hence off-on-battery by default.
