pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// What this computer has, checked once at start, so hardware-only features appear only where
// they work: the ASUS page and charge limit (asusctl), the keyboard light (any *kbd_backlight
// LED), the shared-monitor switch (~/.config/monswitch.conf, see docs/USER-GUIDE.md), hibernation
// (logind says it can: swap and resume set up) and an NVIDIA GPU.
Singleton {
    // a real display, not a virtual screen tests/nested.sh parks its test desktop on (kept out of every Settings list)
    function realScreen(name) { return !String(name ?? "").startsWith("hyprism-test-") }

    property bool asus: false
    property bool canHibernate: false
    property bool nvidia: false
    property string kbdDevice: ""      // e.g. asus::kbd_backlight
    property string switchOutput: ""   // monitor monswitch hands over, e.g. HDMI-A-1
    readonly property bool monitorSwitch: switchOutput !== ""

    function refresh() { probe.running = false; probe.running = true }   // after Settings > Shared Monitor saves

    Process {
        id: probe
        running: true
        command: ["sh", "-c", "command -v asusctl >/dev/null && echo asus; "
            + "for l in /sys/class/leds/*kbd_backlight; do [ -e \"$l\" ] && echo \"kbd ${l##*/}\" && break; done; "
            // the monitor's name only, read as text (the file is never run as shell)
            + "f=\"${XDG_CONFIG_HOME:-$HOME/.config}/monswitch.conf\"; [ -f \"$f\" ] && sed -n 's/^OUT=\\([A-Za-z0-9._-]*\\)$/switch \\1/p' \"$f\" | head -1; "
            + "busctl call org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager CanHibernate 2>/dev/null | grep -q '\"yes\"' && echo hibernate; "
            + "grep -qs 0x10de /sys/bus/pci/devices/*/vendor && echo nvidia; true"]
        stdout: StdioCollector {
            onStreamFinished: {
                switchOutput = ""
                for (const line of text.trim().split("\n")) {
                    const [key, value] = [line.split(" ")[0], line.slice(line.indexOf(" ") + 1)]
                    if (key === "asus") asus = true
                    else if (key === "kbd") kbdDevice = value
                    else if (key === "switch") switchOutput = value
                    else if (key === "hibernate") canHibernate = true
                    else if (key === "nvidia") nvidia = true
                }
            }
        }
    }
}
