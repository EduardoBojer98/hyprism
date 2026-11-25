pragma Singleton
import Quickshell
import QtQuick
import QtQuick.Layouts

// Notifications: their own panel, opened from the bell in the bar, Super+N or
// `qs ipc call notifications toggle` (the Control Center holds the controls only). A header with the
// count, Do Not Disturb and Clear all; then the history grouped by app, a group folded into its
// newest card until you open it, ones that arrived since you last looked marked; an empty state when there is
// nothing; then Earlier, the dismissed ones (folded while there are new ones), with Clear history. Styled and moving like every
// other panel of the active theme.
Singleton {
    id: root

    readonly property bool open: popup.open
    property var unfolded: ({})            // app name -> true
    property bool showEarlier: false

    function toggle() { popup.toggle() }
    // keyboard: Up / Down walk the cards (Tab reaches the buttons too), Enter opens one, Delete dismisses it
    function step(from, forward) {
        for (let i = from.nextItemInFocusChain(forward), n = 0; i && i !== from && n < 500; i = i.nextItemInFocusChain(forward), n++)
            if (i.notificationCard) { i.forceActiveFocus(); return true }
        return false
    }
    function fold(app, on) { const u = Object.assign({}, unfolded); if (on) delete u[app]; else u[app] = true; unfolded = u }

    CursorPopup {
        id: popup
        name: "notifications"
        placement: "topRight"
        boxWidth: Notifications.cardWidth + Theme.spaceM * 2
        boxHeight: column.implicitHeight + Theme.spaceM * 2
        focusItem: column
        onOpened: { Notifications.seenBefore = Notifications.seenAt; Notifications.seenAt = Date.now()
                    root.showEarlier = Notifications.history.length === 0; Notifications.now = new Date(); root.unfolded = ({}) }
        onClosed: Notifications.seenAt = Date.now()   // what arrived while it was open was seen

        Glass {
            anchors.fill: parent
            strong: true
            radius: Theme.radiusLarge

            ColumnLayout {
                id: column
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.spaceM }
                spacing: 8
                readonly property Item focused: Window.activeFocusItem
                Keys.onDownPressed: root.step(focused ?? column, true)
                Keys.onUpPressed: root.step(focused ?? column, false)
                function cards() {
                    const out = []
                    for (let i = column.nextItemInFocusChain(true), n = 0; i && i !== column && n < 500; i = i.nextItemInFocusChain(true), n++)
                        if (i.notificationCard && !out.includes(i)) out.push(i)
                    return out
                }
                Keys.onDeletePressed: {
                    const card = focused
                    if (!card?.notificationCard) return
                    // the list is rebuilt after a dismiss: put the keyboard on the card now in the same place
                    const at = cards().indexOf(card)
                    column.forceActiveFocus()
                    card.notification?.dismiss()
                    Qt.callLater(() => { const c = column.cards(); if (c.length) c[Math.min(at, c.length - 1)].forceActiveFocus() })
                }

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
                    Chip {   // in the header, where you look for it, not under a long list
                        visible: Notifications.history.length > 0
                        icon: "\u{F0A79}"
                        label: "Clear all"
                        onClicked: Notifications.clearAll()
                    }
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
                        font { family: Theme.iconFont; pixelSize: Theme.iconLarge }
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Notifications.dnd ? "Do Not Disturb is on" : "You're all caught up"
                        color: Theme.subtext
                        font { family: Theme.font; pixelSize: Theme.fontLabel; weight: Font.Medium }
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Notifications.dnd ? "Only critical notifications show; they still land here" : "New notifications show up here"
                        color: Theme.muted
                        font { family: Theme.font; pixelSize: Theme.fontCaption }
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
                        // room for the folded stack (lines say "+n more" instead); lines sit close, like a log
                        Layout.bottomMargin: unfolded || Notifications.kind === "line" ? 0 : 12
                        spacing: Notifications.kind === "line" ? 0 : 6

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


                // ---- Earlier: the dismissed ones, as plain records; a click opens the app ----
                RowLayout {
                    visible: Notifications.earlier.length > 0
                    Layout.fillWidth: true
                    Layout.leftMargin: 4
                    Layout.topMargin: 4
                    Text {
                        Layout.fillWidth: true
                        text: "Earlier · " + Notifications.earlier.length
                        color: Theme.subtext
                        elide: Text.ElideRight
                        font { family: Theme.font; pixelSize: Theme.fontCaption; weight: Font.DemiBold }
                    }
                    Chip { label: root.showEarlier ? "Hide" : "Show"; onClicked: root.showEarlier = !root.showEarlier }
                    Chip { label: "Clear history"; onClicked: Notifications.clearEarlier() }
                }
                Repeater {
                    // shortcut: the newest 20 only, each card costs a little; raise it if more are wanted
                    model: root.showEarlier ? Notifications.earlier.slice(0, 20) : []
                    NotificationCard {
                        required property var modelData
                        Layout.fillWidth: true
                        flat: true
                        notification: modelData
                    }
                }
            }
        }
    }
}
