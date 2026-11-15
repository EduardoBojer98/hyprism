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
    property var host: null   // the panel it sits in (PanelState): ControlCenter.view or a Flyout's
    spacing: ControlCenter.gap

    // ---- power mode ---------------------------------------------------------------------
    ControlCenterModule {
        title: "Power mode"
        detail: Config.controlCenter.showHardware && !isNaN(Sensors.cpu) ? `CPU ${Math.round(Sensors.cpu)}°` : ""
        warn: Sensors.cpu >= 90
        onDetailClicked: { host.hide(); SettingsApp.show(Machine.asus ? "asus" : "power") }

        Choice {   // the asusctl / power-profiles id stays "quiet"; people read Silent
            Layout.fillWidth: true
            options: ["Silent", "Balanced", "Performance"]
            index: PowerMode.profile
            accessibleName: "Power mode"
            onPicked: i => PowerMode.set(i)
        }
    }
}
