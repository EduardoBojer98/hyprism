pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

// Alt+Tab: the open windows, most recently used first, as a row of cards. Hold Alt and press Tab
// (Shift+Tab goes back), let go of Alt to switch; Escape or a click outside cancels.
// Hyprland binds Alt+Tab to `qs ipc call alttab next|prev`; while the row is open it has the keyboard,
// so letting go of Alt arrives here. The order comes from Hyprland's focus history, read once per opening.
Singleton {
    id: root

    property bool open: false
    property var windows: []    // [{ address, title, cls, ws }], most recent first
    property int index: 0
    property int pending: 0     // steps asked for before the list arrived (a quick Alt+Tab)

    function next() { step(1) }
    function prev() { step(-1) }
    function step(d) {
        if (!open) { open = true; pending = d; reader.running = true; return }
        if (windows.length === 0) { pending += d; return }
        index = (index + d + windows.length) % windows.length
    }
    function commit() {
        const w = windows[index]
        cancel()
        if (w) Quickshell.execDetached(["hyprctl", "dispatch", `hl.dsp.focus({ window = "address:${w.address}" })`])
    }
    function cancel() { open = false; windows = []; index = 0; pending = 0 }

    Process {
        id: reader
        command: ["hyprctl", "-j", "clients"]
        stdout: StdioCollector {
            onStreamFinished: {
                let list = []
                try { list = JSON.parse(text) } catch (e) { list = [] }
                // mapped windows on real workspaces (not the drop-down terminal's special one), most recent first
                root.windows = list.filter(c => c.mapped && c.workspace?.id > 0)
                    .sort((a, b) => a.focusHistoryID - b.focusHistoryID)
                    .map(c => ({ address: c.address, title: c.title, cls: c.class, ws: c.workspace.name }))
                if (root.windows.length === 0) { root.cancel(); return }
                // one press starts on the window before this one: Alt+Tab once = back to the last window
                root.index = ((root.pending > 0 ? root.pending : root.windows.length + root.pending) % root.windows.length + root.windows.length) % root.windows.length
                root.pending = 0
            }
        }
    }

    IpcHandler {
        target: "alttab"
        function next(): void { root.next() }
        function prev(): void { root.prev() }
        function cancel(): void { root.cancel() }
    }

    Overlay {
        name: "alttab"
        open: root.open && root.windows.length > 0
        dim: false
        cardWidth: row.implicitWidth + Theme.spaceL * 2
        cardHeight: row.implicitHeight + Theme.spaceL * 2
        onDismissed: root.cancel()
        onKeyPressed: event => {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { root.commit(); event.accepted = true }
            else if (event.key === Qt.Key_Right) { root.step(1); event.accepted = true }
            else if (event.key === Qt.Key_Left) { root.step(-1); event.accepted = true }
        }
        onKeyReleased: event => { if (event.key === Qt.Key_Alt || event.key === Qt.Key_Meta) root.commit() }

        Flickable {
            anchors.fill: parent
            anchors.margins: Theme.spaceL
            contentWidth: row.implicitWidth
            clip: true
            // keep the chosen card in view on a narrow screen
            contentX: Math.max(0, Math.min(contentWidth - width, (row.children[root.index]?.x ?? 0) - width / 2 + 60))
            Row {
                id: row
                spacing: Theme.spaceS
                Repeater {
                    model: root.windows
                    Rectangle {
                        id: cardItem
                        required property var modelData
                        required property int index
                        readonly property bool chosen: index === root.index
                        width: 120; height: 120
                        radius: Theme.radius
                        color: chosen ? Theme.selected : "transparent"
                        border.width: chosen ? 2 : 0
                        border.color: Theme.accent
                        Accessible.role: Accessible.ListItem
                        Accessible.name: modelData.title
                        Accessible.selected: chosen
                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: Theme.spaceS
                            spacing: Theme.spaceXs
                            IconImage {
                                Layout.alignment: Qt.AlignHCenter
                                implicitSize: 48
                                source: Quickshell.iconPath(DesktopEntries.heuristicLookup(cardItem.modelData.cls)?.icon ?? "", "application-x-executable")
                            }
                            Text {
                                Layout.fillWidth: true
                                text: cardItem.modelData.title || cardItem.modelData.cls
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight; maximumLineCount: 2; wrapMode: Text.Wrap
                                color: cardItem.chosen ? Theme.onSelected : Theme.text
                                font { family: Theme.font; pixelSize: Theme.fontCaption }
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: { root.index = cardItem.index; root.commit() }
                        }
                    }
                }
            }
        }
    }
}
