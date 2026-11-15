import Quickshell
import QtQuick
import QtQuick.Layouts

// The Control Center's contents: its sections in the order Settings gives them, then a footer with the battery
// and the panel's own buttons (Arrange, Settings, Lock, Power). Used by ControlCenter.qml for the panel and by
// Settings > Control Center as a live preview (with its own PanelState and `enabled: false`).
ColumnLayout {
    id: body
    property var host: null   // the PanelState of the panel it sits in
    spacing: ControlCenter.groupGap

    GridLayout {   // one column; each section takes the row of its place in ControlCenter.shownSections
        Layout.fillWidth: true
        columns: 1
        rowSpacing: ControlCenter.groupGap

        ControlCenterConnections { host: body.host; tiles: ControlCenter.shownTiles; Layout.row: ControlCenter.row("connections"); visible: ControlCenter.shows("connections") && tiles.length > 0 }
        ControlCenterSliders { host: body.host; inPanel: true; parts: ControlCenter.shownSliders; Layout.row: ControlCenter.row("sliders"); visible: ControlCenter.shows("sliders") && parts.length > 0 }
        ControlCenterToggles { host: body.host; ids: ControlCenter.shownToggles; Layout.row: ControlCenter.row("toggles"); visible: ControlCenter.shows("toggles") && ids.length > 0 }
        ControlCenterMedia { host: body.host; Layout.row: ControlCenter.row("media"); visible: ControlCenter.shows("media") }
        ControlCenterPower { host: body.host; Layout.row: ControlCenter.row("power"); visible: ControlCenter.shows("power") }
    }

    // ---- footer: the battery as a readout, then the panel's own buttons, quieter than the tiles ----
    RowLayout {
        Layout.fillWidth: true
        spacing: 2
        Row {
            visible: Sys.hasBattery
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: Theme.spaceXs
            spacing: Theme.spaceXs
            Text { anchors.verticalCenter: parent.verticalCenter; text: Sys.batteryGlyph; color: Sys.batteryLow ? Theme.error : Sys.charging ? Theme.success : Theme.subtext
                   font { family: Theme.iconFont; pixelSize: 16 } }
            Text { anchors.verticalCenter: parent.verticalCenter; text: Sys.batteryPct + "%" + (Sys.charging ? "  ·  Charging" : ""); color: Sys.batteryLow ? Theme.error : Theme.subtext
                   font { family: Theme.font; pixelSize: Theme.fontCaption; weight: Font.Medium; features: { "tnum": 1 } } }
        }
        Item { Layout.fillWidth: true; implicitHeight: 1 }
        Repeater {
            model: [
                { glyph: "\u{F03EB}", tip: "Arrange the Control Center", run: () => SettingsApp.show("controlcenter") },
                { glyph: "\u{F0493}", tip: "Settings", run: () => SettingsApp.show("") },
                { glyph: "\u{F033E}", tip: "Lock", run: () => Quickshell.execDetached(["loginctl", "lock-session"]) },
                { glyph: "\u{F0425}", tip: "Power", run: () => PowerMenu.show() }
            ]
            Rectangle {
                id: btn
                required property var modelData
                function run() { body.host?.hide(); modelData.run() }
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: Theme.ccWell; implicitHeight: Theme.ccWell
                radius: Theme.radiusSmall
                color: area.pressed ? Theme.fillActive : area.containsMouse || btn.activeFocus ? Theme.fillHover : "transparent"
                scale: area.pressed ? Theme.pressScale : 1
                activeFocusOnTab: true
                Keys.onSpacePressed: run()
                Keys.onReturnPressed: run()
                FocusRing {}
                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easing } }
                Text { anchors.centerIn: parent; text: btn.modelData.glyph; color: btn.modelData.tip === "Power" ? Theme.error : Theme.text; font { family: Theme.iconFont; pixelSize: 16 } }
                MouseArea { id: area; Accessible.role: Accessible.Button; Accessible.name: btn.modelData.tip; Accessible.onPressAction: btn.run(); anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onContainsMouseChanged: containsMouse ? body.host?.hint(parent, btn.modelData.tip) : body.host?.unhint(parent)
                            onClicked: btn.run() }
            }
        }
    }
}
