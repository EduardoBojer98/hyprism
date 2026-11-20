import QtQuick
import QtQuick.Layouts

// Battery and power: the level and what the battery is doing, the draw and the time left (only while it
// runs on battery), the CPU temperature and fans, the power mode and Caffeine. The battery and
// power-profile items' flyout. Readings come from Metrics while it is open (Flyouts.qml asks for them).
ColumnLayout {
    id: mod
    property var host: null   // the panel it sits in (PanelState): ControlCenter.view or a Flyout's
    Layout.fillWidth: true
    spacing: ControlCenter.gap

    readonly property bool draining: Sys.hasBattery && !Sys.plugged && !Sys.charging
    readonly property string state: !Sys.hasBattery ? "No battery" : Sys.charging ? "Charging"
                                  : Sys.plugged ? (Sys.batteryPct >= 99 ? "Fully charged" : "Plugged in, not charging") : "On battery"
    // the readouts that exist on this machine, as "label value"
    readonly property var facts: [
        Metrics.has("battery_power") && Metrics.value("battery_power") >= 1 ? ["Draw", Metrics.text("battery_power")] : null,
        mod.draining && Metrics.has("battery_time") ? ["Left", Metrics.text("battery_time")] : null,
        Metrics.has("fans") ? ["Fans", Metrics.text("fans")] : null
    ].filter(f => f)

    ControlCenterModule {
        visible: Sys.hasBattery
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spaceS
            Text {
                text: Sys.batteryGlyph
                color: Sys.batteryLow ? Theme.error : Sys.charging ? Theme.success : Theme.text
                font { family: Theme.iconFont; pixelSize: Theme.fontHeading }
            }
            Text {
                text: Sys.batteryPct + "%"
                color: Sys.batteryLow ? Theme.error : Theme.text
                font { family: Theme.displayFont; pixelSize: Theme.fontDisplay; weight: Theme.displayWeight; features: { "tnum": 1 } }
            }
            Text {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignBottom
                Layout.bottomMargin: Theme.spaceXs
                text: mod.state
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignRight
                color: Theme.subtext
                font { family: ControlCenter.textFont; pixelSize: Theme.fontLabel }
            }
        }
        RowLayout {
            visible: mod.facts.length > 0
            Layout.fillWidth: true
            spacing: Theme.spaceL
            Repeater {
                model: mod.facts
                Column {
                    required property var modelData
                    Text { text: modelData[0]; color: Theme.subtext; font { family: ControlCenter.textFont; pixelSize: Theme.fontCaption } }
                    Text { text: modelData[1]; color: Theme.text; font { family: ControlCenter.textFont; pixelSize: Theme.fontLabel; weight: Font.DemiBold; features: { "tnum": 1 } } }
                }
            }
        }
    }

    ControlCenterPower { host: mod.host }

    ControlCenterModule {
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spaceS
            Column {
                Layout.fillWidth: true
                Text { text: "Caffeine"; color: Theme.text; font { family: ControlCenter.textFont; pixelSize: Theme.fontSize; weight: Font.DemiBold } }
                Text {
                    width: parent.width
                    text: !Caffeine.active ? "The screen sleeps as usual" : Caffeine.endsAt > 0 ? "Awake until " + Qt.formatTime(new Date(Caffeine.endsAt), Sys.h24 ? "HH:mm" : "h:mm ap") : "Keeping the screen awake"
                    elide: Text.ElideRight
                    color: Theme.subtext
                    font { family: ControlCenter.textFont; pixelSize: Theme.fontCaption }
                }
            }
            Toggle {
                checked: Caffeine.active
                accessibleName: "Caffeine"
                onToggled: on => on ? Caffeine.start(0) : Caffeine.stop()
            }
        }
    }
}
