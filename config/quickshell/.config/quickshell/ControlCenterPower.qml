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

// Control Center part: the power mode choice.
// Used by ControlCenter.qml and Flyouts.qml; the panel's own state comes from `host`.
ColumnLayout {
    Layout.fillWidth: true
    id: pw
    property var host: null   // the panel it sits in (PanelState): ControlCenter.view or a Flyout's
    property bool inPanel: false   // the Control Center: the card folds to one line (Config.controlCenter.folded "power")
    readonly property bool folded: inPanel && Array.from(Config.controlCenter.folded ?? []).includes("power")
    readonly property string temp: Config.controlCenter.showHardware && !isNaN(Sensors.cpu) ? `CPU ${Math.round(Sensors.cpu)}°` : ""
    spacing: ControlCenter.gap

    // ---- power mode ---------------------------------------------------------------------
    ControlCenterModule {
        title: "Power mode"
        detail: pw.folded ? ["Silent", "Balanced", "Performance"][PowerMode.profile] + (pw.temp ? " · " + pw.temp : "") : pw.temp
        warn: Sensors.cpu >= 90
        expandable: pw.inPanel
        isExpanded: !pw.folded
        onDetailClicked: {
            if (!pw.inPanel) { host.hide(); SettingsApp.show(Machine.asus ? "asus" : "power"); return }
            const l = Array.from(Config.controlCenter.folded ?? []).filter(k => k !== "power")
            Config.set("controlCenter", "folded", pw.folded ? l : l.concat(["power"]))
        }

        ControlCenterModes {   // the asusctl / power-profiles id stays "quiet"; people read Silent
            visible: !pw.folded
            options: [{ glyph: "\u{F0F86}", name: "Silent" }, { glyph: "\u{F0F85}", name: "Balanced" }, { glyph: "\u{F04C5}", name: ControlCenter.hud ? "Perf" : "Performance" }]
            current: PowerMode.profile
            accessibleName: "Power mode"
            onPicked: i => PowerMode.set(i)
        }
    }
}
