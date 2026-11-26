import QtQuick
import QtQuick.Layouts

// Search & Launcher: Spotlight (tap Super): its style (the theme's own or a preset, drawn as a gallery; picking
// one resets the look options so it opens as designed), where it opens, its look, suggestions, result order and search. Your own actions are made in Settings > Actions (SettingsPageActions.qml).
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

    // Picking a style starts it as designed: the look options below go back to the style's own, so no two styles
    // end up looking alike under the same overrides. Where it opens (Open, beside the button) and your other options
    // (suggestions, order, search) stay: Open is the one place setting for every style.
    readonly property var lookKeys: ({ startView: "theme", rows: "style", dim: "style", corners: "style", size: 100 })
    readonly property bool tweaked: Object.keys(lookKeys).some(k => Config.launcher[k] !== lookKeys[k])
    readonly property string styleName: Launcher.preset ? Launcher.preset.name : Theme.current.name + "'s own"
    function asDesigned() { for (const k of Object.keys(lookKeys)) Config.set("launcher", k, lookKeys[k]) }
    function pick(id) { Config.set("launcher", "style", id); asDesigned() }

    // Style: the theme's own launcher or one of Launcher.styles, each drawn in the active theme's colours
    SettingGroup {
        title: "Style"
        Text {
            Layout.fillWidth: true
            Layout.margins: 16
            Layout.bottomMargin: 0
            text: "Each style is its own way to work, in its own place. Picking one starts it as designed; colours and fonts follow the theme."
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
                    // the chosen one as you adjusted it, the rest as designed
                    spec: Object.assign({}, style ?? Launcher.styles[Theme.current.launcher.style] ?? Theme.current.launcher, !chosen ? {} : Object.assign(
                        Config.launcher.position !== "theme" ? { placement: "center" } : {},
                        ({ home: { view: "home" }, apps: { view: "grid" }, search: { view: "inline" } })[Config.launcher.startView] ?? {},
                        Config.launcher.rows !== "style" ? { rows: Config.launcher.rows } : {},
                        Config.launcher.corners !== "style" ? { corners: Config.launcher.corners === "soft" ? "round" : Config.launcher.corners } : {}))
                    label: style ? style.name : Theme.current.name + "'s own"
                    about: style ? style.about : "Follows the theme, and changes with it"
                    chosen: (Config.launcher.style ?? "theme") === modelData
                    onPicked: page.pick(modelData)
                }
            }
        }
    }

    // where it opens: one setting for every style, kept when you pick another
    SettingGroup {
        title: "Where it opens"
        SettingRow {
            label: "Open"
            hint: Config.launcher.position === "center" ? "In the middle of the screen you're working on"
                : Config.launcher.position === "pointer" ? "Around the mouse pointer, on the screen you're working on"
                : "Where " + page.styleName + " goes: " + (({ center: "the middle", fullscreen: "the whole screen", island: "a sheet from the bottom", column: "a column on the left", strip: "a strip along the top", half: "half the screen", corner: "a corner" })[Launcher.rl.placement] ?? "its own place")
            ConfigChoice { section: "launcher"; key: "position"; values: ["theme", "center", "pointer"]; labels: ["Style's place", "Middle", "At the pointer"] }
        }
        SettingRow {
            label: "Beside the button you click"
            hint: Config.launcher.besideButton ? "A bar or dock button opens it next to that button; shortcuts use Open"
                                               : "Off: the dock, the bar and the shortcuts all open it in the same place"
            ConfigToggle { section: "launcher"; key: "besideButton" }
        }
    }

    // your adjustments over the chosen style; "Style's own" leaves each to it
    SettingGroup {
        title: "Look of " + page.styleName
        SettingRow {
            label: "See it"
            hint: "Opens the launcher over this window, as you've set it"
            PillButton { text: "Open launcher"; onClicked: Launcher.show("search") }
        }
        SettingRow {
            label: "Before you type, show"
            hint: Config.launcher.startView === "theme" ? page.styleName + " opens on " + ({ apps: "every app", search: "just the search field", home: "suggestions" })[Launcher.look.startView] : ""
            ConfigChoice { section: "launcher"; key: "startView"; values: ["theme", "home", "apps", "search"]; labels: ["Style's own", "Suggestions", "All apps", "Search field"] }
        }
        SettingRow {
            label: "Size"
            hint: "Width, search bar and icons, against the style's own"
            ConfigSlider { section: "launcher"; key: "size"; from: 80; to: 130; step: 5; format: v => v + " %" }
        }
        SettingRow {
            label: "Rows"
            hint: ({ style: "As the style draws them", standard: "Icon, name and a second line", compact: "One line each, small icons: more on screen",
                     cards: "Tall rows with big icons, easy to hit", text: "No icons, a column saying what each result is" })[Config.launcher.rows] ?? ""
            ConfigChoice { section: "launcher"; key: "rows"; values: ["style", "standard", "compact", "cards", "text"]; labels: ["Style's own", "Standard", "Compact", "Cards", "Text"] }
        }
        SettingRow {
            label: "Corners"
            ConfigChoice { section: "launcher"; key: "corners"; values: ["style", "sharp", "soft", "round"]; labels: ["Style's own", "Square", "Soft", "Round"] }
        }
        SettingRow {
            label: "Screen behind it"
            ConfigChoice { section: "launcher"; key: "dim"; values: ["style", "none", "light", "dark"]; labels: ["Style's own", "Clear", "Dimmed", "Dark"] }
        }
        SettingRow {
            label: "Second line under results"
            hint: "A file's folder, an app's description"
            ConfigToggle { section: "launcher"; key: "subtitles" }
        }
        SettingRow {
            label: "Key hints"
            hint: "The keys and what they do, under the results"
            ConfigToggle { section: "launcher"; key: "hints" }
        }
        SettingRow {
            label: "Back to how " + page.styleName + " is designed"
            hint: page.tweaked ? "Puts the look options above back to the style's own" : "Nothing changed"
            PillButton { text: "Reset"; enabled: page.tweaked; onClicked: page.asDesigned() }
        }
    }

    SettingGroup {
        title: "Results"
        SettingRow {
            label: "Results at most"
            ConfigSlider { section: "launcher"; key: "maxResults"; from: 10; to: 80; step: 5; format: v => String(v) }
        }
        SettingRow {
            label: "Apps per row"
            hint: "In All apps and Launchpad; fewer when the panel is too narrow for them"
            ConfigChoice { section: "launcher"; key: "columns"; values: [5, 6, 7, 8, 9] }
        }
        SettingRow {
            label: "Clipboard button"
            hint: "Super+V always opens the history at the pointer"
            ConfigChoice { section: "launcher"; key: "clipboardInside"; values: [true, false]; labels: ["History inside", "Clipboard popup"] }
        }
        SettingRow {
            visible: Config.launcher.style === "launchpad" || (Config.launcher.padLayout ?? []).length > 0
            label: "Launchpad arrangement"
            hint: (Config.launcher.padLayout ?? []).length ? "Your order and folders. Reset puts every app back by name, with no folders"
                : "By name. In Launchpad, hold an icon and drag it to move it; drop it on another app to make a folder"
            PillButton { text: "Reset"; enabled: (Config.launcher.padLayout ?? []).length > 0; onClicked: Config.set("launcher", "padLayout", []) }
        }
    }

    SettingGroup {
        title: "Suggestions"
        Text {
            Layout.fillWidth: true
            Layout.margins: 16
            Layout.bottomMargin: 4
            text: "What the suggestions show before you type. A style shows only the parts that suit it."
            color: Theme.subtext
            wrapMode: Text.Wrap
            font { family: Theme.font; pixelSize: Theme.fontLabel }
        }
        Repeater {
            model: [{ id: "glance", label: "Today at a glance", hint: "Weather, your next event and the last thing you copied" },
                    { id: "frequent", label: "Frequently used apps", hint: "The apps you open most" },
                    { id: "recent", label: "Recent", hint: "What you opened from here lately" },
                    { id: "quick", label: "Quick actions", hint: "Lock, screenshot, Night Light and the like" }]
            SettingRow {
                id: sug
                required property var modelData
                readonly property bool on: Config.launcher.home.includes(modelData.id)
                label: modelData.label
                hint: modelData.hint
                Toggle {
                    checked: sug.on
                    accessibleName: sug.modelData.label
                    onToggled: on => Config.set("launcher", "home", on ? Array.from(Config.launcher.home).concat([sug.modelData.id]) : Config.launcher.home.filter(h => h !== sug.modelData.id))
                }
            }
        }
        Text {
            Layout.fillWidth: true
            Layout.leftMargin: 16; Layout.rightMargin: 16; Layout.topMargin: 8
            text: "Quick actions to show, in the order you pick them. Recent leaves them out."
            color: Theme.subtext
            wrapMode: Text.Wrap
            font { family: Theme.font; pixelSize: Theme.fontLabel }
        }
        Flow {
            Layout.fillWidth: true
            Layout.margins: 16
            Layout.topMargin: 8
            spacing: Theme.spaceS
            Repeater {
                model: Actions.all.filter(a => (a.showIn ?? []).includes("launcher") && Actions.available(a))
                Chip {
                    required property var modelData
                    readonly property var picked: Array.from(Config.launcher.quickActions)
                    icon: modelData.icon || "\u{F018D}"
                    label: modelData.name
                    active: picked.includes(modelData.id)
                    accessibleName: modelData.name
                    onClicked: Config.set("launcher", "quickActions", active ? picked.filter(id => id !== modelData.id) : picked.concat([modelData.id]))
                }
            }
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
            label: "Quick Look"
            hint: "Move onto a file with ↑↓ and press Space (or Ctrl+Y) for a large preview. From a file manager: qs ipc call quicklook open PATH"
            ConfigToggle { section: "launcher"; key: "quickLook" }
        }
        SettingRow {
            label: "Converters"
            hint: "Units, money, time zones and dates as you type: 5 km in mi, 100 eur to ron, 3pm tokyo, days until 25 dec"
            ConfigToggle { section: "launcher"; key: "converters" }
        }
        SettingRow {
            visible: Config.launcher.converters
            label: "Exchange rates"
            hint: (Search.ratesAge || "Fetched the first time you convert money") + ". From the European Central Bank, at most once a day; offline, the last ones"
            PillButton { text: "Refresh now"; onClicked: Search.refreshRates(true) }
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
