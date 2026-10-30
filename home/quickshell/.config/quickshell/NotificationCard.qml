import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts

// One notification: app icon, app name and age, title, body and the app's buttons. Used for the
// banners and in the notification centre. Click to open it in the app, × to dismiss.
Glass {
    id: card

    property Notification notification
    property bool banner: false
    property int stacked: 0                // more notifications folded behind this one
    readonly property bool hovered: area.containsMouse || closeArea.containsMouse
    readonly property bool critical: notification?.urgency === NotificationUrgency.Critical
    readonly property var buttons: (notification?.actions ?? []).filter(a => a.identifier !== "default" && a.text !== "")
    signal expandRequested()

    implicitHeight: content.implicitHeight + Theme.spaceM * 2
    strong: true
    radius: Theme.radius
    border.color: critical ? Theme.peach : Theme.stroke

    // folded cards peek out underneath, like the macOS stack
    Repeater {
        model: Math.min(card.stacked, 2)
        Rectangle {
            required property int index
            z: -1 - index
            x: (index + 1) * 8; width: card.width - x * 2
            y: card.height - card.radius; height: card.radius + (index + 1) * 6
            radius: card.radius
            color: Theme.glassStrong
            border { color: Theme.stroke; width: 1 }
            opacity: 0.8 - index * 0.25
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: if (card.stacked > 0) card.expandRequested(); else if (card.notification) Notifications.activate(card.notification)
    }

    RowLayout {
        id: content
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.spaceM }
        spacing: Theme.spaceM

        IconImage {
            readonly property string src: card.notification ? Notifications.iconOf(card.notification) : ""
            Layout.alignment: Qt.AlignTop
            visible: src !== ""
            implicitSize: 36
            source: src
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            RowLayout {
                Layout.fillWidth: true
                Text {
                    Layout.fillWidth: true
                    text: card.notification?.appName ?? ""
                    color: Theme.subtext
                    elide: Text.ElideRight
                    font { family: Theme.font; pixelSize: Theme.fontCaption; weight: Font.DemiBold }
                }
                Text {
                    visible: !card.hovered || card.stacked > 0
                    text: card.stacked > 0 ? `${card.stacked} more` : card.notification ? Notifications.ago(card.notification) : ""
                    color: Theme.muted
                    font { family: Theme.font; pixelSize: Theme.fontCaption }
                }
            }
            Text {
                Layout.fillWidth: true
                text: card.notification?.summary ?? ""
                color: Theme.text
                elide: Text.ElideRight
                font { family: Theme.font; pixelSize: Theme.fontSize; weight: Font.DemiBold }
            }
            Text {
                Layout.fillWidth: true
                visible: text !== ""
                text: card.notification?.body ?? ""
                color: Theme.subtext
                textFormat: Text.StyledText
                wrapMode: Text.Wrap
                maximumLineCount: card.banner ? 3 : 5
                elide: Text.ElideRight
                font { family: Theme.font; pixelSize: Theme.fontLabel }
            }
            RowLayout {
                visible: card.buttons.length > 0 && card.stacked === 0
                Layout.topMargin: Theme.spaceXs
                spacing: Theme.spaceXs
                Repeater {
                    model: card.buttons.slice(0, 3)
                    PillButton { required property var modelData; text: modelData.text; onClicked: modelData.invoke() }
                }
            }
        }
    }

    // dismiss, shown on hover
    Rectangle {
        anchors { top: parent.top; right: parent.right; margins: Theme.spaceS }
        width: 22; height: 22; radius: 11
        visible: card.hovered && card.stacked === 0
        color: closeArea.containsMouse ? Theme.fillActive : Theme.fillHover
        Text { anchors.centerIn: parent; text: "\u{F0156}"; color: Theme.text; font { family: Theme.iconFont; pixelSize: 12 } }
        MouseArea {
            id: closeArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: card.notification?.dismiss()
        }
    }
}
