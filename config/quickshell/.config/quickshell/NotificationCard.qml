import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts

// One notification: app icon, app name and age, title, body and the app's buttons. Used for the
// banners and in the notification centre. Click to open it in the app, × to dismiss.
// It takes a kind (Notifications.kind: Settings, or the theme's notify.kind), banners and the centre alike:
//   card     a soft card: the icon in a soft circle, a folded group peeks out as two card edges (Lumen)
//   bubble   round, a lifted tone and no edge
//   line     a log line in mono: `23:19 [app] title — body`, actions as `[open] [dismiss]`; types in (Monolith)
//   block    a thick accent bar on the left, the title in the display font, a hard shadow; red when urgent (Poster)
//   tag      a card with the app's name as an accent tag
//   compact  one row: a small icon, the title and one line of body
//   pill     the compact row in a fully round capsule, a lifted tone and no edge
//   minimal  the title and text only: no icon, app row or edge
// Padding, icon and type sizes and how many lines of text show come from Notifications (Settings > Density, Text size).
// Settings draws each kind with a sample (kindOverride) to choose from. How a banner arrives is Notifications.qml's.
Glass {
    id: card

    property var notification              // a live Notification, or a saved record (Notifications.qml)
    property bool banner: false
    property int stacked: 0                // more notifications folded behind this one
    readonly property bool hovered: area.containsMouse || closeArea.containsMouse || replying   // a banner waits while you type
    property bool replying: false
    // in the centre: arrived since you last looked (timed out unseen, or held by Do Not Disturb)
    readonly property bool missed: !banner && !kindOverride && !!notification && Notifications.missed(notification)
    // the app takes a typed reply (a chat app): a field under the text, Enter sends it
    readonly property bool canReply: !!notification?.hasInlineReply && (banner || stacked === 0)
    readonly property bool critical: notification?.urgency === NotificationUrgency.Critical
    readonly property var buttons: (notification?.actions ?? []).filter(a => a.identifier !== "default" && a.text !== "")
    property string kindOverride: ""       // Settings' style picker draws every kind
    readonly property string kind: kindOverride || Notifications.kind
    readonly property bool isLine: kind === "line"
    readonly property bool isBlock: kind === "block"
    readonly property bool isPill: kind === "pill"
    readonly property bool isMinimal: kind === "minimal"
    readonly property bool isCompact: kind === "compact" || isPill   // one row
    readonly property int pad: isCompact || isLine ? Math.max(Theme.spaceS, Notifications.pad - Theme.spaceXs) : Notifications.pad
    readonly property bool showButtons: Config.notifications.showActions && (banner || stacked === 0)
    // block: an urgent one is a red card, its text in the colour that reads on red
    readonly property bool red: isBlock && critical
    readonly property color ink: red ? Theme.errorText : Theme.text
    readonly property color inkSoft: red ? Theme.errorText : Theme.subtext
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

    implicitHeight: (isLine ? log : content).implicitHeight + pad * 2
    strong: !isLine
    radius: isPill && Theme.radius > 0 ? height / 2 : flat ? Theme.radius : kind === "bubble" ? Math.min(height / 2, 26) : Theme.radiusLarge
    color: red ? Theme.error
         : isBlock ? (flat ? Theme.raised : Qt.alpha(Theme.glassStrong, 1))   // opaque: the hard shadow must not show through
         : isLine && flat ? (area.containsMouse ? Theme.fillHover : "transparent")   // the centre: plain lines on the panel
         : flat ? Theme.fill : kind === "bubble" || isPill ? Theme.raised : Theme.glassStrong   // bubble, pill: a lifted tone instead of an edge
    border.color: red ? Theme.stroke : isLine ? "transparent" : critical ? Theme.warning : Theme.stroke   // line: urgent is its red tag and hairline
    border.width: isBlock ? Math.max(1, Theme.line) : (isLine || isMinimal || isPill || kind === "bubble") && !critical ? 0 : (critical || !flat ? Math.max(1, Theme.line) : 0)

    Rectangle {   // block: the hard shadow, an offset block in the second accent like Poster's panels (PopupDepth)
        visible: card.isBlock
        z: -2
        x: Theme.shadowOffset; y: Theme.shadowOffset
        width: card.width; height: card.height
        color: Theme.accent2
    }
    Rectangle {   // block: the thick accent bar; line: an urgent line gets a hairline in the error colour
        id: bar
        visible: card.isBlock || card.isLine && card.critical
        width: card.isBlock ? Theme.spaceS : 2
        height: parent.height
        color: card.red ? Theme.errorText : card.isBlock ? Theme.accent : Theme.error
    }

    // a folded group peeks out underneath as up to two card edges (not lines: they say "+n more")
    Repeater {
        model: !isLine ? Math.min(card.stacked, 2) : 0
        Rectangle {
            required property int index
            z: -1 - index
            x: (index + 1) * 8; width: card.width - x * 2
            // below the card, never under it: a see-through (glass) card would show it through as grey bars
            y: card.height - 1; height: (index + 1) * 6
            radius: Math.min(card.radius, 6)
            // a solid raised tone with an edge: a faint fill or glass reads as nothing on a dark panel
            color: Theme.raised
            border { color: Theme.stroke; width: 1 }
            opacity: 1 - index * 0.3
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
        visible: !card.isLine
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: card.pad; leftMargin: card.pad + (card.isBlock ? bar.width : 0) }
        spacing: Theme.spaceS

        Rectangle {   // the app icon; card: in a soft circle
            id: icon
            readonly property string src: card.notification ? Notifications.iconOf(card.notification) : ""
            readonly property bool soft: card.kind === "card"
            Layout.alignment: card.isCompact ? Qt.AlignVCenter : Qt.AlignTop
            visible: src !== "" && Config.notifications.showIcons && !card.isMinimal
            implicitWidth: soft ? Notifications.iconSize + Theme.spaceS : image.implicitSize
            implicitHeight: implicitWidth
            radius: width / 2
            color: soft ? Theme.accentWash : "transparent"
            IconImage {
                id: image
                anchors.centerIn: parent
                implicitSize: card.isCompact || icon.soft ? Notifications.iconSmall : Notifications.iconSize
                source: icon.src
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: card.isCompact ? 0 : 2

            RowLayout {
                visible: !card.isCompact && !card.isMinimal
                Layout.fillWidth: true
                Layout.rightMargin: closeButton.visible ? closeButton.width : 0   // the × sits over this row
                Rectangle {   // missed: an accent dot before the app's name
                    visible: card.missed
                    implicitWidth: 8; implicitHeight: 8; radius: 4
                    color: card.red ? Theme.errorText : Theme.accent
                    Accessible.role: Accessible.StaticText
                    Accessible.name: "New"
                }
                Rectangle {   // tag: the app's name on an accent tag
                    visible: card.kind === "tag" && appName.text !== ""
                    implicitWidth: appTag.implicitWidth + 12; implicitHeight: appTag.implicitHeight + 4
                    Layout.maximumWidth: 220
                    radius: Theme.radius === 0 ? 0 : height / 2
                    color: Theme.accent
                    Text { id: appTag; anchors.centerIn: parent; width: Math.min(implicitWidth, parent.width - 12); text: appName.text; elide: Text.ElideRight; color: Theme.accentText
                           font { family: Theme.font; pixelSize: Notifications.fontMeta; weight: Font.DemiBold } }
                }
                Text {
                    id: appName
                    visible: card.kind !== "tag"
                    Layout.fillWidth: true
                    text: card.isBlock ? (card.notification?.appName ?? "").toUpperCase() : card.notification?.appName ?? ""
                    color: card.inkSoft
                    elide: Text.ElideRight
                    font { family: Theme.font; pixelSize: Notifications.fontMeta; weight: card.isBlock ? Font.Bold : Font.DemiBold; letterSpacing: card.isBlock ? 1 : 0 }
                }
                Item { visible: card.kind === "tag"; Layout.fillWidth: true }
                Text {
                    visible: !card.hovered || card.stacked > 0
                    text: card.stacked > 0 ? `${card.stacked} more` : card.notification ? Notifications.ago(card.notification) : ""
                    color: card.red ? Theme.errorText : Theme.muted
                    font { family: Theme.font; pixelSize: Notifications.fontMeta }
                }
            }
            Text {
                Layout.fillWidth: true
                Layout.rightMargin: (card.isCompact || card.isMinimal) && closeButton.visible ? closeButton.width : 0
                visible: text !== ""
                text: card.notification?.summary ?? ""
                color: card.ink
                elide: Text.ElideRight
                // block: the title in the display font (Poster's heavy type)
                font { family: card.isBlock ? Theme.displayFont : Theme.font; pixelSize: card.isBlock ? Notifications.fontDisplay : Notifications.fontHead
                       weight: card.isBlock ? Theme.displayWeight : Font.DemiBold }
            }
            Text {
                Layout.fillWidth: true
                visible: text !== ""
                text: card.notification?.body ?? ""
                color: card.inkSoft
                textFormat: Text.StyledText
                wrapMode: Text.Wrap
                maximumLineCount: card.isCompact ? 1 : Notifications.lines + (card.banner ? 0 : 1)
                elide: Text.ElideRight
                font { family: Theme.font; pixelSize: Notifications.fontBody }
            }
            RowLayout {
                visible: card.buttons.length > 0 && card.showButtons
                Layout.topMargin: Theme.spaceXs
                spacing: Theme.spaceXs
                Repeater {
                    model: card.buttons.slice(0, 3)
                    PillButton { required property var modelData; text: modelData.text; onClicked: modelData.invoke() }
                }
            }
            TextField {   // the reply
                visible: card.canReply
                Layout.topMargin: Theme.spaceXs
                placeholder: card.notification?.inlineReplyPlaceholder || "Write a reply"
                onTextChanged: card.replying = text !== ""
                onAccepted: if (text.trim() !== "") { card.notification.sendInlineReply(text); text = "" }
                Layout.fillWidth: true
            }
        }
    }

    // ---- line: one log line, `HH:mm [app] title — body`, then its actions in brackets ----
    readonly property var logParts: {
        const n = card.notification
        if (!n) return []
        const body = String(n.body ?? "").replace(/<[^>]*>/g, "").replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&quot;/g, "\"").replace(/&amp;/g, "&")
        return [[card.missed ? "• " : "", Theme.accent, true],
                [Qt.formatTime(new Date(Notifications.timeOf(n)), "HH:mm") + " ", Theme.muted, false],
                ["[" + (card.critical ? "!! " : "") + (n.appName || "other").toLowerCase() + "] ", card.critical ? Theme.error : Theme.accent, false],
                [n.summary ?? "", Theme.text, true],
                [body ? " — " + body : "", Theme.subtext, false]]
    }
    readonly property int logLength: logParts.reduce((s, p) => s + p[0].length, 0)
    property int typed: -1                 // characters typed so far while a new line types in; -1 = all
    function logText(upTo) {
        const esc = s => s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
        let out = "", left = upTo
        for (const [t, c, bold] of logParts) {
            const s = t.slice(0, Math.max(0, left)); left -= t.length
            if (s) out += (bold ? "<b>" : "") + `<font color="${c}">${esc(s)}</font>` + (bold ? "</b>" : "")
        }
        return upTo < logLength ? out + `<font color="${Theme.accent}">█</font>` : out   // the block caret while typing
    }
    // a new banner types in, a few ms a character (full motion only: reduced motion shows the whole line)
    NumberAnimation { id: typeIn; target: card; property: "typed"; from: 0; to: card.logLength
                      duration: Math.min(card.logLength * Theme.stagger, Theme.pulse); onStopped: card.typed = -1 }
    Component.onCompleted: if (isLine && banner && Theme.moves) typeIn.start()

    component LogAction: Text {   // `[word]`: a text button
        id: act
        property string word
        signal clicked()
        text: "[" + word + "]"
        color: actArea.containsMouse || activeFocus ? Theme.accent : Theme.subtext
        font { family: Theme.monoFont; pixelSize: Notifications.fontMeta; underline: actArea.containsMouse }
        activeFocusOnTab: !card.banner
        Keys.onReturnPressed: clicked()
        Keys.onSpacePressed: clicked()
        Accessible.role: Accessible.Button
        Accessible.name: word
        Accessible.onPressAction: clicked()
        MouseArea { id: actArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: act.clicked() }
    }

    ColumnLayout {
        id: log
        visible: card.isLine
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: card.pad; leftMargin: card.pad + (bar.visible ? bar.width : 0) }
        spacing: 2
        Text {
            Layout.fillWidth: true
            text: card.logText(card.typed < 0 ? card.logLength : card.typed)
            textFormat: Text.StyledText
            wrapMode: Text.Wrap
            maximumLineCount: Notifications.lines + (card.banner ? 0 : 1)
            elide: Text.ElideRight
            font { family: Theme.monoFont; pixelSize: Notifications.fontBody }
        }
        Flow {
            Layout.fillWidth: true
            spacing: Theme.spaceS
            visible: card.typed < 0
            LogAction {
                visible: (card.notification?.actions ?? []).some(a => a.identifier === "default") && (card.banner || card.stacked === 0)
                word: "open"; onClicked: card.open()
            }
            Repeater {
                model: card.showButtons ? card.buttons.slice(0, 3) : []
                LogAction { required property var modelData; word: modelData.text.toLowerCase(); onClicked: modelData.invoke() }
            }
            LogAction { visible: card.stacked > 0; word: "+" + card.stacked + " more"; onClicked: card.banner ? card.open() : card.expandRequested() }
            LogAction { visible: card.banner || card.stacked === 0; word: "dismiss"; onClicked: card.notification?.dismiss() }
        }
        TextField {   // the reply
            visible: card.canReply
            Layout.topMargin: Theme.spaceXs
            placeholder: card.notification?.inlineReplyPlaceholder || "Write a reply"
            onTextChanged: card.replying = text !== ""
            onAccepted: if (text.trim() !== "") { card.notification.sendInlineReply(text); text = "" }
            Layout.fillWidth: true
        }
    }

    // dismiss, shown on hover (line: `[dismiss]` is always there instead)
    Rectangle {
        id: closeButton
        anchors { top: parent.top; right: parent.right; rightMargin: Theme.spaceXs + 2
                  topMargin: card.isCompact ? Math.round((card.height - height) / 2) : Theme.spaceXs + 2 }
        width: Theme.glyphL + 2; height: width; radius: width / 2
        visible: !card.isLine && (card.hovered || card.activeFocus) && (card.banner || card.stacked === 0)
        color: closeArea.containsMouse ? Theme.fillActive : Theme.fillHover
        Text { anchors.centerIn: parent; text: "\u{F0156}"; color: card.ink; font { family: Theme.iconFont; pixelSize: Theme.glyphXs } }
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
