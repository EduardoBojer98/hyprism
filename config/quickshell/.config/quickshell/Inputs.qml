pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Touchpad and touchscreen on or off (Control Center). For a 2-in-1: stop the palm from moving
// the pointer while typing on the external keyboard, or the screen reacting while it's folded.
// Not saved: both are back on after logging in, so nobody gets locked out of their pointer.
Singleton {
    id: root
    property bool touchpad: true
    property bool touchscreen: true
    // tablet mode (a 2-in-1 folded): controls grow to finger size (Theme.hit). Set by ~/.local/bin/panel
    property bool tablet: false
    IpcHandler {
        target: "tablet"
        function set(on: bool): void { root.tablet = on }
    }
    property string touchpadName: ""
    function setTouchpad(on) {
        touchpad = on
        if (touchpadName) Quickshell.execDetached(["hyprctl", "eval", `hl.device({ name = ${JSON.stringify(touchpadName)}, enabled = ${on} })`])   // the name quoted as a Lua string, whatever it holds
    }
    function setTouchscreen(on) {
        touchscreen = on
        Quickshell.execDetached(["hyprctl", "eval", `hl.config({ input = { touchdevice = { enabled = ${on} } } })`])
    }
    // the touchpad's device name, from Hyprland
    Process {
        running: true
        command: ["sh", "-c", "hyprctl -j devices | jq -r '.mice[].name' | grep -i touchpad | head -1"]
        stdout: StdioCollector { onStreamFinished: root.touchpadName = text.trim().replace(/[^A-Za-z0-9:_.-]/g, "") }
    }
}
