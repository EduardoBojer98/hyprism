pragma Singleton
import Quickshell
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC

// Notifications: their own panel, opened from the bell in the bar, Super+N or
// `qs ipc call notifications toggle` (the Control Center holds the controls only). A header with the
// count, Do Not Disturb and Clear all; then the history grouped by app, a group folded into its
// newest card until you open it; an empty state when there is nothing. Styled and moving like every
// other panel of the active theme.
Singleton {
    id: root

    readonly property bool open: popup.open
    property var unfolded: ({})            // app name -> true

    function toggle() { popup.toggle() }
    function fold(app, on) { const u = Object.assign({}, unfolded); if (on) delete u[app]; else u[app] = true; unfolded = u }

    CursorPopup {
        id: popup
        name: "notifications"
        placement: "topRight"
        boxWidth: 380
        boxHeight: Math.min(column.implicitHeight + 24, popup.maxHeight)
        onOpened: { Notifications.unread = 0; Notifications.now = new Date(); root.unfolded = ({}) }

        Glass {
            anchors.fill: parent
            strong: true
            radius: Theme.radiusLarge
        }
        Flickable {
            anchors { fill: parent; margins: 12 }
            contentHeight: column.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            QQC.ScrollBar.vertical: GlassScrollBar {}

            ColumnLayout {
                id: column
                width: parent.width
                spacing: 8

                // ---- header: title and count, Do Not Disturb, Clear all ----
                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 4
                    spacing: 8
                    Text {
                        text: "Notifications"
                        color: Theme.text
                        font { family: Theme.font; pixelSize: Theme.fontTitle; weight: Font.DemiBold }
                    }
                    Rectangle {   // how many, in the accent
                        visible: Notifications.history.length > 0
                        implicitWidth: Math.max(20, count.implicitWidth + 10); implicitHeight: 20
                        radius: Theme.radius === 0 ? 0 : 10
                        color: Theme.accent
                        Text { id: count; anchors.centerIn: parent; text: Notifications.history.length; color: Theme.accentText
                               font { family: Theme.font; pixelSize: Theme.fontCaption; weight: Font.Bold; features: { "tnum": 1 } } }
                    }
                    Item { Layout.fillWidth: true }
                    Chip {
                        icon: Notifications.dnd ? "\u{F009B}" : "\u{F009A}"
                        label: Notifications.dnd ? "Silenced" : "Do Not Disturb"
                        active: Notifications.dnd
                        onClicked: Notifications.toggleDnd()
                    }
                }
                Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.stroke }

                // ---- nothing yet ----
                Column {
                    visible: Notifications.history.length === 0
                    Layout.fillWidth: true
                    Layout.topMargin: 28
                    Layout.bottomMargin: 28
                    spacing: 8
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Notifications.dnd ? "\u{F009B}" : "\u{F009E}"
                        color: Theme.muted
                        font { family: Theme.iconFont; pixelSize: 34 }
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Notifications.dnd ? "Do Not Disturb is on" : "You're all caught up"
                        color: Theme.subtext
                        font { family: Theme.font; pixelSize: Theme.fontLabel; weight: Font.Medium }
                    }
                }

                // ---- the history, grouped by app ----
                Repeater {
                    model: Notifications.groups
                    ColumnLayout {
                        id: group
                        required property var modelData
                        readonly property bool unfolded: modelData.items.length === 1 || root.unfolded[modelData.app] === true
                        Layout.fillWidth: true
                        Layout.bottomMargin: unfolded ? 0 : 12        // room for the folded stack
                        spacing: 6

                        RowLayout {
                            visible: group.modelData.items.length > 1 && group.unfolded
                            Layout.fillWidth: true
                            Layout.leftMargin: 4
                            Text {
                                Layout.fillWidth: true
                                text: group.modelData.app
                                color: Theme.subtext
                                elide: Text.ElideRight
                                font { family: Theme.font; pixelSize: Theme.fontCaption; weight: Font.DemiBold }
                            }
                            Chip { label: "Show less"; onClicked: root.fold(group.modelData.app, true) }
                            Chip { icon: "\u{F0156}"; onClicked: Notifications.clearApp(group.modelData.app) }
                        }
                        Repeater {
                            model: group.unfolded ? group.modelData.items : group.modelData.items.slice(0, 1)
                            NotificationCard {
                                required property var modelData
                                Layout.fillWidth: true
                                flat: true
                                notification: modelData
                                stacked: group.unfolded ? 0 : group.modelData.items.length - 1
                                onExpandRequested: root.fold(group.modelData.app, false)
                            }
                        }
                    }
                }

                PillButton {
                    visible: Notifications.history.length > 0
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 4
                    text: "Clear all"
                    onClicked: Notifications.clearAll()
                }
            }
        }
    }
}
