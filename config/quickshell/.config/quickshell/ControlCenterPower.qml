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

        ControlCenterSegmented {   // the asusctl / power-profiles id stays "quiet"; people read Silent
            visible: !pw.folded && !ControlCenter.hud
            options: ["Silent", "Balanced", "Performance"]
            current: PowerMode.profile
            accessibleName: "Power mode"
            onPicked: i => PowerMode.set(i)
        }
        Item {   // hud: `mode: <balanced>`; the arrows (or Left / Right, or a click on the word) step through the modes
            id: hudMode
            visible: !pw.folded && ControlCenter.hud
            Layout.fillWidth: true
            implicitHeight: Math.max(Theme.hit, Theme.fontLabel * 2)
            readonly property var names: ["silent", "balanced", "performance"]
            function step(d) { PowerMode.set((PowerMode.profile + d + names.length) % names.length) }
            activeFocusOnTab: true
            Keys.onLeftPressed: step(-1)
            Keys.onRightPressed: step(1)
            Keys.onSpacePressed: step(1)
            Accessible.role: Accessible.Slider
            Accessible.name: "Power mode"
            Accessible.description: names[PowerMode.profile] ?? ""
            Accessible.focusable: true
            FocusRing {}
            Row {
                anchors.verticalCenter: parent.verticalCenter
                Repeater {
                    model: [["mode: ", 0], ["<", -1], [hudMode.names[PowerMode.profile] ?? "?", 1], [">", 1]]
                    Text {
                        required property var modelData
                        required property int index
                        text: modelData[0]
                        color: index === 0 ? Theme.subtext : index === 2 ? Theme.accent : stepArea.containsMouse ? Theme.accent : Theme.text
                        font { family: Theme.monoFont; pixelSize: Theme.fontLabel; weight: index === 2 ? Font.Bold : Font.Normal }
                        MouseArea {
                            id: stepArea
                            anchors { fill: parent; margins: -Theme.spaceXs }
                            enabled: index > 0
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            Accessible.ignored: true
                            onClicked: hudMode.step(modelData[1])
                        }
                    }
                }
            }
        }
    }
}
