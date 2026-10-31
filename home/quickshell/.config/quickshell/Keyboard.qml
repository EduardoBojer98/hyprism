pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

// Keyboard layouts: the ones set in Settings > Keyboard & Touchpad (Hyprland's kb_layout /
// kb_variant), the active one, and the bar's dropdown to switch between them.
//   Keyboard.short ("US") · Keyboard.layouts · Keyboard.use(i) · `qs ipc call keyboard toggle`
//   Keyboard.catalog: every layout and variant xkb knows, for Settings to add from
Singleton {
    id: root

    readonly property bool open: popup.open
    property var layouts: []          // [{ code: "rs", variant: "latin", name: "Serbian (Latin)" }]
    property int active: 0
    readonly property string short: (layouts[active]?.code ?? "us").toUpperCase()
    property var catalog: []          // [{ code, variant, name }], layouts first, then variants
    function nameOf(code, variant) { return catalog.find(c => c.code === code && c.variant === (variant ?? ""))?.name ?? (code.toUpperCase() + (variant ? ` (${variant})` : "")) }

    function toggle() { popup.toggle() }
    function refresh() { reader.running = false; reader.running = true }
    Timer { id: retry; interval: 1000; onTriggered: root.refresh() }
    function use(i) { Quickshell.execDetached(["hyprctl", "switchxkblayout", "all", String(i)]); active = i }

    // the active layout changes with the Alt+Shift toggle too; the list changes when Settings reloads Hyprland
    Connections {
        target: Hyprland
        function onRawEvent(event) { if (event.name === "activelayout" || event.name === "configreloaded") root.refresh() }
    }

    // main keyboard from hyprctl, then each layout's full name from xkb's own list
    Process {
        id: reader
        running: true
        command: ["sh", "-c", "hyprctl -j devices; echo '--'; awk '/^! layout/{s=1;next} /^! variant/{s=2;next} /^!/{s=0} s==1{c=$1; $1=\"\"; print \"L\", c, $0} s==2{v=$1; sub(\":\",\"\",$2); c=$2; $1=$2=\"\"; print \"V\", c\"(\"v\")\", $0}' /usr/share/X11/xkb/rules/evdev.lst"]
        stdout: StdioCollector {
            onStreamFinished: {
                const [json, names] = text.split("\n--\n")
                let kb
                // while Hyprland reloads its config, hyprctl can answer with something that isn't JSON: ask again
                try { const d = JSON.parse(json); kb = d.keyboards.find(k => k.main) ?? d.keyboards[0] } catch (e) { retry.restart(); return }
                if (!kb) return
                const lookup = {}, catalog = []
                for (const l of (names ?? "").split("\n")) {
                    const m = l.match(/^([LV]) (\S+)\s+(.*)$/)
                    if (!m) continue
                    lookup[m[2]] = m[3].trim()
                    const v = m[2].match(/^(\w+)\((.+)\)$/)   // "rs(latin)"
                    catalog.push({ code: v ? v[1] : m[2], variant: v ? v[2] : "", name: m[3].trim() })
                }
                if (catalog.length) root.catalog = catalog
                const codes = kb.layout.split(","), variants = (kb.variant ?? "").split(",")
                root.layouts = codes.map((c, i) => {
                    const v = variants[i] ?? ""
                    return { code: c, variant: v, name: lookup[v ? `${c}(${v})` : c] ?? c.toUpperCase() }
                })
                root.active = Math.max(0, kb.active_layout_index ?? 0)
            }
        }
    }

    IpcHandler {
        target: "keyboard"
        function toggle(): void { root.toggle() }
    }

    CursorPopup {
        id: popup
        name: "keyboard"
        placement: "cursor"
        boxWidth: 236
        boxHeight: menu.implicitHeight + Theme.spaceS * 2
        onOpened: root.refresh()

        Glass {
            anchors.fill: parent
            strong: true
            radius: Theme.radiusLarge

            ColumnLayout {
                id: menu
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.spaceS }
                spacing: 0

                Text {
                    Layout.margins: Theme.spaceS
                    Layout.bottomMargin: Theme.spaceXs
                    text: "Input sources"
                    color: Theme.subtext
                    font { family: Theme.font; pixelSize: Theme.fontCaption; weight: Font.DemiBold }
                }
                Repeater {
                    model: root.layouts
                    Rectangle {
                        id: row
                        required property var modelData
                        required property int index
                        readonly property bool current: index === root.active
                        Layout.fillWidth: true
                        Layout.preferredHeight: Theme.controlHeight + 2
                        radius: Theme.radiusSmall - 2
                        color: area.containsMouse ? Theme.accent : "transparent"
                        RowLayout {
                            anchors { fill: parent; leftMargin: Theme.spaceS; rightMargin: Theme.spaceS + 2 }
                            spacing: Theme.spaceS + 2
                            Rectangle { // the same keycap as in the bar
                                Layout.preferredWidth: 26; Layout.preferredHeight: 16
                                radius: 4
                                color: "transparent"
                                border { color: Qt.alpha(area.containsMouse ? Theme.accentText : Theme.text, 0.45); width: 1 }
                                Text {
                                    anchors.centerIn: parent
                                    text: row.modelData.code.toUpperCase()
                                    color: area.containsMouse ? Theme.accentText : Theme.text
                                    font { family: Theme.font; pixelSize: 9; weight: Font.Bold; letterSpacing: 0.3 }
                                }
                            }
                            Text {
                                Layout.fillWidth: true
                                text: row.modelData.name
                                elide: Text.ElideRight
                                color: area.containsMouse ? Theme.accentText : Theme.text
                                font { family: Theme.font; pixelSize: Theme.fontSize; weight: row.current ? Font.DemiBold : Font.Normal }
                            }
                            Text {
                                visible: row.current
                                text: "\u{F012C}"
                                color: area.containsMouse ? Theme.accentText : Theme.accent
                                font { family: Theme.iconFont; pixelSize: 14 }
                            }
                        }
                        MouseArea { id: area; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { root.use(row.index); popup.hide() } }
                    }
                }
                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; Layout.topMargin: Theme.spaceXs; Layout.bottomMargin: Theme.spaceXs; color: Theme.stroke }
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Theme.controlHeight
                    radius: Theme.radiusSmall - 2
                    color: setArea.containsMouse ? Theme.accent : "transparent"
                    Text {
                        anchors { left: parent.left; leftMargin: Theme.spaceS + 2; verticalCenter: parent.verticalCenter }
                        text: "Add or remove layouts…"
                        color: setArea.containsMouse ? Theme.accentText : Theme.text
                        font { family: Theme.font; pixelSize: Theme.fontSize }
                    }
                    MouseArea { id: setArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { popup.hide(); SettingsApp.show("input") } }
                }
            }
        }
    }
}
