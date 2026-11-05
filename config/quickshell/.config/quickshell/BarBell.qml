import QtQuick

// Notifications: always in its place; a bell (filled when there are notifications), the unread count
// on it, crossed out during Do Not Disturb. Opens the Notifications panel.
BarItem {
    id: bell
    property color tone: Theme.text
    active: NotificationCenter.open
    onPressed: NotificationCenter.toggle()
    Item {
        width: 16; height: 18
        Text { anchors.centerIn: parent; text: Notifications.dnd ? "\u{F009B}" : Notifications.history.length ? "\u{F009A}" : "\u{F009C}"; color: bell.tone; font { family: Theme.iconFont; pixelSize: 16 } }
        Rectangle {
            visible: Notifications.unread > 0 && !Notifications.dnd
            x: parent.width - 7; y: -3
            width: Math.max(14, badge.implicitWidth + 6); height: 14; radius: Theme.radius === 0 ? 0 : 7
            color: Theme.error
            Text { id: badge; anchors.centerIn: parent; text: Notifications.unread > 9 ? "9+" : Notifications.unread; color: "white"; font { family: Theme.font; pixelSize: 9; weight: Font.Bold } }
        }
    }
}
