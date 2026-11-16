import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// The installed icon or cursor themes as cards with a few pictures from each (~/.local/bin/theme-preview),
// for Settings > Icons and Cursor. Click one to use it. Themes you added (~/.local/share/icons, ~/.icons)
// can go to the Trash; system themes belong to their package. Cards appear as the script finds them.
ColumnLayout {
    id: root
    property string kind              // "icons" or "cursors"
    property string key               // its Config.appearance key: "iconTheme" or "cursorTheme"
    property string own               // the one the active desktop theme brings (its theme.json icons / cursor)
    property var list: []             // [{ name, user, dir, pics }]
    readonly property var themes: list.map(t => t.name)
    property var pending: null        // the theme waiting for "Move to Trash"
    property string status: ""
    property var incoming: []
    readonly property string chosen: Config.appearance[key]

    function reload() { lister.running = false; lister.running = true }

    Layout.fillWidth: true
    spacing: 0

    Process {
        id: lister
        running: true
        command: ["theme-preview", root.kind]
        onStarted: root.incoming = []
        stdout: SplitParser {
            onRead: line => {
                const f = line.split("\t")
                if (f.length < 3) return
                root.incoming.push({ name: f[0], user: f[1] === "user", dir: f[2], pics: f.slice(3) })
                if (!lister.loaded) root.list = root.incoming.slice()   // the first time, show each as it comes; later, swap at the end
            }
        }
        property bool loaded: false
        onExited: { root.list = root.incoming; loaded = true }
    }
    Process {
        id: remover
        property var target: ({})
        stderr: StdioCollector { id: rmErr }
        onExited: code => {
            if (code === 0) {
                if (root.chosen === target.name) Config.set("appearance", root.key, "theme")
                root.status = target.name + " is in the Trash"
            } else root.status = "Couldn't move " + target.name + " to the Trash: " + (rmErr.text.trim() || "gio trash failed")
            root.pending = null
            root.reload()
        }
    }

    GridLayout {
        Layout.fillWidth: true
        Layout.margins: 12
        columns: Math.max(2, Math.floor((width + columnSpacing) / (180 + columnSpacing)))
        columnSpacing: 10
        rowSpacing: 10
        // outside the Repeater, so a change of the theme's own doesn't rebuild every card (and reset the scroll)
        Card { modelData: ({ name: "theme", own: true, user: false, pics: (root.list.find(t => t.name === root.own) ?? { pics: [] }).pics }) }
        Repeater {
            model: root.list
            Card {}
        }
    }
    Text {
        visible: root.list.length === 0
        Layout.fillWidth: true
        Layout.margins: 16
        Layout.topMargin: 0
        text: lister.running ? "Looking for themes…" : "No " + (root.kind === "icons" ? "icon" : "cursor") + " themes found"
        color: Theme.subtext
        font { family: Theme.font; pixelSize: Theme.fontCaption }
    }
    SettingRow {
        visible: root.pending !== null
        label: "Move " + (root.pending?.name ?? "") + " to the Trash?"
        hint: (root.pending?.dir ?? "").replace(Quickshell.env("HOME"), "~") + (root.chosen === root.pending?.name ? ". It's in use, so you go back to the theme's own." : ". You can restore it from the Trash.")
        PillButton { text: "Move to Trash"; primary: true; enabled: !remover.running; onClicked: { remover.target = root.pending; remover.command = ["gio", "trash", "--", root.pending.dir]; remover.running = true } }
        PillButton { text: "Cancel"; onClicked: root.pending = null }
    }
    Text {
        Layout.fillWidth: true
        Layout.margins: 16
        Layout.topMargin: 0
        text: root.status !== "" ? root.status
            : "Themes you added can go to the Trash (the button on their card). System themes, in /usr/share/icons, come with a package; remove them with your package manager."
        color: Theme.subtext
        wrapMode: Text.Wrap
        font { family: Theme.font; pixelSize: Theme.fontCaption }
    }

    component Card: Rectangle {
        id: card
        required property var modelData
        readonly property bool chosen: root.chosen === modelData.name
        readonly property var pics: modelData.pics.filter(p => p !== "")
        readonly property real cell: Math.min(root.kind === "icons" ? 30 : 32, (pictures.width - 5 * 6) / 6)

        Layout.fillWidth: true
        implicitHeight: col.implicitHeight + 24
        radius: Theme.radiusSmall
        color: area.containsMouse ? Theme.fillHover : "transparent"
        border { color: card.chosen ? Theme.accent : area.containsMouse ? Theme.strokeStrong : Theme.stroke; width: card.chosen ? 2 : 1 }
        Accessible.role: Accessible.RadioButton
        Accessible.name: card.modelData.own ? "Theme's own" : card.modelData.name
        Accessible.checkable: true
        Accessible.checked: card.chosen
        Accessible.onPressAction: Config.set("appearance", root.key, card.modelData.name)

        MouseArea { id: area; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Config.set("appearance", root.key, card.modelData.name) }

        Column {
            id: col
            x: 12; y: 12
            width: parent.width - 24
            spacing: 8
            Row {
                id: pictures
                width: parent.width
                height: card.cell
                spacing: 6
                Repeater {
                    model: card.pics
                    Image {
                        required property string modelData
                        width: card.cell; height: card.cell
                        source: "file://" + modelData
                        sourceSize { width: card.cell * 2; height: card.cell * 2 }
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        smooth: true
                    }
                }
            }
            Row {
                width: parent.width - (trash.visible ? trash.width + 4 : 0)
                spacing: 6
                Rectangle {   // the one in use
                    visible: card.chosen
                    anchors.verticalCenter: parent.verticalCenter
                    width: 16; height: 16; radius: Theme.radius === 0 ? 0 : 8
                    color: Theme.accent
                    Text { anchors.centerIn: parent; text: "\u{F012C}"; color: Theme.accentText; font { family: Theme.iconFont; pixelSize: Theme.iconSmall - 4 } }
                }
                Text {
                    width: parent.width - (card.chosen ? 22 : 0)
                    text: card.modelData.own ? "Theme's own" : card.modelData.name
                    color: card.chosen ? Theme.accent : Theme.text
                    elide: Text.ElideRight
                    font { family: Theme.font; pixelSize: Theme.fontLabel; weight: card.chosen ? Font.DemiBold : Font.Medium }
                }
            }
            Text {
                width: parent.width - (trash.visible ? trash.width + 4 : 0)
                text: card.modelData.own ? (lister.loaded && !root.themes.includes(root.own) ? root.own + " isn't installed" : Theme.current.name + " uses " + root.own)
                    : card.modelData.name === "default" ? "Your system's cursor"
                    : card.modelData.user ? "Added by you" : "System"
                color: Theme.subtext
                elide: Text.ElideRight
                font { family: Theme.font; pixelSize: Theme.fontCaption }
            }
        }

        Rectangle {   // move a theme you added to the Trash (asks first, below the cards)
            id: trash
            visible: card.modelData.user && (area.containsMouse || trashArea.containsMouse || root.pending?.name === card.modelData.name || activeFocus)
            anchors { right: parent.right; bottom: parent.bottom; margins: 8 }
            width: 28; height: 28
            radius: Theme.radius === 0 ? 0 : 14
            color: trashArea.containsMouse ? Theme.fillActive : "transparent"
            activeFocusOnTab: card.modelData.user
            Accessible.role: Accessible.Button
            Accessible.name: "Move " + card.modelData.name + " to the Trash"
            Accessible.onPressAction: root.pending = card.modelData
            Keys.onSpacePressed: root.pending = card.modelData
            Keys.onReturnPressed: root.pending = card.modelData
            FocusRing {}
            Text { anchors.centerIn: parent; text: "\u{F0A7A}"; color: trashArea.containsMouse ? Theme.error : Theme.subtext; font { family: Theme.iconFont; pixelSize: Theme.iconSmall } }
            MouseArea { id: trashArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { root.status = ""; root.pending = card.modelData } }
            ToolTipText { shown: trashArea.containsMouse; text: "Move to Trash" }
        }
    }
}
