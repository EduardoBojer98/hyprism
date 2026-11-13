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

// Control Center part: the row of shortcut buttons (screenshot, colour, windows ...).
// Used by ControlCenter.qml; reads the panel's state from the ControlCenter singleton.
ColumnLayout {
    Layout.fillWidth: true
    Layout.row: Math.max(0, ControlCenter.shownSections.indexOf("shortcuts"))
    visible: ControlCenter.shownSections.includes("shortcuts") && ControlCenter.shownShortcuts.length > 0
    spacing: ControlCenter.gap

    // ---- shortcuts ------------------------------------------------------------------------
    GridLayout {
        Layout.fillWidth: true
        columns: 4
        columnSpacing: ControlCenter.gap
        rowSpacing: ControlCenter.gap
        Repeater {
            model: ControlCenter.shownShortcuts
            ControlCenterIconButton {
                required property string modelData
                readonly property var sc: ControlCenter.shortcutInfo[modelData]
                glyph: sc.glyph
                label: sc.label
                onClicked: { ControlCenter.hide(); sc.run() }
            }
        }
    }
}
