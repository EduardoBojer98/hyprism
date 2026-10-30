pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Wallpaper images from the folders in Settings > Wallpaper, setting one (hyprpaper live, and
// saved to hyprpaper.conf and the lock screen), and the optional slideshow.
//   Wallpapers.images · Wallpapers.apply(path) · Wallpapers.next() · `qs ipc call wallpaper next`
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

    function apply(path) {
        if (!path) return
        current = path
        Config.set("wallpaper", "current", path)
        const safe = path.replace(/[|'\\\n]/g, "")
        const saved = safe.startsWith(home + "/") ? "~" + safe.slice(home.length) : safe   // config files stay portable
        Quickshell.execDetached(["hyprctl", "hyprpaper", "wallpaper", "," + safe])
        // the one `path =` line in each file: the wallpaper block and the lock screen background
        Quickshell.execDetached(["sh", "-c", "sed -i 's|^\\(\\s*path\\s*=\\s*\\).*|\\1" + saved + "|' \"$HOME/.config/hypr/hyprpaper.conf\" \"$HOME/.config/hypr/hyprlock.conf\""])
    }

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

    // every image in the folders (and one level of subfolders), plus what hyprpaper.conf shows now
    Process {
        id: lister
        command: ["sh", "-c", "for d in \"$@\"; do [ -d \"$d\" ] && find -L \"$d\" -maxdepth 2 -type f \\( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \\); done | sort -u; echo '--'; grep -oP '^\\s*path\\s*=\\s*\\K.*' \"$HOME/.config/hypr/hyprpaper.conf\" | head -1",
                  "sh"].concat(root.c.folders.map(root.expand))
        stdout: StdioCollector {
            onStreamFinished: {
                const [list, cur] = text.split("--\n")
                root.images = list.trim().split("\n").filter(x => x)
                if (!root.current) root.current = root.c.current || root.expand((cur ?? "").trim())
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

    IpcHandler {
        target: "wallpaper"
        function next(): void { root.next() }
        function set(path: string): void { root.apply(root.expand(path)) }
    }
}
