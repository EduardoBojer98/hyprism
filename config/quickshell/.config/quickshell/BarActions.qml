pragma Singleton
import Quickshell
import QtQuick

// What a click, right-click or scroll on a bar item can do, chosen per item in settings.json
// (bar.items.<id>.click / rightClick / scroll). One place, so every item offers the same choices:
//   "default"            the item's own behaviour (same as leaving it out)
//   "none"               nothing
//   "panel:<name>"       open or close a panel: controlcenter, launcher, notifications, calendar, weather,
//                        system, power, clipboard, cheatsheet
//   "settings:<page>"    open Settings on that page (e.g. settings:power)
//   "volume" / "brightness"   scroll changes it
//   "run:<command>"      run a command of yours (it is your settings file, so it runs as you typed it)
Singleton {
    readonly property var panels: ({
        controlcenter: () => ControlCenter.toggle(), launcher: () => Launcher.toggle(),
        notifications: () => NotificationCenter.toggle(), calendar: () => Calendar.toggle(),
        weather: () => Weather.toggle(), system: () => Sensors.toggle(), power: () => PowerMenu.toggle(),
        clipboard: () => Clipboard.toggle(), cheatsheet: () => Cheatsheet.toggle()
    })
    readonly property var names: ["default", "none", "volume", "brightness"].concat(Object.keys(panels).map(p => "panel:" + p))

    // true when the action was handled; false means "do the item's own thing"
    function run(action, delta) {
        if (typeof action !== "string" || action === "" || action === "default") return false
        if (action === "none") return true
        const cut = action.indexOf(":")
        const kind = cut < 0 ? action : action.slice(0, cut)
        const arg = cut < 0 ? "" : action.slice(cut + 1)
        if (kind === "panel" && panels[arg]) { panels[arg](); return true }
        if (kind === "settings" && /^[a-z]+$/.test(arg)) { SettingsApp.show(arg); return true }
        if (kind === "volume") { Sys.nudgeVolume(delta ?? 1); return true }
        if (kind === "brightness") { Sys.nudgeBrightness(delta ?? 1); return true }
        if (kind === "run" && arg !== "") { Quickshell.execDetached(["sh", "-c", arg]); return true }
        console.warn("bar: unknown action '" + action + "'")
        return false
    }
}
