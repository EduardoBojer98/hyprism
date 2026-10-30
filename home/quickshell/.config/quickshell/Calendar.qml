pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Controls

// Month calendar centred under the clock (click the date and time in the bar). Scroll or the
// arrows change month; the month title goes back to today. `qs ipc call calendar toggle`.
Singleton {
    id: root

    readonly property bool open: popup.open
    property date month: new Date()
    readonly property var locale: Qt.locale("en_GB")   // Monday first, English names

    function toggle() { popup.toggle() }
    function shift(n) { month = new Date(month.getFullYear(), month.getMonth() + n, 1) }

    IpcHandler {
        target: "calendar"
        function toggle(): void { root.toggle() }
    }

    CursorPopup {
        id: popup
        name: "calendar"
        placement: "top"
        boxWidth: 300
        boxHeight: cal.implicitHeight + Theme.spaceL * 2
        onOpened: root.month = new Date()

        Glass {
            anchors.fill: parent
            strong: true
            radius: Theme.radiusLarge
            WheelHandler { onWheel: event => root.shift(event.angleDelta.y > 0 ? -1 : 1) }

            Column {
                id: cal
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.spaceL }
                spacing: Theme.spaceS

                Item {
                    width: parent.width; height: Theme.controlHeight
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.locale.standaloneMonthName(root.month.getMonth()) + " " + root.month.getFullYear()
                        color: Theme.text
                        font { family: Theme.font; pixelSize: Theme.fontTitle; weight: Font.DemiBold }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.month = new Date() }
                    }
                    Row {
                        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                        spacing: Theme.spaceXs
                        Chip { icon: "\u{F0141}"; onClicked: root.shift(-1) }
                        Chip { icon: "\u{F0142}"; onClicked: root.shift(1) }
                    }
                }
                DayOfWeekRow {
                    width: parent.width
                    locale: root.locale
                    delegate: Text {
                        required property string shortName
                        text: shortName.slice(0, 2)
                        horizontalAlignment: Text.AlignHCenter
                        color: Theme.muted
                        font { family: Theme.font; pixelSize: Theme.fontCaption; weight: Font.DemiBold }
                    }
                }
                MonthGrid {
                    width: parent.width
                    height: 6 * 32 + 5 * spacing   // the grid sizes its cells from its own height
                    locale: root.locale
                    month: root.month.getMonth()
                    year: root.month.getFullYear()
                    spacing: 2
                    delegate: Item {
                        required property int day
                        required property int month
                        required property bool today
                        implicitHeight: 32
                        Rectangle { anchors.centerIn: parent; width: 30; height: 30; radius: 15; visible: parent.today; color: Theme.accent }
                        Text {
                            anchors.centerIn: parent
                            text: parent.day
                            color: parent.today ? Theme.accentText : parent.month === root.month.getMonth() ? Theme.text : Theme.muted
                            font { family: Theme.font; pixelSize: Theme.fontSize; weight: parent.today ? Font.Bold : Font.Normal; features: { "tnum": 1 } }
                        }
                    }
                }
            }
        }
    }
}
