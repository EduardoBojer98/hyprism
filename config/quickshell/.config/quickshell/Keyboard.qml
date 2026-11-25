pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

// Keyboard layouts: the ones set in Settings > Keyboard (Hyprland's kb_layout /
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

    // Caps Lock and Num Lock: on when any keyboard has them on (Hyprland keeps them per keyboard). Read at
    // start and whenever Hyprland reports one of the keys (binds.lua: pass-through binds call
    // `qs ipc call keyboard locks`), never on a timer.
    property bool capsLock: false
    property bool numLock: false
    property bool locksKnown: false   // false until the first read: changes before it are the start state, not news
    function readLocks() { lockReader.running = false; lockReader.running = true }
    Timer { id: lockLater; interval: 60; onTriggered: root.readLocks() }   // the state changes just after the key
    Process {
        id: lockReader
        running: true
        command: ["hyprctl", "-j", "devices"]
        stdout: StdioCollector {
            onStreamFinished: {
                let kbs
                try { kbs = JSON.parse(text).keyboards ?? [] } catch (e) { return }
                root.capsLock = kbs.some(k => k.capsLock === true)
                root.numLock = kbs.some(k => k.numLock === true)
                root.locksKnown = true
            }
        }
    }

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
        function locks(): string { lockLater.restart(); return JSON.stringify({ caps: root.capsLock, num: root.numLock }) }
    }

    CursorPopup {
        id: popup
        name: "keyboard"
        placement: "cursor"
        boxWidth: 236
        boxHeight: menu.implicitHeight + Theme.spaceS * 2
        focusItem: menu
        onOpened: root.refresh()

        Glass {
            anchors.fill: parent
            strong: true
            radius: Theme.radiusLarge

            MenuList {
                id: menu
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.spaceS }

                Text {
                    Layout.margins: Theme.spaceS
                    Layout.bottomMargin: Theme.spaceXs
                    text: "Input sources"
                    color: Theme.subtext
                    font { family: Theme.font; pixelSize: Theme.fontCaption; weight: Font.DemiBold }
                }
                Repeater {
                    model: root.layouts
                    MenuRow {
                        id: row
                        required property var modelData
                        required property int index
                        label: modelData.name
                        checked: index === root.active
                        bold: checked
                        onClicked: { root.use(index); popup.hide() }
                        Rectangle {   // the same keycap as in the bar
                            width: Theme.iconSmall + 10; height: Theme.iconSmall
                            radius: Math.min(4, Theme.radiusSmall)
                            color: "transparent"
                            border { color: Qt.alpha(row.ink, 0.45); width: 1 }
                            Text {
                                anchors.centerIn: parent
                                text: row.modelData.code.toUpperCase()
                                color: row.ink
                                font { family: Theme.font; pixelSize: Theme.fontCaption - 2; weight: Font.Bold; letterSpacing: 0.3 }
                            }
                        }
                    }
                }
                MenuDivider {}
                MenuRow { label: "Add or remove layouts…"; onClicked: { popup.hide(); SettingsApp.show("input") } }
            }
        }
    }
}
