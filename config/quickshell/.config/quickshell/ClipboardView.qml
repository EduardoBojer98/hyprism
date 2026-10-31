import Quickshell
import QtQuick

// The clipboard history list (cards with text, image or file previews, pin and delete). Used by
// the Super+V popup and inside Spotlight. Keyboard handling stays with the owner, through
// up() / down() / paste() / remove() / pin() / expand().
Item {
    id: view
    readonly property var current: Clipboard.shown[list.currentIndex] ?? null
    readonly property alias list: list

    function up() { list.decrementCurrentIndex() }
    function down() { list.incrementCurrentIndex() }
    function reset() { list.currentIndex = 0 }
    function paste() { if (current) Clipboard.paste(current) }
    function remove() { if (current) Clipboard.run(["delete", current.id]) }
    function pin() { if (current) Clipboard.run([current.pinned ? "unpin" : "pin", current.id]) }
    function expand() { if (current) Clipboard.expandedId = Clipboard.expandedId === current.id ? "" : current.id }

    ListView {
        id: list
        anchors.fill: parent
        clip: true
        spacing: Theme.spaceXs
        model: Clipboard.shown
        boundsBehavior: Flickable.StopAtBounds
        highlightMoveDuration: Theme.animFast

        Text {
            anchors.centerIn: parent
            visible: list.count === 0
            text: Clipboard.filter ? "Nothing matches" : Config.clipboard.paused ? "History is paused" : "Copy something and it shows up here"
            color: Theme.subtext
            font { family: Theme.font; pixelSize: Theme.fontSize }
        }

        delegate: Rectangle {
            id: card
            required property var modelData
            required property int index
            readonly property bool current: ListView.isCurrentItem
            readonly property bool expanded: Clipboard.expandedId === modelData?.id
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
                    if (mouse.button === Qt.RightButton) Clipboard.expandedId = card.expanded ? "" : card.modelData?.id
                    else Clipboard.paste(card.modelData)
                }
            }

            Item {
                id: content
                anchors { left: parent.left; right: tools.left; top: parent.top; margins: Theme.spaceM }
                implicitHeight: card.modelData?.kind === "image" ? thumb.height : body.implicitHeight

                Image {
                    id: thumb
                    visible: card.modelData?.kind === "image"
                    source: visible && card.modelData ? "file://" + card.modelData?.path : ""
                    width: Math.min(parent.width, implicitWidth)
                    height: visible ? Math.min(card.expanded ? 300 : 110, width * implicitHeight / Math.max(1, implicitWidth)) : 0
                    fillMode: Image.PreserveAspectFit
                    horizontalAlignment: Image.AlignLeft
                    asynchronous: true
                    sourceSize.width: 720
                }
                Text {
                    id: body
                    visible: card.modelData?.kind !== "image"
                    width: parent.width
                    text: card.modelData?.kind === "files"
                          ? card.modelData?.preview.trim().split("\n").map(p => "\u{F0214}  " + p.split("/").pop()).join("\n")
                          : card.modelData?.preview.trim()
                    color: Theme.text
                    wrapMode: Text.WrapAnywhere
                    maximumLineCount: card.expanded ? 24 : 3
                    elide: Text.ElideRight
                    font { family: card.modelData?.kind === "files" ? Theme.iconFont : Theme.font; pixelSize: Theme.fontSize }
                }
            }

            Row {
                id: tools
                anchors { right: parent.right; top: parent.top; margins: Theme.spaceS }
                spacing: 2
                opacity: card.current || card.modelData?.pinned ? 1 : 0
                Chip {
                    icon: card.modelData?.pinned ? "\u{F0403}" : "\u{F0931}"
                    active: card.modelData?.pinned
                    onClicked: Clipboard.run([card.modelData?.pinned ? "unpin" : "pin", card.modelData?.id])
                }
                Chip { icon: "\u{F0A7A}"; visible: card.current; onClicked: Clipboard.run(["delete", card.modelData?.id]) }
            }
        }
    }

}
