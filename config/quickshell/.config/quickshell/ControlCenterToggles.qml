import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import Quickshell.Networking
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Control Center part: the quick-toggle tiles (Caffeine, shared monitor, key light, keyboard, touchpad, touchscreen, record).
// Used by ControlCenter.qml; reads the panel's state from the ControlCenter singleton.
ColumnLayout {
    Layout.fillWidth: true
    Layout.row: Math.max(0, ControlCenter.shownSections.indexOf("toggles"))
    visible: ControlCenter.shownSections.includes("toggles")
    spacing: ControlCenter.gap

    // ---- quick toggles: name, then what it's doing ---------------------------------------
    GridLayout {
        id: grid
        Layout.fillWidth: true
        // up to four in one row, else rows of four or three, whichever leaves the fuller last row (5: 3+2, 6: 3+3,
        // 7: 4+3); the last row's tiles share the full width. 12 grid columns: every row count divides it.
        columns: 12
        readonly property int perRow: count <= 4 ? Math.max(1, count) : count % 4 === 0 || count % 4 === 3 ? 4 : 3
        readonly property int lastRow: Math.floor((count - 1) / perRow)
        function row(id) { return Math.floor(idx(id) / perRow) }
        function span(id) { const r = row(id); return 12 / (r < lastRow ? perRow : count - lastRow * perRow) }
        function col(id) { return (idx(id) % perRow) * span(id) }
        readonly property var ids: ControlCenter.shownToggles.filter(id => id !== "touchpad" || Inputs.touchpadName !== "")   // what is actually drawn
        readonly property int count: ids.length
        function idx(id) { return Math.max(0, ids.indexOf(id)) }
        columnSpacing: ControlCenter.gap
        rowSpacing: ControlCenter.gap
        ControlCenterQuickToggle {
            visible: ControlCenter.shownToggles.includes("caffeine")
            Layout.row: grid.row("caffeine"); Layout.column: grid.col("caffeine"); Layout.columnSpan: grid.span("caffeine"); Layout.preferredWidth: grid.span("caffeine"); Layout.horizontalStretchFactor: grid.span("caffeine")
            glyph: "\u{F0176}"
            label: "Caffeine"
            status: Caffeine.active ? Caffeine.remaining(ControlCenter.now.getTime()) : "Off"
            hint: "Keep awake · chevron to choose how long"
            active: Caffeine.active
            expandable: true
            isExpanded: ControlCenter.view.expanded === "caffeine"
            onToggled: Caffeine.toggle()
            onExpand: ControlCenter.view.toggleExpanded("caffeine")
        }
        ControlCenterQuickToggle { // shared monitor (monswitch), only when ~/.config/monswitch.conf exists
            visible: ControlCenter.shownToggles.includes("monitor")
            Layout.row: grid.row("monitor"); Layout.column: grid.col("monitor"); Layout.columnSpan: grid.span("monitor"); Layout.preferredWidth: grid.span("monitor"); Layout.horizontalStretchFactor: grid.span("monitor")
            readonly property bool ours: Hyprland.monitors.values.some(m => m.name === Machine.switchOutput)
            glyph: "\u{F0379}"
            label: "Monitor"
            status: ours ? "Here" : "Other PC"
            hint: ours ? "Shared monitor shows this computer · click to hand it over" : "Shared monitor shows the other computer · click to take it back"
            active: ours
            onToggled: Quickshell.execDetached(["monswitch", "toggle"])
        }
        ControlCenterQuickToggle {
            visible: ControlCenter.shownToggles.includes("keylight")
            Layout.row: grid.row("keylight"); Layout.column: grid.col("keylight"); Layout.columnSpan: grid.span("keylight"); Layout.preferredWidth: grid.span("keylight"); Layout.horizontalStretchFactor: grid.span("keylight")
            glyph: ControlCenter.kbdLight > 0 ? "\u{F0E5B}" : "\u{F0E5A}"
            label: "Key light"
            status: ["Off", "Low", "Medium", "High"][ControlCenter.kbdLight]
            hint: "Keyboard backlight · click for the next level"
            active: ControlCenter.kbdLight > 0
            onToggled: ControlCenter.setKbd((ControlCenter.kbdLight + 1) % 4)
        }
        ControlCenterQuickToggle {
            visible: ControlCenter.shownToggles.includes("keyboard")
            Layout.row: grid.row("keyboard"); Layout.column: grid.col("keyboard"); Layout.columnSpan: grid.span("keyboard"); Layout.preferredWidth: grid.span("keyboard"); Layout.horizontalStretchFactor: grid.span("keyboard")
            glyph: "\u{F030C}"
            label: "Keyboard"
            status: Osk.visible ? "Shown" : "Hidden"
            hint: "On-screen keyboard"
            active: Osk.visible
            onToggled: Osk.toggle()
        }
        ControlCenterQuickToggle {
            visible: ControlCenter.shownToggles.includes("touchpad") && Inputs.touchpadName !== ""
            Layout.row: grid.row("touchpad"); Layout.column: grid.col("touchpad"); Layout.columnSpan: grid.span("touchpad"); Layout.preferredWidth: grid.span("touchpad"); Layout.horizontalStretchFactor: grid.span("touchpad")
            glyph: Inputs.touchpad ? "\u{F0E40}" : "\u{F0E41}"
            label: "Touchpad"
            status: Inputs.touchpad ? "On" : "Off"
            hint: "Turn it off while typing on an external keyboard; back on at the next login"
            active: Inputs.touchpad
            onToggled: Inputs.setTouchpad(!Inputs.touchpad)
        }
        ControlCenterQuickToggle {
            visible: ControlCenter.shownToggles.includes("touchscreen")
            Layout.row: grid.row("touchscreen"); Layout.column: grid.col("touchscreen"); Layout.columnSpan: grid.span("touchscreen"); Layout.preferredWidth: grid.span("touchscreen"); Layout.horizontalStretchFactor: grid.span("touchscreen")
            glyph: "\u{F0741}"
            label: "Touch"
            status: Inputs.touchscreen ? "On" : "Off"
            hint: "Touchscreen and pen; back on at the next login"
            active: Inputs.touchscreen
            onToggled: Inputs.setTouchscreen(!Inputs.touchscreen)
        }
        ControlCenterQuickToggle {
            visible: ControlCenter.shownToggles.includes("record")
            Layout.row: grid.row("record"); Layout.column: grid.col("record"); Layout.columnSpan: grid.span("record"); Layout.preferredWidth: grid.span("record"); Layout.horizontalStretchFactor: grid.span("record")
            glyph: "\u{F044A}"
            label: "Record"
            status: Sys.recording ? "Recording" : "Off"
            hint: "Record the screen under the mouse (Super+Alt+R) · Super+Alt+Shift+R for an area"
            active: Sys.recording
            onToggled: { if (!Sys.recording) ControlCenter.hide(); Quickshell.execDetached(["sh", "-c", "sleep 0.3; record " + (Sys.recording ? "stop" : "screen")]) }
        }
    }

    ControlCenterDrop {
        open: ControlCenter.view.expanded === "caffeine"
        title: "Caffeine"
        switchOn: Caffeine.active
        onSwitched: Caffeine.toggle()
        settingsLabel: "Lock & Sleep Settings…"
        settingsPage: "idle"

        Text {
            Layout.fillWidth: true
            Layout.leftMargin: 6
            Layout.rightMargin: 6
            Layout.bottomMargin: 2
            wrapMode: Text.Wrap
            text: !Caffeine.active ? "Keeps the screen on and stops sleep. Stays on after a restart until you turn it off."
                : Caffeine.endsAt === 0 ? "Keeping the screen on until you turn it off."
                : "Keeping the screen on until " + Qt.formatTime(new Date(Caffeine.endsAt), "HH:mm") + "  ·  " + Caffeine.remaining(ControlCenter.now.getTime())
            color: Theme.subtext
            font { family: Theme.font; pixelSize: Theme.fontCaption }
        }
        ControlCenterSectionLabel { text: Caffeine.active ? "Change to" : "Turn on for" }
        ControlCenterSegmented {
            options: Caffeine.choices.map(m => m === 0 ? "Always" : Caffeine.label(m))
            current: Caffeine.active ? Caffeine.choices.indexOf(Caffeine.minutes) : -1
            onPicked: i => { Caffeine.start(Caffeine.choices[i]); ControlCenter.now = new Date() }
        }
    }
}
