pragma Singleton
import Quickshell
import QtQuick

// What a click, right-click or scroll on a bar item can do, chosen per item in settings.json
// (bar.items.<id>.click / rightClick / scroll). One place, so every item offers the same choices:
//   "default"            the item's own behaviour (same as leaving it out)
//   "none"               nothing
//   "action:<id>"        run an action (Actions.qml): a panel (action:panel-calendar), a built-in or one of yours
//   "panel:<name>"       older spelling of action:panel-<name>: controlcenter, launcher, notifications, calendar,
//                        weather, system, power, clipboard, cheatsheet, and the flyouts volume, network, bluetooth,
//                        brightness, media, battery
//   "settings:<page>"    open Settings on that page (e.g. settings:power)
//   "volume" / "brightness"   scroll changes it
//   "run:<command>"      run a command of yours through sh (it is your settings file); a failure shows a notification
Singleton {
    // panels keep their short "panel:" spelling in the list; every other action shown on the bar is "action:<id>"
    readonly property var names: ["default", "none", "volume", "brightness"]
        .concat(Actions.forSurface("bar").map(a => a.id.startsWith("panel-") ? "panel:" + a.id.slice(6) : "action:" + a.id))

    // true when the action was handled; false means "do the item's own thing"
    function run(action, delta) {
        if (typeof action !== "string" || action === "" || action === "default") return false
        if (action === "none") return true
        const cut = action.indexOf(":")
        const kind = cut < 0 ? action : action.slice(0, cut)
        const arg = cut < 0 ? "" : action.slice(cut + 1)
        if ((kind === "action" || kind === "panel") && Actions.get(kind === "panel" ? "panel-" + arg : arg)) {
            Actions.run(kind === "panel" ? "panel-" + arg : arg)
            return true
        }
        if (kind === "settings" && /^[a-z]+$/.test(arg)) { SettingsApp.show(arg); return true }
        if (kind === "volume") { Sys.nudgeVolume(delta ?? 1); return true }
        if (kind === "brightness") { Sys.nudgeBrightness(delta ?? 1); return true }
        if (kind === "run" && arg !== "") {
            const a = { id: "bar-run", name: arg, run: { type: "shell", value: arg } }
            const why = Actions.exec(a, a.run, [], null)
            if (why) Actions.fail(a, why, [])
            return true
        }
        console.warn("bar: unknown action '" + action + "'")
        return false
    }
}
