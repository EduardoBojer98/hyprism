pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick

// Clipboard history (Super+V), Windows 11 style, opened at the cursor. History is kept by
// ~/.local/bin/clipstore (wl-paste --watch, one call per copy, no polling). Choosing an entry puts
// it back on the clipboard with its original MIME type and presses Ctrl+V in the app you were
// in (Ctrl+Shift+V in terminals); without wtype it just stays on the clipboard.
// Keys: type to search · ↑↓ move · Enter paste · Space preview · Ctrl+P pin · Delete remove · Esc
Singleton {
    id: root

    property var entries: []           // from `clipstore list`
    property string filter: ""
    property bool terminalFocused: false
    property string expandedId: ""

    readonly property var shown: {
        const q = filter.trim().toLowerCase()
        const list = q ? entries.filter(e => e.preview.toLowerCase().includes(q)) : entries
        return list.filter(e => e.pinned).concat(list.filter(e => !e.pinned))   // pins first
    }

    function toggle() { popup.toggle() }
    function reload() { lister.running = true }

    function paste(e) {
        popup.hide()
        Quickshell.execDetached(Config.clipboard.autoPaste
            ? ["clipstore", "paste", e.id, root.terminalFocused ? "1" : "0"]
            : ["clipstore", "copy", e.id])
    }
    // Copy any text and paste it where the user was (launcher snippets)
    function pasteText(text) { Quickshell.execDetached(["clipstore", "text", text, root.terminalFocused ? "1" : "0"]) }
    function run(args) { Quickshell.execDetached(["clipstore"].concat(args)); refresh.restart() }

    IpcHandler {
        target: "clipboard"
        function toggle(): void { root.toggle() }
    }

    Process {
        id: lister
        command: ["clipstore", "list"]
        stdout: StdioCollector { onStreamFinished: { try { root.entries = JSON.parse(text) } catch (e) { root.entries = [] } } }
    }
    Process {
        id: focused
        command: ["hyprctl", "-j", "activewindow"]
        stdout: StdioCollector {
            onStreamFinished: {
                let c = ""
                try { c = JSON.parse(text).class ?? "" } catch (e) {}
                root.terminalFocused = /ghostty|kitty|alacritty|foot|konsole|wezterm|terminal/i.test(c)
            }
        }
    }
    Timer { id: refresh; interval: 150; onTriggered: root.reload() }

    CursorPopup {
        id: popup
        name: "clipboard"
        boxWidth: 400
        boxHeight: 540
        focusItem: search
        onOpened: { root.filter = ""; search.text = ""; list.currentIndex = 0; root.expandedId = ""; root.reload(); focused.running = true }

        Glass {
            anchors.fill: parent
            strong: true
            radius: Theme.radiusLarge

            Column {
                id: header
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.spaceM }
                spacing: Theme.spaceS

                Item {
                    width: parent.width; height: 28
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Clipboard"
                        color: Theme.text
                        font { family: Theme.font; pixelSize: Theme.fontTitle; weight: Font.DemiBold }
                    }
                    Row {
                        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                        spacing: Theme.spaceXs
                        Chip {
                            icon: Config.clipboard.paused ? "\u{F040A}" : "\u{F03E4}"
                            label: Config.clipboard.paused ? "Paused" : ""
                            active: Config.clipboard.paused
                            onClicked: Config.set("clipboard", "paused", !Config.clipboard.paused)
                        }
                        Chip { label: "Clear all"; onClicked: root.run(["clear"]) }
                    }
                }

                Rectangle {
                    width: parent.width; height: 34
                    radius: height / 2
                    color: Theme.fill
                    border { color: search.activeFocus ? Theme.accent : Theme.stroke; width: 1 }
                    Text {
                        id: glyph
                        anchors { left: parent.left; leftMargin: Theme.spaceM; verticalCenter: parent.verticalCenter }
                        text: "\u{F0349}"
                        color: Theme.subtext
                        font { family: Theme.iconFont; pixelSize: Theme.iconSmall }
                    }
                    TextInput {
                        id: search
                        anchors { left: glyph.right; leftMargin: Theme.spaceS; right: parent.right; rightMargin: Theme.spaceM; verticalCenter: parent.verticalCenter }
                        color: Theme.text
                        selectionColor: Theme.accent
                        font { family: Theme.font; pixelSize: Theme.fontSize }
                        onTextChanged: { root.filter = text; list.currentIndex = 0 }
                        Text { visible: !search.text; text: "Search history"; color: Theme.muted; font: search.font }

                        Keys.onUpPressed: list.decrementCurrentIndex()
                        Keys.onDownPressed: list.incrementCurrentIndex()
                        Keys.onReturnPressed: if (root.shown[list.currentIndex]) root.paste(root.shown[list.currentIndex])
                        Keys.onEnterPressed: if (root.shown[list.currentIndex]) root.paste(root.shown[list.currentIndex])
                        Keys.onEscapePressed: popup.hide()
                        Keys.onPressed: event => {
                            const e = root.shown[list.currentIndex]
                            if (!e) return
                            if (event.key === Qt.Key_Delete) { root.run(["delete", e.id]); event.accepted = true }
                            else if (event.key === Qt.Key_P && (event.modifiers & Qt.ControlModifier)) { root.run([e.pinned ? "unpin" : "pin", e.id]); event.accepted = true }
                            else if (event.key === Qt.Key_Space && !search.text) { root.expandedId = root.expandedId === e.id ? "" : e.id; event.accepted = true }
                        }
                    }
                }
            }

            ListView {
                id: list
                anchors { left: parent.left; right: parent.right; top: header.bottom; bottom: parent.bottom; margins: Theme.spaceS; topMargin: Theme.spaceM }
                clip: true
                spacing: Theme.spaceXs
                model: root.shown
                boundsBehavior: Flickable.StopAtBounds
                highlightMoveDuration: Theme.animFast

                Text {
                    anchors.centerIn: parent
                    visible: list.count === 0
                    text: root.filter ? "Nothing matches" : Config.clipboard.paused ? "History is paused" : "Copy something and it shows up here"
                    color: Theme.subtext
                    font { family: Theme.font; pixelSize: Theme.fontSize }
                }

                delegate: Rectangle {
                    id: card
                    required property var modelData
                    required property int index
                    readonly property bool current: ListView.isCurrentItem
                    readonly property bool expanded: root.expandedId === modelData.id
                    width: list.width
                    height: Math.max(48, content.implicitHeight + Theme.spaceM * 2)
                    radius: Theme.radiusSmall
                    color: current ? Theme.fillActive : area.containsMouse ? Theme.fillHover : Theme.fill
                    border { color: current ? Theme.strokeStrong : "transparent"; width: 1 }
                    Behavior on height { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easing } }

                    MouseArea {
                        id: area
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onEntered: list.currentIndex = card.index
                        onClicked: mouse => {
                            if (mouse.button === Qt.RightButton) root.expandedId = card.expanded ? "" : card.modelData.id
                            else root.paste(card.modelData)
                        }
                    }

                    Item {
                        id: content
                        anchors { left: parent.left; right: tools.left; top: parent.top; margins: Theme.spaceM }
                        implicitHeight: card.modelData.kind === "image" ? thumb.height : body.implicitHeight

                        Image {
                            id: thumb
                            visible: card.modelData.kind === "image"
                            source: visible ? "file://" + card.modelData.path : ""
                            width: Math.min(parent.width, implicitWidth)
                            height: visible ? Math.min(card.expanded ? 300 : 110, width * implicitHeight / Math.max(1, implicitWidth)) : 0
                            fillMode: Image.PreserveAspectFit
                            horizontalAlignment: Image.AlignLeft
                            asynchronous: true
                            sourceSize.width: 720
                        }
                        Text {
                            id: body
                            visible: card.modelData.kind !== "image"
                            width: parent.width
                            text: card.modelData.kind === "files"
                                  ? card.modelData.preview.trim().split("\n").map(p => "\u{F0214}  " + p.split("/").pop()).join("\n")
                                  : card.modelData.preview.trim()
                            color: Theme.text
                            wrapMode: Text.WrapAnywhere
                            maximumLineCount: card.expanded ? 24 : 3
                            elide: Text.ElideRight
                            font { family: card.modelData.kind === "files" ? Theme.iconFont : Theme.font; pixelSize: Theme.fontSize }
                        }
                    }

                    Row {
                        id: tools
                        anchors { right: parent.right; top: parent.top; margins: Theme.spaceS }
                        spacing: 2
                        opacity: card.current || card.modelData.pinned ? 1 : 0
                        Chip {
                            icon: card.modelData.pinned ? "\u{F0403}" : "\u{F0931}"
                            active: card.modelData.pinned
                            onClicked: root.run([card.modelData.pinned ? "unpin" : "pin", card.modelData.id])
                        }
                        Chip { icon: "\u{F0A7A}"; visible: card.current; onClicked: root.run(["delete", card.modelData.id]) }
                    }
                }
            }
        }
    }
}
