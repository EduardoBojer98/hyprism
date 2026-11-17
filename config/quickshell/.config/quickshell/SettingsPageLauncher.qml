import QtQuick
import QtQuick.Layouts

// Search & Launcher: Spotlight (tap Super): its style (the theme's own or a preset, drawn as a gallery),
// how it opens and the result order. Your own actions are made in Settings > Actions (SettingsPageActions.qml).
ColumnLayout {
    id: page
    spacing: 20

    // Result groups: drag to reorder, turn on/off (Config.launcher.order lists the ones that are on)
    readonly property var allGroups: ["apps", "files", "calc", "settings", "actions", "web"]
    readonly property var groupRows: Config.launcher.order.concat(allGroups.filter(g => !Config.launcher.order.includes(g)))
    // dragging `g` before or after `target`; onto a hidden group it is hidden too, and a hidden one
    // dropped among the shown ones comes back there
    function placeGroup(g, target, after) {
        if (g === target) return
        const o = Config.launcher.order.filter(x => x !== g), i = o.indexOf(target)
        if (i >= 0) o.splice(i + (after ? 1 : 0), 0, g)
        Config.set("launcher", "order", o)
    }
    function toggleGroup(g) {
        const o = Array.from(Config.launcher.order)
        Config.set("launcher", "order", o.includes(g) ? o.filter(x => x !== g) : o.concat([g]))
    }

    // Style: the theme's own launcher or one of Launcher.styles, each drawn in the active theme's colours
    SettingGroup {
        title: "Style"
        SettingRow {
            label: "Open"
            hint: Config.launcher.position === "center" ? "Super opens it in the middle of the screen you're working on, in every style"
                : Config.launcher.position === "pointer" ? "Super opens it around the mouse pointer, on the screen you're working on"
                : "Where the style puts it: centred, or along a screen edge"
            ConfigChoice { section: "launcher"; key: "position"; values: ["center", "pointer", "theme"]; labels: ["Middle", "At the pointer", "Style's place"] }
        }
        Text {
            Layout.fillWidth: true
            Layout.margins: 16
            Layout.bottomMargin: 0
            text: "Where Spotlight opens and its shape. Colours and fonts always follow the theme, so every style works in every theme."
            color: Theme.subtext
            wrapMode: Text.Wrap
            font { family: Theme.font; pixelSize: Theme.fontLabel }
        }
        GridLayout {
            Layout.fillWidth: true
            Layout.margins: 12
            columns: Math.max(2, Math.floor((width + columnSpacing) / (190 + columnSpacing)))
            columnSpacing: 14
            rowSpacing: 16
            Repeater {
                model: ["theme"].concat(Launcher.styleIds)
                LauncherStylePreview {
                    required property string modelData
                    readonly property var style: Launcher.styles[modelData] ?? null
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    // drawn where it will open: centred unless "Style's place", and on the view you start on
                    spec: Object.assign({}, style ?? Theme.current.launcher,
                        Config.launcher.position !== "theme" ? { placement: "center" } : {},
                        ({ home: { view: "home" }, apps: { view: "grid" }, search: { view: "inline" } })[Config.launcher.startView] ?? {})
                    label: style ? style.name : Theme.current.name + "'s own"
                    about: style ? style.about : "Follows the theme, and changes with it"
                    chosen: (Config.launcher.style ?? "theme") === modelData
                    onPicked: Config.set("launcher", "style", modelData)
                }
            }
        }
    }

    SettingGroup {
        title: "Spotlight"
        SettingRow {
            label: "Before you type, show"
            hint: Config.launcher.startView === "theme" ? "Launchpad and Drawer open on all apps, Terminal on the search field, the others on suggestions" : ""
            ConfigChoice { section: "launcher"; key: "startView"; values: ["home", "apps", "search", "theme"]; labels: ["Suggestions", "All apps", "Just the search field", "The style's own"] }
        }
        SettingRow {
            label: "Apps per row"
            hint: "In All apps; fewer when the panel is too narrow for them"
            ConfigChoice { section: "launcher"; key: "columns"; values: [5, 6, 7, 8, 9] }
        }
        SettingRow {
            label: "Clipboard button"
            hint: "Super+V always opens the history at the pointer"
            ConfigChoice { section: "launcher"; key: "clipboardInside"; values: [true, false]; labels: ["History inside Spotlight", "Open the clipboard popup"] }
        }
    }

    SettingGroup {
        title: "Result order"
        Repeater {
            model: page.groupRows
            DragItem {
                id: groupRow
                required property string modelData
                required property int index
                readonly property bool on: Config.launcher.order.includes(modelData)
                Layout.fillWidth: true
                implicitHeight: rowContent.implicitHeight
                key: "launcherGroups"
                payload: modelData
                floatOn: page.parent
                radius: Theme.radius
                SettingRow {
                    id: rowContent
                    anchors.fill: parent
                    label: "\u{2807}  " + (groupRow.on ? (groupRow.index + 1) + ".  " : "") + Search.groupNames[groupRow.modelData]
                    hint: groupRow.on ? "" : "Hidden from results · drag it among the others or switch it on"
                    Toggle { checked: groupRow.on; onToggled: page.toggleGroup(groupRow.modelData) }
                }
                DropSpot { anchors.fill: parent; key: "launcherGroups"; vertical: true; owner: groupRow; onPlaced: (g, after) => page.placeGroup(g, groupRow.modelData, after) }
            }
        }
    }

    SettingGroup {
        title: "Search"
        SettingRow {
            label: "Web search"
            hint: "Used when nothing else matches"
            ConfigChoice {
                section: "launcher"; key: "webSearch"
                values: ["https://duckduckgo.com/?q=%s", "https://www.google.com/search?q=%s", "https://search.brave.com/search?q=%s", "https://www.startpage.com/do/search?q=%s"]
                labels: ["DuckDuckGo", "Google", "Brave", "Startpage"]
            }
        }
        SettingRow {
            label: "Search files in your home folder"
            hint: "Skips node_modules, vendor and hidden folders"
            ConfigToggle { section: "launcher"; key: "showFiles" }
        }
        SettingRow {
            label: "Forget what you used"
            hint: "Clears the most-used ranking and the Recent list on the suggestions"
            PillButton { text: "Forget"; onClicked: { Config.set("launcher", "usage", {}); Config.set("launcher", "recent", []) } }
        }
    }

    SettingGroup {
        title: "Your actions"
        SettingRow {
            label: "Commands, snippets, folders and toggles"
            hint: "Made in Settings > Actions; the ones set to show in Spotlight come up when you type their name"
            PillButton { text: "Open Actions"; onClicked: SettingsApp.show("actions") }
        }
    }

    ResetGroup { sections: ["launcher"] }
}
