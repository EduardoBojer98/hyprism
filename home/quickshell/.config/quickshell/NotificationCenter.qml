pragma Singleton
import Quickshell
import QtQuick
import QtQuick.Layouts

// Notification centre at the top right (the bell in the bar, Super+N, `qs ipc call notifications
// toggle`): the history grouped by app. A group folds into a stack of its newest notification;
// click the stack to unfold it. The calendar is its own popup under the clock (Calendar.qml).
Singleton {
    id: root

    readonly property bool open: popup.open
    property var unfolded: ({})            // app name -> true

    function toggle() { popup.toggle() }
    function fold(app, on) { const u = Object.assign({}, unfolded); if (on) delete u[app]; else u[app] = true; unfolded = u }

    CursorPopup {
        id: popup
        name: "notificationcenter"
        placement: "topRight"
        boxWidth: 380
        boxHeight: Math.min(column.implicitHeight, popup.targetScreen.height - popup.topReserve - Theme.spaceXl)
        onOpened: { Notifications.unread = 0; Notifications.now = new Date(); root.unfolded = ({}) }

        Flickable {
            anchors.fill: parent
            contentHeight: column.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: column
                width: parent.width
                spacing: Theme.spaceM

                // ---- header ----
                Glass {
                    Layout.fillWidth: true
                    implicitHeight: 44
                    strong: true
                    radius: Theme.radius
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
                            radius: Theme.radius
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
