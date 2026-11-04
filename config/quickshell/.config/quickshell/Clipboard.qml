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

    signal pasted()
    // Fresh list and the focused window's type (terminals paste with Ctrl+Shift+V)
    function prepare() { filter = ""; expandedId = ""; reload(); focused.running = true }
    function paste(e) {
        popup.hide()
        pasted()
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
        boxHeight: Math.min(540, popup.maxHeight)
        focusItem: search
        onOpened: { root.filter = ""; search.text = ""; clipView.reset(); root.expandedId = ""; root.reload(); focused.running = true }

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
                        onTextChanged: { root.filter = text; clipView.reset() }
                        Text { visible: !search.text; text: "Search history"; color: Theme.muted; font: search.font }

                        Keys.onUpPressed: clipView.up()
                        Keys.onDownPressed: clipView.down()
                        Keys.onReturnPressed: clipView.paste()
                        Keys.onEnterPressed: clipView.paste()
                        Keys.onEscapePressed: popup.hide()
                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Delete) { clipView.remove(); event.accepted = true }
                            else if (event.key === Qt.Key_P && (event.modifiers & Qt.ControlModifier)) { clipView.pin(); event.accepted = true }
                            else if (event.key === Qt.Key_Space && !search.text) { clipView.expand(); event.accepted = true }
                        }
                    }
                }
            }

            ClipboardView {
                id: clipView
                anchors { left: parent.left; right: parent.right; top: header.bottom; bottom: parent.bottom; margins: Theme.spaceS; topMargin: Theme.spaceM }
            }
        }
    }
}
