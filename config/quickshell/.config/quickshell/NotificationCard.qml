import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts

// One notification: app icon, app name and age, title, body and the app's buttons. Used for the
// banners and in the notification centre. Click to open it in the app, × to dismiss.
// Banners take a kind (Notifications.kind: Settings, or the theme's notify.kind):
//   card     a panel card: icon, app and age, title, body
//   bubble   round, a lifted tone and no edge
//   line     no frame, an accent hairline down the left
//   block    a thick accent frame (Poster)
//   tag      a card with the app's name as an accent tag
//   compact  one row: a small icon, the title and one line of body
// Settings draws each kind with a sample (kindOverride) to choose from.
Glass {
    id: card

    property var notification              // a live Notification, or a saved record (Notifications.qml)
    property bool banner: false
    property int stacked: 0                // more notifications folded behind this one
    readonly property bool hovered: area.containsMouse || closeArea.containsMouse
    readonly property bool critical: notification?.urgency === NotificationUrgency.Critical
    readonly property var buttons: (notification?.actions ?? []).filter(a => a.identifier !== "default" && a.text !== "")
    // banners take the theme's kind (Themes.qml notify.kind); the notification centre keeps cards
    property string kindOverride: ""       // Settings' style picker draws every kind
    readonly property string kind: kindOverride || (banner ? Notifications.kind : "card")
    readonly property bool isMinimal: kind === "line"
    readonly property bool isCompact: kind === "compact"
    readonly property int pad: isCompact ? Theme.spaceS + 2 : Theme.spaceM
    signal expandRequested()
    Accessible.role: Accessible.Alert
    Accessible.name: [card.notification?.appName, card.notification?.summary].filter(s => s).join(": ")
    Accessible.description: card.notification?.body ?? ""
    Accessible.onPressAction: open()
    Accessible.focusable: !banner
    readonly property bool notificationCard: true   // NotificationCenter walks the cards by this

    // keyboard (in the notification centre): Tab or the arrows to a card, Enter opens it, Delete dismisses it
    activeFocusOnTab: !banner
    // in the notification centre a folded group opens; a banner opens its newest
    function open() { if (card.stacked > 0 && !card.banner) card.expandRequested(); else if (card.notification) Notifications.activate(card.notification) }
    Keys.onReturnPressed: open()
    Keys.onEnterPressed: open()
    Keys.onSpacePressed: open()
    FocusRing {}

    implicitHeight: content.implicitHeight + pad * 2
    strong: !isMinimal
    radius: flat ? Theme.radius : kind === "bubble" ? Math.min(height / 2, 26) : Theme.radiusLarge
    color: flat ? Theme.fill : kind === "bubble" ? Theme.raised : Theme.glassStrong   // bubble: a lifted tone instead of an edge
    border.color: critical ? Theme.warning : kind === "block" ? Theme.accent : (isMinimal ? "transparent" : Theme.stroke)
    border.width: kind === "block" ? 3 : (isMinimal || kind === "bubble") && !critical ? 0 : (critical || !flat ? Math.max(1, Theme.line) : 0)

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
        onClicked: card.open()
    }

    RowLayout {
        id: content
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: card.pad }
        spacing: Theme.spaceS

        IconImage {
            readonly property string src: card.notification ? Notifications.iconOf(card.notification) : ""
            Layout.alignment: card.isCompact ? Qt.AlignVCenter : Qt.AlignTop
            visible: src !== "" && Config.notifications.showIcons
            implicitSize: card.isCompact ? Theme.iconMedium : Theme.iconLarge
            source: src
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            RowLayout {
                visible: !card.isCompact
                Layout.fillWidth: true
                Layout.rightMargin: closeButton.visible ? closeButton.width : 0   // the × sits over this row
                Rectangle {   // tag: the app's name on an accent tag
                    visible: card.kind === "tag" && appName.text !== ""
                    implicitWidth: appTag.implicitWidth + 12; implicitHeight: appTag.implicitHeight + 4
                    Layout.maximumWidth: 220
                    radius: Theme.radius === 0 ? 0 : height / 2
                    color: Theme.accent
                    Text { id: appTag; anchors.centerIn: parent; width: Math.min(implicitWidth, parent.width - 12); text: appName.text; elide: Text.ElideRight; color: Theme.accentText
                           font { family: Theme.font; pixelSize: Theme.fontCaption; weight: Font.DemiBold } }
                }
                Text {
                    id: appName
                    visible: card.kind !== "tag"
                    Layout.fillWidth: true
                    text: card.notification?.appName ?? ""
                    color: Theme.subtext
                    elide: Text.ElideRight
                    font { family: Theme.font; pixelSize: Theme.fontCaption; weight: Font.DemiBold }
                }
                Item { visible: card.kind === "tag"; Layout.fillWidth: true }
                Text {
                    visible: !card.hovered || card.stacked > 0
                    text: card.stacked > 0 ? `${card.stacked} more` : card.notification ? Notifications.ago(card.notification) : ""
                    color: Theme.muted
                    font { family: Theme.font; pixelSize: Theme.fontCaption }
                }
            }
            Text {
                Layout.fillWidth: true
                Layout.rightMargin: card.isCompact && closeButton.visible ? closeButton.width : 0
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
                maximumLineCount: card.isCompact ? 1 : card.banner ? 3 : 5
                elide: Text.ElideRight
                font { family: Theme.font; pixelSize: Theme.fontLabel }
            }
            RowLayout {
                visible: card.buttons.length > 0 && (card.banner || card.stacked === 0)
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
        visible: (card.hovered || card.activeFocus) && (card.banner || card.stacked === 0)
        color: closeArea.containsMouse ? Theme.fillActive : Theme.fillHover
        Text { anchors.centerIn: parent; text: "\u{F0156}"; color: Theme.text; font { family: Theme.iconFont; pixelSize: Theme.glyphXs } }
        MouseArea {
            id: closeArea
            Accessible.role: Accessible.Button
            Accessible.name: "Dismiss"
            Accessible.onPressAction: card.notification?.dismiss()
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: card.notification?.dismiss()
        }
    }
}
