pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// What this computer has, checked once at start, so hardware-only features appear only where
// they work: the ASUS page and charge limit (asusctl), the keyboard light (any *kbd_backlight
// LED), and the shared-monitor switch (~/.config/monswitch.conf, see docs/USER-GUIDE.md).
Singleton {
    property bool asus: false
    property string kbdDevice: ""      // e.g. asus::kbd_backlight
    property string switchOutput: ""   // monitor monswitch hands over, e.g. HDMI-A-1
    readonly property bool monitorSwitch: switchOutput !== ""

    Process {
        running: true
        command: ["sh", "-c", "command -v asusctl >/dev/null && echo asus; "
            + "for l in /sys/class/leds/*kbd_backlight; do [ -e \"$l\" ] && echo \"kbd ${l##*/}\" && break; done; "
            + "f=\"${XDG_CONFIG_HOME:-$HOME/.config}/monswitch.conf\"; [ -f \"$f\" ] && (. \"$f\"; echo \"switch $OUT\"); true"]
        stdout: StdioCollector {
            onStreamFinished: {
                for (const line of text.trim().split("\n")) {
                    const [key, value] = [line.split(" ")[0], line.slice(line.indexOf(" ") + 1)]
                    if (key === "asus") asus = true
                    else if (key === "kbd") kbdDevice = value
                    else if (key === "switch") switchOutput = value
                }
            }
        }
    }
}
