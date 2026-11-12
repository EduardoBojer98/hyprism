pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Settings > Wallpaper > "Colours from the wallpaper" (Config.appearance.wallpaperColours, off by default).
// When on and the wallpaper is your own picture (not one a theme draws or ships), the `wallpaper-colours` script
// picks an accent and a second accent from it, kept at 3:1 contrast on the theme's surface. They are saved as
// the theme's adjustments (Themes.adjust: accent, accent2), so validation and the text-on-accent check still apply.
// What they replaced is kept in Config.appearance.custom[theme]._before and put back when the mode goes off,
// the wallpaper is the theme's own again, or another theme becomes the active one.
Singleton {
    id: root

    readonly property string cur: Wallpapers.current
    // the pictures themes draw (~/.cache/hyprism/wallpapers) or ship in their folders are not "yours"
    readonly property bool own: cur !== "" && cur.indexOf("/hyprism/wallpapers/") < 0 && !cur.startsWith(Themes.shippedDir + "/") && !cur.startsWith(Themes.ownDir + "/")
    readonly property bool want: Config.loaded && Themes.ready && Config.appearance.wallpaperColours && own
    readonly property string theme: Config.appearance.theme
    readonly property string surface: Theme.surfaceColor.toString()
    readonly property string job: want ? [cur, theme, Theme.light ? "light" : "dark", surface].join("|") : ""
    onJobChanged: debounce.restart()
    onWantChanged: debounce.restart()
    onThemeChanged: debounce.restart()

    function restoreAll(keepActive) {
        const all = JSON.parse(JSON.stringify(Config.appearance.custom ?? {}))
        let changed = false
        for (const id of Object.keys(all)) {
            const o = all[id]
            if (!o || typeof o !== "object" || o._before === undefined || (keepActive && id === theme)) continue
            for (const k of ["accent", "accent2"]) {
                const v = o._before?.[k]
                if (v === undefined || v === null) delete o[k]; else o[k] = v
            }
            delete o._before
            if (Object.keys(o).length === 0) delete all[id]
            changed = true
        }
        if (changed) Config.set("appearance", "custom", all)
    }

    function apply(r) {
        if (!/^#[0-9a-f]{6}$/.test(r.accent ?? "") || !/^#[0-9a-f]{6}$/.test(r.accent2 ?? "")) { restoreAll(false); return }
        const o = (Config.appearance.custom ?? {})[theme] ?? {}
        if (o._before === undefined) Themes.adjust("_before", { accent: o.accent ?? null, accent2: o.accent2 ?? null })
        Themes.adjust("accent", r.accent)
        Themes.adjust("accent2", r.accent2)
    }

    Timer {
        id: debounce
        interval: 800
        onTriggered: {
            if (!Config.loaded || !Themes.ready) return
            root.restoreAll(root.want)
            if (!root.want || !/^#[0-9a-fA-F]{6}$/.test(root.surface)) return
            runner.job = root.job
            runner.running = false
            runner.command = ["wallpaper-colours", root.cur, Theme.light ? "light" : "dark", root.surface]
            runner.running = true
        }
    }
    Process {
        id: runner
        property string job: ""
        stdout: StdioCollector {
            onStreamFinished: {
                if (runner.job !== root.job) return   // the picture or theme changed meanwhile: a newer run follows
                try { root.apply(JSON.parse(text)) } catch (e) { console.warn("wallpaper-colours: " + e) }
            }
        }
    }
    Component.onCompleted: debounce.restart()
}
