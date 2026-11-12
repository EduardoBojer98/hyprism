import Quickshell
import Quickshell.Widgets
import QtQuick

// Launcher part: the search pill (lens, text field, key handling) and the round mode buttons.
// Used by Launcher.qml; reads the panel's state from the Launcher singleton.
Item {
    property alias input: field
    width: parent.width
    height: Launcher.look.field
    z: 1   // above the panel, so the mode buttons' tooltips show over it

    Glass {
        id: searchBox
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom; right: buttons.left; rightMargin: Launcher.unified ? 0 : Theme.spaceS }
        strong: true
        flat: Launcher.unified
        color: Launcher.unified ? "transparent" : Launcher.surface
        border.width: Launcher.unified ? 0 : 1
        radius: Launcher.look.corners === "round" ? height / 2 : Launcher.corner

        Text {
            id: lens
            anchors { left: parent.left; leftMargin: Theme.spaceL + 2; verticalCenter: parent.verticalCenter }
            readonly property bool typed: Launcher.prompt !== "" && Launcher.mode === "search"
            text: typed ? Launcher.prompt : Launcher.mode === "search" ? "\u{F0349}" : Launcher.modes.find(m => m.id === Launcher.mode)?.glyph ?? ""
            color: typed ? Theme.accent : Theme.subtext
            font { family: typed ? Theme.monoFont : Theme.iconFont; pixelSize: typed ? field.font.pixelSize : Theme.iconMedium; weight: Font.Bold }
        }
        TextInput {
            id: field
            anchors { left: lens.right; leftMargin: Theme.spaceM; right: parent.right; rightMargin: Theme.spaceL; verticalCenter: parent.verticalCenter }
            color: Theme.text
            selectionColor: Theme.accent
            font {
                family: Launcher.bigQuery ? Theme.displayFont : Theme.font
                pixelSize: Math.round(Launcher.look.field * (Launcher.bigQuery ? 0.5 : 0.38))
                weight: Launcher.bigQuery ? Theme.displayWeight : Font.Normal
            }
            onTextChanged: {
                if (Launcher.mode === "clip") { Clipboard.filter = text; Launcher.clipView.reset(); return }
                Search.query = text; Launcher.results.currentIndex = 0; Launcher.grid.currentIndex = 0; Launcher.homeIndex = 0; Launcher.confirmFor = null
            }
            Text {
                visible: !field.text
                anchors.verticalCenter: parent.verticalCenter
                text: Launcher.mode === "search" ? (Launcher.bigQuery ? "Search" : "Search apps, files, settings and more") : Launcher.modes.find(m => m.id === Launcher.mode)?.hint ?? ""
                color: Theme.muted
                font: field.font
            }

            Keys.onPressed: event => {
                const inGrid = Launcher.view === "apps"
                if (Launcher.view === "clip") {
                    if (event.key === Qt.Key_Down) Launcher.clipView.down()
                    else if (event.key === Qt.Key_Up) Launcher.clipView.up()
                    else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) Launcher.clipView.paste()
                    else if (event.key === Qt.Key_Delete) Launcher.clipView.remove()
                    else if (event.key === Qt.Key_P && (event.modifiers & Qt.ControlModifier)) Launcher.clipView.pin()
                    else if (event.key === Qt.Key_Space && !field.text) Launcher.clipView.expand()
                    else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) Launcher.cycleMode()
                    else if (event.key === Qt.Key_Escape) Launcher.close()
                    else return
                    event.accepted = true
                    return
                }
                if (Launcher.view === "home" && !Launcher.confirmFor) {
                    const n = Launcher.homeItems.length, nA = Search.frequentApps.length, i = Launcher.homeIndex
                    if (event.key === Qt.Key_Right) Launcher.homeIndex = Math.min(n - 1, i + 1)
                    else if (event.key === Qt.Key_Left) Launcher.homeIndex = Math.max(0, i - 1)
                    else if (event.key === Qt.Key_Down) Launcher.homeIndex = Math.min(n - 1, i < nA ? nA : i + 1)
                    else if (event.key === Qt.Key_Up) Launcher.homeIndex = i < nA ? i : i === nA ? 0 : i - 1
                    else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) Launcher.activate(Launcher.homeItems[i])
                    else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) Launcher.cycleMode()
                    else if (event.key === Qt.Key_Escape) Launcher.close()
                    else return
                    event.accepted = true
                    return
                }
                if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) { Launcher.cycleMode() }
                else if (event.key === Qt.Key_Down) { inGrid ? Launcher.grid.moveCurrentIndexDown() : Launcher.results.incrementCurrentIndex() }
                else if (event.key === Qt.Key_Up) { inGrid ? Launcher.grid.moveCurrentIndexUp() : Launcher.results.decrementCurrentIndex() }
                else if (inGrid && event.key === Qt.Key_Right && field.cursorPosition === field.text.length) { Launcher.grid.moveCurrentIndexRight() }
                else if (inGrid && event.key === Qt.Key_Left && field.cursorPosition === 0) { Launcher.grid.moveCurrentIndexLeft() }
                else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    if (Launcher.confirmFor) { const r = Launcher.confirmFor; Launcher.confirmFor = null; Launcher.close(); Search.activate(r) }
                    else if (inGrid) { const e = Launcher.appGrid[Launcher.grid.currentIndex]; if (e) { Launcher.close(); Search.remember("app:" + e.id); e.execute() } }
                    else Launcher.activate(Launcher.listModel[Launcher.results.currentIndex])
                }
                else if (event.key === Qt.Key_Escape) { if (Launcher.confirmFor) Launcher.confirmFor = null; else Launcher.close() }
                else return
                event.accepted = true
            }
        }
    }

    Glass {
        id: buttons
        anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
        width: modeRow.implicitWidth + 12
        radius: height / 2
        strong: true
        flat: Launcher.unified
        color: Launcher.unified ? "transparent" : Launcher.surface
        border.width: Launcher.unified ? 0 : 1
        Row {
            id: modeRow
            anchors.centerIn: parent
            spacing: 2
        Repeater {
            model: Launcher.modes
            Rectangle {
                required property var modelData
                readonly property bool current: Launcher.mode === modelData.id
                width: 36; height: 36
                radius: width / 2
                color: current ? Theme.fillActive : buttonArea.containsMouse ? Theme.fillHover : "transparent"
                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                Text {
                    anchors.centerIn: parent
                    text: modelData.glyph
                    color: current ? Theme.accent : Theme.subtext
                    font { family: Theme.iconFont; pixelSize: Theme.iconMedium - 4 }
                }
                MouseArea {
                    id: buttonArea
                    Accessible.role: Accessible.Button
                    Accessible.name: modelData.name
                    Accessible.onPressAction: Launcher.setMode(modelData.id)
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Launcher.setMode(modelData.id)
                }
                ToolTipText { shown: buttonArea.containsMouse; text: modelData.name }
            }
        }
        }
    }
}
