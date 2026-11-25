import QtQuick
import QtQuick.Layouts

// The power menu's contents in its layout (tiles, row, blocks or list): PowerMenu draws it in its card, and
// Settings > Power Menu draws it as a live preview with a stand-in `menu` and `enabled: false`.
// `menu` gives style, actions, selected, confirming, host, uptime, details, activate(i) and hide().
ColumnLayout {
    id: content
    property var menu
    property bool closable: true
    // keyboard: how many actions sit in one row of the current layout
    readonly property int columns: menu.style === "list" ? 1 : menu.style === "row" ? menu.actions.length : menu.style === "blocks" ? blockGrid.columns : grid.columns
    spacing: Theme.spaceL

    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.spaceM
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Text {
                text: content.menu.style === "blocks" ? "POWER" : content.menu.style === "list" ? "$ power" : "Power"
                color: content.menu.style === "list" ? Theme.accent : Theme.text
                font {
                    family: content.menu.style === "blocks" ? Theme.displayFont : content.menu.style === "list" ? Theme.monoFont : Theme.font
                    pixelSize: content.menu.style === "blocks" ? Theme.fontDisplay : content.menu.style === "list" ? Theme.fontTitle : Theme.fontHeading
                    weight: content.menu.style === "blocks" ? Math.max(Theme.displayWeight, Font.Bold) : Font.Bold
                }
            }
            Text {
                Layout.fillWidth: true
                text: content.menu.style === "list" ? "// " + content.menu.host + (content.menu.uptime ? "  up " + content.menu.uptime : "")
                                            : content.menu.host + (content.menu.uptime ? " · up " + content.menu.uptime : "")
                elide: Text.ElideRight
                color: Theme.subtext
                font { family: content.menu.style === "list" ? Theme.monoFont : Theme.font; pixelSize: Theme.fontLabel }
            }
        }
        Rectangle {   // close
            visible: content.closable
            Layout.alignment: Qt.AlignTop
            width: 28; height: 28; radius: 14
            color: closeArea.containsMouse ? Theme.fillHover : Theme.fill
            Text { anchors.centerIn: parent; text: "\u{F0156}"; color: Theme.subtext; font { family: Theme.iconFont; pixelSize: Theme.glyphS } }
            MouseArea { id: closeArea; Accessible.role: Accessible.Button; Accessible.name: "Close"; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: content.menu.hide() }
        }
    }

    GridLayout {
        id: grid
        visible: content.menu.style === "tiles"
        Layout.fillWidth: true
        // tiles need ~150 px each; below two of those, compact rows
        readonly property bool rows: width < 300
        columns: rows ? 1 : width >= 3 * 150 + 2 * columnSpacing ? 3 : 2
        columnSpacing: Theme.spaceM
        rowSpacing: Theme.spaceM

        Repeater {
            model: content.menu.actions
            Rectangle {
                id: tile
                required property var modelData
                required property int index
                readonly property bool asking: content.menu.confirming === modelData.id
                readonly property bool lit: tileArea.containsMouse || content.menu.selected === index
                readonly property color tone: asking || modelData.danger ? Theme.error : Theme.accentLikeError ? Theme.text : Theme.accent

                Layout.fillWidth: true
                Layout.preferredHeight: grid.rows ? 52 : 112
                radius: Theme.radius
                color: asking ? Qt.rgba(tone.r, tone.g, tone.b, 0.22) : lit ? Theme.fillHover : Theme.fill
                border { color: asking ? tone : content.menu.selected === index ? Theme.strokeStrong : "transparent"; width: 1 }
                Behavior on color { ColorAnimation { duration: Theme.animFast } }

                GridLayout {
                    anchors { fill: parent; margins: Theme.spaceM }
                    columns: grid.rows ? 2 : 1
                    rowSpacing: Theme.spaceS
                    columnSpacing: Theme.spaceM

                    Rectangle {
                        Layout.alignment: grid.rows ? Qt.AlignVCenter : Qt.AlignHCenter
                        width: grid.rows ? 30 : 46; height: width; radius: width / 2
                        color: tile.lit || tile.asking ? tile.tone : Theme.fillActive
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                        Text {
                            anchors.centerIn: parent
                            text: tile.modelData.icon
                            color: tile.lit || tile.asking ? (tile.tone === Theme.text ? Theme.base : Theme.accentText) : tile.modelData.danger ? Theme.error : Theme.text
                            font { family: Theme.iconFont; pixelSize: grid.rows ? 15 : 22 }
                        }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: grid.rows ? Qt.AlignVCenter : Qt.AlignHCenter
                        spacing: 1
                        Text {
                            Layout.fillWidth: true
                            horizontalAlignment: grid.rows ? Text.AlignLeft : Text.AlignHCenter
                            text: tile.modelData.label
                            elide: Text.ElideRight
                            color: tile.asking ? tile.tone : Theme.text
                            font { family: Theme.font; pixelSize: Theme.fontSize; weight: Font.DemiBold }
                        }
                        Text {
                            Layout.fillWidth: true
                            visible: tile.asking
                            horizontalAlignment: grid.rows ? Text.AlignLeft : Text.AlignHCenter
                            text: "Press again to confirm"
                            elide: Text.ElideRight
                            color: Theme.subtext
                            font { family: Theme.font; pixelSize: Theme.fontCaption }
                        }
                    }
                }
                MouseArea {
                    id: tileArea
                    Accessible.role: Accessible.Button
                    Accessible.name: tile.modelData.label
                    Accessible.onPressAction: content.menu.activate(tile.index)
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: content.menu.selected = tile.index
                    onClicked: content.menu.activate(tile.index)
                }
            }
        }
                    }

    // row: one line of round buttons, each named under it, the way a modern desktop asks
    RowLayout {
        visible: content.menu.style === "row"
        Layout.fillWidth: true
        Layout.topMargin: Theme.spaceS
        spacing: Theme.spaceS
        Repeater {
            model: content.menu.actions
            Item {
                id: btn
                required property var modelData
                required property int index
                readonly property bool asking: content.menu.confirming === modelData.id
                readonly property bool lit: btnArea.containsMouse || content.menu.selected === index
                readonly property color tone: asking || modelData.danger ? Theme.error : Theme.accentLikeError ? Theme.text : Theme.accent
                Layout.fillWidth: true
                implicitHeight: disc.height + Theme.spaceS + btnLabel.implicitHeight + Theme.spaceXs
                Rectangle {
                    id: disc
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 60; height: 60; radius: Math.min(30, Theme.radiusLarge * 2)
                    color: btn.asking || btn.lit ? btn.tone : Theme.fill
                    border { width: 1; color: btn.lit || btn.asking ? "transparent" : Theme.stroke }
                    scale: btnArea.pressed ? Theme.pressScale : btn.lit ? 1.06 : 1
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easing } }
                    Text {
                        anchors.centerIn: parent
                        text: btn.modelData.icon
                        color: btn.asking || btn.lit ? (btn.tone === Theme.text ? Theme.base : Theme.accentText) : btn.modelData.danger ? Theme.error : Theme.text
                        font { family: Theme.iconFont; pixelSize: Theme.glyphL + 4 }
                    }
                }
                Text {
                    id: btnLabel
                    anchors { top: disc.bottom; topMargin: Theme.spaceS; left: parent.left; right: parent.right }
                    horizontalAlignment: Text.AlignHCenter
                    text: btn.asking ? "Confirm?" : btn.modelData.label
                    elide: Text.ElideRight
                    color: btn.asking ? btn.tone : btn.lit ? Theme.text : Theme.subtext
                    font { family: Theme.font; pixelSize: Theme.fontLabel; weight: btn.lit || btn.asking ? Font.DemiBold : Font.Medium }
                }
                MouseArea {
                    id: btnArea
                    Accessible.role: Accessible.Button
                    Accessible.name: btn.modelData.label
                    Accessible.onPressAction: content.menu.activate(btn.index)
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: content.menu.selected = btn.index
                    onClicked: content.menu.activate(btn.index)
                }
            }
        }
    }

    // blocks: giant display-type blocks with their key, a hard shadow; the chosen one an accent block
    GridLayout {
        id: blockGrid
        visible: content.menu.style === "blocks"
        Layout.fillWidth: true
        columns: width >= 3 * 170 + 2 * columnSpacing ? 3 : width >= 2 * 140 + columnSpacing ? 2 : 1
        columnSpacing: Theme.spaceL
        rowSpacing: Theme.spaceL

        Repeater {
            model: content.menu.actions
            Item {
                id: blk
                required property var modelData
                required property int index
                readonly property bool asking: content.menu.confirming === modelData.id
                readonly property bool lit: blkArea.containsMouse || content.menu.selected === index
                readonly property color fill: asking || lit && modelData.danger ? Theme.error : lit ? Theme.accent : Theme.surfaceColor
                readonly property color ink: asking || lit ? Theme.accentText : Theme.text
                readonly property int drop: blkArea.pressed ? 0 : Theme.spaceS   // the shadow collapses on press
                Layout.fillWidth: true
                Layout.preferredHeight: blockGrid.columns === 1 ? 72 : 132

                Rectangle {   // the hard shadow
                    x: Theme.spaceS; y: Theme.spaceS; width: parent.width; height: parent.height
                    color: Theme.text
                }
                Rectangle {
                    x: Theme.spaceS - blk.drop; y: Theme.spaceS - blk.drop; width: parent.width; height: parent.height
                    color: blk.fill
                    border { width: Math.max(2, Theme.line); color: Theme.text }
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                    Rectangle {   // the key
                        anchors { top: parent.top; right: parent.right; margins: Theme.spaceM }
                        width: keyText.implicitHeight + Theme.spaceXs; height: width
                        color: "transparent"
                        border { width: Math.max(2, Theme.line); color: blk.ink }
                        Text {
                            id: keyText
                            anchors.centerIn: parent
                            text: blk.modelData.key
                            color: blk.ink
                            font { family: Theme.displayFont; pixelSize: Theme.fontTitle; weight: Font.Bold }
                        }
                    }
                    Column {
                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: Theme.spaceM }
                        Text {
                            width: parent.width
                            visible: blk.asking
                            text: "AGAIN TO CONFIRM"
                            elide: Text.ElideRight
                            color: blk.ink
                            font { family: Theme.font; pixelSize: Theme.fontCaption; weight: Font.Bold; letterSpacing: 1 }
                        }
                        Text {
                            width: parent.width
                            text: blk.modelData.label.toUpperCase()
                            elide: Text.ElideRight
                            color: blk.ink
                            font { family: Theme.displayFont; pixelSize: Theme.fontDisplay; weight: Math.max(Theme.displayWeight, Font.Bold) }
                        }
                    }
                }
                MouseArea {
                    id: blkArea
                    Accessible.role: Accessible.Button
                    Accessible.name: blk.modelData.label + ", key " + blk.modelData.key
                    Accessible.onPressAction: content.menu.activate(blk.index)
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: content.menu.selected = blk.index
                    onClicked: content.menu.activate(blk.index)
                }
            }
        }
    }

    // list: numbered mono lines, a > on the chosen one
    Column {
        visible: content.menu.style === "list"
        Layout.fillWidth: true
        spacing: 0
        Repeater {
            model: content.menu.actions
            Rectangle {
                id: line
                required property var modelData
                required property int index
                readonly property bool asking: content.menu.confirming === modelData.id
                readonly property bool lit: lineArea.containsMouse || content.menu.selected === index
                width: parent.width
                height: lineText.implicitHeight + Theme.spaceS * 2
                color: lit ? Theme.fill : "transparent"
                Text {
                    id: lineText
                    anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: Theme.spaceS }
                    textFormat: Text.PlainText
                    text: (line.lit ? "> " : "  ") + (line.index + 1) + ") " + line.modelData.label.toLowerCase()
                          + (line.asking ? "   press " + (line.index + 1) + " again to confirm" : "")
                    elide: Text.ElideRight
                    color: line.asking || line.modelData.danger && line.lit ? Theme.error : line.lit ? Theme.accent : Theme.text
                    font { family: Theme.monoFont; pixelSize: Theme.fontSize }
                }
                MouseArea {
                    id: lineArea
                    Accessible.role: Accessible.Button
                    Accessible.name: (line.index + 1) + ", " + line.modelData.label
                    Accessible.onPressAction: content.menu.activate(line.index)
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: content.menu.selected = line.index
                    onClicked: content.menu.activate(line.index)
                }
            }
        }
    }
    Text {
        visible: content.menu.style === "list"
        Layout.fillWidth: true
        text: "[1-" + content.menu.actions.length + "] pick  [enter] run  [esc] close"
        elide: Text.ElideRight
        color: Theme.subtext
        font { family: Theme.monoFont; pixelSize: Theme.fontCaption }
    }
}
