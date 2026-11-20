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
    // the pictures themes draw or ship are not "yours"
    readonly property bool own: cur !== "" && !Wallpapers.isTheme(cur)
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
            runner.command = ["wallpaper-colours", Wallpapers.still(root.cur), Theme.light ? "light" : "dark", root.surface]
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

    // Settings > Appearance > Light or dark "Wallpaper": how bright your own picture is, 0 to 1 (-1: a theme's
    // picture, or the theme sets the wallpaper, where switching halves would swap the picture too)
    readonly property string brightJob: Config.loaded && Config.appearance.mode === "wallpaper" && own && !Config.appearance.wallpaper ? Wallpapers.still(cur) : ""
    property real bright: -1
    onBrightJobChanged: {
        if (!brightJob) { bright = -1; return }
        meter.running = false
        meter.command = ["magick", brightJob.startsWith("/") ? brightJob + "[0]" : "./" + brightJob, "-resize", "64x64", "-colorspace", "Gray", "-format", "%[fx:mean]", "info:"]
        meter.running = true
    }
    Process {
        id: meter
        stdout: StdioCollector { onStreamFinished: { const v = parseFloat(text); if (v >= 0 && v <= 1) root.bright = v } }
    }

    // Settings > Lock Screen "Colours from its picture": accents picked from what the lock screen shows (its own
    // picture or the desktop's), for the lock screen only; ThemeSync writes them. "" = the desktop's accents.
    readonly property string lockPicture: Config.lockscreen.wallpaper ? Wallpapers.expand(Config.lockscreen.wallpaper) : Wallpapers.still(cur)
    // picked as on a dark surface brighter than the dimmed picture, so they read over it (light enough for ThemeSync's 0.45 check)
    readonly property string lockJob: Config.loaded && Config.lockscreen.wallpaperColours && lockPicture.startsWith("/") ? lockPicture : ""
    property string lockAccent: ""
    property string lockAccent2: ""
    onLockJobChanged: lockDebounce.restart()
    Timer {
        id: lockDebounce
        interval: 800
        onTriggered: {
            root.lockAccent = ""; root.lockAccent2 = ""
            if (!root.lockJob) return
            lockRunner.job = root.lockJob
            lockRunner.running = false
            lockRunner.command = ["wallpaper-colours", root.lockPicture, "dark", "#3a3a3a"]   // palette: a contrast reference above the dimmed picture, not a theme colour
            lockRunner.running = true
        }
    }
    Process {
        id: lockRunner
        property string job: ""
        stdout: StdioCollector {
            onStreamFinished: {
                if (lockRunner.job !== root.lockJob) return
                try {
                    const r = JSON.parse(text)
                    if (/^#[0-9a-f]{6}$/.test(r.accent ?? "") && /^#[0-9a-f]{6}$/.test(r.accent2 ?? "")) { root.lockAccent = r.accent; root.lockAccent2 = r.accent2 }
                } catch (e) { console.warn("wallpaper-colours (lock): " + e) }
            }
        }
    }
}
