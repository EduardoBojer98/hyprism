pragma Singleton
import Quickshell
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

// Notification centre at the top right (click the clock, Super+N, `qs ipc call notifications
// toggle`): the month calendar, then the history grouped by app. A group folds into a stack of
// its newest notification; click the stack to unfold it. Scroll on the calendar to change month.
Singleton {
    id: root

    readonly property bool open: popup.open
    property var unfolded: ({})            // app name -> true
    property date month: new Date()
    readonly property var locale: Qt.locale("en_GB")   // Monday first, English names

    function toggle() { popup.toggle() }
    function shift(n) { month = new Date(month.getFullYear(), month.getMonth() + n, 1) }
    function fold(app, on) { const u = Object.assign({}, unfolded); if (on) delete u[app]; else u[app] = true; unfolded = u }

    CursorPopup {
        id: popup
        name: "notificationcenter"
        placement: "topRight"
        boxWidth: 380
        boxHeight: Math.min(column.implicitHeight, popup.targetScreen.height - popup.topReserve - Theme.spaceXl)
        onOpened: { Notifications.unread = 0; Notifications.now = new Date(); root.month = new Date(); root.unfolded = ({}) }

        Flickable {
            anchors.fill: parent
            contentHeight: column.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: column
                width: parent.width
                spacing: Theme.spaceM

                // ---- calendar ----
                Glass {
                    Layout.fillWidth: true
                    implicitHeight: cal.implicitHeight + Theme.spaceL * 2
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

                // ---- header ----
                Glass {
                    Layout.fillWidth: true
                    implicitHeight: 44
                    strong: true
                    radius: height / 2
                    RowLayout {
                        anchors { fill: parent; leftMargin: Theme.spaceL; rightMargin: Theme.spaceS }
                        Text {
                            Layout.fillWidth: true
                            text: Notifications.history.length ? "Notifications" : "No notifications"
                            color: Notifications.history.length ? Theme.text : Theme.subtext
                            font { family: Theme.font; pixelSize: Theme.fontSize; weight: Font.DemiBold }
                        }
                        Chip {
                            icon: Notifications.dnd ? "\u{F009B}" : "\u{F009A}"
                            label: Notifications.dnd ? "Do Not Disturb" : ""
                            active: Notifications.dnd
                            onClicked: Notifications.toggleDnd()
                        }
                        Chip { visible: Notifications.history.length > 0; label: "Clear all"; onClicked: Notifications.clearAll() }
                    }
                }

                // ---- groups ----
                Repeater {
                    model: Notifications.groups
                    ColumnLayout {
                        id: group
                        required property var modelData
                        readonly property bool open: modelData.items.length === 1 || root.unfolded[modelData.app] === true
                        Layout.fillWidth: true
                        Layout.bottomMargin: open ? 0 : 12        // room for the folded stack
                        spacing: Theme.spaceS

                        Glass {
                            visible: group.modelData.items.length > 1 && group.open
                            Layout.fillWidth: true
                            implicitHeight: 36
                            strong: true
                            radius: height / 2
                            RowLayout {
                                anchors { fill: parent; leftMargin: Theme.spaceL; rightMargin: Theme.spaceXs }
                                Text {
                                    Layout.fillWidth: true
                                    text: group.modelData.app
                                    color: Theme.subtext
                                    elide: Text.ElideRight
                                    font { family: Theme.font; pixelSize: Theme.fontLabel; weight: Font.DemiBold }
                                }
                                Chip { label: "Show less"; onClicked: root.fold(group.modelData.app, true) }
                                Chip { icon: "\u{F0156}"; onClicked: Notifications.clearApp(group.modelData.app) }
                            }
                        }
                        Repeater {
                            model: group.open ? group.modelData.items : group.modelData.items.slice(0, 1)
                            NotificationCard {
                                required property var modelData
                                Layout.fillWidth: true
                                notification: modelData
                                stacked: group.open ? 0 : group.modelData.items.length - 1
                                onExpandRequested: root.fold(group.modelData.app, false)
                            }
                        }
                    }
                }
            }
        }
    }
}
