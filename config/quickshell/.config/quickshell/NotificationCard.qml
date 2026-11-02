import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts

// One notification: app icon, app name and age, title, body and the app's buttons. Used for the
// banners and in the notification centre. Click to open it in the app, × to dismiss.
// Style follows Config.notifications.style: card (full), pill (compact one-line), minimal (no border).
Glass {
    id: card

    property Notification notification
    property bool banner: false
    property int stacked: 0                // more notifications folded behind this one
    readonly property bool hovered: area.containsMouse || closeArea.containsMouse
    readonly property bool critical: notification?.urgency === NotificationUrgency.Critical
    readonly property var buttons: (notification?.actions ?? []).filter(a => a.identifier !== "default" && a.text !== "")
    readonly property string notifStyle: Config.notifications.style ?? "card"
    readonly property bool isPill: notifStyle === "pill"
    readonly property bool isMinimal: notifStyle === "minimal"
    signal expandRequested()

    implicitHeight: content.implicitHeight + (isPill ? Theme.spaceS : Theme.spaceM) * 2
    strong: !isMinimal
    radius: flat ? Theme.radius : isPill ? height / 2 : Theme.radiusLarge
    border.color: critical ? Theme.peach : (isMinimal ? "transparent" : Theme.stroke)
    border.width: isMinimal && !critical ? 0 : (critical || !flat ? 1 : 0)

    // folded cards peek out underneath (card style only)
    Repeater {
        model: (!isPill && !isMinimal) ? Math.min(card.stacked, 2) : 0
        Rectangle {
            required property int index
            z: -1 - index
            x: (index + 1) * 8; width: card.width - x * 2
            y: card.height - card.radius; height: card.radius + (index + 1) * 6
            radius: card.radius
            color: card.flat ? Theme.fill : Theme.glassStrong
            border { color: Theme.stroke; width: card.flat ? 0 : 1 }
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
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: isPill ? Theme.spaceS : Theme.spaceM }
        spacing: Theme.spaceS

        // App icon: hidden in pill mode
        IconImage {
            readonly property string src: card.notification ? Notifications.iconOf(card.notification) : ""
            Layout.alignment: Qt.AlignTop
            visible: !card.isPill && src !== ""
            implicitSize: 32
            source: src
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: isPill ? 0 : 2

            RowLayout {
                Layout.fillWidth: true
                // In pill mode: show app · summary on one line
                Text {
                    visible: card.isPill
                    Layout.fillWidth: true
                    text: [card.notification?.appName, card.notification?.summary].filter(Boolean).join("  ·  ")
                    color: Theme.text
                    elide: Text.ElideRight
                    font { family: Theme.font; pixelSize: Theme.fontLabel; weight: Font.Medium }
                }
                // Normal mode: app name
                Text {
                    visible: !card.isPill
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
                visible: !card.isPill && text !== ""
                text: card.notification?.summary ?? ""
                color: Theme.text
                elide: Text.ElideRight
                font { family: Theme.font; pixelSize: Theme.fontSize; weight: Font.DemiBold }
            }
            Text {
                Layout.fillWidth: true
                visible: !card.isPill && text !== ""
                text: card.notification?.body ?? ""
                color: Theme.subtext
                textFormat: Text.StyledText
                wrapMode: Text.Wrap
                maximumLineCount: card.banner ? 3 : 5
                elide: Text.ElideRight
                font { family: Theme.font; pixelSize: Theme.fontLabel }
            }
            RowLayout {
                visible: !card.isPill && card.buttons.length > 0 && card.stacked === 0
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
