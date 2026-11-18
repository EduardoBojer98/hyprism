pragma Singleton
import Quickshell
import Quickshell.Hyprland
import QtQuick

// When an action is offered (an action's `when`, Actions.qml): a plain object, every key must hold. Structured on
// purpose, never code to evaluate. Each test reads a live service property, so a binding that asks follows it.
//   screens: 2              at least that many screens
//   external: true|false    a screen besides the built-in panel is (not) connected
//   app: "firefox"          a window of that app is open (its Wayland app id / class)
//   battery: true|false     running on battery (false: plugged in)
//   wifi: "Home"            connected to that Wi-Fi network
//   powerMode: "quiet"      the power mode now: quiet | balanced | performance
//   hardware: "asus"        a hardware flag: asus, nvidia, canHibernate, monitorSwitch, wifi, bluetooth, mic,
//                           keylight, touchpad, phone (a paired phone is nearby)
//   recording: true|false   a screen recording is (not) running
//   preset: "desk"          that display preset can be applied (every screen it names is connected)
Singleton {
    readonly property var keys: ["screens", "external", "app", "battery", "wifi", "powerMode", "hardware", "recording", "preset"]
    readonly property var hardwareFlags: ["asus", "nvidia", "canHibernate", "monitorSwitch", "wifi", "bluetooth", "mic", "keylight", "touchpad", "phone"]

    function screens() { return Quickshell.screens.filter(s => Machine.realScreen(s.name)) }
    function hardware(flag) {
        switch (flag) {
        case "wifi": return !!Sys.wifi
        case "bluetooth": return !!Sys.adapter
        case "mic": return Sys.source !== null
        case "keylight": return Machine.kbdDevice !== ""
        case "touchpad": return Inputs.touchpadName !== ""
        case "phone": return Phone.ready
        default: return Machine[flag] === true
        }
    }
    function test(key, v) {
        switch (key) {
        case "screens": return screens().length >= v
        case "external": return screens().some(s => !s.name.startsWith("eDP")) === v
        case "app": return Hyprland.toplevels.values.some(t => (t.wayland?.appId ?? "").toLowerCase() === String(v).toLowerCase())
        case "battery": return (Sys.hasBattery && !Sys.plugged) === v
        case "wifi": return Sys.network?.name === v
        case "powerMode": return PowerMode.names[PowerMode.profile] === v
        case "hardware": return hardware(v)
        case "recording": return Sys.recording === v
        case "preset": { const p = Displays.presets.find(x => x.id === v); return !!p && Displays.available(p) }
        default: return false   // an unknown test never holds, so a typo hides the action instead of always showing it
        }
    }
    function holds(when) {
        if (!when) return true
        return Object.keys(when).every(k => test(k, when[k]))
    }
    // why a `when` from settings.json can't be used, or ""
    function problem(when) {
        if (when === undefined || when === null) return ""
        if (typeof when !== "object" || Array.isArray(when)) return "when must be an object"
        for (const k of Object.keys(when)) {
            const v = when[k]
            if (!keys.includes(k)) return "unknown condition " + k
            if (k === "screens" && !(Number.isInteger(v) && v >= 1 && v <= 8)) return "screens: a number 1-8"
            if (["external", "battery", "recording"].includes(k) && typeof v !== "boolean") return k + ": true or false"
            if (["app", "wifi", "preset"].includes(k) && !(typeof v === "string" && v.length > 0 && v.length <= 80)) return k + ": a name"
            if (k === "powerMode" && !PowerMode.names.includes(v)) return "powerMode: " + PowerMode.names.join(", ")
            if (k === "hardware" && !hardwareFlags.includes(v)) return "hardware: " + hardwareFlags.join(", ")
        }
        return ""
    }
}
