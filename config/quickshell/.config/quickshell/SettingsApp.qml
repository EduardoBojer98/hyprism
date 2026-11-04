pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC

// The Settings app: one glass window with a sidebar of groups, each opening into its pages (a
// submenu in the sidebar, or tabs when the window is narrow); one page shows at a time.
// Open with Super+I, the Control Center's gear, the launcher ("Settings"), or
// `qs ipc call settings open [group or page]`.
Singleton {
    id: root

    property bool open: false
    property string section: "appearance"   // the group open in the sidebar
    property string pageId: "appearance"    // the page shown

    // The sidebar: groups like a normal desktop's settings, each with one or more pages.
    // Page ids still work everywhere (show("sound"), `qs ipc call settings open bluetooth`).
    // Adding a setting: put its row on the page it belongs to (SettingsPage<Id>.qml) and a word for
    // it in that page's `keys` below, so search finds it. Adding a page: a SettingsPage<Id>.qml, an
    // entry in allSections, and its id in one group here.
    readonly property var allGroups: [
        { id: "appearance", name: "Appearance",          glyph: "\u{F03D8}", pages: ["appearance", "builder", "wallpaper", "icons", "cursor"] },
        { id: "barGroup",   name: "Menu Bar",            glyph: "\u{F0E7F}", pages: ["bar"] },
        { id: "dockGroup",  name: "Dock",                glyph: "\u{F0A1F}", pages: ["dock"] },
        { id: "lockGroup",  name: "Lock Screen",         glyph: "\u{F033E}", pages: ["lockscreen"] },
        { id: "desktop",    name: "Desktop & Widgets",   glyph: "\u{F056E}", pages: ["controlcenter", "notifications", "launcher", "clipboard", "weather", "calendar", "hotcorners"] },
        { id: "windows",    name: "Windows",             glyph: "\u{F05AF}", pages: ["windows", "windowlook", "apprules"] },
        { id: "display",    name: "Displays",            glyph: "\u{F0379}", pages: ["displays", "monitor"] },
        { id: "input",      name: "Input",               glyph: "\u{F030C}", pages: ["input", "keybinds"] },
        { id: "sound",      name: "Sound",               glyph: "\u{F057E}", pages: ["sound"] },
        { id: "network",    name: "Network & Bluetooth", glyph: "\u{F05A9}", pages: ["network", "bluetooth"] },
        { id: "power",      name: "Power",               glyph: "\u{F0079}", pages: ["power", "idle", "asus"] },
        { id: "applications", name: "Apps",              glyph: "\u{F003B}", pages: ["installed", "apps", "startup"] },
        { id: "system",     name: "About",               glyph: "\u{F02FD}", pages: ["about", "language"] },
    ]
    // ASUS Hardware only on machines with asusctl
    readonly property var sections: allGroups.map(g => Object.assign({}, g, { pages: g.pages.filter(p => p !== "asus" || Machine.asus) }))
    readonly property var currentGroup: sections.find(g => g.id === section) ?? sections[0]
    function pageName(id) { return allSections.find(p => p.id === id)?.name ?? "" }

    // Pages: what each SettingsPage<Id>.qml is called, and the words search finds it by (Spotlight searches these too)
    readonly property var allSections: [
        { id: "appearance",    name: "Themes",              glyph: "\u{F03D8}", keys: "theme look colour accent font text size corners gaps shadow blur animations motion reduce terminal" },
        { id: "builder",       name: "Theme Builder",       glyph: "\u{F0E1E}", keys: "custom own theme create make editor colours fonts bar dock panels motion design" },
        { id: "wallpaper",     name: "Wallpaper",           glyph: "\u{F02E9}", keys: "background picture slideshow blur folder" },
        { id: "icons",         name: "Icons",               glyph: "\u{F0BC1}", keys: "icon theme papirus" },
        { id: "cursor",        name: "Cursor",              glyph: "\u{F01BF}", keys: "pointer mouse size" },
        { id: "bar",           name: "Menu Bar",            glyph: "\u{F0E7F}", keys: "panel top bottom left right position size floating items widgets clock seconds date 24-hour window title monitor" },
        { id: "dock",          name: "Dock",                glyph: "\u{F0A1F}", keys: "taskbar pinned apps icon size hide automatically running windows pictures position monitor" },
        { id: "lockscreen",    name: "Lock Screen",         glyph: "\u{F033E}", keys: "lock clock date avatar user picture blur brightness widgets battery media layout" },
        { id: "controlcenter", name: "Control Center",      glyph: "\u{F0493}", keys: "quick settings tiles toggles sliders shortcuts" },
        { id: "notifications", name: "Notifications",       glyph: "\u{F009A}", keys: "do not disturb dnd sound banners history muted apps" },
        { id: "launcher",      name: "Search & Launcher",   glyph: "\u{F0349}", keys: "spotlight apps files web search actions" },
        { id: "clipboard",     name: "Clipboard",           glyph: "\u{F014C}", keys: "copy paste history images" },
        { id: "weather",       name: "Weather",             glyph: "\u{F0595}", keys: "city forecast celsius fahrenheit" },
        { id: "calendar",      name: "Calendar",            glyph: "\u{F00ED}", keys: "holidays week numbers moon first day" },
        { id: "hotcorners",    name: "Hot Corners",         glyph: "\u{F0A1C}", keys: "corner action" },
        { id: "windows",       name: "Window Behaviour",    glyph: "\u{F05AF}", keys: "layout tiling dwindle master scrolling focus follows mouse split snap" },
        { id: "windowlook",    name: "Window Look",         glyph: "\u{F03D8}", keys: "title bars opacity dim inactive" },
        { id: "apprules",      name: "App Rules",           glyph: "\u{F0493}", keys: "float pin workspace rule" },
        { id: "displays",      name: "Displays",            glyph: "\u{F0379}", keys: "monitor resolution scale rotation refresh night light arrangement" },
        { id: "monitor",       name: "Shared Monitor",      glyph: "\u{F0E58}", keys: "ddc input switch kvm mirror" },
        { id: "input",         name: "Keyboard & Touchpad", glyph: "\u{F030C}", keys: "layout serbian latin repeat touchpad mouse sensitivity natural scroll tap" },
        { id: "keybinds",      name: "Keyboard Shortcuts",  glyph: "\u{F0313}", keys: "keys binds hotkeys" },
        { id: "sound",         name: "Sound",               glyph: "\u{F057E}", keys: "volume output input microphone speakers" },
        { id: "network",       name: "Wi-Fi & Network",     glyph: "\u{F05A9}", keys: "wifi ethernet internet vpn" },
        { id: "bluetooth",     name: "Bluetooth",           glyph: "\u{F00AF}", keys: "devices headphones pair" },
        { id: "power",         name: "Battery & Power",     glyph: "\u{F0079}", keys: "battery charge limit power profile performance warning" },
        { id: "idle",          name: "Lock & Sleep",        glyph: "\u{F04B2}", keys: "idle timeout screen off suspend" },
        { id: "asus",          name: "ASUS Hardware",       glyph: "\u{F061A}", keys: "fan curve keyboard light" },
        { id: "installed",     name: "Installed Apps",      glyph: "\u{F003B}", keys: "uninstall remove packages" },
        { id: "apps",          name: "Default Apps",        glyph: "\u{F003B}", keys: "browser mail terminal file manager task manager" },
        { id: "startup",       name: "Startup Apps",        glyph: "\u{F040A}", keys: "autostart login" },
        { id: "language",      name: "Language & Region",   glyph: "\u{F05CA}", keys: "locale formats date numbers" },
        { id: "about",         name: "About",               glyph: "\u{F02FD}", keys: "system version hardware" },
    ]
    // search: pages whose name, group or words match every word typed
    property string query: ""
    readonly property var results: {
        const words = query.trim().toLowerCase().split(/\s+/).filter(w => w)
        if (!words.length) return []
        const visible = sections.flatMap(g => g.pages.map(p => ({ page: p, group: g.name })))
        return visible.map(v => Object.assign({ group: v.group }, allSections.find(x => x.id === v.page)))
            .filter(p => p.id && words.every(w => (p.name + " " + p.group + " " + p.keys).toLowerCase().includes(w)))
    }

    // s: a group id (its first page), a page id, or "" (where you left off)
    function show(s) {
        const g = sections.find(x => x.id === s) ?? sections.find(x => x.pages.includes(s))
        if (g) { section = g.id; pageId = g.pages.includes(s) ? s : g.pages[0] }
        open = true
    }

    IpcHandler {
        target: "settings"
        function open(section: string): void { root.show(section) }
        function toggle(): void { root.open = !root.open }
    }

    // Lua table literal from a plain JS object (strings, numbers, booleans, nested objects)
    function lua(value, indent) {
        indent = indent || ""
        if (typeof value === "string") return JSON.stringify(value)
        if (typeof value === "number" || typeof value === "boolean") return String(value)
        const inner = indent + "    "
        return "{\n" + Object.keys(value).map(k =>
            inner + "[" + JSON.stringify(k) + "] = " + lua(value[k], inner) + ",").join("\n") + "\n" + indent + "}"
    }

    // Write a text file in the Hyprland config (the repo, through the stow link)
    function writeHyprFile(rel, text) {
        // mkdir: settings/ isn't in git (your own choices), so a fresh install has to create it
        Quickshell.execDetached(["sh", "-c", "f=\"$HOME/.config/hypr/" + rel + "\"; mkdir -p \"$(dirname \"$f\")\"; cat > \"$f\" <<'QS_EOF'\n" + text + "\nQS_EOF"])
    }

    FloatingWindow {
        id: win
        // Narrow window: the sidebar shrinks to icons and the page margins tighten; rows put their
        // control under the label when both don't fit (SettingRow). Anything still too big scrolls.
        readonly property bool compact: width < 780
        readonly property int pad: width < 640 ? Theme.spaceL : 28
        // filling (almost) the whole screen means Hyprland has it maximised
        readonly property bool maximised: screen ? width >= screen.width - 80 && height >= screen.height - 120 : false

        visible: root.open
        title: "Settings"
        color: "transparent"
        implicitWidth: 1020
        implicitHeight: 700
        minimumSize: Qt.size(460, 360)
        onVisibleChanged: if (!visible) root.open = false

        Glass {
            anchors.fill: parent
            strong: true
            radius: 0
            border.width: 0

            // ---- sidebar ---------------------------------------------------------------------
            Rectangle {
                id: sidebar
                anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                width: win.compact ? 64 : 240
                color: Theme.sidebar

                Flickable {
                    id: nav
                    anchors.fill: parent
                    contentHeight: navColumn.implicitHeight + 30
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    QQC.ScrollBar.vertical: GlassScrollBar {}

                    Column {
                        id: navColumn
                        x: 12; y: 18
                        width: sidebar.width - 24
                        spacing: 2

                        Text {
                            visible: !win.compact
                            text: "Settings"
                            leftPadding: 10
                            bottomPadding: 12
                            color: Theme.text
                            font { family: Theme.font; pixelSize: Theme.fontHeading; weight: Font.Bold }
                        }
                        TextField {   // search: type to list matching pages, Enter opens the first
                            id: searchField
                            visible: !win.compact
                            width: parent.width
                            placeholder: "Search settings"
                            onTextChanged: root.query = text
                            onAccepted: if (root.results.length) { root.show(root.results[0].id); text = "" }
                            Keys.onEscapePressed: text = ""
                        }
                        Item { width: 1; height: 8; visible: !win.compact }
                        Text {
                            visible: root.query.trim() !== "" && root.results.length === 0
                            leftPadding: 10; topPadding: 6
                            width: parent.width
                            wrapMode: Text.Wrap
                            text: "Nothing matches"
                            color: Theme.subtext
                            font { family: Theme.font; pixelSize: Theme.fontLabel }
                        }
                        Repeater {   // search results replace the groups while there is a query
                            model: root.results
                            Rectangle {
                                required property var modelData
                                width: parent.width
                                height: 44
                                radius: Theme.radiusSmall
                                color: resArea.containsMouse ? Theme.fillHover : "transparent"
                                Column {
                                    anchors { left: parent.left; leftMargin: 10; right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                                    Text { width: parent.width; elide: Text.ElideRight; text: modelData.name; color: Theme.text
                                           font { family: Theme.font; pixelSize: Theme.fontLabel + 1; weight: Font.DemiBold } }
                                    Text { width: parent.width; elide: Text.ElideRight; text: modelData.group; color: Theme.subtext
                                           font { family: Theme.font; pixelSize: Theme.fontCaption } }
                                }
                                MouseArea { id: resArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                            onClicked: { root.show(modelData.id); searchField.text = "" } }
                            }
                        }

                        Repeater {
                            model: root.query.trim() === "" ? root.sections : []
                            Column {
                                id: navGroup
                                required property var modelData
                                readonly property bool current: root.section === modelData.id
                                readonly property bool open: current && modelData.pages.length > 1 && !win.compact
                                width: parent.width
                                spacing: 2
                                Rectangle {
                                    width: parent.width
                                    height: 34
                                    radius: Theme.radiusSmall
                                    color: current ? Theme.fillActive : navArea.containsMouse ? Theme.fillHover : "transparent"
                                    border { color: current ? Theme.stroke : "transparent"; width: 1 }
                                    Row {
                                        anchors { left: parent.left; leftMargin: win.compact ? (parent.width - 24) / 2 : 10; verticalCenter: parent.verticalCenter }
                                        spacing: 10
                                        Rectangle {
                                            width: 24; height: 24; radius: Math.min(7, Theme.radiusSmall)
                                            color: current ? Theme.accent : Theme.fill
                                            Text {
                                                anchors.centerIn: parent
                                                text: modelData.glyph
                                                color: current ? Theme.accentText : Theme.text
                                                font { family: Theme.iconFont; pixelSize: Theme.iconSmall - 2 }
                                            }
                                        }
                                        Text {
                                            visible: !win.compact
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: sidebar.width - 24 - 54
                                            elide: Text.ElideRight
                                            text: modelData.name
                                            color: Theme.text
                                            font { family: Theme.font; pixelSize: Theme.fontLabel; weight: current ? Font.DemiBold : Font.Normal }
                                        }
                                    }
                                    MouseArea { id: navArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.show(modelData.id) }
                                }
                                // submenu: the open group's pages
                                Repeater {
                                    model: navGroup.open ? navGroup.modelData.pages : []
                                    Rectangle {
                                        required property string modelData
                                        readonly property bool current: root.pageId === modelData
                                        width: parent.width
                                        height: 30
                                        radius: Theme.radiusSmall
                                        color: current ? Theme.accentWash : subArea.containsMouse ? Theme.fillHover : "transparent"
                                        Rectangle {   // a short accent bar beside the page you're on
                                            visible: parent.current
                                            anchors { left: parent.left; leftMargin: 26; verticalCenter: parent.verticalCenter }
                                            width: 3; height: 14; radius: 1.5
                                            color: Theme.accent
                                        }
                                        Text {
                                            anchors { left: parent.left; leftMargin: 44; right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                                            text: root.pageName(modelData)
                                            elide: Text.ElideRight
                                            color: parent.current ? Theme.text : Theme.subtext
                                            font { family: Theme.font; pixelSize: Theme.fontLabel; weight: parent.current ? Font.DemiBold : Font.Normal }
                                        }
                                        MouseArea { id: subArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.show(modelData) }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Rectangle { // divider
                anchors { left: sidebar.right; top: parent.top; bottom: parent.bottom }
                width: 1
                color: Theme.stroke
            }

            // ---- page ------------------------------------------------------------------------
            Flickable {
                id: page
                anchors { left: sidebar.right; leftMargin: 1; right: parent.right; top: parent.top; bottom: parent.bottom }
                contentHeight: pageColumn.implicitHeight + win.pad * 2
                contentWidth: pageColumn.width + win.pad * 2     // wider than the window only below ~340 px of page
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                QQC.ScrollBar.vertical: GlassScrollBar {}
                QQC.ScrollBar.horizontal: GlassScrollBar {}

                Connections { target: root; function onPageIdChanged() { page.contentY = 0; page.contentX = 0 } }

                ColumnLayout {
                    id: pageColumn
                    x: win.pad; y: win.pad
                    width: Math.max(page.width - win.pad * 2, 340)
                    spacing: 16

                    Column {
                        Layout.fillWidth: true
                        Layout.rightMargin: 100   // clear of the window buttons
                        spacing: 2
                        Text {   // the group, small, above the page's own title
                            visible: root.currentGroup.pages.length > 1
                            text: root.currentGroup.name
                            color: Theme.subtext
                            font { family: Theme.font; pixelSize: Theme.fontCaption; weight: Font.Medium }
                        }
                        Text {
                            width: parent.width
                            text: root.pageName(root.pageId)
                            elide: Text.ElideRight
                            color: Theme.text
                            font { family: Theme.displayFont; pixelSize: Theme.fontHeading + 1; weight: Theme.displayWeight > Font.Medium ? Theme.displayWeight : Font.Bold }
                        }
                    }

                    // narrow window: the sidebar shows icons only, so the group's pages become tabs
                    Choice {
                        visible: win.compact && root.currentGroup.pages.length > 1
                        options: root.currentGroup.pages.map(p => root.pageName(p))
                        index: root.currentGroup.pages.indexOf(root.pageId)
                        onPicked: i => root.show(root.currentGroup.pages[i])
                    }

                    Loader {
                        Layout.fillWidth: true
                        active: root.open
                        source: "SettingsPage" + root.pageId.charAt(0).toUpperCase() + root.pageId.slice(1) + ".qml"
                    }
                }
            }

            // ---- window buttons: minimise, maximise, close (the shell draws its own, like a GTK app) ----
            Row {
                anchors { top: parent.top; right: parent.right; margins: 12 }
                spacing: 8
                Repeater {
                    model: [
                        { glyph: "\u{F05B0}", tip: "Minimise", act: () => Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.window.move({ workspace = \"special:minimized\", follow = false })"]) },
                        { glyph: win.maximised ? "\u{F05B2}" : "\u{F05AF}", tip: win.maximised ? "Restore" : "Maximise", act: () => Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.window.fullscreen({ action = \"toggle\", mode = \"maximized\" })"]) },
                        { glyph: "\u{F05AD}", tip: "Close", act: () => root.open = false }
                    ]
                    Rectangle {
                        required property var modelData
                        width: 24; height: 24; radius: 12
                        color: btnArea.pressed ? Theme.fillActive : btnArea.containsMouse ? Theme.fillHover : Theme.fill
                        border { color: Theme.stroke; width: 1 }
                        Text {
                            anchors.centerIn: parent
                            text: modelData.glyph
                            color: Theme.text
                            font { family: Theme.iconFont; pixelSize: 13 }
                        }
                        MouseArea { id: btnArea; anchors.fill: parent; hoverEnabled: true; onClicked: modelData.act() }
                        ToolTipText { shown: btnArea.containsMouse; text: modelData.tip }
                    }
                }
            }
        }
    }
}
