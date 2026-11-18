import QtQuick
import QtQuick.Layouts

// The display switcher (Super+P, `qs ipc call displays switcher`): Extend, Mirror, Only <screen> and your
// presets in one list. Up / Down choose, Enter applies, Esc or a click outside closes. Applying goes through
// Displays, so a bad mode still gets the keep-or-revert countdown.
Overlay {
    id: sw
    name: "display-switcher"
    cardWidth: 420
    cardHeight: col.implicitHeight + Theme.spaceL * 2
    open: Displays.switcherOpen
    onDismissed: Displays.switcherOpen = false

    property int index: 0
    onOpenChanged: if (open) index = 0

    // { name, hint, run } rows; a preset that needs a screen that isn't connected is left out
    readonly property var items: {
        const out = [], many = Displays.monitors.length > 1
        const builtIn = Displays.builtInPresets.filter(p => p.how === "extend" || p.how === "mirror")
        for (const p of builtIn) out.push({ name: p.name, hint: "", run: () => Displays.applyMode(p.how) })
        if (many) for (const m of Displays.monitors)
            out.push({ name: "Only " + Displays.label(m), hint: m.name, run: () => Displays.applyMode("only:" + m.key) })
        for (const p of Displays.presets.filter(x => Displays.available(x)))
            out.push({ name: p.name, hint: Config.displays.defaultPreset === p.id ? "default preset" : "preset", run: () => Displays.applyPreset(p.id) })
        out.push({ name: "Display settings…", hint: "", run: () => SettingsApp.show("displays") })
        return out
    }
    function choose(i) {
        if (i < 0 || i >= items.length) return
        Displays.switcherOpen = false
        items[i].run()
    }
    onKeyPressed: event => {
        if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab) index = (index + 1) % Math.max(1, items.length)
        else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab) index = (index + items.length - 1) % Math.max(1, items.length)
        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) choose(index)
        else if (event.key === Qt.Key_P && (event.modifiers & Qt.MetaModifier)) index = (index + 1) % Math.max(1, items.length)   // Super+P again steps on, like Windows
        else return
        event.accepted = true
    }

    ColumnLayout {
        id: col
        anchors { fill: parent; margins: Theme.spaceL }
        spacing: Theme.spaceXs

        Text { text: "Display switcher"; color: Theme.text; font { family: Theme.font; pixelSize: Theme.fontHeading; weight: Font.DemiBold } Layout.bottomMargin: Theme.spaceS }
        Text {
            visible: sw.items.length === 0
            text: "Only one screen is connected"
            color: Theme.subtext
            font { family: Theme.font; pixelSize: Theme.fontSize }
        }
        Repeater {
            model: sw.items
            Rectangle {
                required property var modelData
                required property int index
                Layout.fillWidth: true
                implicitHeight: Math.max(36, Theme.hit)
                radius: Theme.radiusSmall
                color: sw.index === index ? Theme.accentWash : (hover.containsMouse ? Theme.fillHover : "transparent")
                border { color: sw.index === index ? Theme.accent : "transparent"; width: 1 }
                Accessible.role: Accessible.Button
                Accessible.name: modelData.name
                RowLayout {
                    anchors { fill: parent; leftMargin: Theme.spaceM; rightMargin: Theme.spaceM }
                    Text { text: modelData.name; color: Theme.text; font { family: Theme.font; pixelSize: Theme.fontSize; weight: Font.Medium } }
                    Item { Layout.fillWidth: true }
                    Text { text: modelData.hint; color: Theme.subtext; font { family: Theme.font; pixelSize: Theme.fontCaption } }
                }
                MouseArea { id: hover; anchors.fill: parent; hoverEnabled: true; onClicked: sw.choose(index) }
            }
        }
        Text {
            text: "Up / Down to choose · Enter applies · Esc closes"
            color: Theme.subtext
            font { family: Theme.font; pixelSize: Theme.fontCaption }
            Layout.topMargin: Theme.spaceS
        }
    }
}
