import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts

// One notification: app icon, app name and age, title, body and the app's buttons. Used for the
// banners and in the notification centre. Click to open it in the app, × to dismiss.
// Banners take the theme's kind (Themes.qml notify.kind): bubble, card, line, block, tag.
Glass {
    id: card

    property Notification notification
    property bool banner: false
    property int stacked: 0                // more notifications folded behind this one
    readonly property bool hovered: area.containsMouse || closeArea.containsMouse
    readonly property bool critical: notification?.urgency === NotificationUrgency.Critical
    readonly property var buttons: (notification?.actions ?? []).filter(a => a.identifier !== "default" && a.text !== "")
    // banners take the theme's kind (Themes.qml notify.kind); the notification centre keeps cards
    readonly property string kind: banner ? Theme.current.notify.kind : "card"
    readonly property bool isMinimal: kind === "line"
    signal expandRequested()

    implicitHeight: content.implicitHeight + Theme.spaceM * 2
    strong: !isMinimal
    radius: flat ? Theme.radius : kind === "bubble" ? Math.min(height / 2, Theme.radiusLarge + 6) : Theme.radiusLarge
    color: flat ? Theme.fill : Theme.glassStrong
    border.color: critical ? Theme.warning : kind === "block" || kind === "tag" ? Theme.accent : (isMinimal ? "transparent" : Theme.stroke)
    border.width: kind === "block" ? 3 : kind === "tag" ? 1 : isMinimal && !critical ? 0 : (critical || !flat ? Math.max(1, Theme.line) : 0)

    Rectangle {   // line: an accent hairline down the left edge, the rest plain text on the surface
        visible: card.kind === "line"
        width: 1; height: parent.height
        color: Theme.accent
    }

    // folded cards peek out underneath (card style only)
    Repeater {
        model: !isMinimal ? Math.min(card.stacked, 2) : 0
        Rectangle {
            required property int index
            z: -1 - index
            x: (index + 1) * 8; width: card.width - x * 2
            // below the card, never under it: a see-through (glass) card would show it through as grey bars
            y: card.height - 1; height: (index + 1) * 6
            radius: Math.min(card.radius, 6)
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
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.spaceM }
        spacing: Theme.spaceS

        IconImage {
            readonly property string src: card.notification ? Notifications.iconOf(card.notification) : ""
            Layout.alignment: Qt.AlignTop
            visible: src !== ""
            implicitSize: Theme.iconLarge
            source: src
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            RowLayout {
                Layout.fillWidth: true
                Layout.rightMargin: closeButton.visible ? closeButton.width : 0   // the × sits over this row
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
                visible: text !== ""
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
        id: closeButton
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
