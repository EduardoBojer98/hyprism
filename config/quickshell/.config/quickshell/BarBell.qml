import QtQuick

// Notifications: always in its place; a bell (filled when there are notifications), the unread count
// on it, crossed out during Do Not Disturb; during a Focus mode, the mode's icon and name. Opens the Notifications panel.
BarItem {
    id: bell
    property color tone: Theme.text
    active: NotificationCenter.open
    opens: "notifications"
    onPressed: NotificationCenter.toggle()
    Item {   // wide enough for the badge, so it never hangs past the item (or off the screen's edge)
        width: unread.visible ? 16 + unread.width - 7 : 16; height: 18
        Text { anchors.centerIn: parent; text: Focus.mode ? (Focus.mode.icon || "\u{F0594}") : Notifications.dnd ? "\u{F009B}" : Notifications.history.length ? "\u{F009A}" : "\u{F009C}"; color: bell.tone; font { family: Theme.iconFont; pixelSize: 16 } }
        Rectangle {
            id: unread
            visible: Notifications.unread > 0 && !Notifications.dnd
            x: 16 - 7; y: -3
            width: Math.max(14, badge.implicitWidth + 6); height: 14; radius: Theme.radius === 0 ? 0 : 7
            color: Theme.error
            Text { id: badge; anchors.centerIn: parent; text: Notifications.unread > 9 ? "9+" : Notifications.unread; color: Theme.errorText; font { family: Theme.font; pixelSize: 9; weight: Font.Bold } }
        }
    }
    Text {   // the Focus mode on now (Focus.qml)
        visible: Focus.mode !== null && !bell.vertical
        text: Focus.mode?.name ?? ""
        color: bell.tone
        font { family: Theme.font; pixelSize: Theme.fontLabel; weight: Font.Medium }
    }
}
