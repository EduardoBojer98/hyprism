pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Wallpaper images from the folders in Settings > Wallpaper, setting one (hyprpaper live, and
// saved as hypr/settings/wallpaper for hyprpaper and the lock screen), the optional slideshow, and
// the desktop blur: hyprpaper can't blur, so it is shown a blurred copy kept in ~/.cache/wallpaper-blur
// (the link keeps the original; the lock screen blurs on its own).
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
        show(safe)
        // hyprpaper.conf and hyprlock.conf both read this link (kept out of git, it's your choice)
        Quickshell.execDetached(["sh", "-c", "mkdir -p \"$HOME/.config/hypr/settings\" && ln -sfn \"$1\" \"$HOME/.config/hypr/settings/wallpaper\"", "sh", safe])
    }

    // What hyprpaper displays: the picture, or a blurred copy (made once per picture and strength,
    // at most 2560 px wide, blurred at half that, so even a big photo takes well under a second;
    // the newest 10 copies are kept)
    function show(path) {
        if (!path) return
        if (c.blur <= 0) { Quickshell.execDetached(["hyprctl", "hyprpaper", "wallpaper", "," + path]); return }
        Quickshell.execDetached(["sh", "-c",
            "d=\"$HOME/.cache/wallpaper-blur\"; out=\"$d/$(printf %s \"$1$2\" | md5sum | cut -c1-16).jpg\"; mkdir -p \"$d\"; "
            + "[ -f \"$out\" ] || { magick \"$1\" -resize 1280x1280\\> -blur 0x\"$2\" -resize 200% -quality 92 \"$out.tmp.jpg\" && mv \"$out.tmp.jpg\" \"$out\"; }; "
            + "[ -f \"$out\" ] && hyprctl hyprpaper wallpaper \",$out\"; ls -t \"$d\"/*.jpg | tail -n +11 | xargs -r rm -f",
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

    // every image in the folders (and one level of subfolders), plus the one shown now
    Process {
        id: lister
        command: ["sh", "-c", "for d in \"$@\"; do [ -d \"$d\" ] && find -L \"$d\" -maxdepth 2 -type f \\( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \\); done | sort -u; echo '--'; readlink -f \"$HOME/.config/hypr/settings/wallpaper\"",
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

    IpcHandler {
        target: "wallpaper"
        function next(): void { root.next() }
        function set(path: string): void { root.apply(root.expand(path)) }
    }
}
