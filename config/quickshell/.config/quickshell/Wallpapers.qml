pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.UPower
import QtQuick

// Wallpaper images and videos from the folders in Settings > Wallpaper, setting one (hyprpaper live, and
// saved as hypr/settings/wallpaper for hyprpaper and the lock screen), the optional slideshow, and
// the desktop blur: hyprpaper can't blur, so it is shown a blurred copy kept in ~/.cache/wallpaper-blur
// (the link keeps the original; the lock screen blurs on its own).
// A video ("live wallpaper") has a still frame (wallpaper-still) that takes the picture's place everywhere above;
// mpvpaper plays the video over it (see the player at the end).
//   Wallpapers.images · Wallpapers.apply(path) · Wallpapers.pick(path) · Wallpapers.next() · `qs ipc call wallpaper next`
Singleton {
    id: root

    readonly property var c: Config.wallpaper
    readonly property string home: Quickshell.env("HOME")
    property var images: []          // full paths, sorted by name
    property string current: ""      // full path shown now
    // what the slideshow cycles through
    readonly property var pool: c.source === "selected" ? c.selected.filter(p => images.includes(p)) : images

    function expand(p) { return p.startsWith("~") ? home + p.slice(1) : p }
    function refresh() { lister.running = false; lister.running = true }
    function isVideo(p) { return /\.(mp4|webm|mkv|mov)$/i.test(p ?? "") }
    // what stands for a wallpaper wherever a picture is needed: itself, or a video's frame (same name as wallpaper-still makes)
    function still(p) { return isVideo(p) ? (Quickshell.env("XDG_CACHE_HOME") || home + "/.cache") + "/hyprism/live/" + Qt.md5(p) + ".jpg" : p }

    function apply(path) {
        if (!path) return
        current = path
        Config.set("wallpaper", "current", path)
        const safe = path.replace(/[|'\\\n]/g, "")
        show(safe)
        // hyprpaper.conf and hyprlock.conf both read this link (kept out of git, it's your choice)
        Quickshell.execDetached(["sh", "-c", "mkdir -p \"$HOME/.config/hypr/settings\" && ln -sfn \"$1\" \"$HOME/.config/hypr/settings/wallpaper\"", "sh", still(safe)])
    }

    // What hyprpaper displays: the picture, or a blurred copy (made once per picture and strength,
    // at most 2560 px wide, blurred at half that, so even a big photo takes well under a second;
    // the newest 10 copies are kept)
    function show(path) {
        if (!path || !path.startsWith("/")) return   // an absolute file path only: nothing ImageMagick or ffmpeg could read as an option or a coder
        Quickshell.execDetached(["sh", "-c",
            "s=$(wallpaper-still \"$1\"); [ -n \"$s\" ] || exit 0; "
            + "if [ \"$2\" -gt 0 ]; then d=\"$HOME/.cache/wallpaper-blur\"; out=\"$d/$(printf %s \"$s$2\" | md5sum | cut -c1-16).jpg\"; mkdir -p \"$d\"; "
            + "[ -f \"$out\" ] || { magick \"$s\" -resize 1280x1280\\> -blur 0x\"$2\" -resize 200% -quality 92 \"$out.tmp.jpg\" && mv \"$out.tmp.jpg\" \"$out\"; }; "
            + "ls -t \"$d\"/*.jpg | tail -n +11 | xargs -r rm -f; [ -f \"$out\" ] || exit 0; s=$out; fi; "
            + "hyprctl hyprpaper wallpaper \",$s\"",
            "sh", path, String(c.blur)])
    }
    Timer { id: blurDebounce; interval: 400; onTriggered: root.show(root.current) }
    Connections { target: Config.wallpaper; function onBlurChanged() { blurDebounce.restart() } }

    function next() {
        const list = pool
        if (list.length < 2) return
        let i = list.indexOf(current)
        if (c.order === "shuffle") {
            let j = Math.floor(Math.random() * (list.length - 1))
            if (j >= i && i >= 0) j++     // never the same one twice in a row
            i = j
        } else i = (i + 1) % list.length
        apply(list[i])
    }

    // A wallpaper you pick yourself stays when you switch themes (Settings > Themes > Wallpaper turns it back on)
    function pick(path) {
        Config.set("appearance", "wallpaper", false)
        apply(path)
    }

    // every image and video in the folders (and one level of subfolders), every theme's own wallpaper, plus the one
    // shown now; each video's still is made first, so its Settings tile has a picture
    Process {
        id: lister
        command: ["sh", "-c", "l=$({ for d in \"$@\"; do [ -d \"$d\" ] && find -L \"$d\" -maxdepth 2 -type f \\( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' -o -iname '*.mp4' -o -iname '*.webm' -o -iname '*.mkv' -o -iname '*.mov' \\); done; theme-wallpaper --all 2>/dev/null; } | sort -u); "
                  + "printf '%s\\n' \"$l\" | grep -iE '\\.(mp4|webm|mkv|mov)$' | tr '\\n' '\\0' | xargs -0 -r wallpaper-still >/dev/null; "
                  + "printf '%s\\n' \"$l\"; echo '--'; readlink -f \"$HOME/.config/hypr/settings/wallpaper\"",
                  "sh"].concat(root.c.folders.map(root.expand))
        stdout: StdioCollector {
            onStreamFinished: {
                const [list, cur] = text.split("--\n")
                root.images = list.trim().split("\n").filter(x => x)
                if (!root.current) {
                    root.current = root.c.current || root.expand((cur ?? "").trim())
                    // shortcut: hyprpaper.conf shows the sharp picture at login until this swaps in the blurred copy
                    if (root.c.blur > 0) root.show(root.current)
                }
            }
        }
    }
    Component.onCompleted: refresh()
    Connections { target: Config.wallpaper; function onFoldersChanged() { root.refresh() } }

    Timer {
        interval: Math.max(1, root.c.interval) * 60000
        repeat: true
        running: root.c.slideshow && root.pool.length > 1
        onTriggered: root.next()
    }

    // Live wallpaper: one mpvpaper per screen, over hyprpaper's still frame (which stays if mpvpaper is missing or
    // stops). A playing video about doubles idle power even behind windows (Hyprland still draws it), so it pauses
    // over mpv's socket: on battery (unless liveOnBattery), and on a fullscreen window, or any window with
    // livePause "windows". mpvpaper's own -p/-s do nothing on Hyprland. Measured: docs/research/live-wallpapers.md.
    readonly property bool live: isVideo(current) && current.startsWith("/")
    readonly property bool batteryPause: UPower.onBattery && !c.liveOnBattery
    Variants {
        model: root.live ? Quickshell.screens.filter(s => Machine.realScreen(s.name)) : []
        Process {
            id: player
            required property ShellScreen modelData
            readonly property string sock: Quickshell.env("XDG_RUNTIME_DIR") + "/hyprism-wallpaper-" + modelData.name + ".sock"
            readonly property var ws: Hyprland.monitorFor(modelData)?.activeWorkspace ?? null
            readonly property bool paused: root.batteryPause
                || (ws !== null && (root.c.livePause === "windows" ? ws.toplevels.values.length > 0 : ws.hasFullscreen))
            function send(cmd) {
                Quickshell.execDetached(["sh", "-c", "printf '%s\\n' \"$2\" | socat - UNIX-CONNECT:\"$1\" >/dev/null 2>&1", "sh", sock, JSON.stringify({ command: cmd })])
            }
            onPausedChanged: send(["set_property", "pause", paused])
            readonly property string file: root.current   // another video: the same player loads it (an image ends the player)
            onFileChanged: if (root.live) send(["loadfile", file])
            // gpu-hwdec-interop=vaapi: the default also loads CUDA and Vulkan, which wakes a sleeping NVIDIA card on
            // hybrid laptops. shortcut: no VA-API (an NVIDIA-only desktop) decodes on the CPU; add NVDEC when one shows up
            Component.onCompleted: {
                command = ["mpvpaper", "-o", "hwdec=vaapi gpu-hwdec-interop=vaapi profile=fast loop-file=inf no-audio panscan=1.0 input-ipc-server=" + sock + (paused ? " pause=yes" : ""),
                           modelData.name, root.current]
                running = true
            }
        }
    }

    IpcHandler {
        target: "wallpaper"
        function next(): void { root.next() }
        function set(path: string): void { root.apply(root.expand(path)) }
    }
}
