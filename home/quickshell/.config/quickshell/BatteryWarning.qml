import Quickshell
import Quickshell.Services.UPower
import QtQuick

// Low battery: one notification at Config.battery.warnAt and a critical one (it stays) at
// criticalAt, while on battery. Each fires once until the charger goes in or the level climbs back.
Scope {
    id: root

    readonly property var bat: UPower.displayDevice
    readonly property int pct: Math.round((bat?.percentage ?? 1) * 100)
    readonly property bool draining: UPower.onBattery && (bat?.isPresent ?? false)
    property int warned: 0   // 0 none yet, 1 low, 2 critical

    function check() {
        const c = Config.battery
        if (!draining || pct > c.warnAt) { warned = 0; return }
        if (!c.warn) return
        if (pct <= c.criticalAt && warned < 2) {
            warned = 2
            Quickshell.execDetached(["notify-send", "-a", "Battery", "-u", "critical", "-i", "battery-caution",
                                     "Battery critically low", pct + "% left. Plug in now or save your work."])
        } else if (pct > c.criticalAt && warned < 1) {
            warned = 1
            Quickshell.execDetached(["notify-send", "-a", "Battery", "-i", "battery-low",
                                     "Battery low", pct + "% left"])
        }
    }
    onPctChanged: check()
    onDrainingChanged: check()
    Component.onCompleted: check()
}
