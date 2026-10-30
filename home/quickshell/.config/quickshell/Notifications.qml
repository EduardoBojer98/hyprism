import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import Quickshell.Services.Notifications
import QtQuick

// Notification server (replaces mako) with pop-up cards in the top-right corner
// of the focused screen. Click a card to dismiss it.
Scope {
    NotificationServer {
        id: server
        actionsSupported: true
        bodyMarkupSupported: true
        imageSupported: true
        onNotification: n => n.tracked = true
    }

    PanelWindow {
        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null
        anchors { top: true; right: true }
        margins { top: 8; right: 10 }
        implicitWidth: 360
        implicitHeight: Math.max(1, list.contentHeight)
        exclusiveZone: 0
        color: "transparent"
        visible: server.trackedNotifications.values.length > 0
        WlrLayershell.namespace: "qs-notifications"
        WlrLayershell.layer: WlrLayer.Overlay

        ListView {
            id: list
            anchors.fill: parent
            spacing: 8
            interactive: false
            model: server.trackedNotifications

            add: Transition { NumberAnimation { property: "x"; from: 380; duration: 260; easing.type: Easing.OutCubic } }
            remove: Transition { NumberAnimation { property: "opacity"; to: 0; duration: 180 } }
            displaced: Transition { NumberAnimation { property: "y"; duration: 200; easing.type: Easing.OutCubic } }

            delegate: Glass {
                id: card
                required property Notification modelData
                readonly property bool critical: modelData?.urgency === NotificationUrgency.Critical

                width: list.width
                height: content.implicitHeight + 24
                strong: true
                radius: Theme.radius
                border { color: critical ? Theme.peach : Theme.stroke; width: 1 }

                Timer {
                    running: !card.critical
                    interval: card.modelData?.expireTimeout > 0 ? card.modelData?.expireTimeout * 1000 : 5000
                    onTriggered: card.modelData?.expire()
                }

                Row {
                    id: content
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                    spacing: 12

                    IconImage {
                        readonly property string src: (card.modelData?.image || card.modelData?.appIcon) ?? ""
                        visible: src !== ""
                        implicitSize: 36
                        source: src.startsWith("/") || src.includes("://") ? src : Quickshell.iconPath(src, true)
                    }

                    Column {
                        width: parent.width - 48
                        spacing: 2

                        Text {
                            width: parent.width
                            text: card.modelData?.summary ?? ""
                            color: Theme.text
                            elide: Text.ElideRight
                            font { family: Theme.font; pixelSize: Theme.fontSize; weight: Font.DemiBold }
                        }
                        Text {
                            width: parent.width
                            visible: text !== ""
                            text: card.modelData?.body ?? ""
                            color: Theme.subtext
                            textFormat: Text.StyledText
                            wrapMode: Text.Wrap
                            maximumLineCount: 4
                            elide: Text.ElideRight
                            font { family: Theme.font; pixelSize: 12 }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    // Default action if the app offers one, otherwise just dismiss
                    onClicked: {
                        const action = card.modelData?.actions.find(a => a.identifier === "default")
                        if (action) action.invoke()
                        else card.modelData?.dismiss()
                    }
                }
            }
        }
    }
}
