import QtQuick

// The battery in the bar: a cell filled to the charge (ok colour while charging, error when low) and its
// percentage where Settings > Menu Bar > Battery percentage puts it: inside the cell, beside it, or off.
// Used by the quick-settings item (BarStatus) and the Battery item (BarWidget).
Grid {
    id: bat
    property color tone: Theme.text
    property string family: Theme.font
    property bool vertical: false
    readonly property string where: Config.bar.batteryPercent   // inside | beside | off
    readonly property bool inside: where === "inside"
    readonly property color fillTone: Sys.batteryLow ? Theme.error : Sys.charging ? Theme.success : tone
    readonly property string pct: Sys.batteryPct + (Sys.charging ? "+" : "%")

    visible: Sys.hasBattery
    columns: vertical ? 1 : 2
    spacing: vertical ? 2 : 4
    horizontalItemAlignment: Grid.AlignHCenter
    verticalItemAlignment: Grid.AlignVCenter

    Item {
        implicitWidth: cell.width + 3
        implicitHeight: cell.height
        Rectangle {
            id: cell
            width: bat.inside ? (Sys.batteryPct >= 100 ? 34 : 30) : 21
            height: bat.inside ? 16 : 12
            radius: Math.min(bat.inside ? 4 : 3.5, Theme.radiusSmall)
            color: "transparent"
            border { color: Qt.alpha(bat.tone, 0.5); width: 1 }
            Rectangle {   // the charge
                x: 2; y: 2
                width: Math.max(2, (parent.width - 4) * Math.min(1, Sys.batteryPct / 100)); height: parent.height - 4
                radius: Math.max(0, parent.radius - 1.5)
                color: bat.fillTone
                opacity: bat.inside ? 0.38 : 1   // a tint under the number, so it stays readable
            }
            Text {
                visible: bat.inside
                anchors.centerIn: parent
                text: Sys.batteryPct
                color: Sys.batteryLow ? Theme.error : bat.tone
                font { family: bat.family; pixelSize: 10; weight: Font.Bold; features: { "tnum": 1 } }
            }
        }
        Rectangle { anchors { left: cell.right; leftMargin: 1; verticalCenter: cell.verticalCenter } width: 2; height: 4; radius: 1; color: Qt.alpha(bat.tone, 0.5) }
    }
    Text {
        visible: bat.where === "beside"
        text: bat.pct
        color: Sys.batteryLow ? Theme.error : bat.tone
        font { family: bat.family; pixelSize: bat.vertical ? Theme.fontCaption : Theme.fontLabel; features: { "tnum": 1 } }
    }
}
