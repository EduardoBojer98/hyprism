import Quickshell
import QtQuick
import QtQuick.Layouts

// Dock: on or off, where it sits and on which monitors, how it behaves, and its pinned apps
// (dock.pinned, app ids) and widgets (dock.widgets). Its look comes from the theme; every option works in
// every theme, and a dock on the same edge as the bar sits beside it. Inside the menu bar the dock is the bar's
// "apps" item: only what applies there is shown (size, hiding, previews and widgets are the floating dock's).
ColumnLayout {
    id: page
    spacing: 20

    property string query: ""
    readonly property var pinned: Config.dock.pinned
    readonly property bool inBar: Theme.dockInBar
    // every widget: the shown ones in their order, then the rest
    readonly property var widgets: Config.dock.widgets.filter(id => Theme.dockWidgets[id] !== undefined)
    readonly property var widgetList: widgets.concat(Object.keys(Theme.dockWidgets).filter(id => !widgets.includes(id)))
    function moveWidget(id, by) {
        const list = Array.from(widgets), i = list.indexOf(id), j = i + by
        if (i < 0 || j < 0 || j >= list.length) return
        list.splice(i, 1); list.splice(j, 0, id)
        Config.set("dock", "widgets", list)
    }
    function showWidget(id, on) { Config.set("dock", "widgets", on ? widgets.concat([id]) : widgets.filter(x => x !== id)) }
    readonly property var matches: {
        const q = query.trim().toLowerCase()
        if (!q) return []
        return DesktopEntries.applications.values
            .filter(e => !e.noDisplay && !pinned.includes(e.id) && (e.name.toLowerCase().includes(q) || e.id.toLowerCase().includes(q)))
            .sort((a, b) => a.name.localeCompare(b.name))
            .slice(0, 8)
    }
    function add(id) { Config.set("dock", "pinned", pinned.concat([id])); query = ""; search.text = "" }
    function remove(id) { Config.set("dock", "pinned", pinned.filter(x => x !== id)) }
    // dragging: `id` before or after `target` (the dock itself reorders the same way)
    function place(id, target, after) {
        if (id === target) return
        const list = pinned.filter(x => x !== id), i = list.indexOf(target)
        if (i < 0) return
        list.splice(i + (after ? 1 : 0), 0, id)
        Config.set("dock", "pinned", list)
    }




    SettingGroup {
        title: "Place"
        DesktopPreview { show: "dock"; Layout.fillWidth: true; Layout.topMargin: 4 }
        SettingRow {
            label: "Show the dock"
            ConfigToggle { section: "dock"; key: "enabled" }
        }
        SettingRow {
            visible: Config.dock.enabled
            label: "Position"
            hint: (Theme.dockInBar ? "Inside the menu bar" : "At the " + Theme.dockEdge + " of the screen") + "; saved with the menu bar layout, for every theme"
            Choice {
                readonly property var values: ["bar", "bottom", "left", "right", "top"]
                options: ["In the bar", "Bottom", "Left", "Right", "Top"]
                index: Math.max(0, values.indexOf(Theme.dockMode))
                onPicked: i => Theme.setLayout({ dock: values[i] })
            }
        }
        SettingRow {   // the named sizes over a slider for any size between: a size of your own lights no preset
            visible: Config.dock.enabled && !page.inBar
            label: "Size"
            hint: Config.dock.iconSize + " px icons" + (dockSize.values.includes(Config.dock.iconSize) ? "" : ", your own size")
            PresetSlider {
                id: dockSize
                values: [36, 44, 52, 60]
                options: ["Small", "Medium", "Large", "Huge"]
                from: 24; to: 72
                value: Config.dock.iconSize
                unit: "px"
                accessibleName: "Dock size"
                onPicked: v => Config.set("dock", "iconSize", Math.round(v))
            }
        }
        SettingRow {
            visible: Config.dock.enabled && !page.inBar
            label: "Spacing"
            hint: "Room around the icons"
            ConfigChoice { section: "dock"; key: "size"; values: ["compact", "regular", "roomy"]; labels: ["Compact", "Regular", "Roomy"] }
        }
        Repeater {
            model: Config.dock.enabled && !page.inBar ? Quickshell.screens.filter(s => Machine.realScreen(s.name)) : []
            SettingRow {
                required property var modelData
                label: "On " + modelData.name
                hint: modelData.width + " × " + modelData.height
                Toggle {
                    checked: !Config.dock.hiddenOn.some(k => Displays.matches(k, modelData))
                    onToggled: on => Config.set("dock", "hiddenOn", on ? Config.dock.hiddenOn.filter(k => !Displays.matches(k, modelData))
                                                                        : Array.from(Config.dock.hiddenOn).concat([Displays.keyForName(modelData.name)]))
                }
            }
        }
        SettingRow {
            visible: Config.dock.enabled && Config.dock.showRunning && !Config.dock.combine
            label: "Open windows as names"
            hint: "Each open window shows just its app's name, without an icon" + (page.inBar ? " or title" : ", picture or title")
            ConfigToggle { section: "dock"; key: "nameOnly" }
        }
        SettingRow {
            visible: Config.dock.enabled && page.inBar && !(Config.dock.nameOnly && Config.dock.showRunning && !Config.dock.combine)
            label: "Open windows"
            hint: "An icon, or with its name or title beside it"
            ConfigChoice { section: "dock"; key: "barLabels"; values: ["icon", "name", "title"]; labels: ["Icon", "App name", "Window title"] }
        }
        SettingRow {
            visible: Config.dock.enabled && !page.inBar
            label: "Look"
            hint: ({ theme: "The theme's own " + ({ glass: "glass", surface: "panel", ink: "ink block" })[Theme.dockStyle.fill] ?? "fill",
                     clear: "An even overlay, or nothing at all at 0%",
                     frosted: "Frosted glass: what's behind the dock blurred, a light rim and a soft shadow",
                     none: "No background: the icons float on their own" })[Config.dock.look] ?? ""
            ConfigChoice { section: "dock"; key: "look"; values: ["theme", "clear", "frosted", "none"]; labels: ["Theme's", "Clear", "Frosted", "None"] }
        }
        SettingRow {
            visible: Config.dock.enabled && !page.inBar && Config.dock.look !== "theme" && Config.dock.look !== "none"
            label: "Overlay"
            hint: Config.dock.tint === 0 ? "None: completely transparent" + (Config.dock.look === "frosted" ? " over the blur" : "")
                                         : "The dock's own colour over what's behind it"
            ConfigSlider { section: "dock"; key: "tint"; from: 0; to: 100; step: 5; format: v => v + "%" }
        }
        SettingRow {
            visible: Config.dock.enabled
            label: "Active window mark"
            hint: "Under each open app" + (page.inBar ? "" : "'s icon") + "; bigger on the focused one. Works the same in the bar."
            ThemeChoice { key: "dockMark"; values: ["theme", "dot", "line", "bar", "ring", "diamond"]; labels: ["Default", "Dot", "Line", "Bar", "Ring", "Diamond"] }
        }
        SettingRow {
            visible: Config.dock.enabled
            label: "Mark position"
            hint: "Edge: the side toward the screen edge. Inner: the other side. Left: beside the icon (the top on a vertical bar or dock)"
            ThemeChoice { key: "dockMarkSide"; values: ["theme", "edge", "inner", "left"]; labels: ["Default", "Edge", "Inner", "Left"] }
        }
    }

    SettingGroup {
        visible: Config.dock.enabled
        title: "Behaviour"
        SettingRow {
            visible: !page.inBar
            label: "Hide automatically"
            hint: "Slides away until the pointer touches its edge; stays on an empty desktop"
            ConfigToggle { section: "dock"; key: "autoHide" }
        }
        SettingRow {
            label: "Combine open apps with their icons"
            hint: Config.dock.combine ? "Like Windows' combined taskbar: an open app shares its icon" + (page.inBar ? "" : "; hover it for its windows")
                                      : "Off: pinned apps are launchers, every open window is its own tile after them"
            ConfigToggle { section: "dock"; key: "combine" }
        }
        SettingRow {
            visible: Config.dock.combine && !page.inBar
            label: "Window previews on hover"
            hint: "A live picture of each window; click one to bring it up, middle-click to close it"
            ConfigToggle { section: "dock"; key: "previews" }
        }
        SettingRow {
            visible: !page.inBar
            label: "Launcher button"
            hint: "The button at the dock's start that opens Search & Launcher. Off: Super or Super+Space still open it"
            ConfigToggle { section: "dock"; key: "launcher" }
        }
        SettingRow {
            visible: Config.dock.launcher && !page.inBar
            label: "Launcher icon"
            hint: "Point at one to see how it moves; it plays on the dock when you point at the button or the launcher is open"
            Flow {   // section "dock", key "launcherIcon": each design drawn live; hover plays it
                spacing: 8
                Repeater {
                    model: iconSample.styles
                    Rectangle {
                        id: pick
                        required property var modelData
                        readonly property bool chosen: Config.dock.launcherIcon === modelData[0]
                        function choose() { Config.set("dock", "launcherIcon", modelData[0]) }
                        width: 64; height: 70
                        radius: Theme.radius
                        color: chosen ? Theme.accentWash : pickArea.containsMouse ? Qt.alpha(Theme.text, 0.06) : "transparent"
                        border { color: chosen ? Theme.accent : Qt.alpha(Theme.text, 0.15); width: chosen ? 2 : 1 }
                        activeFocusOnTab: true
                        Keys.onPressed: e => { if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.key === Qt.Key_Space) { pick.choose(); e.accepted = true } }
                        FocusRing {}
                        Rectangle {   // the dock's tile behind it
                            anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 7 }
                            width: 40; height: 40; radius: Math.round(40 * 0.27)
                            color: Qt.alpha(Theme.text, pickArea.containsMouse ? 0.17 : 0.07)
                            DockLauncherIcon {
                                anchors.centerIn: parent
                                style: pick.modelData[0]
                                size: 40
                                lit: pickArea.containsMouse || pick.activeFocus
                            }
                        }
                        Text {
                            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 5 }
                            text: pick.modelData[1]
                            color: pick.chosen ? Theme.text : Theme.subtext
                            font { family: Theme.font; pixelSize: Theme.fontCaption }
                        }
                        MouseArea {
                            id: pickArea
                            Accessible.role: Accessible.RadioButton
                            Accessible.name: "Launcher icon " + pick.modelData[1]
                            Accessible.checkable: true
                            Accessible.checked: pick.chosen
                            Accessible.onPressAction: pick.choose()
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: pick.choose()
                        }
                    }
                }
                DockLauncherIcon { id: iconSample; visible: false }   // only for its list of designs
            }
        }
        SettingRow {
            label: "Show open apps"
            hint: Config.dock.combine ? "Open apps that aren't pinned join after the pinned ones" : "Each window as its own tile, after the pinned apps"
            ConfigToggle { section: "dock"; key: "showRunning" }
        }
        SettingRow {
            visible: Config.dock.showRunning && !Config.dock.combine && !Config.dock.nameOnly && !page.inBar
            label: "Window pictures"
            hint: "A picture of each window, live while the pointer is on the dock. Off: just the app icon"
            ConfigToggle { section: "dock"; key: "thumbnails" }
        }
        SettingRow {
            id: refreshRow
            readonly property var presets: [30, 60, 300, 900]
            property bool custom: !presets.includes(Config.dock.thumbRefresh)
            property string error: ""
            visible: Config.dock.showRunning && Config.dock.thumbnails && !Config.dock.combine && !Config.dock.nameOnly && !page.inBar
            label: "Refresh pictures"
            hint: error !== "" ? error : "How often the pictures update while the pointer is elsewhere"
            Choice {
                options: ["30 s", "1 min", "5 min", "15 min", "Custom"]
                index: refreshRow.custom ? 4 : refreshRow.presets.indexOf(Config.dock.thumbRefresh)
                onPicked: i => {
                    refreshRow.custom = i === 4
                    if (i < 4) refreshRow.error = Config.set("dock", "thumbRefresh", refreshRow.presets[i])
                }
            }
        }
        SettingRow {
            visible: refreshRow.visible && refreshRow.custom
            label: "Every (seconds)"
            hint: "10 to 86400, Enter to save"
            TextField {
                width: 96
                text: Config.dock.thumbRefresh
                onAccepted: refreshRow.error = Config.set("dock", "thumbRefresh", Math.round(Number(text)))
            }
        }
    }

    SettingGroup {
        title: "Pinned apps · drag to reorder"
        Text {
            visible: page.pinned.length === 0
            Layout.fillWidth: true
            Layout.margins: 16
            text: "Nothing pinned. Search below to add an app."
            color: Theme.muted
            font { family: Theme.font; pixelSize: Theme.fontLabel }
        }
        Repeater {
            model: page.pinned
            DragItem {
                id: pin
                required property string modelData
                required property int index
                Layout.fillWidth: true
                implicitHeight: 46
                key: "pinned"
                payload: modelData
                floatOn: page.parent
                radius: Theme.radius
                AppRow {
                    anchors.fill: parent
                    entry: DesktopEntries.byId(pin.modelData)
                    fallback: pin.modelData
                    first: pin.index === 0 || pin.dragging
                    action: "Unpin"
                    onTriggered: page.remove(pin.modelData)
                }
                DropSpot { anchors.fill: parent; key: "pinned"; vertical: true; owner: pin; onPlaced: (id, after) => page.place(id, pin.modelData, after) }
            }
        }
        SettingRow {
            label: "Add an app"
            hint: "Type part of the app's name"
            TextField {
                id: search
                width: 220
                placeholder: "e.g. Files"
                onTextChanged: page.query = text
                onAccepted: if (page.matches.length) page.add(page.matches[0].id)
            }
        }
        Repeater {
            model: page.matches
            AppRow {
                required property var modelData
                entry: modelData
                action: "Add"
                onTriggered: page.add(modelData.id)
            }
        }
    }

    SettingGroup {
        visible: Config.dock.enabled && !page.inBar
        title: "Widgets · small tiles after the open windows"
        SettingRow { visible: page.widgets.length === 0; label: "No widgets on the dock"; hint: "Add one below" }
        Repeater {
            model: page.widgets
            SettingRow {
                id: wrow
                required property string modelData
                label: Theme.dockWidgets[modelData].name
                hint: Theme.dockWidgets[modelData].about
                Row {
                    spacing: 8
                    ArrowButton { glyph: "\u{F0143}"; tip: "Move " + wrow.label + " earlier"; enabled: page.widgets.indexOf(wrow.modelData) > 0; onClicked: page.moveWidget(wrow.modelData, -1) }
                    ArrowButton { glyph: "\u{F0140}"; tip: "Move " + wrow.label + " later"; enabled: page.widgets.indexOf(wrow.modelData) < page.widgets.length - 1; onClicked: page.moveWidget(wrow.modelData, 1) }
                    PillButton { text: "Remove"; onClicked: page.showWidget(wrow.modelData, false) }
                }
            }
        }
        SettingRow {
            visible: page.widgetList.length > page.widgets.length
            label: "Add a widget"
            hint: "It goes at the end; move it with the arrows"
        }
        Flow {
            visible: page.widgetList.length > page.widgets.length
            Layout.fillWidth: true; Layout.leftMargin: 16; Layout.rightMargin: 16; Layout.bottomMargin: 12
            spacing: 8
            Repeater {
                model: page.widgetList.filter(id => !page.widgets.includes(id))
                PillButton { required property string modelData; text: "+ " + Theme.dockWidgets[modelData].name; onClicked: page.showWidget(modelData, true) }
            }
        }
    }

    Text {
        Layout.fillWidth: true
        text: page.inBar ? "In the bar: click an open app to bring it up, middle-click for a new window. Size, hiding, previews and widgets are for a dock of its own: choose another place above."
                         : "In the dock: drag an icon along it to reorder, right-click it to pin, unpin, minimise or quit."
        color: Theme.subtext
        wrapMode: Text.Wrap
        font { family: Theme.font; pixelSize: Theme.fontCaption }
    }

    ResetGroup { sections: ["dock"] }
}
