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
            selectedTextColor: Theme.accentText
            // behind a typed prompt (Monolith) a terminal's block caret in the accent; otherwise a thin line
            cursorDelegate: Rectangle {
                width: Launcher.prompt !== "" ? Math.round(field.font.pixelSize * 0.6) : 1
                height: field.cursorRectangle.height
                color: Launcher.prompt !== "" ? Qt.alpha(Theme.accent, 0.75) : Theme.text
                visible: field.activeFocus
                SequentialAnimation on opacity {
                    running: field.activeFocus && Theme.animate
                    loops: Animation.Infinite
                    onRunningChanged: if (!running) parent.opacity = 1
                    PropertyAction { value: 1 }
                    PauseAnimation { duration: 530 }
                    PropertyAction { value: 0 }
                    PauseAnimation { duration: 530 }
                }
            }
            font {
                family: Launcher.preset?.mono ? Theme.monoFont : Launcher.bigQuery ? Theme.displayFont : Theme.font
                pixelSize: Math.round(Launcher.look.field * (Launcher.bigQuery ? 0.5 : 0.38))
                weight: Launcher.bigQuery ? Theme.displayWeight : Font.Normal
            }
            onTextChanged: {
                if (Launcher.mode === "clip") { Clipboard.filter = text; Launcher.clipView.reset(); return }
                Search.query = text; Launcher.results.currentIndex = 0; Launcher.grid.currentIndex = 0; Launcher.homeIndex = 0; Launcher.confirmFor = null
            }
            Text {
                visible: !field.text
                x: Launcher.prompt !== "" ? Math.round(field.font.pixelSize * 0.6) + Theme.spaceS : 0   // after the block caret
                width: parent.width - x
                elide: Text.ElideRight
                anchors.verticalCenter: parent.verticalCenter
                text: Launcher.mode === "search" ? (Launcher.bigQuery || Launcher.look.width < 560 ? "Search" : "Search apps, files, settings and more") : Launcher.modes.find(m => m.id === Launcher.mode)?.hint ?? ""
                color: Theme.muted
                font: field.font
            }

            Keys.onPressed: event => {
                const inGrid = Launcher.view === "apps"
                // Menu key or Shift+F10: the selected app's menu
                if ((event.key === Qt.Key_Menu || (event.key === Qt.Key_F10 && (event.modifiers & Qt.ShiftModifier))) && Launcher.view !== "clip") {
                    if (Launcher.view === "home") Launcher.menuFor(Launcher.homeItems[Launcher.homeIndex])
                    else if (inGrid) Launcher.menuFor(Launcher.appGrid[Launcher.grid.currentIndex], Launcher.grid.currentItem)
                    else Launcher.menuFor(Launcher.listModel[Launcher.results.currentIndex], Launcher.results.currentItem)
                    event.accepted = true
                    return
                }
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
                    const n = Launcher.homeItems.length, nA = Launcher.homeSections.includes("frequent") && Launcher.rows !== "text" && Launcher.rows !== "compact" ? Search.frequentApps.length : 0, i = Launcher.homeIndex
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
        radius: Launcher.corner === 0 ? 0 : height / 2
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
                radius: Launcher.corner === 0 ? 0 : width / 2
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
